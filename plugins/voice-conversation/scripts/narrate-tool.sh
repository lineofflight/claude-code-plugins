#!/usr/bin/env bash
# PostToolUse hook — briefly narrates tool actions.
# Receives tool use info on stdin as JSON.

set -euo pipefail

[ "${VOICE_ENABLED:-true}" = "true" ] || exit 0
[ -n "${ELEVENLABS_API_KEY:-}" ] || exit 0

VOICE_ID="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
TTS_MODEL="${ELEVENLABS_TTS_MODEL:-eleven_flash_v2_5}"

payload=$(cat)
tool_name=$(echo "$payload" | jq -r '.tool_name // empty' 2>/dev/null)
tool_input=$(echo "$payload" | jq -r '.tool_input // empty' 2>/dev/null)

[ -z "$tool_name" ] && exit 0

# Build a short narration based on tool type
case "$tool_name" in
  Bash)
    cmd=$(echo "$tool_input" | jq -r '.command // empty' 2>/dev/null | head -c 60)
    narration="Running a command."
    # Try to make it more specific for common commands
    case "$cmd" in
      npm\ test*|yarn\ test*|pytest*|jest*) narration="Running tests." ;;
      npm\ install*|yarn\ install*|pip\ install*) narration="Installing dependencies." ;;
      npm\ run\ build*|yarn\ build*) narration="Building the project." ;;
      git\ *) narration="Running a git command." ;;
    esac
    ;;
  Edit)
    file=$(echo "$tool_input" | jq -r '.file_path // empty' 2>/dev/null | xargs basename 2>/dev/null || true)
    narration="Editing ${file:-a file}."
    ;;
  Write)
    file=$(echo "$tool_input" | jq -r '.file_path // empty' 2>/dev/null | xargs basename 2>/dev/null || true)
    narration="Writing ${file:-a file}."
    ;;
  *)
    narration="Using ${tool_name}."
    ;;
esac

# Speak the narration
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
  # TODO: pipe to audio player

echo "[voice] Narrated: $narration" >&2
