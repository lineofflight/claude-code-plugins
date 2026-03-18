#!/usr/bin/env bash
set -euo pipefail

SESSION_PID=$PPID
PIDFILE="/tmp/cc-voice-watcher.${SESSION_PID}"
SPOKEFILE="/tmp/cc-voice-spoke.${SESSION_PID}"
AFPLAY_PIDFILE="/tmp/cc-voice-afplay.${SESSION_PID}"

# Don't start if already running
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  exit 0
fi

# Launch watcher in background
# Self-terminates if session dies
(
  trap 'rm -f "$PIDFILE"' EXIT
  was_recording=0
  while kill -0 "$SESSION_PID" 2>/dev/null; do
    if pgrep -x rec >/dev/null 2>&1 || pgrep -x arecord >/dev/null 2>&1; then
      if (( was_recording == 0 )); then
        # Barge-in: stop our TTS playback on recording start
        if [[ -f "$AFPLAY_PIDFILE" ]]; then
          kill "$(cat "$AFPLAY_PIDFILE")" 2>/dev/null || true
          rm -f "$AFPLAY_PIDFILE"
        fi
        # Mark: user spoke this turn (rising edge only)
        touch "$SPOKEFILE"
      fi
      was_recording=1
    else
      was_recording=0
    fi
    sleep 0.2
  done
) &

echo $! > "$PIDFILE"
