---
name: talkback
description: Configure TTS engine for the talkback plugin. Use when user types /talkback.
user_invocable: true
---

Help the user configure their TTS engine for the talkback plugin.

Ask which engine they want:
1. **say** (default) — macOS built-in, no setup needed
2. **ElevenLabs** — high-quality AI voices, requires API key

If they choose ElevenLabs, ask for:
- API key (required)
- Voice ID (optional — default is Rachel, `21m00Tcm4TlvDq8ikWAM`)

## Where to save

Check the plugin's install scope in `~/.claude/plugins/installed_plugins.json` under `plugins["talkback@lineofflight"][0].scope`.

- **user scope** → write env vars to `~/.claude/settings.json`
- **project scope** → write `TALKBACK_ENGINE` to `.claude/settings.json`, but put `ELEVENLABS_API_KEY` in `.claude/settings.local.json` (gitignored) to avoid committing secrets
- **personal scope** → write env vars to `.claude/settings.local.json`

Save under the `env` key in the appropriate settings file using the Edit tool.

After saving, tell the user to run `/reload-plugins` to apply.
