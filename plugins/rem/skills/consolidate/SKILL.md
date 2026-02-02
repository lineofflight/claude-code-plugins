---
name: consolidate
description: Turn recurring patterns into permanent skills.
context: fork
agent: general-purpose
disable-model-invocation: true
---

# Consolidate

Crystallize patterns into skills, prune stale ones.

## Process

1. **Scan** patterns in `.claude/rem/patterns/` for recurring learnings (3+ occurrences)
2. **Crystallize** into matching project skill (`.claude/skills/{domain}/`)
   - If no matching skill exists, create one (using `/skill-creator` if available)
3. **Review** skills for bloat, keep concise
4. **Forget** crystallized/stale patterns
5. **Commit** changes

## Constraints

- Only touches project-scoped skills (`.claude/skills/`)
- Never touches user-scoped skills (`~/.claude/skills/`)

## Thresholds

- Crystallize after 3+ occurrences
- Skills stay under ~100 lines
- Patterns older than 30 days → review for deletion
