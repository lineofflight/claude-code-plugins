#!/usr/bin/env bash

input="$(cat)"

# Check if stop hook is active (avoid recursion)
echo "$input" | grep -q '"stop_hook_active":[ ]*true' && exit 0

# Only speak when voice mode is active
pgrep -f embeddedspeech >/dev/null 2>&1 || exit 0

# Extract last_assistant_message
text="$(echo "$input" | jq -r '.last_assistant_message // empty')"
[[ -z "$text" ]] && exit 0

# Strip markdown and code for TTS
text="$(echo "$text" | \
  sed '/^``` *[[:alpha:]]*/,/^```/d' | \
  sed 's/`[^`]*`//g; s/\*\*//g; s/\*//g; s/^#\{1,6\} //' | \
  sed '/^|/d; /^---*$/d' | \
  tr '\n' ' ' | \
  sed 's/  */ /g; s/^ //; s/ $//')"
[[ -z "$text" ]] && exit 0

# TTS via macOS say
say "$text"
