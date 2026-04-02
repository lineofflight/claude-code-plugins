#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

input="$(cat)"

# Check if stop hook is active (avoid recursion)
echo "$input" | grep -q '"stop_hook_active":[ ]*true' && exit 0

# Extract last_assistant_message
text="$(echo "$input" | jq -r '.last_assistant_message // empty')"
[[ -z "$text" ]] && exit 0

# Strip markdown and code for TTS
text="$(echo "$text" | \
  sed '/^``` *[[:alpha:]]*/,/^```/d' | \
  sed 's/`//g; s/\*\*//g; s/\*//g; s/^#\{1,6\} //' | \
  sed '/^|/d; /^---*$/d' | \
  tr '\n' ' ' | \
  sed 's/  */ /g; s/^ //; s/ $//')"
[[ -z "$text" ]] && exit 0

# Only speak if the response starts with a natural speech word
speak=false
text_lower="$(echo "$text" | tr '[:upper:]' '[:lower:]')"
while IFS= read -r starter; do
  [[ -z "$starter" ]] && continue
  starter_lower="$(echo "$starter" | tr '[:upper:]' '[:lower:]')"
  if [[ "$text_lower" =~ ^"$starter_lower"([^a-z]|$) ]]; then
    speak=true
    break
  fi
done < "$SCRIPT_DIR/speech-starters.txt"
$speak || exit 0

# Speak via wrapper (supports barge-in), then clear the voice toggle
"$SCRIPT_DIR/talkback.sh" "$text"
rm -f "$SCRIPT_DIR/run/last-spoken"
