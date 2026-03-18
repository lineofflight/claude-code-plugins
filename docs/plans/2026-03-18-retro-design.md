# Retro Plugin Design

Session pattern extraction and skill consolidation for Claude Code.

## Overview

Two-phase plugin: an automatic **observe** hook silently captures gaps during sessions, and a manual **`/retro`** skill lets you review accumulated observations and consolidate them into durable project knowledge.

Inspired by [rem-sleep](https://github.com/lineofflight/claude-code-plugins) (removed in 323dbc5, superseded by auto memory) and [Intercom's internal plugin system](https://x.com/brian_scanlan/status/2033978300003987527).

## Architecture

```
Session transcript
        | observe (PreCompact, SessionEnd)
        | Claude Haiku, async
        v
~/.claude/projects/<project>/retro/<date>-<summary>.md
        | /retro (manual, user-invoked)
        | session model
        v
.claude/skills/{domain}/SKILL.md    (new skills)
CLAUDE.md                           (universal rules)
discard                             (noise removed)
```

## Phase 1: Observe (hook)

Fires on **PreCompact** and **SessionEnd**. Runs Claude Haiku, async. Scans the session transcript and classifies gaps into five categories:

| Classification | Catches |
|---|---|
| `missing_skill` | Repeated manual workflow that should be encoded |
| `missing_tool` | Needed a tool or MCP that wasn't available |
| `repeated_failure` | Same error hit multiple times, workaround found |
| `wrong_info` | Claude gave incorrect information, had to be corrected |
| `new_convention` | Pattern or preference established during the session |

### Output

One file per session in `~/.claude/projects/<project>/retro/`:

```markdown
# Session: 2026-03-18 - debugging flaky test

- type: repeated_failure
  summary: BSD grep -P fails on macOS, had to use ggrep
  details: grep -P not supported, installed grep via homebrew
  context: shell hooks, macOS

- type: missing_skill
  summary: Manual steps to set up local dev environment
  details: Had to explain the docker-compose + seed sequence 3 times
  context: onboarding, local dev

- type: new_convention
  summary: Always use absolute paths in hook scripts
  details: Relative paths broke when hooks ran from different cwd
  context: plugin authoring
```

Writes nothing if the session had no notable gaps.

## Phase 2: `/retro` (skill)

User-invocable. Reads all files from `~/.claude/projects/<project>/retro/`, analyzes accumulated gaps, and proposes a **batch action plan**:

> Based on 8 gaps across 3 sessions, I propose:
> - **Create skill** `local-dev-setup` — 3 gaps about repeated manual setup steps
> - **Update CLAUDE.md** — add "use absolute paths in hook scripts" (2 mentions)
> - **Discard** 3 gaps — one-off issues, not patterns

The user approves, edits, or rejects. On approval, `/retro` executes the plan and clears processed gap files.

### Placement guidance

- **CLAUDE.md** — Universal rules needed on every task. Burns context tokens every turn; only universal rules justify the cost.
- **Skills** — Domain knowledge for specific areas. Loaded on demand.
- **Discard** — One-off issues that aren't patterns.

## Plugin Structure

```
plugins/retro/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json
│   └── observe
├── skills/
│   └── retro/
│       └── SKILL.md
└── README.md
```

## Design Decisions

- **Two-phase split** over single-pass: old rem-sleep auto-consolidated without human judgment. This design harvests silently, consolidates with human review.
- **Haiku for observe** over Sonnet: triage doesn't need synthesis. Misclassifications are caught during `/retro`.
- **Batch proposals** over per-gap prompting: less tedious, user can still override individual items.
- **One file per session** over one file per gap: tidier, `/retro` parses individual gaps from within.
- **`~/.claude/projects/<project>/retro/`** as storage: alongside auto memory, user-scoped, no custom slug computation.
- **PreCompact + SessionEnd** triggers: PreCompact is rare after the 1M token upgrade but serves as a safety net.
