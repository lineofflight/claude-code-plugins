#!/usr/bin/env node

/**
 * Voice Conversation Orchestrator
 *
 * Spawns a Claude Code session with stream-json output and manages a full-duplex
 * voice loop: ElevenLabs Scribe STT (mic → text) and ElevenLabs TTS (text → speaker).
 *
 * Architecture:
 *   Mic → STT WebSocket → transcript → Claude (stdin) → stream-json → text filter → TTS WebSocket → Speaker
 *
 * Key behaviors:
 *   - Text filtering: code blocks, URLs, file paths are not spoken
 *   - Barge-in: user speech cancels TTS playback and yields new input
 *   - Non-blocking: STT/TTS/Claude pipelines run independently
 */

import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import WebSocket from "ws";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;
if (!ELEVENLABS_API_KEY) {
  console.error("ELEVENLABS_API_KEY is required");
  process.exit(1);
}

const VOICE_ID =
  process.env.ELEVENLABS_VOICE_ID || "21m00Tcm4TlvDq8ikWAM"; // Rachel
const TTS_MODEL =
  process.env.ELEVENLABS_TTS_MODEL || "eleven_flash_v2_5";
const SILENCE_THRESHOLD = parseFloat(
  process.env.VOICE_SILENCE_THRESHOLD || "0.5"
);

// ---------------------------------------------------------------------------
// Text filter — decide what gets spoken vs. displayed only
// ---------------------------------------------------------------------------

/**
 * Accumulates streaming text deltas and emits speakable chunks.
 * Strips code fences, URLs, and file paths. Buffers until sentence boundary.
 */
class TextFilter {
  constructor() {
    this.buffer = "";
    this.inCodeBlock = false;
    this.codeBlockAnnounced = false;
  }

  /** Feed a text_delta chunk. Returns array of speakable strings (may be empty). */
  push(text) {
    const speakable = [];

    for (const char of text) {
      this.buffer += char;

      // Detect code fence boundaries
      if (this.buffer.endsWith("```")) {
        if (!this.inCodeBlock) {
          this.inCodeBlock = true;
          this.codeBlockAnnounced = false;
          // Flush anything before the fence
          const before = this.buffer.slice(0, -3).trim();
          if (before) speakable.push(...this.#extractSentences(before));
          this.buffer = "";
          continue;
        } else {
          this.inCodeBlock = false;
          if (!this.codeBlockAnnounced) {
            speakable.push("Here's some code.");
            this.codeBlockAnnounced = true;
          }
          this.buffer = "";
          continue;
        }
      }

      // Skip content inside code blocks
      if (this.inCodeBlock) {
        this.buffer = "";
        continue;
      }

      // Try to extract complete sentences
      if (/[.!?]\s/.test(this.buffer) || this.buffer.endsWith("\n\n")) {
        const cleaned = this.#cleanForSpeech(this.buffer);
        if (cleaned) speakable.push(cleaned);
        this.buffer = "";
      }
    }

    return speakable;
  }

  /** Flush remaining buffer (call at end of turn). */
  flush() {
    if (this.inCodeBlock) {
      this.inCodeBlock = false;
      if (!this.codeBlockAnnounced) return ["Here's some code."];
      return [];
    }
    const cleaned = this.#cleanForSpeech(this.buffer);
    this.buffer = "";
    return cleaned ? [cleaned] : [];
  }

  #extractSentences(text) {
    return text
      .split(/(?<=[.!?])\s+/)
      .map((s) => this.#cleanForSpeech(s))
      .filter(Boolean);
  }

  #cleanForSpeech(text) {
    return (
      text
        // Remove URLs
        .replace(/https?:\/\/\S+/g, "")
        // Remove file paths (Unix and relative)
        .replace(/(?:\/[\w.-]+){2,}/g, "")
        .replace(/\b[\w.-]+\/[\w.-]+(?:\/[\w.-]+)+/g, "")
        // Remove inline code
        .replace(/`[^`]+`/g, "")
        // Remove markdown formatting
        .replace(/[*_~#]+/g, "")
        // Remove pipe-table rows
        .replace(/\|[^|]+\|/g, "")
        // Collapse whitespace
        .replace(/\s+/g, " ")
        .trim()
    );
  }
}

// ---------------------------------------------------------------------------
// TTS — ElevenLabs WebSocket text-to-speech
// ---------------------------------------------------------------------------

class TTSStream {
  constructor() {
    this.ws = null;
    this.connected = false;
    this.audioQueue = [];
  }

  async connect() {
    const url = `wss://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}/stream-input?model_id=${TTS_MODEL}`;

    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(url);

      this.ws.on("open", () => {
        // Begin-of-stream message
        this.ws.send(
          JSON.stringify({
            text: " ",
            voice_settings: { stability: 0.5, similarity_boost: 0.75 },
            xi_api_key: ELEVENLABS_API_KEY,
          })
        );
        this.connected = true;
        resolve();
      });

      this.ws.on("message", (data) => {
        const msg = JSON.parse(data.toString());
        if (msg.audio) {
          // Audio chunk received — write to stdout as raw PCM for playback
          const buf = Buffer.from(msg.audio, "base64");
          process.stdout.write(buf);
        }
      });

      this.ws.on("error", reject);
      this.ws.on("close", () => {
        this.connected = false;
      });
    });
  }

  /** Send a text chunk to be spoken. */
  speak(text) {
    if (!this.connected || !text.trim()) return;
    this.ws.send(
      JSON.stringify({
        text: text + " ",
        try_trigger_generation: true,
      })
    );
  }

  /** Flush buffered audio and signal end of input. */
  flush() {
    if (!this.connected) return;
    this.ws.send(JSON.stringify({ text: "", flush: true }));
  }

  /** Cancel current speech (barge-in). Closes and reconnects. */
  async cancel() {
    if (this.ws) {
      this.ws.close();
      this.connected = false;
    }
    await this.connect();
  }

  close() {
    if (this.ws) {
      this.ws.send(JSON.stringify({ text: "" })); // EOS
      this.ws.close();
    }
  }
}

