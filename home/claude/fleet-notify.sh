#!/usr/bin/env bash
# Claude Code Notification hook → macOS banner that names WHICH team needs you.
# Wired in ~/.claude/settings.json under hooks.Notification.
# jq comes from nix (home.packages), not brew; hooks may run with a minimal
# PATH, so fall back to home-manager's per-user profile path.
JQ="$(command -v jq || echo "/etc/profiles/per-user/${USER}/bin/jq")"
TN=/opt/homebrew/bin/terminal-notifier
input=$(cat)
team=$(printf '%s' "$input" | "$JQ" -r '.cwd // ""' 2>/dev/null | xargs -r basename 2>/dev/null)
msg=$(printf '%s' "$input" | "$JQ" -r '.message // "needs your input"' 2>/dev/null)
"$TN" -title "Claude: ${team:-fleet}" -message "${msg:-needs your input}" -sound Glass -activate com.apple.Terminal
