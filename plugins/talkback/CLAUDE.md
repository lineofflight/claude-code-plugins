# Talkback Plugin Dev Notes

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
- `talkback.sh` — TTS engine wrapper, supports `say` (default) and ElevenLabs, writes `run/tts.pid` for barge-in
- `start-watcher.sh` — compiles (if needed), starts watcher, manages `run/watcher.pid`
- `tts.sh` — Stop hook: strips markdown, checks for speech starter words, delegates to `talkback.sh`
- `voice-context.sh` — UserPromptSubmit hook: injects conversational context prompting speech starters for voice-like input
- `speech-starters.txt` — shared word list used by both `voice-context.sh` (prompt) and `tts.sh` (detection)

## Configuration

Engine is configured via env vars in `~/.claude/settings.json`. Use `/talkback` skill to set up.

- `TALKBACK_ENGINE` — `say` (default) or `elevenlabs`
- `ELEVENLABS_API_KEY` — required for ElevenLabs
- `ELEVENLABS_VOICE_ID` — optional, defaults to Rachel

## State files (`hooks/run/`, gitignored)

- `last-spoken` — unix timestamp, acts as a per-turn voice toggle
- `tts.pid` — PID of active TTS process for barge-in
- `tts.mp3` — temporary audio file for ElevenLabs playback
- `watcher.pid` — PID of watcher daemon
