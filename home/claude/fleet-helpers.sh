#!/usr/bin/env bash
# Claude Code fleet helpers - umbrella level (works in any project).
# Sourced from programs.zsh.initContent in home.nix as
# `source ~/.dotfiles/home/claude/fleet-helpers.sh`.
#
# Monitoring helpers work anywhere. Spawn (ccnew) defers to a project's
# bin/stream when present (Immersion Finder), else falls back to a plain worktree.

# --- Monitoring -------------------------------------------------------------

# ccpeek <tmux-window> [lines]  — peek at an agent's output without attaching.
ccpeek() {
  if [ -z "$1" ]; then echo "usage: ccpeek <window> [lines]"; return 2; fi
  if ! command -v tmux >/dev/null 2>&1; then echo "tmux not installed"; return 1; fi
  tmux capture-pane -p -t "$1" 2>/dev/null | grep -v '^[[:space:]]*$' | tail -n "${2:-20}"
}

# ccfleet  — one-screen dashboard: every tmux window + its last non-empty line.
ccfleet() {
  if ! command -v tmux >/dev/null 2>&1; then echo "tmux not installed"; return 1; fi
  if ! tmux info >/dev/null 2>&1; then echo "no tmux server running"; return 0; fi
  printf '%-28s %s\n' "WINDOW" "LAST LINE"
  tmux list-windows -a -F '#S:#I #W' 2>/dev/null | while read -r target name; do
    local last
    last=$(tmux capture-pane -p -t "$target" 2>/dev/null | grep -v '^[[:space:]]*$' | tail -n 1)
    printf '%-28s %s\n' "$name" "${last:0:90}"
  done
}

# ccwatch [seconds]  — refresh the fleet dashboard on an interval (Ctrl-C to stop).
ccwatch() {
  local n="${1:-5}"
  while true; do clear; date '+%H:%M:%S'; echo; ccfleet; sleep "$n"; done
}

# ccworktrees  — list git worktrees with branch + dirty state (run inside a repo).
ccworktrees() {
  local root; root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not in a git repo"; return 1; }
  git -C "$root" worktree list --porcelain | awk '
    /^worktree /{wt=$2}
    /^branch /{br=$2}
    /^detached/{br="(detached)"}
    /^$/{if(wt){printf "%-55s %s\n", wt, br; wt=""; br=""}}
    END{if(wt) printf "%-55s %s\n", wt, br}'
}

# --- Spawn ------------------------------------------------------------------

# ccnew <name> [extra args]  — start a stream. Uses bin/stream if the repo has it
# (Immersion Finder → gets port/auth/DB isolation), else a plain worktree + npm install.
ccnew() {
  if [ -z "$1" ]; then echo "usage: ccnew <name> [args]"; return 2; fi
  local root; root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not in a git repo"; return 1; }
  if [ -x "$root/bin/stream" ]; then
    ( cd "$root" && bin/stream new "$@" )
  else
    local path="$root/.claude/worktrees/$1"
    git -C "$root" worktree add "$path" -b "$1" || return 1
    if [ -f "$path/package.json" ]; then
      echo "installing deps in $path (needs node on PATH — nvm users export it first)…"
      ( cd "$path" && npm install )
    fi
    echo "stream ready: $path   → launch with:  cd '$path' && claude"
  fi
}
