# dotfiles

My Mac setup, managed with nix-darwin and home-manager.
One repo, one command, and the whole machine is configured the same way every time.

Forked from [Kun Chen's dotfiles](https://github.com/kunchenguid/dotfiles)
([walkthrough video](https://youtu.be/5N-okeDdIuI)) and adapted for my machine.
His structure and design decisions are kept; the contents are mine.

## What you get

Running the switch builds:

- System settings (dark mode, fast key repeat, tap to click, dock)
- Homebrew apps (WezTerm, herdr, gh, tmux, terminal-notifier)
- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Neovim, Hack Nerd Font)
- Shell (zsh, aliases, starship prompt, nvm)
- Editor (Neovim config with the rose-pine moon theme)
- Terminal (WezTerm config with the rose-pine moon theme)
- tmux config (fleet workflow for running multiple Claude Code agents)
- Agent configs: a tool-agnostic `home/AGENTS.md` shared by Claude, Codex, and
  opencode, plus a Claude-specific overlay in `home/claude/CLAUDE.md`

## How this was adopted (not a fresh machine)

This config was adopted onto an already-configured Mac, which is worth knowing if
you ever repeat the process:

1. Everything already working (Homebrew leaves, shell exports, Claude Code setup,
   tmux config, git identity) was either declared in the config or deliberately shed.
2. The first `darwin-rebuild switch` ran with `homebrew.onActivation.cleanup = "none"`.
3. Only after verifying nothing broke was cleanup flipped to `"zap"`.

`zap` means: every switch removes any Homebrew package or cask not listed in
`configuration.nix`. That is intentional - it forces every package to be declared.
Read `brews` and `casks` before running a switch on a machine with existing
Homebrew packages.

## Prerequisites

- Apple Silicon Mac. For Intel, set `nixpkgs.hostPlatform = "x86_64-darwin";` in
  `configuration.nix`.

## Fresh-machine setup

```sh
git clone https://github.com/JacyAnderson/dotfiles.git
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config
   files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username,
   and offers to fix it if they differ.
4. Runs the first `darwin-rebuild switch`.

After that, `darwin-rebuild` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed, check that the config builds without touching the system:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

You only need a rebuild for changes that aren't symlinked files (package lists,
system defaults). The files under `home/` are live - editing them is editing the
running config.

## Repo tour

- `flake.nix` - the entry point. Wires up nixpkgs, nix-darwin, home-manager, and
  nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config: shell, packages, prompt, git identity, symlinks.
- `rebuild.sh` - re-applies the config after the first switch.
- `home/` - config files symlinked into place (Neovim, WezTerm, herdr, tmux,
  Claude settings, the shared `AGENTS.md`).
- `home/claude/` - Claude Code helpers reached by path, not symlink: statusline,
  fleet notification hook, fleet shell helpers, orchestration reference, and the
  Claude-specific `CLAUDE.md` overlay.

## How the symlinks work

The files under `home/` are the real files - editing them here is editing the live
config. `home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim`
straight at this repo, so the two never drift out of sync.

`~/.claude` deliberately gets only two symlinks (`settings.json` and `CLAUDE.md`):
that directory is Claude Code's mutable state, not a config directory. Everything
else in `home/claude/` is referenced by its `~/.dotfiles/...` path, which
`bootstrap.sh` guarantees exists before the first build.

## Notes

The first time you launch `nvim`, it bootstraps lazy.nvim by cloning plugins from
GitHub. That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.

## License

MIT No Attribution. See `LICENSE`.
