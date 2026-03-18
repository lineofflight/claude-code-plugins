#!/usr/bin/env bash
set -euo pipefail

togglefile="/tmp/cc-voice-toggle"

if [[ -f "$togglefile" ]]; then
  rm -f "$togglefile"
  echo "Voice output off"
else
  touch "$togglefile"
  echo "Voice output on"
fi
