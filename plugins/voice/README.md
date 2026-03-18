# Voice

Text-to-speech output for Claude Code. Speaks Claude's responses aloud using
macOS `say`.

## How it works

When you use CC's built-in `/voice`, the plugin automatically detects it and:

- Injects conversational context so responses are natural and spoken-friendly
- Speaks responses aloud via macOS `say`, stripping markdown artifacts

No configuration or manual toggle needed.

## Requirements

- macOS (uses `say` for speech)
- `jq`
