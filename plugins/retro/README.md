# Retro

Session gap extraction and skill consolidation for Claude Code.

## How it works

**Observe** — A hook fires on PreCompact and SessionEnd, scanning the transcript for gaps: missing skills, missing tools, repeated failures, wrong information, and new conventions. Observations are stored per-session in `~/.claude/projects/<project>/retro/`.

**Review** — Run `/retro` to review accumulated observations. The skill analyzes gaps across sessions, proposes batch actions (create skills, update CLAUDE.md, or discard), and executes approved changes.

## Gap classifications

| Type | Description |
|------|-------------|
| `missing_skill` | Repeated manual workflow that should be encoded |
| `missing_tool` | Needed a tool or MCP that wasn't available |
| `repeated_failure` | Same error hit multiple times, workaround found |
| `wrong_info` | Claude gave incorrect information, corrected by user |
| `new_convention` | Pattern or preference established during the session |
