#!/usr/bin/env bash

# Detect CC's native /voice via Apple's speech recognition process
if pgrep -f embeddedspeech >/dev/null 2>&1; then
  echo '{"additionalContext": "User spoke via voice. Be conversational. Your final message will be spoken aloud, so keep it to a sentence or two."}'
fi
