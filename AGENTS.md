# Project notes for agents

This repo is a fork of Kun Chen's dotfiles, adapted for Jacy Anderson's machine.
Deliberate decisions - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional. It forces the good
  habit of declaring every Homebrew package in the Nix config instead of installing things ad-hoc,
  which keeps the machine reproducible. Do not soften it to `uninstall` or `none`.
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
