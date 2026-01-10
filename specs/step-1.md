# Step 1 — Project foundation + hybrid architecture

## Goal
Establish the AppKit + SwiftUI hybrid scaffolding, project structure, and privacy/entitlements so later steps can focus on functionality without rework.

## Deliverables
- Hybrid app skeleton: `NSApplicationDelegate` owns the menu bar item, settings window, and HUD controller.
- SwiftUI views hosted in AppKit containers (Settings window + HUD view).
- Project folders/groups and base types for services (hotkey, audio, model runner, clipboard).
- Privacy strings and baseline capabilities (microphone + input monitoring/accessibility guidance).

## TODOs
- [ ] Create a clear group/folder layout (mirrors on-disk folder names):
  - `App/` (AppDelegate, lifecycle, app state)
  - `UI/` (SwiftUI views, HUD view, settings view)
  - `Services/` (HotkeyService, AudioRecorder, ModelRunner, ClipboardService)
  - `Models/` (settings models, enums for Wispr variants)
  - `Support/` (logging, helpers)
- [ ] Add `NSApplicationDelegate` entry point and wire SwiftUI app lifecycle to AppKit:
  - AppDelegate creates: `NSStatusItem`, `SettingsWindowController`, `HUDWindowController`.
  - Use `NSHostingView`/`NSHostingController` to host SwiftUI.
- [ ] Add settings storage model (UserDefaults-backed) with strongly typed keys for:
  - Hotkey selection (key code + modifiers)
  - Model variant
  - Audio device (input) preference
  - Copy-to-clipboard toggle
- [ ] Add privacy usage strings in `Info.plist`:
  - `NSMicrophoneUsageDescription`
- [ ] Document permission requirements in a README-like comment (or internal doc):
  - Input Monitoring / Accessibility for global hotkey capture
  - Microphone access for recording
- [ ] Add structured logging helper (thin wrapper around `Logger`) for consistent subsystem/category names.

## Architecture decisions (lock in now)
- **Hybrid pattern**: AppKit for lifecycle + menu bar; SwiftUI for settings + HUD content.
- **Windowing**:
  - Settings: `NSWindow` with `NSHostingView` (standard title bar).
  - HUD: borderless `NSPanel` anchored to bottom center, `non-activating` window level.
- **Services** are `@MainActor` only when UI-facing; audio + model run in background queues/Tasks.
- **Single source of truth**: `AppState` or `SettingsStore` as an `ObservableObject` injected into views.

## Non-goals for this step
- No hotkey capture or audio recording yet.
- No model integration.
- No UI polish beyond layout scaffolding.

## Verification plan (human)
- Build and run; app launches with menu bar icon and a Settings window opens.
- Settings window shows placeholder text and is hosted by SwiftUI.
- No permissions prompts yet, but `Info.plist` contains `NSMicrophoneUsageDescription`.
- Project folder structure is present on disk and matches Xcode groups.

## Agent documentation requirements
- Any new type or non-trivial function must include a concise doc comment describing purpose + lifecycle expectations.
- Each service should include a short header comment explaining thread/actor usage.
- Avoid redundant comments; prefer small, precise comments only where control flow is complex.
