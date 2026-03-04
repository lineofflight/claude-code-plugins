#!/usr/bin/env bash
# Stop hook — speaks Claude's response via ElevenLabs TTS.
# Receives the assistant message on stdin as JSON.
# Filters out code blocks, URLs, and file paths before speaking.

set -euo pipefail

[ "${VOICE_ENABLED:-true}" = "true" ] || exit 0
[ -n "${ELEVENLABS_API_KEY:-}" ] || exit 0

VOICE_ID="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
TTS_MODEL="${ELEVENLABS_TTS_MODEL:-eleven_flash_v2_5}"

# Read the stop hook payload from stdin
payload=$(cat)

# Extract assistant text content, stripping code blocks, URLs, paths
text=$(echo "$payload" | jq -r '
  .stop_response // .message // "" |
  if type == "array" then
    [.[] | select(.type == "text") | .text] | join(" ")
  elif type == "string" then .
  else ""
  end
' 2>/dev/null || echo "")

[ -z "$text" ] && exit 0

# Clean for speech
clean=$(echo "$text" | \
  sed 's/```[^`]*```/Here is some code./g' | \
  sed 's/`[^`]*`//g' | \
  sed 's|https\?://[^ ]*||g' | \
  sed 's|/[a-zA-Z0-9_./-]\{2,\}||g' | \
  sed 's/[*_~#|]//g' | \
  tr -s ' ' | \
  head -c 5000)

[ -z "$clean" ] && exit 0

# Send to ElevenLabs TTS REST endpoint (streaming)
curl -sS --max-time 30 \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg text "$clean" --arg model "$TTS_MODEL" '{
    text: $text,
    model_id: $model,
    voice_settings: { stability: 0.5, similarity_boost: 0.75 }
  }')" \
  "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}/stream" \
  --output /dev/null &
  # TODO: pipe to audio player (aplay, afplay, sox, etc.) instead of /dev/null
  # e.g.: | aplay -r 44100 -f S16_LE -c 1

echo "[voice] Spoke ${#clean} chars" >&2
