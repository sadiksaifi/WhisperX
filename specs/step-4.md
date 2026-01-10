# Step 4 — Settings UI + menu bar controls

## Goal
Expose configuration (hotkey, model, input device, clipboard behavior) and provide the menu bar UX that feels native to macOS.

## Deliverables
- SwiftUI Settings window (HIG‑aligned form layout).
- Menu bar icon with a small menu (Settings + basic options).
- Hotkey picker UI and model variant picker UI.

## TODOs
- [ ] Build Settings view in SwiftUI:
  - Section: Hotkey (custom key capture field + reset button).
  - Include debounce setting (default 100 ms) once wired.
  - Section: Model (variant picker + short descriptor table).
  - Section: Audio (input device picker, optional level meter).
  - Section: Output (auto‑copy toggle, optional paste‑after‑transcribe toggle).
- [ ] Implement a hotkey picker component:
  - Capture next keypress while focused.
  - Validate against unsupported keys.
  - Store as `CGKeyCode` + modifiers.
- [ ] Add `NSStatusItem` menu:
  - Status row (e.g., “Idle / Listening / Transcribing”).
  - “Settings…”
  - “Copy last transcript”
  - “Quit”
- [ ] Wire menu actions to `AppState`:
  - Update status label based on audio/transcription state.
  - Allow manual copy of last transcript.
- [ ] Add small “basic options” inline menu toggles (e.g., Auto‑copy).

## Design notes (HIG‑aligned)
- Use a standard `Form` with grouped sections and clear labels.
- Keep window size modest; avoid custom chrome.
- Menu bar icon should be monochrome template image.

## Verification plan (human)
- Menu bar icon appears; menu items behave correctly.
- Settings window opens via menu item and displays correct current values.
- Hotkey picker captures keys and updates behavior immediately.
- Changing model variant updates the chosen model in settings.

## Agent documentation requirements
- Document the hotkey picker UX and limitations.
- Provide brief comments for each settings section explaining purpose.
