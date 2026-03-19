# Voice Plugin Dev Notes

## Building the watcher

The `watcher` binary is a universal (ARM + Intel) macOS binary built from `hooks/watcher.swift`. Rebuild after editing:

```bash
cd hooks
swiftc -O -target arm64-apple-macosx13.0 -o watcher-arm64 watcher.swift
swiftc -O -target x86_64-apple-macosx13.0 -o watcher-x86_64 watcher.swift
lipo -create watcher-arm64 watcher-x86_64 -output watcher
rm watcher-arm64 watcher-x86_64
```

The binary is shipped with the plugin. `start-watcher.sh` will recompile automatically if the source is newer than the binary, but the shipped binary avoids requiring `swiftc` for end users.

## Architecture

- `watcher.swift` — CoreAudio listener, detects mic on/off, writes `run/last-spoken` timestamp, kills TTS PID on barge-in
- `speak.sh` — TTS wrapper, writes `run/tts.pid` so watcher can kill it, `exec say` for direct PID targeting
- `start-watcher.sh` — compiles (if needed), starts watcher, manages `run/watcher.pid`
- `tts.sh` — Stop hook: strips markdown, delegates to `speak.sh`, removes `last-spoken` after speaking (per-turn toggle)
- `voice-context.sh` — UserPromptSubmit hook: injects conversational context if `last-spoken` is recent

## State files (`hooks/run/`, gitignored)

- `last-spoken` — unix timestamp, acts as a per-turn voice toggle
- `tts.pid` — PID of active `say` process for barge-in
- `watcher.pid` — PID of watcher daemon
