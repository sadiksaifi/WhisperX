# AGENTS.md

This file provides guidance to AI agents like you when working with code in this repository.

## Build Commands

```bash
# Build (Debug)
xcodebuild build -scheme whisperX -configuration Debug

# Build (Release)
xcodebuild build -scheme whisperX -configuration Release

# Open in Xcode (Cmd+B to build, Cmd+R to run)
open whisperX.xcodeproj

# Run Tests
xcodebuild test -scheme whisperX -destination 'platform=macOS'
```

## Test Infrastructure

Unit tests are located in the `whisperXTests/` directory. The test suite covers:

- **WhisperModelTests** - Model enum properties, ratings, codable conformance
- **SettingsStoreTests** - UserDefaults persistence, default values
- **InstallationStateTests** - Installation location detection, state properties
- **UpdateStateTests** - SemanticVersion parsing/comparison, UpdateCheckState, error handling
- **AudioRecorderTests** - Error descriptions, configuration constants
- **ModelRunnerTests** - Error descriptions, recovery suggestions
- **PermissionManagerTests** - Permission status enums, guidance flag tracking
- **AudioDeviceTests** - Device struct properties, identifiable/equatable conformance
- **ClipboardServiceTests** - Copy operations (paste requires system access)
- **HotkeyServiceTests** - Configuration, initialization, delegate handling
- **UpdateServiceTests** - State management, version comparison, asset selection

## Architecture Overview

WhisperX is a macOS menu bar app for push-to-talk transcription using WhisperKit (local Whisper models on Apple Silicon).

**Hybrid AppKit + SwiftUI Pattern:**
- `whisperXApp.swift` - SwiftUI @main entry point, delegates to AppDelegate
- `AppDelegate.swift` - Core lifecycle manager, owns all services, orchestrates recording/transcription pipeline
- SwiftUI used for views (HUD, Settings), AppKit for window management (NSPanel, NSWindow)

**Key Services (in Services/):**
- `HotkeyService` - CGEventTap global hotkey detection (runs on dedicated background thread, delegates to MainActor)
- `AudioRecorder` - AVAudioEngine recording at 16kHz mono WAV
- `ModelRunner` - Swift actor wrapping WhisperKit transcription
- `PermissionManager` - Accessibility and Microphone permission checking
- `AudioDeviceManager` - CoreAudio device enumeration with PropertyListener
- `ClipboardService` - NSPasteboard copy + CGEvent paste simulation

**State Management (in Models/):**
- `AppState` - Observable runtime state (recordingState, lastTranscription, hudFeedback)
- `SettingsStore` - UserDefaults-backed persistent preferences

**UI Layer (in UI/):**
- `HUDView` + `HUDWindowController` - Floating non-activating status indicator (NSPanel)
- `SettingsView` + `SettingsWindowController` - Settings interface
- `Components/` - Reusable pickers (hotkey, audio device, model)

## Threading Model

- **MainActor**: AppDelegate, AppState, SettingsStore, PermissionManager, AudioDeviceManager, window controllers
- **Swift Actor**: ModelRunner (async transcription)
- **Background CFRunLoop**: HotkeyService (CGEventTap requires dedicated thread)
- **AVAudioEngine internal queue**: AudioRecorder buffer processing

## Data Flow: Recording Pipeline

1. HotkeyService detects press (after debounce) → calls delegate on MainActor
2. AppDelegate starts AudioRecorder, shows HUD, sets recordingState = .recording
3. HotkeyService detects release → calls delegate
4. AppDelegate stops recording, sets recordingState = .transcribing
5. ModelRunner.transcribe() runs async (loads model on first call)
6. Result copied to clipboard (if enabled), HUD shows feedback, then hides

## Key Constraints

- **App Sandbox disabled** - Required for CGEventTap global hotkey capture
- **Hardened Runtime enabled** - Security requirement
- **Accessibility permission required** - For global hotkey monitoring
- **Microphone permission required** - For audio recording
- **macOS 26.2+ / Xcode 16.2+** - Build requirements

## Specs Directory

The `specs/` directory contains step-by-step implementation specs (step-1.md through step-5.md). Follow the execution protocol in `specs/SPECS.md` when implementing new features: one step at a time, verify before proceeding.
