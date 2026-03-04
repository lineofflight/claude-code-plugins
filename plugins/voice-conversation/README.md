# Voice Conversation Plugin

Voice conversational UI for Claude Code using ElevenLabs STT (Scribe) and TTS (Flash/Turbo).

## Status: Exploration / Proof of Concept

This plugin explores adding a voice layer on top of Claude Code sessions. It ships in two modes:

### Mode 1: Hooks (drop-in, output only)

Install the plugin and Claude's responses are spoken aloud. No changes to your workflow — hooks fire automatically on `Stop`, `PostToolUse`, and `Notification` events.

```bash
export ELEVENLABS_API_KEY="your-key"
claude --plugin-dir ./plugins/voice-conversation
```

### Mode 2: Orchestrator (full-duplex, bidirectional)

A standalone Node.js process wrapping a Claude Code session with real-time STT input and TTS output.

```bash
cd plugins/voice-conversation && npm install
export ELEVENLABS_API_KEY="your-key"
node scripts/orchestrator.mjs
```

## Architecture

```
┌─────────────┐  audio   ┌──────────────┐  transcript  ┌──────────────┐
│  Microphone  │ ───────▶ │  ElevenLabs  │ ───────────▶ │              │
└─────────────┘          │ Scribe STT   │              │ Orchestrator │
                         │ (WebSocket)  │              │              │
┌─────────────┐  audio   ┌──────────────┐  text        │ Claude Code  │
│   Speaker   │ ◀─────── │  ElevenLabs  │ ◀─────────── │ (stream-json)│
└─────────────┘          │ TTS Stream   │              │              │
                         │ (WebSocket)  │              └──────────────┘
                         └──────────────┘
```

## Design Decisions

### What gets spoken vs. displayed

| Content | Spoken | Displayed |
|---------|--------|-----------|
| Prose / explanations | Yes | Yes |
| Code blocks | "Here's some code" | Yes |
| URLs, file paths | No | Yes |
| Inline code | No | Yes |
| Tool use (Edit, Bash) | Brief narration | Yes |
| Tool output | No | Yes |

### Non-blocking flow

STT, TTS, and the Claude session run in separate async pipelines. None blocks the others. TTS streams audio chunks as they arrive from ElevenLabs — playback starts before the full sentence is synthesized.

### Barge-in

When VAD detects user speech during TTS playback:
1. TTS context is closed (audio stops)
2. Audio routes to STT
3. On transcript commit, the new message is yielded to the Claude session

### Latency budget

| Stage | Latency |
|-------|---------|
| Scribe STT (streaming) | ~150–300ms to partial, ~500ms to final |
| Claude processing | Variable (1–60s for agentic tasks) |
| Flash v2.5 TTS (WebSocket) | ~75ms to first audio byte |
| **Overhead** | **~300–800ms added to Claude's response time** |

## Prior Art & Landscape

### Claude Code native voice (March 3, 2026)

Anthropic shipped `/voice` in Claude Code — hold spacebar to speak, transcription via ElevenLabs. Currently input-only (STT), no TTS output. Rolling out to ~5% of users.

### OpenClaw Talk Mode

Full voice loop: VAD → Whisper/Deepgram STT → LLM → ElevenLabs/OpenAI TTS → barge-in. Mature implementation (~2–4s cycle). Generalist agent, not coding-specific.

### Community projects

| Project | Approach |
|---------|----------|
| [VoiceMode MCP](https://github.com/mbailey/voicemode) | Full bidirectional voice via MCP server |
| [Claude-to-Speech](https://github.com/LAURA-agent/Claude-to-Speech) | TTS output via Stop hook + ElevenLabs |
| [claude-code-voice-notifications](https://github.com/ZeldOcarina/claude-code-voice-notifications) | ElevenLabs TTS for task completion alerts |
| [hns](https://hns-cli.dev/docs/drive-coding-agents/) | CLI: `claude "$(hns)"` for voice input |
| [whis](https://github.com/frankdierolf/whis) | CLI: `claude "$(whis --as ai-prompt)"` |
| [Aqua Voice](https://aquavoice.com/) | Commercial, 0.9% WER, sub-450ms |

### ElevenLabs integration points

- **Conversational AI platform** — managed STT → LLM → TTS pipeline with barge-in. Supports custom LLM backends. Less suitable for Claude Code's long-running agentic loops (expects fast, synchronous responses).
- **DIY pipeline** (what this plugin uses) — separate STT (Scribe WebSocket) and TTS (Flash WebSocket) with manual barge-in handling. Better fit for variable-latency agentic workloads.
- **Multi-Context TTS WebSocket** — handles barge-in by managing independent audio generation contexts. Up to 5 contexts per connection. Close context A when interrupted, open context B for new response.

## Open Questions

- [ ] Audio I/O: how to capture mic and play audio cross-platform? (node-record-lpcm16, sox, portaudio bindings)
- [ ] Should the orchestrator mode use the Agent SDK's async generator input instead of spawning `claude -p` per turn?
- [ ] Integration with Claude Code's native `/voice` — complement it (add TTS output) rather than replace it?
- [ ] Sentence boundary detection could be smarter (NLP-based vs. punctuation-based)
- [ ] Should tool narration be configurable? (some users may find "Editing auth.py" annoying)

## ElevenLabs Pricing

| Component | Cost |
|-----------|------|
| Scribe STT (realtime) | $0.28–0.48/hr |
| TTS (Flash v2.5) | ~0.5 credits/char |
| Free tier | 10,000 credits/month (~10 min TTS) |
| Starter | $5/mo — 30,000 credits |
| Scale | $22/mo — 100,000 credits |
