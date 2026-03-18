#!/usr/bin/env bash

SESSION_PID=$PPID
PIDFILE="/tmp/cc-voice-watcher.${SESSION_PID}"
SAY_PIDFILE="/tmp/cc-voice-say.${SESSION_PID}"

if [[ -f "$PIDFILE" ]]; then
  kill "$(cat "$PIDFILE")" 2>/dev/null || true
  rm -f "$PIDFILE"
fi

if [[ -f "$SAY_PIDFILE" ]]; then
  kill "$(cat "$SAY_PIDFILE")" 2>/dev/null || true
  rm -f "$SAY_PIDFILE"
fi

rm -f "/tmp/cc-voice-spoke.${SESSION_PID}"
