#!/usr/bin/env bash

# macOS only — requires say command
if [[ "$(uname)" != "Darwin" ]]; then
  echo "voice: TTS requires macOS" >&2
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/run/tts.pid"
text="$1"

[[ -z "$text" ]] && exit 0

# Write our PID so the watcher can kill us
echo $$ > "$PID_FILE"

# exec replaces this shell with say, so the PID file
# points at the actual TTS process. The watcher handles
# PID file cleanup after kill.
exec say "$text"
