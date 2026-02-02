# REM Plugin

Pattern-to-skill consolidation for Claude Code.

## Structure

```
rem/
  .claude-plugin/
    plugin.json
  skills/
    observe/SKILL.md      # Model-invocable, records patterns
    consolidate/SKILL.md  # Manual (/rem:consolidate), crystallizes skills
  hooks/
    hooks.json            # Random consolidation reminders
```

## Skills

- **observe**: Auto-loads when Claude encounters issues. Records to `.claude/rem/patterns/{domain}.md`
- **consolidate**: Manual invocation. Scans patterns, updates/creates skills, prunes stale entries
