import CoreAudio
import Foundation

// State directory passed as first argument
guard CommandLine.arguments.count > 1 else {
    fputs("usage: watcher <run-dir>\n", stderr)
    exit(1)
}
let runDir = CommandLine.arguments[1]
let timestampFile = "\(runDir)/last-spoken"
let ttsPidFile = "\(runDir)/tts.pid"

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

let callbackQueue = DispatchQueue(label: "mic-watcher")
var bargeInTimer: DispatchWorkItem?
let bargeInDelay: TimeInterval = 0.3  // debounce to filter spurious mic blips

AudioObjectAddPropertyListenerBlock(deviceID, &runningAddress, callbackQueue) { _, _ in
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
        // Mic went active — debounce before barge-in
        let timer = DispatchWorkItem {
            if let pidStr = try? String(contentsOfFile: ttsPidFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
               let pid = Int32(pidStr) {
                kill(pid, SIGTERM)
                try? FileManager.default.removeItem(atPath: ttsPidFile)
            }
        }
        bargeInTimer = timer
        callbackQueue.asyncAfter(deadline: .now() + bargeInDelay, execute: timer)
    } else if !running && wasRunning {
        // Mic went idle — cancel pending barge-in if it was a blip
        bargeInTimer?.cancel()
        bargeInTimer = nil
        // Write timestamp
        try? String(Int(Date().timeIntervalSince1970)).write(toFile: timestampFile, atomically: true, encoding: .utf8)
    }
    wasRunning = running
}

// Keep alive
signal(SIGTERM, SIG_IGN)
let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigterm.setEventHandler {
    try? FileManager.default.removeItem(atPath: timestampFile)
    exit(0)
}
sigterm.resume()

signal(SIGINT, SIG_IGN)
let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigint.setEventHandler {
    try? FileManager.default.removeItem(atPath: timestampFile)
    exit(0)
}
sigint.resume()

dispatchMain()
