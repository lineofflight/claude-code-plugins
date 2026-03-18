# Voice

TTS output for Claude Code. Speaks Claude's responses aloud via ElevenLabs.

## Modes

- **Native voice** (CC built-in `/voice`): Fully automatic. Detects `rec`/`arecord`, speaks back only when you used voice input. Barge-in support — start speaking and playback stops.
- **External STT** (Monologue, etc.): Use `/voice` to toggle on/off. Claude speaks all responses while toggled on.

## Setup

1. Set your ElevenLabs API key:

   ```
   export ELEVENLABS_API_KEY="your-key-here"
   ```

2. Optionally set a custom voice:

   ```
   export ELEVENLABS_VOICE_ID="your-voice-id"
   ```

   Defaults to Rachel (`21m00Tcm4TlvDq8ikWAM`).

## Requirements

- macOS (uses `afplay` for audio playback)
- `jq` and `curl`
- `claude` CLI
