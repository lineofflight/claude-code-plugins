# agy-driver dev notes

Standalone driver for Antigravity (`agy`) workers. Born from a spike that proved
agy can be driven far more simply than csd's tmux harnesses.

## Design decisions

- **One-shot, not persistent.** agy has `-p` (blocks until the turn ends, prints
  the reply) and `--conversation <id>` (resume). So each turn is
  `agy -p <prompt> [--conversation <id>]`. No tmux, no pane lifecycle, turn-end =
  process exit. This is why the driver is ~1 file of plain Node.
- **conversationId discovery.** agy mints its own id. We learn it by diffing
  `~/.gemini/antigravity-cli/brain/` before/after the first turn (robust even for
  no-tool turns), and from the tool hook's payload. The brain-dir diff only runs
  when no id is known yet, so a resume can't be hijacked by another session's
  concurrent dir; the hook is the authoritative refresh if a turn forks a new
  conversation.
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

- Per-worker auth/home: uses the operator's real `~/.gemini`. No isolation, so
  concurrent workers share Gemini auth/session store. Fine for serial use.
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
