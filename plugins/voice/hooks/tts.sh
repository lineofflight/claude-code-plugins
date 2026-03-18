#!/usr/bin/env bash

[[ -n "${ELEVENLABS_API_KEY:-}" ]] || exit 0

input="$(cat)"

[[ "$(echo "$input" | jq -r '.stop_hook_active // false')" == "true" ]] && exit 0

# Check if voice is active (manual toggle or native voice detected this turn)
spokefile="/tmp/cc-voice-spoke.$PPID"
if [[ ! -f /tmp/cc-voice-toggle ]] && [[ ! -f "$spokefile" ]]; then
  exit 0
fi

# Clean spoke file early so it's cleared even if TTS fails
rm -f "$spokefile"

text="$(echo "$input" | jq -r '.last_assistant_message // empty')"
[[ -z "$text" ]] && exit 0

# Strip markdown and code for TTS
text="$(echo "$text" | \
  sed '/^``` *[[:alpha:]]*/,/^```/d' | \
  sed 's/`[^`]*`//g; s/\*\*//g; s/\*//g; s/^#\{1,6\} //' | \
  sed '/^|/d; /^---*$/d' | \
  tr '\n' ' ' | \
  sed 's/  */ /g; s/^ //; s/ $//')"
[[ -z "$text" ]] && exit 0

if (( ${#text} > 500 )); then
  text="${text:0:500}"
  text="${text% *}..."
fi

# TTS via ElevenLabs
voice_id="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
tmpfile="$(mktemp /tmp/voice-XXXXXX.mp3)"
trap 'rm -f "$tmpfile"' EXIT

curl -s \
  -X POST "https://api.elevenlabs.io/v1/text-to-speech/${voice_id}/stream" \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg t "$text" '{text: $t, model_id: "eleven_flash_v2_5"}')" \
  -o "$tmpfile"

[[ -s "$tmpfile" ]] || exit 0

pidfile="/tmp/cc-voice-afplay.$PPID"
afplay "$tmpfile" &
afplay_pid=$!
echo "$afplay_pid" > "$pidfile"
wait "$afplay_pid" 2>/dev/null || true
rm -f "$pidfile"
