---
name: driving-agy-sessions
description: Drive Google Antigravity (agy) coding sessions as background workers — launch, send prompts, wait, read output, hand off to a human. Use when delegating coding tasks to agy, running an agy worker alongside Claude, or orchestrating agy from a controller. Mirrors claude-session-driver's command vocabulary.
user_invocable: true
---

# Driving agy Sessions

Drive Google Antigravity (`agy`) coding sessions as "workers" you launch, prompt,
wait on, read, and hand off, mirroring `claude-session-driver` (csd) so the
vocabulary is familiar: `launch`, `send`, `converse`, `wait-for-turn`, `status`,
`read-turn`, `read-events`, `stop`, `handoff`.

## How agy differs from csd

csd drives claude/codex/pi as persistent TUIs in tmux. agy doesn't need that: it
has `agy -p <prompt>` (one-shot, blocks until the turn finishes and prints the
reply) plus `agy --conversation <id>` (resume by id). So an agy worker is a
sequence of resumable one-shots, **no tmux, no persistent pane.** Turn-end is the
process exiting, so `converse` just blocks and returns the reply.

Workers run with `--dangerously-skip-permissions` (auto-approve tools). Drive
only sandboxed/trusted tasks.

## The CLI

`scripts/claude-session-driver-agy` is a self-contained Node CLI (`agy` and `node` on PATH; no
build). All state lives under `/tmp/agy-workers/<name>/` (override with
`AGY_WORKER_DIR`). Reference the script by its plugin path.

```
SD="${CLAUDE_PLUGIN_ROOT}/scripts/claude-session-driver-agy"
```

### Launch

```
node "$SD" launch my-task /path/to/project
```

Sets up the worker and writes a workspace `.agents/hooks.json` so agy's tool
hooks (`PreToolUse`/`PostToolUse`) stream into the worker's event log.

### Converse (the typical case)

```
node "$SD" converse my-task "Refactor the auth module" 300
```

Sends the prompt, blocks until agy finishes, prints the reply on stdout. The
conversation id is learned on the first turn and reused, so context carries
across calls:

```
node "$SD" converse my-task "Now add tests for expired tokens" 300
```

Add `--with-turn` to render the full turn (tool calls + results) as markdown
instead of the bare reply.

### Lower-level control

```
node "$SD" send my-task "Run the failing tests"   # background, returns immediately
node "$SD" wait-for-turn my-task 600              # block until it finishes
node "$SD" status my-task                         # idle | working | gone
node "$SD" read-turn my-task --full               # last turn as markdown
node "$SD" read-events my-task                    # tool-event JSONL
```

### Hand off to a human

```
node "$SD" handoff my-task
# prints:  agy --conversation <id>   (run from the worker's cwd)
```

### Stop

```
node "$SD" stop my-task
```

Kills any in-flight send, removes the workspace hooks, and deletes worker state.

## Verifying a worker's output

`converse`/`read-turn` return whatever agy reports, verbatim, including when agy
is confidently wrong. For correctness-critical handoffs, verify the **artifact on
disk**, not agy's prose self-report.

## Notes / limitations

- **Auth** comes from the operator's real `~/.gemini` (the agy/Gemini login). No
  per-worker auth staging yet.
- **Env vars.** `AGY_BIN` overrides the `agy` binary (default `agy`);
  `AGY_WORKER_DIR` overrides the worker-state root (default `/tmp/agy-workers`).
- **One worker per cwd.** agy reads a single `.agents/hooks.json` per directory,
  so `launch` refuses a cwd that already has a different worker's hooks. Give
  each concurrent worker its own cwd.
- **One controller per worker.** Concurrent `send`s to the same worker collide.
- **Workspace hooks** are written into the project's `.agents/hooks.json`;
  `stop` removes the file. Add `.agents/` to the project's gitignore if needed.
- **No-tool turns** still resolve: the conversation id is recovered from agy's
  session store even when no tool hook fired.