// ---------------------------------------------------------------------------
// STT — ElevenLabs Scribe WebSocket speech-to-text
// ---------------------------------------------------------------------------

class STTStream {
  constructor({ onTranscript, onSpeechStart }) {
    this.onTranscript = onTranscript;
    this.onSpeechStart = onSpeechStart;
    this.ws = null;
  }

  async connect() {
    const url = `wss://api.elevenlabs.io/v1/speech-to-text/realtime?model_id=scribe_v2_realtime&sample_rate=16000&language_code=en`;

    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(url, {
        headers: { "xi-api-key": ELEVENLABS_API_KEY },
      });

      this.ws.on("open", () => {
        console.error("[STT] Connected — listening…");
        resolve();
      });

      this.ws.on("message", (data) => {
        const msg = JSON.parse(data.toString());

        if (msg.type === "partial_transcript" && msg.text) {
          // User is speaking — trigger barge-in
          this.onSpeechStart?.();
        }

        if (msg.type === "committed_transcript" && msg.text) {
          console.error(`[STT] "${msg.text}"`);
          this.onTranscript(msg.text);
        }
      });

      this.ws.on("error", reject);
    });
  }

  /** Feed raw PCM audio from microphone. */
  sendAudio(pcmBuffer) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(
        JSON.stringify({
          audio_base_64: pcmBuffer.toString("base64"),
          sample_rate: 16000,
        })
      );
    }
  }

  close() {
    this.ws?.close();
  }
}

// ---------------------------------------------------------------------------
// Claude Code session — stream-json mode
// ---------------------------------------------------------------------------

function spawnClaude(sessionId) {
  const args = [
    "-p",
    "--output-format",
    "stream-json",
    "--verbose",
    "--include-partial-messages",
  ];
  if (sessionId) args.push("--resume", sessionId);

  return spawn("claude", args, {
    stdio: ["pipe", "pipe", "inherit"],
  });
}

// ---------------------------------------------------------------------------
// Main orchestrator
// ---------------------------------------------------------------------------

async function main() {
  const tts = new TTSStream();
  const textFilter = new TextFilter();
  let claude = null;
  let currentSessionId = null;
  let speaking = false;

  // --- STT setup: when user speaks, barge-in; when transcript commits, send to Claude ---
  const stt = new STTStream({
    onSpeechStart: async () => {
      if (speaking) {
        console.error("[BARGE-IN] User speaking — cancelling TTS");
        speaking = false;
        await tts.cancel();
      }
    },
    onTranscript: (text) => {
      sendToClaudeSession(text);
    },
  });

  // --- Send user message to Claude ---
  function sendToClaudeSession(text) {
    if (!text.trim()) return;
    console.error(`[USER] ${text}`);

    // Spawn a new Claude process for each turn, resuming the session
    const args = [
      "-p",
      text,
      "--output-format",
      "stream-json",
      "--verbose",
      "--include-partial-messages",
    ];
    if (currentSessionId) args.push("--resume", currentSessionId);

    claude = spawn("claude", args, {
      stdio: ["pipe", "pipe", "inherit"],
    });

    handleClaudeOutput(claude);
  }

  // --- Process Claude's streaming output ---
  function handleClaudeOutput(proc) {
    const rl = createInterface({ input: proc.stdout });
    speaking = true;

    rl.on("line", (line) => {
      try {
        const event = JSON.parse(line);

        // Capture session ID
        if (event.session_id) currentSessionId = event.session_id;

        // Text deltas → filter → TTS
        if (
          event.type === "stream_event" &&
          event.event?.delta?.type === "text_delta"
        ) {
          const chunks = textFilter.push(event.event.delta.text);
          for (const chunk of chunks) {
            tts.speak(chunk);
          }
        }

        // Tool use narration
        if (
          event.type === "stream_event" &&
          event.event?.type === "content_block_start" &&
          event.event?.content_block?.type === "tool_use"
        ) {
          const toolName = event.event.content_block.name;
          tts.speak(`Using ${toolName}.`);
        }
      } catch {
        // Non-JSON line, ignore
      }
    });

    rl.on("close", () => {
      // Flush remaining text
      const remaining = textFilter.flush();
      for (const chunk of remaining) {
        tts.speak(chunk);
      }
      tts.flush();
      speaking = false;
    });
  }

  // --- Connect everything ---
  console.error("[VOICE] Connecting to ElevenLabs…");
  await tts.connect();
  await stt.connect();

  console.error("[VOICE] Ready. Speak to begin.");
  tts.speak("Voice mode active. Go ahead.");
  tts.flush();

  // --- Handle stdin as fallback text input ---
  const stdinRL = createInterface({ input: process.stdin });
  stdinRL.on("line", (line) => {
    sendToClaudeSession(line);
  });

  // --- Graceful shutdown ---
  process.on("SIGINT", () => {
    console.error("\n[VOICE] Shutting down…");
    stt.close();
    tts.close();
    claude?.kill();
    process.exit(0);
  });
}

main().catch((err) => {
  console.error("[VOICE] Fatal:", err);
  process.exit(1);
});
