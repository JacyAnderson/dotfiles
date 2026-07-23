# Claude Code Fleet Orchestration — umbrella reference

Applies to **every** project (Immersion Finder, Tap Exchange, …). This is the reusable "how to run a fleet" know-how; each project supplies its own stream tooling and domain agents. Linked from the global `~/.claude/CLAUDE.md` (the Claude overlay in this repo).

Related: model-routing doctrine (below + `~/.claude/CLAUDE.md`), per-project stream tooling (IF: `docs/planning/reference/multistream.md` → `bin/stream`), and the power-user track (IF: `docs/planning/operations/jacy-learning-plan.md`).

---

## 0. Model routing (recap — full doctrine in ~/.claude/CLAUDE.md)

Pay for judgment, not grunt work; don't automate the matching. Default `opusplan` (Opus plans, Sonnet executes). Tier subagents by *output*: code/architecture → `inherit`, judgment → `sonnet`, research/search → `haiku`. Escalate to Fable 5 deliberately (`/model fable` or the `architecture-advisor` agent) only for high-blast-radius, hard-to-reverse work. No custom per-prompt router.

## 1. The one decision: pick the mode

Before spawning anything, ask **"how do these pieces relate?"**

| The work is… | Use | Notes |
|---|---|---|
| One problem, interlocking subtasks | **Agent team** (lead + 3–5 teammates) | Shared task list + mailbox; roles = your `.claude/agents/`, so teammates inherit the right tier |
| Unrelated tracks | **Independent parallel sessions**, one stream each | Worktree-isolated; no file collisions |
| A helper you just want results from | **Background subagent** (`Ctrl+B` / `run_in_background` / `/tasks`) | Fire-and-forget; reports back to caller |
| A big mechanical sweep | **Workflow** / `/batch` | Deterministic fan-out, each item its own PR |
| One focused thing | Just one stream — **don't orchestrate** | Most work. Orchestration has a coordination tax |

Rookie mistake: spawning a team for a single-file change. Only pay the coordination tax when parallelism actually buys time.

## 2. Isolation: one stream per parallel track

A **stream** = a worktree + (ideally) an isolated runtime (port, auth URL, DB).

- **Immersion Finder:** use `bin/stream` — it adds the isolated runtime raw worktrees lack (port, Better Auth callback URL, optional Neon DB branch) and runs `npm install`. See `docs/planning/reference/multistream.md`.
- **Generic / other projects (e.g. Tap Exchange):** `claude --worktree <name>` (native; honors `.worktreeinclude`), or the `ccnew` helper. Run `npm install` once in a fresh worktree or typecheck/lint fail with misleading "implicitly any" errors.
- **Merge child-first** for stacked work (merge child into parent branch, then parent into main — a parent-first merge strips the child).

## 3. The orchestrator's loop (every fleet session)

1. **Decompose** into the most independent chunks possible.
2. **Partition files** — teammates *share the worktree*, so give each a non-overlapping area. Independent sessions are worktree-isolated, so no overlap risk there.
3. **Kick off + gate** — approve each teammate's plan before it runs (catches a bad approach before it burns tokens).
4. **Monitor** — agent panel / tmux panes / `ccfleet` / `ccpeek`; watch for *needs-input* and *idle*.
5. **Unblock** — answer questions, re-scope, kill anything stuck.
6. **Integrate** — review diffs, merge (child-first for stacks), let CI run.

## 4. Monitoring the fleet

- In-session **agent panel**; **tmux/iTerm2 split panes** (`teammateMode: tmux|iterm2`).
- **`ccfleet`** — dashboard of every tmux window + its last line; **`ccpeek <window>`** — peek one without attaching; **`ccwatch`** — auto-refresh. (Global shell helpers, `~/.dotfiles/home/claude/fleet-helpers.sh`, sourced by zsh via home.nix.)
- **`claude remote-control`** — secure URL + QR code; execution stays local; steer from your phone.
- Advanced: Claude Code writes JSONL session files you can tail for a scripted status board.

## 5. Power habits (running 5 agents vs *leading* 5)

- **3–5 concurrent, ~8 ceiling.** More = coordination tax + linear quota burn on your one machine.
- **Give each teammate full context up front** — they don't share your context window. State the goal, the *why*, and the constraints, or they re-derive badly. Biggest quality lever.
- **Keep the lead lean; delegate grunt work down-tier** to your Sonnet/Haiku teammates.
- **Never fan out interdependent work** — if B needs A, serialize.
- **Cost discipline:** each teammate re-reads context cold (no shared prompt cache), so fan-out has a real per-agent cost — worth it only when tracks are genuinely independent. Watch the statusline USD.

## 6. Anti-patterns

- A team for a single-file change. • Two teammates editing the same files. • Fanning out sequentially-dependent work. • Pinning a broad agent to Fable (bleeds credits).

## 7. Enhancements to grow into

- **Agent memory** — `memory: project` frontmatter lets an agent accumulate domain knowledge across sessions (per-project, so it stays subsidiary-scoped). Good for long-lived specialists.
- **Hooks** as quality gates — `TeammateIdle` / `TaskCreated` / `TaskCompleted` (exit code 2 blocks + gives feedback); e.g. auto-run typecheck before a teammate reports done.
- **Skills** for repeatable multi-step workflows you invoke by name.
- See the power-user tiers in `docs/planning/operations/jacy-learning-plan.md`.

## 8. Sharing agents across projects (hybrid model)

Global `~/.claude/agents/` = umbrella (all projects); project `.claude/agents/` = subsidiary. **On a name collision, the project agent overrides the global one** — so a project can specialize a shared role. Model tiers travel with each agent (`inherit`/`sonnet`/`haiku`/`fable`).

**Hybrid split (decided):**
- **Universal → promote to global archetypes** (generic bodies that read each project's own `CLAUDE.md`/ADRs for context): `architecture-advisor` (fable), `api-engineer`, `auth-engineer`, `infrastructure-engineer`, `qa-engineer`, `technical-architect`, and the business analysts (`financial-analyst`, `market-analyst`, `operations-analyst`, `product-strategist`, `growth-strategist`, `user-researcher`).
- **Domain-specific → keep project-local.** Immersion Finder: `cultural-ethics-reviewer`, `lms-engineer`, `sustainability-analyst`, and the design-system-coupled `frontend-engineer` / `design-system-engineer` / `a11y-engineer`. Tap Exchange: its own trading/fintech/compliance specialists.

**Execution:** promote the generic archetypes to global **once** (when standing up the second project, so they can be validated against a real second repo — not speculatively). After that, each new project writes only its domain specialists and inherits the rest. Immersion Finder keeps its richer local versions where they exist (they override the global archetype automatically).
