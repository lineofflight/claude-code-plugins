# REM

> Forgetting is hard.

![The Persistence of Memory](https://upload.wikimedia.org/wikipedia/en/d/dd/The_Persistence_of_Memory.jpg)

Pattern-to-skill consolidation for Claude Code. Like sleep consolidates memory.

## How It Works

```
Session transcript (gold mine)
        │ encode (PreCompact, SessionEnd)
        ▼
~/.claude/rem/patterns/<project>/{domain}.md    (personal, ephemeral)
        │ consolidate (inside encode)
        ▼
.claude/skills/{domain}/                        (shared, durable)
~/.claude/projects/<project>/memory/MEMORY.md   (auto memory sync)
```

User-scoped input, project-scoped output.

## Encode

The `encode` hook fires on `PreCompact` and `SessionEnd` (on clear). It extracts patterns from the conversation transcript across 9 categories:

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

It also checks existing patterns for contradictions — if the session disproves a previous pattern, the stale entry is updated or removed.

After encoding, the hook consolidates accumulated patterns in the same pass:

1. **Crystallize** — find recurring learnings (3+ similar observations) and promote to project skills (`.claude/skills/{domain}/`) or `CLAUDE.md`.
2. **Prune** — remove stale (>30 days) and consolidated patterns.
3. **Sync** — write one-liner summaries of new skills to auto memory (`MEMORY.md`) and remove duplicate entries.

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
