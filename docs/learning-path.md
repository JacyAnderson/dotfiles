# Learning path: getting fluent with this setup

Tailored to this repo's actual layout. Work through the levels in order; each
exercise is ~10 minutes and uses your own machine, not a tutorial sandbox.

## First: the one mental model everything hangs off

The machine is a **cache of this repo**, not a pet configured by hand. Every
`./rebuild.sh` evaluates the repo into an immutable "generation" in
`/nix/store` and flips symlinks to point at it. Nothing is edited in place;
old generations stick around, which is why rollback is trivial and
experimentation is safe.

The repo has **five layers**, top of file to bottom of stack:

| Layer | File | Owns |
|---|---|---|
| Flake | `flake.nix` + `flake.lock` | *Which versions of everything* (pinned inputs), and which machines exist |
| Host | `hosts/<LocalHostName>.nix` | *This* machine: its macOS user, architecture, profile |
| nix-darwin | `configuration.nix` + `profiles/*/system.nix` | macOS itself: `system.defaults`, Homebrew orchestration |
| home-manager | `home.nix` + `profiles/*/home.nix` | Your user: CLI packages, zsh, git, starship |
| Plain dotfiles | `home/.config/*` | wezterm/nvim/herdr configs, symlinked edit-in-place |

And **two change loops** — knowing which one you're in prevents 90% of
confusion:

- **Fast loop:** edit anything under `home/.config/` → live immediately
  (out-of-store symlinks). No rebuild.
- **Declarative loop:** edit any `.nix` file → `./rebuild.sh` → new
  generation.

## Level 1 — Operate it (this week)

Goal: the daily loop becomes muscle memory.

1. **Add a CLI tool.** Find something at
   [search.nixos.org/packages](https://search.nixos.org/packages) (try `htop`
   or `tldr`), add it to `home.packages` in `home.nix`, run `./rebuild.sh`,
   open a new tab, run it. *Teaches: the package loop and where packages come
   from.*
2. **Add a shell alias** to `shellAliases` in `home.nix` and rebuild. Then
   notice `~/.zshrc` is generated — `readlink ~/.zshrc` — you never edit it
   directly anymore. *Teaches: home-manager owns files you used to
   hand-edit.*
3. **Break something on purpose, then roll back.** Introduce a typo in
   `home.nix`, run `./rebuild.sh`, read the error (the real message is
   usually in the last 10 lines). Fix it. Then run
   `darwin-rebuild --list-generations` to see your history. *Teaches: failed
   builds never touch the running system — the safety property that makes
   this whole approach worth it.*

## Level 2 — Understand the machinery (weeks 2–3)

1. **Read `flake.nix` until it stops being magic.** The `inputs` are pinned
   by `flake.lock` (open it — just JSON with git revisions). The `follows`
   lines force all three tools to share one nixpkgs so you don't get two
   copies of everything. Run `nix flake metadata ~/.dotfiles` to see the
   pins.
2. **Trace a symlink chain.** `ls -la ~/.config/nvim` → store path → this
   repo. Then contrast with `readlink ~/.zshrc` (fully store-managed).
   Knowing which files are which tells you when a rebuild is needed.
3. **Do the staged Homebrew adoption.** `profiles/personal/system.nix` sets
   `onActivation.cleanup = "none"` for the first verified switch; flip it to
   `"zap"` once confident, and Homebrew becomes declarative — anything not
   listed in `brews`/`casks` gets removed. Run `brew list` first and declare
   anything you actually want to keep. *Teaches the "declare or lose it"
   philosophy.*
4. **Change a macOS default.** Browse the
   [nix-darwin options manual](https://nix-darwin.github.io/nix-darwin/manual/)
   (e.g., `dock.tilesize`, screenshot location), add to `system.defaults`,
   rebuild. *Teaches: even OS preferences are code now.*

## Level 3 — Fluency (month 2)

1. **Update your pins:** `nix flake update` then `./rebuild.sh`. If anything
   breaks, `git checkout flake.lock` + rebuild = instant undo. This is the
   "system update" ritual — deliberate, reviewable, reversible.
2. **Learn just enough Nix-the-language** to read modules confidently:
   attribute sets, `let/in`, functions like `{ config, pkgs, user, ... }:`.
   Best resources for this setup: [Zero to Nix](https://zero-to-nix.com)
   (by Determinate, matches the installer) then [nix.dev](https://nix.dev).
   Skip NixOS-the-Linux-distro material and derivation-writing.
3. **Disk hygiene:** old generations accumulate; `sudo nix store gc`
   reclaims them. Do it once so it's not scary.
4. **Search skills:**
   [home-manager options](https://home-manager-options.extranix.com) and the
   nix-darwin manual answer most "is there an option for X" questions —
   usually yes.

## Level 4 — Extend (when a real need appears)

- **Per-project dev environments** (`nix develop` + direnv) — pinned
  Node/tool versions per repo instead of nvm. Only adopt when nvm actually
  bites.
- **A second machine:** drop a `hosts/<LocalHostName>.nix` next to the existing
  one and give it a profile (`./bootstrap.sh` writes that file for you) — this
  is where the architecture pays off dramatically. Note that `flake.nix` itself
  is never edited to add a machine, which is the property that keeps two
  checkouts identical to git and able to pull from each other.

## Two habits worth keeping

- The comments in `configuration.nix` (why `nix.enable = false`) and in
  `profiles/personal/system.nix` (why certain casks are deliberately absent) are
  decision records. When something seems weird, read the comment before
  searching the web.
- If you know React, you already know the model: config files are props,
  `./rebuild.sh` is the render, generations are immutable snapshots. When in
  doubt, ask "what would React do" — you'll usually guess Nix's behavior
  correctly.
