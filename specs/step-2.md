# Step 2 — Global hotkey + push‑to‑talk audio capture + HUD

## Goal
Implement the core “press to talk” interaction: global hotkey detection, start/stop recording on press/release, and display a HUD indicator while listening.

## Deliverables
- `HotkeyService` that listens for a configured key globally (press + release).
- `AudioRecorder` service that records to a temporary file with model‑friendly format.
- `HUDWindowController` that shows a bottom‑center indicator while recording.
- Integration glue: `AppDelegate`/`AppState` hooks services together.

## TODOs
- [ ] Implement `HotkeyService` using `CGEventTap` for global key events:
  - Map `SettingsStore.hotkey` into `CGKeyCode` + modifiers.
  - Ignore key repeats; react only on initial down and corresponding up.
  - Provide delegate/closure callbacks for `onPress`/`onRelease`.
  - Handle tap failure/re‑enable logic and surface errors to logs.
- [ ] Hardcode the invoke key to Globe/Fn for this step:
  - Use the best-available capture approach and document any OS limitations.
  - If Globe/Fn cannot be captured directly, fall back to a nearby function key and log a warning.
- [ ] Add a 100 ms debounce before starting recording:
  - Only start recording if the key is still held after the debounce interval.
  - Cancel the pending start if key is released before the debounce completes.
- [ ] Build `AudioRecorder`:
  - Use `AVAudioEngine` input node + file writer (e.g., `AVAudioFile`).
  - Record mono 16 kHz or 48 kHz PCM; document the format chosen and why.
  - Start/stop methods return a temp file URL.
  - Guard against overlapping recordings.
- [ ] Implement `HUDWindowController`:
  - Borderless, non‑activating `NSPanel`, level `.statusBar` or `.floating`.
  - Bottom‑center positioning across the active screen.
  - SwiftUI HUD view with subtle “listening” animation (pulse/breathing).
- [ ] Wire press/release flow:
  - Press → show HUD → start recording.
  - Release → stop recording → hide HUD.
  - Store the audio URL for next pipeline step.
- [ ] Preflight permissions with a user-facing UI before triggering system prompts:
  - Show a simple guidance sheet/dialog explaining why Accessibility and Microphone access are needed.
  - After user acknowledges, trigger the system permission flows.
- [ ] Add telemetry/logging around hotkey detection + recording start/stop.

## Design notes
- **Hotkey reliability**: `CGEventTap` typically requires Accessibility permission.
  - On first failure, show a one‑time dialog guiding the user to System Settings.
- **Function keys**: Support F1–F19 key codes (not the standalone `fn` modifier).
- **HUD**: follow HIG—minimal chrome, subtle animation, no focus stealing.
- **Debounce**: 100 ms delay prevents accidental starts on quick taps.

## Verification plan (human)
- On first run, if Accessibility permission is missing, app guides the user to enable it.
- Press configured hotkey: HUD appears and stays visible while pressed.
- Release hotkey: recording stops and HUD disappears immediately.
- Recorded audio file exists and has expected sample rate/format.
- Quick taps under 100 ms do not start recording.

## Agent documentation requirements
- Document the hotkey capture approach and any limitations (e.g., `fn` key).
- Include a short comment describing why the chosen audio format is used.
- Add inline comments in the HUD positioning logic (multi‑screen behavior).
