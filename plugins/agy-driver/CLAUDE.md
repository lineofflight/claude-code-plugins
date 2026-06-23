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
  no-tool turns), and opportunistically from the first tool hook's payload.
- **Hooks are for live tool events only**, not turn boundaries. agy's CLI fires
  only `PreToolUse`/`PostToolUse` (verified — no SessionStart/Stop/SessionEnd).
  The hook command (`agy-driver hook <Event> <name>`) appends a normalized event
  and ALWAYS replies `{"decision":"allow"}` (agy's PreToolUse fails closed).
- **Transcript** at `~/.gemini/antigravity-cli/brain/<id>/.system_generated/logs/transcript_full.jsonl`.
  `parseAgyTurn` maps USER_INPUT / PLANNER_RESPONSE (content + tool_calls) /
  CODE_ACTION into a turn for `read-turn`.

## Known gaps / TODO

- Per-worker auth/home: uses the operator's real `~/.gemini`. No isolation, so
  concurrent workers share Gemini auth/session store. Fine for serial use.
- `.agents/hooks.json` is written into the project cwd. `stop` removes it.
- `tool_calls` shape parsed defensively (`name` + `args|arguments|input`);
  confirm against a multi-tool transcript.
- No `adopt`/recovery command yet; `handoff` + `agy --conversation <id>` covers
  manual resume.

## Provenance

Spike + the agy-as-csd-harness investigation lived in
`~/code/csd-agy` (a vendored csd fork) and Frida's
`documents/projects/csd-antigravity.md`. This plugin is the standalone
distillation; the fork can be abandoned.
