# REM

> Forgetting is hard.

![The Persistence of Memory](https://upload.wikimedia.org/wikipedia/en/d/dd/The_Persistence_of_Memory.jpg)

Pattern-to-skill consolidation for Claude Code. Like sleep consolidates memory.

## Usage

### Encode

A `PreCompact` hook fires before context compaction to record patterns worth remembering:

```markdown
# .claude/rem/patterns/rails.md

### 2026-02-02: ActiveRecord includes with polymorphic associations

- **Observation**: N+1 queries persist despite using includes
- **Details**: Use `includes(:commentable)` with explicit polymorphic type
- **Context**: Polymorphic belongs_to with eager loading

### 2026-02-02: Service objects return Result types

- **Observation**: This codebase wraps service responses in Result objects
- **Details**: Always return `Result.success(data)` or `Result.failure(error)`
- **Context**: All service classes in app/services/
```

### Consolidate

A `Stop` hook fires randomly (~5% of responses) to:

1. Scan patterns for recurring learnings (3+ occurrences)
2. Crystallize into project skills (`.claude/skills/{domain}/`)
3. Prune stale/crystallized patterns

Encoding turns conversation into patterns (working memory). REM consolidates them into skills (long-term memory).
