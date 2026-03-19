#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

input="$(cat)"

# Check if stop hook is active (avoid recursion)
echo "$input" | grep -q '"stop_hook_active":[ ]*true' && exit 0

# Only speak when a voice prompt was submitted this session
ts_file="$SCRIPT_DIR/run/last-spoken"
[[ -f "$ts_file" ]] || exit 0
last_spoken=$(cat "$ts_file")
now=$(date +%s)
(( now - last_spoken > 600 )) && { rm -f "$ts_file"; exit 0; }

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

# Skip speaking long responses (likely code-heavy)
word_count=$(echo "$text" | wc -w | tr -d ' ')
(( word_count > 30 )) && { rm -f "$ts_file"; exit 0; }

# Speak via wrapper (supports barge-in), then clear the toggle
# so user must speak again to trigger TTS on the next turn
"$SCRIPT_DIR/speak.sh" "$text"
rm -f "$ts_file"
