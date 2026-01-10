# Step 4 — Settings UI + menu bar controls

## Goal
Expose configuration (hotkey, model, input device, clipboard behavior) and provide the menu bar UX that feels native to macOS.

## Deliverables
- SwiftUI Settings window (HIG‑aligned form layout).
- Menu bar icon with a small menu (Settings + basic options).
- Hotkey picker UI and model variant picker UI.

## TODOs
- [x] Build Settings view in SwiftUI:
  - Section: Hotkey (custom key capture field + reset button).
  - Include debounce setting (default 100 ms) once wired.
  - Section: Model (variant picker + short descriptor table).
  - Section: Audio (input device picker, optional level meter).
  - Section: Output (auto‑copy toggle, optional paste‑after‑transcribe toggle).
- [x] Implement a hotkey picker component:
  - Capture next keypress while focused.
  - Validate against unsupported keys.
  - Store as `CGKeyCode` + modifiers.
- [x] Add `NSStatusItem` menu:
  - Status row (e.g., "Idle / Listening / Transcribing").
  - "Settings…"
  - "Copy last transcript"
  - "Quit"
- [x] Wire menu actions to `AppState`:
  - Update status label based on audio/transcription state.
  - Allow manual copy of last transcript.
- [x] Add small "basic options" inline menu toggles (e.g., Auto‑copy).

## Design notes (HIG‑aligned)
- Use a standard `Form` with grouped sections and clear labels.
- Keep window size modest; avoid custom chrome.
- Menu bar icon should be monochrome template image.

## Verification plan (human)
- [x] Menu bar icon appears; menu items behave correctly.
- [x] Settings window opens via menu item and displays correct current values.
- [x] Hotkey picker captures keys and updates behavior immediately.
- [x] Changing model variant updates the chosen model in settings.

## Agent documentation requirements
- [x] Document the hotkey picker UX and limitations (see HotkeyPickerView.swift header comment).
- [x] Provide brief comments for each settings section explaining purpose (see SettingsView.swift section comments).
