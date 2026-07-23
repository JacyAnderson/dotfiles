# Project notes for agents

This repo is a fork of Kun Chen's dotfiles, adapted for Jacy Anderson's machine.
Deliberate decisions - do NOT silently revert them:

- Per-machine facts live in `hosts/<LocalHostName>.nix` and nowhere else; per-context settings live
  in `profiles/<profile>/`. Never move a machine's user, architecture, or identity back into a
  shared file, and never add a script that rewrites a tracked file to match the local machine. That
  is the exact bug this layout removed: a rewritten checkout diverges from git and can never pull
  cleanly again. Adding a machine must stay a matter of adding a file.
- Homebrew lives in `profiles/<profile>/system.nix`, not `configuration.nix`, so a profile can own
  its package set or decline Homebrew without overriding a shared definition.
- `homebrew.onActivation.cleanup` is currently `"none"` on the personal profile, which is the staged
  adoption state, not the destination. The intent is `"zap"` - it forces the good habit of declaring
  every Homebrew package instead of installing things ad-hoc. Do not soften that intent, and do not
  flip it to `"zap"` without first confirming `brews`/`casks` covers everything `brew leaves` and
  `brew list --cask` report, because `zap` removes anything undeclared.
- `~/.claude` gets exactly two symlinks (`settings.json`, `CLAUDE.md`). That directory is Claude
  Code's mutable state; do not add more `home.file` entries into it. Helper scripts live in
  `home/claude/` and are referenced by their `~/.dotfiles/...` paths instead (bootstrap.sh creates
  that symlink before the first build, so the paths are guaranteed).
- `home/AGENTS.md` is tool-agnostic on purpose - it fans out to Claude, Codex, and opencode.
  Claude-specific policy belongs in `home/claude/CLAUDE.md`, which imports it. Do not add
  Claude-only content to the shared file.
- The `claude-code` cask is deliberately absent: Claude Code is installed via the native installer
  at `~/.local/bin/claude`. Adding the cask would create a second competing install.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
