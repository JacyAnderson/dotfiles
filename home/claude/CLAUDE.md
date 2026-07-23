@~/.dotfiles/home/AGENTS.md

# AI Orchestration & Model Routing (Claude Code, all projects)

How I run Claude Code across every project - umbrella-level, so each project (Immersion Finder, Tap Exchange, ...) inherits it. Full playbook: `~/.dotfiles/home/claude/orchestration.md`.

- **Default model `opusplan`** (Opus plans, Sonnet executes). Escalate to Fable 5 - `/model fable`, or an `architecture-advisor` agent - only for high-blast-radius, hard-to-reverse work. Do **not** build a custom per-prompt model router: it fights the prompt cache and disables native features.
- **Tier subagents by output**: code/architecture -> `inherit`, judgment/review -> `sonnet`, research/search -> `haiku`. Match the model to the output, not the domain.
- **Proactively suggest escalating** to Fable when a genuinely hard architecture or debugging decision appears - don't silently grind on a lower tier.
- **Fleet discipline**: pick the mode (solo / background subagent / agent team / parallel streams / workflow); keep to 3-5 concurrent; give each teammate full context up front; keep the lead lean and delegate grunt work down-tier. Monitoring helpers in `~/.dotfiles/home/claude/fleet-helpers.sh` (`ccfleet`, `ccpeek`, `ccwatch`, `ccnew`), sourced by zsh via home.nix.
