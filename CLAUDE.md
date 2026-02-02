# Claude Code Plugins

Plugin collection for extending Claude Code.

## Structure

- `plugins/` — Plugin packages
- `.claude/rem/patterns/` — Patterns inbox (rem plugin)

## Hooks

Configured in `plugins/*/hooks/hooks.json` ([reference](https://code.claude.com/docs/en/hooks)):
- **PreCompact**: Encodes patterns before context compaction
- **Stop**: Consolidates patterns into skills (~5% chance)
