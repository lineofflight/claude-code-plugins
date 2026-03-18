# Voice

Text-to-speech output for Claude Code. Speaks Claude's responses aloud using
macOS `say`.

## Modes

- **Native voice** (CC built-in `/voice`): Fully automatic. Detects microphone,
  speaks back only when you used voice input. Barge-in support -- start speaking
  and playback stops.
- **Manual toggle**: Use `/tts` to toggle on/off. Claude speaks all responses
  while toggled on.

## Requirements

- macOS (uses `say` for speech)
- `jq`
