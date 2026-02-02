# REM Plugin

Pattern-to-skill consolidation for Claude Code.

## Structure

```
rem/
  .claude-plugin/
    plugin.json
  hooks/
    hooks.json  # PreCompact encoding, Stop consolidation
```

## Hooks

- **PreCompact**: Encodes patterns before context compaction
- **Stop**: Random trigger (~5%) to consolidate when patterns accumulate
