# agy-driver dev notes

Standalone driver for Antigravity (`agy`) workers. Born from a spike that proved
agy can be driven far more simply than csd's tmux harnesses.

## Design decisions

- **One-shot, not persistent.** agy has `-p` (blocks until the turn ends, prints
  the reply) and `--conversation <id>` (resume). So each turn is
  `agy -p <prompt> [--conversation <id>]`. No tmux, no pane lifecycle, turn-end =
  process exit. This is why the driver is ~1 file of plain Node.
- **conversationId discovery.** agy mints its own id and doesn't print it, so we
  pass `--log-file <worker>/agy.log` and parse the id agy logs there
  (`Created conversation <id>` / `Print mode: conversation=<id>`, last match
  wins). The log path is one we own, so its id is unambiguously this turn's —
  race-free even under a concurrent GUI/worker sharing `~/.gemini`, and it
  resolves no-tool turns too (where no hook fires). Earlier builds diffed the
  shared `brain/` dir, which could mis-attribute under concurrency; the log
  replaces that. The hook still adopts the id opportunistically as a backstop.
- **Hooks are for live tool events only**, not turn boundaries. agy's CLI fires
  only `PreToolUse`/`PostToolUse` (verified — no SessionStart/Stop/SessionEnd).
  The hook command (`agy-driver hook <Event> <name>`) appends a normalized event
  and ALWAYS replies `{"decision":"allow"}` (agy's PreToolUse fails closed).
- **Transcript** at `~/.gemini/antigravity-cli/brain/<id>/.system_generated/logs/transcript_full.jsonl`.
  `parseAgyTurn` maps USER_INPUT (prompt) and PLANNER_RESPONSE (assistant
  content + tool_calls) into a turn for `read-turn`. Tool *results* are separate
  MODEL-sourced records named by the tool that ran (`VIEW_FILE`, `RUN_COMMAND`,
  `LIST_DIRECTORY`, `GENERIC`, …) — there is no `CODE_ACTION` type — so any
  non-PLANNER MODEL record is rendered as a result; SYSTEM records
  (`CONVERSATION_HISTORY`, `CHECKPOINT`) are skipped.

## Known gaps / TODO

- Per-worker auth/home: uses the operator's real `~/.gemini`, so concurrent
  workers share Gemini auth/session store. Conversation-id discovery is no longer
  affected (it parses our own `--log-file`), but other shared state still favors
  serial use.
- One worker per cwd: agy reads a single `.agents/hooks.json` per directory, so
  `launch` refuses a cwd that already holds a different worker's hooks, and
  `stop` only removes the file if it's still ours.
- `tool_calls` shape parsed defensively (`name` + `args|arguments|input`),
  confirmed against a multi-tool transcript (`view_file` + `run_command`).
- No `adopt`/recovery command yet; `handoff` + `agy --conversation <id>` covers
  manual resume.

## Provenance

Distilled from a spike that drove agy through csd-style commands, proving agy's
one-shot `-p`/`--conversation` model needs no tmux harness. This plugin is the
standalone result.
