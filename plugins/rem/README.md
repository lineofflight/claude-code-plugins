# REM

> Forgetting is hard.

![The Persistence of Memory](https://upload.wikimedia.org/wikipedia/en/d/dd/The_Persistence_of_Memory.jpg)

Pattern-to-skill consolidation for Claude Code. Like sleep consolidates memory.

## Usage

### Observe (automatic)

When Claude learns something worth remembering, it records a pattern:

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

The `rem:observe` skill auto-loads when Claude encounters gotchas, discovers conventions, or learns something worth capturing.

### Consolidate (manual)

Run `/rem:consolidate` periodically to:

1. Scan patterns for recurring learnings (3+ occurrences)
2. Crystallize into project skills (`.claude/skills/{domain}/`)
3. Create new skills if no matching domain exists
4. Prune stale/crystallized patterns
5. Commit changes

### Dream (random)

A hook fires randomly (~2% of stops) to remind Claude about accumulated patterns.

## Project Setup

For projects using this plugin, create the patterns directory:

```bash
mkdir -p .claude/rem/patterns
```

Add domain files as needed (e.g., `rails.md`, `testing.md`, `api.md`).

## How It Works

```
Session work → rem:observe → .claude/rem/patterns/
                                    ↓
                            /rem:consolidate
                                    ↓
                          .claude/skills/{domain}/
```

Patterns are the inbox. Skills are the memory.
