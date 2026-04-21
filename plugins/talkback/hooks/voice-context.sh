#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Only nudge when user spoke via mic (watcher writes last-spoken timestamp)
ts_file="$SCRIPT_DIR/run/last-spoken"
[[ -f "$ts_file" ]] || exit 0
last_spoken=$(cat "$ts_file")
now=$(date +%s)
(( now - last_spoken > 600 )) && exit 0

# Build word list from shared source of truth
starters=""
while IFS= read -r line; do
  [[ -n "$line" ]] && starters="${starters:+$starters, }$line"
done < "$SCRIPT_DIR/speech-starters.txt"

echo "User spoke with STT. If you would like to speak back with TTS, be conversational, keep it short, and start with a speech word ($starters)."

# One-shot: watcher rewrites the timestamp on the next mic-off, so clear it
# now to avoid nudging subsequent typed turns within the 10-min window.
rm -f "$ts_file"
