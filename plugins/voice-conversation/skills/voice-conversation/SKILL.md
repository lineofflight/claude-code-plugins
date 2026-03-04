---
name: voice-conversation
description: Enables voice-driven conversation with Claude Code via ElevenLabs STT and TTS. Use when setting up or troubleshooting voice mode.
---

# Voice Conversation

A voice conversational UI layered on top of Claude Code, using ElevenLabs for speech-to-text (Scribe) and text-to-speech (Flash/Turbo).

## Quick Start

```bash
# Install dependencies
cd "${CLAUDE_PLUGIN_ROOT}" && npm install

# Set your ElevenLabs API key
export ELEVENLABS_API_KEY="your-key-here"

# Run the voice orchestrator (wraps a Claude Code session)
node scripts/orchestrator.mjs
```

The orchestrator spawns `claude -p` with `--output-format stream-json` and manages a full-duplex voice loop.

## Architecture

```
Mic → ElevenLabs Scribe STT (WebSocket) → Orchestrator → Claude Code (stream-json)
                                              ↓
Speaker ← ElevenLabs TTS (WebSocket) ← Text filter ← stream events (text_delta)
```

### What gets spoken vs. displayed

| Stream event | Spoken? | Displayed? |
|---|---|---|
| `text_delta` (prose) | Yes | Yes |
| `text_delta` (code fences) | No — summarized as "Here's some code" | Yes |
| `text_delta` (URLs, paths) | No | Yes |
| `tool_use` blocks | Brief narration: "Editing auth.py" | Yes |
| Tool output | No | Yes |

### Non-blocking flow

- STT runs continuously in its own async pipeline
- TTS streams audio chunks as they arrive (no wait for full response)
- Neither pipeline blocks the other or the Claude Code session

### Barge-in (human speaks → agent stops)

When VAD detects user speech during TTS playback:
1. Cancel current TTS audio (close ElevenLabs TTS context)
2. Route audio to STT
3. On transcript commit, yield new user message into the Claude session

## Configuration

Environment variables:

| Variable | Default | Description |
|---|---|---|
| `ELEVENLABS_API_KEY` | — | Required. ElevenLabs API key |
| `ELEVENLABS_VOICE_ID` | `21m00Tcm4TlvDq8ikWAM` | Voice to use for TTS |
| `ELEVENLABS_TTS_MODEL` | `eleven_flash_v2_5` | TTS model (flash for lowest latency) |
| `VOICE_SILENCE_THRESHOLD` | `0.5` | Seconds of silence before STT commits |
| `VOICE_ENABLED` | `true` | Set `false` to disable voice hooks without uninstalling |

## Hooks

This plugin registers three hooks:

- **Stop** — When Claude finishes a turn, the response text is filtered and sent to ElevenLabs TTS
- **PostToolUse** — Narrates tool actions ("Running tests", "Editing server.js")
- **Notification** — Speaks permission prompts and idle alerts

## Prior Art

| Project | Approach |
|---|---|
| Claude Code `/voice` (native, March 2026) | STT input only, uses ElevenLabs, 5% rollout |
| VoiceMode MCP (mbailey) | Full bidirectional voice via MCP server |
| Claude-to-Speech (LAURA-agent) | TTS output via Stop hook + ElevenLabs |
| OpenClaw Talk Mode | Full voice loop (VAD → STT → LLM → TTS → barge-in) |
| hns / whis | CLI tools: `claude "$(hns)"` for voice input |
