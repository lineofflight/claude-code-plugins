# Voice v0.4.0: Mic Watcher + Speak Wrapper

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace `embeddedspeech` process detection with a CoreAudio mic watcher for reliable voice detection and clean barge-in.

**Architecture:** A background Swift script watches mic state via CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere`. When mic goes active, it writes a timestamp and kills any running TTS. TTS is wrapped in `speak.sh` which writes its PID for targeted barge-in. Hooks check the timestamp to determine if the prompt came from voice.

**Tech Stack:** Swift (CoreAudio), Bash, macOS `say`

---

### Task 1: Create the mic watcher (`watcher.swift`)

**Files:**
- Create: `plugins/voice/hooks/watcher.swift`

**Step 1: Write the watcher**

```swift
import CoreAudio
import Foundation

// State file paths
let timestampFile = "/tmp/claude-voice-last-spoken"
let ttsPidFile = "/tmp/claude-voice-tts.pid"

// Get default input device
var address = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultInputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)
var deviceID: AudioDeviceID = 0
var size = UInt32(MemoryLayout<AudioDeviceID>.size)
guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID) == noErr else {
    fputs("error: could not get default input device\n", stderr)
    exit(1)
}

var wasRunning = false

// Listen for changes to "is running somewhere"
var runningAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)

AudioObjectAddPropertyListenerBlock(deviceID, &runningAddress, nil) { _, _ in
    var isRunning: UInt32 = 0
    var runSize = UInt32(MemoryLayout<UInt32>.size)
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &runSize, &isRunning)

    let running = isRunning > 0
    if running && !wasRunning {
        // Mic just went active — barge-in: kill TTS
        if let pidStr = try? String(contentsOfFile: ttsPidFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           let pid = Int32(pidStr) {
            kill(pid, SIGTERM)
            try? FileManager.default.removeItem(atPath: ttsPidFile)
        }
    } else if !running && wasRunning {
        // Mic just went idle — write timestamp
        try? String(Int(Date().timeIntervalSince1970)).write(toFile: timestampFile, atomically: true, encoding: .utf8)
    }
    wasRunning = running
}

// Keep alive
signal(SIGTERM) { _ in
    try? FileManager.default.removeItem(atPath: timestampFile)
    exit(0)
}
signal(SIGINT) { _ in
    try? FileManager.default.removeItem(atPath: timestampFile)
    exit(0)
}

dispatchMain()
```

**Step 2: Compile and verify it runs**

Run: `cd plugins/voice/hooks && swiftc -O -o watcher watcher.swift`
Expected: Produces `watcher` binary, no errors.

Run: `./watcher &` then `kill %1`
Expected: Starts, runs in background, exits cleanly on SIGTERM.

**Step 3: Commit**

```bash
git add plugins/voice/hooks/watcher.swift
git commit -m "voice: add CoreAudio mic watcher"
```

---

### Task 2: Create the speak wrapper (`speak.sh`)

**Files:**
- Create: `plugins/voice/hooks/speak.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash

PID_FILE="/tmp/claude-voice-tts.pid"
text="$1"

[[ -z "$text" ]] && exit 0

# Write our PID so the watcher can kill us
echo $$ > "$PID_FILE"

# Trap to clean up PID file on exit
trap 'rm -f "$PID_FILE"' EXIT

# TTS — swap this line to change engine
say "$text"
```

**Step 2: Make executable and test**

Run: `chmod +x plugins/voice/hooks/speak.sh && ./plugins/voice/hooks/speak.sh "test"`
Expected: Speaks "test", PID file created and cleaned up.

**Step 3: Commit**

```bash
git add plugins/voice/hooks/speak.sh
git commit -m "voice: add speak wrapper with PID file for barge-in"
```

---

### Task 3: Update `tts.sh` to use `speak.sh`

**Files:**
- Modify: `plugins/voice/hooks/tts.sh`

**Step 1: Update tts.sh to check timestamp and delegate to speak.sh**

Replace the `embeddedspeech` check with a timestamp check, and replace the `say` call with `speak.sh`:

```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

input="$(cat)"

# Check if stop hook is active (avoid recursion)
echo "$input" | grep -q '"stop_hook_active":[ ]*true' && exit 0

# Only speak when a voice prompt was recently submitted
ts_file="/tmp/claude-voice-last-spoken"
[[ -f "$ts_file" ]] || exit 0
last_spoken=$(cat "$ts_file")
now=$(date +%s)
(( now - last_spoken > 10 )) && exit 0

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

# Speak via wrapper (supports barge-in)
"$SCRIPT_DIR/speak.sh" "$text"
```

**Step 2: Commit**

```bash
git add plugins/voice/hooks/tts.sh
git commit -m "voice: use speak wrapper and timestamp-based detection in tts"
```

---

### Task 4: Update `voice-context.sh` to use timestamp

**Files:**
- Modify: `plugins/voice/hooks/voice-context.sh`

**Step 1: Replace embeddedspeech check with timestamp check**

```bash
#!/usr/bin/env bash

# Detect voice input via mic watcher timestamp
ts_file="/tmp/claude-voice-last-spoken"
if [[ -f "$ts_file" ]]; then
  last_spoken=$(cat "$ts_file")
  now=$(date +%s)
  if (( now - last_spoken <= 5 )); then
    echo '{"additionalContext": "User spoke via voice. Be conversational. Your final message will be spoken aloud, so keep it to a sentence or two."}'
  fi
fi
```

**Step 2: Commit**

```bash
git add plugins/voice/hooks/voice-context.sh
git commit -m "voice: use timestamp detection in voice-context"
```

---

### Task 5: Watcher lifecycle management

**Files:**
- Modify: `plugins/voice/hooks/hooks.json`
- Create: `plugins/voice/hooks/start-watcher.sh`

The watcher needs to start when voice mode is activated. The `/voice` command triggers a `UserPromptSubmit` — we can start the watcher on the first voice prompt if it's not already running.

**Step 1: Create start-watcher.sh**

```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="/tmp/claude-voice-watcher.pid"

# Already running?
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  exit 0
fi

# Compile if needed
if [[ ! -x "$SCRIPT_DIR/watcher" ]] || [[ "$SCRIPT_DIR/watcher.swift" -nt "$SCRIPT_DIR/watcher" ]]; then
  swiftc -O -o "$SCRIPT_DIR/watcher" "$SCRIPT_DIR/watcher.swift" 2>/dev/null || exit 0
fi

# Start watcher in background
"$SCRIPT_DIR/watcher" &
echo $! > "$PID_FILE"
disown
```

**Step 2: Make executable**

Run: `chmod +x plugins/voice/hooks/start-watcher.sh`

**Step 3: Update hooks.json to start watcher on prompt submit**

```json
{
  "description": "TTS output and voice detection for Claude Code",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/start-watcher.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/voice-context.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/tts.sh",
            "async": true,
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Step 4: Commit**

```bash
git add plugins/voice/hooks/start-watcher.sh plugins/voice/hooks/hooks.json
git commit -m "voice: add watcher lifecycle management"
```

---

### Task 6: Add compiled binary to .gitignore and bump version

**Files:**
- Create: `plugins/voice/hooks/.gitignore`
- Modify: `plugins/voice/.claude-plugin/plugin.json`

**Step 1: Gitignore the compiled watcher binary**

```
watcher
```

**Step 2: Bump version to 0.4.0**

Update `plugin.json` version from `"0.3.0"` to `"0.4.0"`.

**Step 3: Commit**

```bash
git add plugins/voice/hooks/.gitignore plugins/voice/.claude-plugin/plugin.json
git commit -m "voice v0.4.0: mic watcher with barge-in"
```
