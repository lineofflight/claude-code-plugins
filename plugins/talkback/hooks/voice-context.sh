#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect voice input via mic watcher timestamp
ts_file="$SCRIPT_DIR/run/last-spoken"
if [[ -f "$ts_file" ]]; then
  last_spoken=$(cat "$ts_file")
  now=$(date +%s)
  if (( now - last_spoken <= 600 )); then
    echo '{"additionalContext": "User spoke via voice. If the answer is short, be conversational. Replies under 30 words will be spoken aloud. If it requires code or detailed explanation, respond normally."}'
  fi
fi
