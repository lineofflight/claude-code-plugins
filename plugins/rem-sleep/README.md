# REM

> Forgetting is hard.

![The Persistence of Memory](https://upload.wikimedia.org/wikipedia/en/d/dd/The_Persistence_of_Memory.jpg)

Pattern-to-skill consolidation for Claude Code. Like sleep consolidates memory.

## How It Works

```
Session transcript (gold mine)
        │ encode (PreCompact, SessionEnd, ~10% Stop)
        ▼
~/.claude/rem/patterns/<project>/{domain}.md    (personal, ephemeral)
        │ consolidate (~5% Stop)
        ▼
.claude/skills/{domain}/                        (shared, durable)
~/.claude/projects/<project>/memory/MEMORY.md   (auto memory sync)
```

User-scoped input, project-scoped output.

## Encode

`PreCompact`, `SessionEnd` (on clear), and `Stop` (~10% chance) hooks extract patterns from conversation transcripts across 9 categories:

- Debugging insights
- Tool failures and resolutions
- Framework/library workarounds
- Undocumented gotchas
- Codebase conventions
- User preferences
- Brand voice/messaging
- Effective approaches
- Architectural decisions

Patterns use YAML frontmatter for machine-parseable metadata:

```markdown
---
domain: rails
date: 2026-02-02
tags: [activerecord, n+1, polymorphic]
---
### ActiveRecord includes with polymorphic associations
- **Observation**: N+1 queries persist despite using includes
- **Details**: Use `includes(:commentable)` with explicit polymorphic type
- **Context**: Polymorphic belongs_to with eager loading
```

The encode hook also checks existing patterns for contradictions — if a session disproves a previous pattern, the stale entry is updated or removed.

## Consolidate

A `Stop` hook fires randomly (~5% of responses) to:

1. **Pre-filter** — count entries per domain, check for stale entries (>30 days). Skip the model call if nothing needs attention.
2. **Crystallize** — find recurring learnings (3+ similar observations) and promote to project skills (`.claude/skills/{domain}/`) or `CLAUDE.md`.
3. **Prune** — remove stale and consolidated patterns.
4. **Sync** — write one-liner summaries of new skills to auto memory (`MEMORY.md`) and remove duplicate entries.

### Placement Guidance

- **CLAUDE.md** — Universal rules needed on every task: style conventions, return type patterns, error handling policy. Burns context tokens every turn — only universal rules justify the cost.
- **Skills** — Domain knowledge for specific areas: framework workarounds, library gotchas, API patterns. Loaded on demand.

### Source Citations

Skills include provenance comments tracing back to the observations that produced them:

```markdown
<!-- consolidated from: rails.md 2026-02-02, 2026-02-04, 2026-02-05 -->
```

## Read-Before-Act

The encode hook maintains an index at `~/.claude/rem/patterns/<project>/INDEX.md` with recent pattern titles. To surface this at session start, add to your project `CLAUDE.md`:

```markdown
When starting unfamiliar work, check ~/.claude/rem/patterns/ for recent learnings.
```

## Storage

Patterns are personal working memory — they reflect what *you* encountered. Two developers hitting different bugs build different pattern sets.

| What | Where | Scope |
|------|-------|-------|
| Patterns | `~/.claude/rem/patterns/<project>/` | User (personal, ephemeral) |
| Skills | `.claude/skills/{domain}/` | Project (shared, durable) |
| Auto memory | `~/.claude/projects/<project>/memory/MEMORY.md` | User (synced) |
