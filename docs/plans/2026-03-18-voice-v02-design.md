# Voice Plugin v0.2 Design

TTS output and barge-in for Claude Code's native `/voice` mode. Replaces
ElevenLabs with macOS `say`. Zero configuration required.

## Components

### 1. `tts` skill (user-invocable toggle)

Toggles TTS output on/off. When activated, injects system prompt guidance:
be conversational, skip markdown, talk like a person. No hard length limit --
the agent decides how much to say.

### 2. Watcher (SessionStart / SessionEnd hooks)

Background process that:

- Detects native `/voice` via `rec`/`arecord` process polling (auto-enables
  TTS when the user is using voice input)
- Barge-in: kills `say` process when user starts speaking

### 3. TTS hook (Stop)

When TTS is active:

- Takes `last_assistant_message`
- Strips code blocks, inline code, markdown formatting, tables
- Passes cleaned text to macOS `say`
- Tracks PID for barge-in

## Removed from v0.1

- ElevenLabs dependency (replaced by `say`)
- `curl`, `jq` dependencies
- 500-char truncation
- API key / voice ID configuration

## Added in v0.2

- `tts` skill with conversational tone guidance
- Zero-config -- install and go
