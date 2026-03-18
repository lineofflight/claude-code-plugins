#!/usr/bin/env bash

SESSION_PID=$PPID
PIDFILE="/tmp/cc-voice-watcher.${SESSION_PID}"
AFPLAY_PIDFILE="/tmp/cc-voice-afplay.${SESSION_PID}"

if [[ -f "$PIDFILE" ]]; then
  kill "$(cat "$PIDFILE")" 2>/dev/null || true
  rm -f "$PIDFILE"
fi

if [[ -f "$AFPLAY_PIDFILE" ]]; then
  kill "$(cat "$AFPLAY_PIDFILE")" 2>/dev/null || true
  rm -f "$AFPLAY_PIDFILE"
fi

rm -f "/tmp/cc-voice-spoke.${SESSION_PID}"
