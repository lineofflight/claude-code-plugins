#!/usr/bin/env bash

# macOS only
if [[ "$(uname)" != "Darwin" ]]; then
  echo "talkback: TTS requires macOS" >&2
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/run/tts.pid"
text="$1"

[[ -z "$text" ]] && exit 0

# Write our PID so the watcher can kill us
echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

ENGINE="${TALKBACK_ENGINE:-say}"

case "$ENGINE" in
  elevenlabs)
    VOICE_ID="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
    curl -s -X POST \
      "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}/stream" \
      -H "xi-api-key: $ELEVENLABS_API_KEY" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg text "$text" '{text: $text, model_id: "eleven_flash_v2_5"}')" \
      -o "$SCRIPT_DIR/run/tts.mp3"
    [[ -s "$SCRIPT_DIR/run/tts.mp3" ]] && exec afplay "$SCRIPT_DIR/run/tts.mp3"
    ;;
  *)
    exec say "$text"
    ;;
esac
