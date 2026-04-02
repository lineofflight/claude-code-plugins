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

echo "User spoke via voice. Be conversational and start with a natural speech word ($starters) so it gets spoken aloud. If it requires code or detailed explanation, respond normally."
