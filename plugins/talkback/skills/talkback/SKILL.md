---
name: talkback
description: Configure TTS engine for the talkback plugin. Use when user types /talkback.
user_invocable: true
---

Configure the talkback plugin's TTS engine using structured prompts.

## Step 1: Choose engine

Use AskUserQuestion to ask which TTS engine to use:

- **say (Recommended)** — macOS built-in, no setup needed
- **ElevenLabs** — high-quality AI voices, requires API key

## Step 2: ElevenLabs setup (if selected)

If the user chose ElevenLabs, use AskUserQuestion to ask for:

- **API key** — provide a single option "I have my API key ready" so they can enter it via "Other" as free text
- **Voice** — offer presets: Rachel (default), Adam, Bella, or custom ID via "Other"

You can combine both into one AskUserQuestion call with two questions.

## Step 3: Save config

Check the plugin's install scope in `~/.claude/plugins/installed_plugins.json` under `plugins["talkback@lineofflight"][0].scope`.

- **user scope** → write env vars to `~/.claude/settings.json`
- **project scope** → write `TALKBACK_ENGINE` to `.claude/settings.json`, but put `ELEVENLABS_API_KEY` in `.claude/settings.local.json` (gitignored) to avoid committing secrets
- **personal scope** → write env vars to `.claude/settings.local.json`

Save under the `env` key in the appropriate settings file using the Edit tool.

After saving, tell the user to run `/reload-plugins` to apply.
