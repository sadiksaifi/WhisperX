# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-11

### Added
- Auto-update mechanism with GitHub releases integration
- Check for updates on launch (configurable in Settings)
- Manual update check button in Settings
- Auto-update option for silent background updates
- Auto-mute system audio during recording to prevent background audio contamination
- Audio feedback sounds (Tink/Purr) for recording start/stop
- Blank audio detection - skip copy/paste when no speech detected

### Fixed
- HUD state machine race condition when rapidly starting new recordings
- Empty HUD pill flash when quickly pressing hotkey

### Changed
- App display name corrected to "WhisperX" in Dock and menu bar
- Initial public release (previously 1.0.0 was internal only)

## [1.0.0] - 2024-01-10 [Internal]

### Added
- Initial release
- Push-to-talk transcription using WhisperKit
- Global hotkey support with configurable key binding
- Multiple Whisper model variants (tiny, base, small, medium, large)
- Auto-copy transcription to clipboard
- Auto-paste after copy option
- Floating HUD overlay showing recording/transcription status
- Audio input device selection
- Menu bar app with quick settings access
- Accessibility and microphone permission handling
