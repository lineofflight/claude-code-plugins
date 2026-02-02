---
name: observe
description: Record learnings worth remembering—gotchas, conventions, insights, decisions. Auto-loads when agent encounters something worth capturing.
---

# Observe

Record patterns for later consolidation into skills.

## When to Record

When you learn something worth remembering:

- Debugging sessions with unclear root causes
- Workarounds for framework/library quirks
- Gotchas that aren't documented
- Codebase conventions discovered
- User preferences learned
- Effective approaches that worked well
- Architectural decisions and rationale

## Where

`.claude/rem/patterns/{domain}.md`

Domain matches the relevant skill area (e.g., `rails.md`, `testing.md`, `sp-api.md`).

## Format

```markdown
### YYYY-MM-DD: Brief title

- **Observation**: What was learned
- **Details**: Specifics, resolution, or rationale
- **Context**: When this applies
```

## Notes

- Patterns accumulate in the inbox
- Run `/consolidate` periodically to crystallize recurring patterns into skills
