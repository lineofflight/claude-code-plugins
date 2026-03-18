#!/usr/bin/env bash

input="$(cat)"

# Check if stop hook is active (avoid recursion)
echo "$input" | grep -q '"stop_hook_active":\s*true' && exit 0

# Check if voice is active (manual toggle or native voice detected this turn)
spokefile="/tmp/cc-voice-spoke.$PPID"
if [[ ! -f /tmp/cc-voice-toggle ]] && [[ ! -f "$spokefile" ]]; then
  exit 0
fi

rm -f "$spokefile"

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
pidfile="/tmp/cc-voice-say.$PPID"
say "$text" &
say_pid=$!
echo "$say_pid" > "$pidfile"
wait "$say_pid" 2>/dev/null || true
rm -f "$pidfile"
