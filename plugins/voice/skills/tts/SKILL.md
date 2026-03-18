---
name: tts
description: Toggle text-to-speech output on or off
user_invocable: true
---

# TTS

Toggle text-to-speech output. When on, Claude speaks responses aloud.

## How it works

Voice output activates in two ways:

1. **Native voice (automatic)**: If you're using CC's built-in `/voice` mode, TTS is automatic. The plugin detects the microphone and speaks back when you spoke. Barge-in works: start speaking and playback stops.

2. **Manual toggle**: Run `/tts` to toggle voice output on or off for all responses.

## When TTS is active

Respond conversationally. Write as you'd speak -- skip markdown formatting, avoid code blocks unless explicitly asked, keep it natural. No length constraint; say as much or as little as the answer needs.

## What to do

Run this command to toggle TTS output:

```
${CLAUDE_PLUGIN_ROOT}/hooks/tts-toggle.sh
```

Then tell the user the result (TTS on or off).
