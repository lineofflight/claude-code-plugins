# claude-session-driver-agy

Drive Google Antigravity (`agy`) coding sessions as background "workers", launch,
prompt, wait, read, hand off. Mirrors [claude-session-driver](https://github.com/obra/superpowers)'s
command vocabulary, scoped to agy.

## Why a separate tool

csd drives claude/codex/pi as persistent TUIs in tmux. agy has `-p` (one-shot,
blocking) plus `--conversation <id>` (resume by id), so an agy worker is a
sequence of resumable one-shots — no tmux, no persistent pane, turn-end is just
the process exiting. That makes a small standalone driver simpler than adding a
harness to csd, and it has zero coupling to csd's release cycle.

## Requirements

- `agy` on PATH (the Antigravity CLI), authenticated via your `~/.gemini` login
- `node` on PATH

Two env vars tune it: `AGY_BIN` overrides the `agy` binary (default `agy`), and
`AGY_WORKER_DIR` overrides where worker state lives (default `/tmp/agy-workers`).

## Usage

```
SD="${CLAUDE_PLUGIN_ROOT}/scripts/claude-session-driver-agy"

node "$SD" launch my-task /path/to/project
node "$SD" converse my-task "Refactor the auth module" 300
node "$SD" converse my-task "Now add edge-case tests" 300
node "$SD" handoff my-task     # -> agy --conversation <id>
node "$SD" stop my-task
```

See the `driving-agy-sessions` skill for the full command surface.

## Commands

| Command | Description |
|---------|-------------|
| `launch <name> <cwd>` | Set up a worker + workspace hooks |
| `converse [--with-turn] <name> <prompt> [timeout]` | Send a prompt, block, print the reply |
| `send <name> <prompt>` | Send without waiting (background) |
| `wait-for-turn <name> [timeout]` | Block until the background send finishes |
| `status <name>` | `idle` \| `working` \| `gone` |
| `read-turn <name> [--full]` | Render the last turn as markdown |
| `read-events <name>` | The tool-event JSONL |
| `stop <name>` | Kill + clean up the worker |
| `handoff <name>` | Print the `agy --conversation` resume command |

## Caveats

Workers run with `--dangerously-skip-permissions` (tools auto-approved) — drive
only sandboxed/trusted tasks. Verify artifacts on disk, not agy's self-report.
