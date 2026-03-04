#!/usr/bin/env bash
# Notification hook — speaks permission prompts and idle alerts.

set -euo pipefail

[ "${VOICE_ENABLED:-true}" = "true" ] || exit 0
[ -n "${ELEVENLABS_API_KEY:-}" ] || exit 0

VOICE_ID="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
TTS_MODEL="${ELEVENLABS_TTS_MODEL:-eleven_flash_v2_5}"

payload=$(cat)
notification_type=$(echo "$payload" | jq -r '.type // empty' 2>/dev/null)

case "$notification_type" in
  permission_prompt)
    narration="Claude needs your permission to proceed."
    ;;
  idle_prompt)
    narration="Claude is waiting for your input."
    ;;
  *)
    exit 0
    ;;
esac

curl -sS --max-time 10 \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg text "$narration" --arg model "$TTS_MODEL" '{
    text: $text,
    model_id: $model,
    voice_settings: { stability: 0.5, similarity_boost: 0.75 }
  }')" \
  "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}/stream" \
  --output /dev/null &

echo "[voice] Notification: $narration" >&2
