#!/usr/bin/env bash

# macOS only — CoreAudio mic watcher requires Darwin
if [[ "$(uname)" != "Darwin" ]]; then
  echo "voice: mic watcher requires macOS" >&2
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$SCRIPT_DIR/run"
PID_FILE="$RUN_DIR/watcher.pid"

mkdir -p "$RUN_DIR"

# Already running?
pid=$(cat "$PID_FILE" 2>/dev/null)
if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
  exit 0
fi

# Compile if needed
if [[ ! -x "$SCRIPT_DIR/watcher" ]] || [[ "$SCRIPT_DIR/watcher.swift" -nt "$SCRIPT_DIR/watcher" ]]; then
  swiftc -O -o "$SCRIPT_DIR/watcher" "$SCRIPT_DIR/watcher.swift" 2>/dev/null || exit 0
fi

# Clean up stale state from a previous session
rm -f "$RUN_DIR/last-spoken"

# Start watcher in background
"$SCRIPT_DIR/watcher" "$RUN_DIR" &
echo $! > "$PID_FILE"
disown
