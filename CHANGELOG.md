# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-alpha.39] - 2026-01-13

### Fixed
- reduce debounce and start latency (#3)
  - decrease hotkey debounce to 10ms for responsiveness
  - reduce pre-recording delay in AppDelegate to 5ms
  - ensure event handling logic runs on main queue
  - update settings defaults to match lower latency

## [0.1.0-alpha.37] - 2026-01-12

### Added
- split update button and status
  - decouple update status display from the trigger button
  - show version availability and success states in a separate label
  - use callout font and secondary color for status information
  - simplify button states to focus on the checking action
- add permission warning banner
  - show banner in settings when permissions are missing
  - add buttons to open system mic and accessibility settings
  - provide context-specific messages for missing permissions
- open settings on tap
  - add tap gesture to HUD view
  - implement tap callback in HUD window controller
  - show settings window when HUD is tapped
- add launch hud and reopen behavior
  - show feedback HUD when application starts
  - open settings when app is reopened via Dock
  - add launched state and indicator to HUD
  - auto-hide launch HUD after two seconds

### Fixed
- reset tcc after install
  - reset Accessibility and Microphone permissions after copying the new bundle so macOS stops treating it as a different app
  - log the reset step to make investigating post-update permission issues easier

## [0.1.0-alpha.31] - 2026-01-12

### Fixed
- set pasteAfterCopy default true
  - default pasteAfterCopy to true so clipboard output is pasted automatically when enabled

## [0.1.0-alpha.29] - 2026-01-12

### Fixed
- add installer logging
  - log DMG and ZIP install steps/errors to /tmp/whisperx-update.log
  - exit when mounting/extracting fails to avoid partial installs

### Documentation
- update model descriptions
  - clarify the default model choice and turbo recommendation in the README table tip
  - document benchmark-based speed ratings for each Whisper model with inline notes
- update build instructions
  - refresh AGENTS.md to lean on make targets for building, installing, and packaging plus note docs references
  - fold README build section into collapsible block and highlight the make-driven workflow, version note, and dmg options

### Maintenance
- use latest type tag
  - query latest tag per release type before collecting commits
  - log the matched tag and use it when generating the changelog

## [0.1.0-alpha.24] - 2026-01-12

### Added
- add auto-update and release flow
  - implement UpdateService to track and install GitHub releases
  - add update settings and manual check UI to SettingsView
  - support background auto-updates and update notifications
  - add GitHub Actions workflow for automated DMG releases
  - update README with installation and security instructions
  - prepare CHANGELOG for initial v0.1.0 public release
- add recording sound feedback
  - implement SoundFeedbackService using system AIFF sounds
  - play "Tink" on recording start and "Purr" on stop
  - add 150ms delay to start flow so sound isn't muted
  - update README warning block to GitHub alert syntax
- add system audio muting for recording
  - implement SystemAudioMuter using CoreAudio APIs
  - mute default output device when recording starts
  - restore previous mute state when recording ends
  - integrate muter service into AppDelegate lifecycle
  - add logging for audio state transitions
- polish transcription flow and hud
  - implement hudFeedback state in AppState for success/error cues
  - redesign HUDView to use minimal Capsule style without text preview
  - add timer-based recentering for HUDWindowController
  - update AppDelegate to handle delayed HUD dismissal after feedback
  - simplify labels in SettingsView and add persistent error section
  - update status menu item titles and "Auto Copy" labeling
  - mark all tasks in step-5.md as completed
- add settings and status menu
  - implement hotkey, model, and audio pickers in settings
  - add status menu with auto-copy and copy-last actions
  - support paste-after-copy via accessibility events
  - wire app state to dynamic menu icon and status labels
  - add audio device monitoring and enumeration service
- implement whisperkit transcription
  - implement ModelRunner actor using WhisperKit
  - add WhisperModel metadata and variant support
  - integrate transcription into app lifecycle
  - add audio validation and cancellation support
  - add WhisperKit dependency via SPM
  - update Step 3 specification checklist
- implement recording and hotkeys
  - implement AudioRecorder using AVAudioEngine for 16kHz mono
  - implement HotkeyService using CGEventTap for push-to-talk
  - add PermissionManager for accessibility and microphone
  - add PermissionGuidanceView for user onboarding
  - update HUD with animated recording indicator
  - disable App Sandbox to allow global event monitoring
- implement app scaffolding and lifecycle
  - add AppDelegate with menu bar and window management
  - implement AppState and SettingsStore for state handling
  - add HUD and Settings UI controllers using SwiftUI
  - configure microphone privacy usage in project
  - set up service stubs for audio, hotkey, and model
  - update progress in step-1.md specs

### Fixed
- enforce beta commit count
  - add helper to extract latest alpha/beta tag counts so prereleases can be compared
  - require beta releases to have at least as many commits as the latest alpha before proceeding
- use app support models
  - document that WhisperKit models live in ~/Library/Application Support/whisperX/Models
  - pass the dedicated download base so WhisperKit saves models in Application Support
- reduce hotkey delay
  - lower default hotkey debounce to 20 ms for faster response
  - add 10 ms and 20 ms picks while dropping 150/200 ms options
- allow contents write
  - grant release workflow contents write permission so artifacts can be published
- ignore blank transcription results
  - detect empty text or [BLANK_AUDIO] tokens
  - skip clipboard operations for blank output
  - hide HUD immediately without showing feedback
  - avoid updating lastTranscription with empty strings
- prevent premature hide and improve start
  - add cancelable work items for HUD hide timers
  - reset HUD state immediately on new recording
  - show HUD on press for instant visual feedback
  - handle key release during recording start delay

### Documentation
- add changelog for v0.1.0-alpha.22
- add changelog for v0.0.0-alpha.21
- refresh readme layout
  - add badges, quick-start tips, and structured sections to clarify install requirements
  - expand models, features, and build instructions while keeping permissions and build notes highlighted
- add project documentation and metadata
  - add README.md with project overview and features
  - add AGENTS.md for AI agent guidance and architecture
  - add CLAUDE.md configuration
  - add MIT license file
- add execution protocol guide
  - add specs/ documentation outlining the linear execution workflow
  - define per-step goals, deliverables, TODOs, and human verification checks
  - describe agent requirements for doc comments, logging, and scoped work

### Maintenance
- lower macOS deployment target
- add repo boilerplate and documentation
  - add .editorconfig and .gitignore
  - include github issue and pull request templates
  - add changelog, code of conduct, and contributing docs
  - add security policy and reporting instructions

### Other
- feat/add dmg installer (#2)
  * feat(release): add dmg creation
  - install create-dmg in workflow so the packaging step can run consistently on the runner
  - replace hdiutil call with create-dmg options to configure window layout, icon positions, and app link
  * feat(dmg): add makefile and dmg tooling
  - add Makefile for building, dmg packaging, and version helpers
  - add release workflow background asset plus generation script
  * feat(updates): add release channel support
  - detect channel/dev status, persist preference, and show warnings/picker in settings
  - fetch releases by channel, compare semantic versions, and signal stable overrides
  - inject MARKETING_VERSION into builds so CI and local runs embed the right version
  * chore(release): add release guide and script
  - add interactive scripts/release.js to guide tagging, changelog updates, and pushes
  - document the release flow in docs/RELEASE_GUIDE.md and expose a make release target
- set project app name
  - set CFBundleDisplayName and CFBundleName to WhisperX
  - increment scheme order hint in user data
- Initial Commit

## [0.1.0-alpha.22] - 2026-01-12

### Added
- add auto-update and release flow
  - implement UpdateService to track and install GitHub releases
  - add update settings and manual check UI to SettingsView
  - support background auto-updates and update notifications
  - add GitHub Actions workflow for automated DMG releases
  - update README with installation and security instructions
  - prepare CHANGELOG for initial v0.1.0 public release
- add recording sound feedback
  - implement SoundFeedbackService using system AIFF sounds
  - play "Tink" on recording start and "Purr" on stop
  - add 150ms delay to start flow so sound isn't muted
  - update README warning block to GitHub alert syntax
- add system audio muting for recording
  - implement SystemAudioMuter using CoreAudio APIs
  - mute default output device when recording starts
  - restore previous mute state when recording ends
  - integrate muter service into AppDelegate lifecycle
  - add logging for audio state transitions
- polish transcription flow and hud
  - implement hudFeedback state in AppState for success/error cues
  - redesign HUDView to use minimal Capsule style without text preview
  - add timer-based recentering for HUDWindowController
  - update AppDelegate to handle delayed HUD dismissal after feedback
  - simplify labels in SettingsView and add persistent error section
  - update status menu item titles and "Auto Copy" labeling
  - mark all tasks in step-5.md as completed
- add settings and status menu
  - implement hotkey, model, and audio pickers in settings
  - add status menu with auto-copy and copy-last actions
  - support paste-after-copy via accessibility events
  - wire app state to dynamic menu icon and status labels
  - add audio device monitoring and enumeration service
- implement whisperkit transcription
  - implement ModelRunner actor using WhisperKit
  - add WhisperModel metadata and variant support
  - integrate transcription into app lifecycle
  - add audio validation and cancellation support
  - add WhisperKit dependency via SPM
  - update Step 3 specification checklist
- implement recording and hotkeys
  - implement AudioRecorder using AVAudioEngine for 16kHz mono
  - implement HotkeyService using CGEventTap for push-to-talk
  - add PermissionManager for accessibility and microphone
  - add PermissionGuidanceView for user onboarding
  - update HUD with animated recording indicator
  - disable App Sandbox to allow global event monitoring
- implement app scaffolding and lifecycle
  - add AppDelegate with menu bar and window management
  - implement AppState and SettingsStore for state handling
  - add HUD and Settings UI controllers using SwiftUI
  - configure microphone privacy usage in project
  - set up service stubs for audio, hotkey, and model
  - update progress in step-1.md specs

### Fixed
- enforce beta commit count
  - add helper to extract latest alpha/beta tag counts so prereleases can be compared
  - require beta releases to have at least as many commits as the latest alpha before proceeding
- use app support models
  - document that WhisperKit models live in ~/Library/Application Support/whisperX/Models
  - pass the dedicated download base so WhisperKit saves models in Application Support
- reduce hotkey delay
  - lower default hotkey debounce to 20 ms for faster response
  - add 10 ms and 20 ms picks while dropping 150/200 ms options
- allow contents write
  - grant release workflow contents write permission so artifacts can be published
- ignore blank transcription results
  - detect empty text or [BLANK_AUDIO] tokens
  - skip clipboard operations for blank output
  - hide HUD immediately without showing feedback
  - avoid updating lastTranscription with empty strings
- prevent premature hide and improve start
  - add cancelable work items for HUD hide timers
  - reset HUD state immediately on new recording
  - show HUD on press for instant visual feedback
  - handle key release during recording start delay

### Documentation
- add changelog for v0.0.0-alpha.21
- refresh readme layout
  - add badges, quick-start tips, and structured sections to clarify install requirements
  - expand models, features, and build instructions while keeping permissions and build notes highlighted
- add project documentation and metadata
  - add README.md with project overview and features
  - add AGENTS.md for AI agent guidance and architecture
  - add CLAUDE.md configuration
  - add MIT license file
- add execution protocol guide
  - add specs/ documentation outlining the linear execution workflow
  - define per-step goals, deliverables, TODOs, and human verification checks
  - describe agent requirements for doc comments, logging, and scoped work

### Maintenance
- add repo boilerplate and documentation
  - add .editorconfig and .gitignore
  - include github issue and pull request templates
  - add changelog, code of conduct, and contributing docs
  - add security policy and reporting instructions

### Other
- feat/add dmg installer (#2)
  * feat(release): add dmg creation
  - install create-dmg in workflow so the packaging step can run consistently on the runner
  - replace hdiutil call with create-dmg options to configure window layout, icon positions, and app link
  * feat(dmg): add makefile and dmg tooling
  - add Makefile for building, dmg packaging, and version helpers
  - add release workflow background asset plus generation script
  * feat(updates): add release channel support
  - detect channel/dev status, persist preference, and show warnings/picker in settings
  - fetch releases by channel, compare semantic versions, and signal stable overrides
  - inject MARKETING_VERSION into builds so CI and local runs embed the right version
  * chore(release): add release guide and script
  - add interactive scripts/release.js to guide tagging, changelog updates, and pushes
  - document the release flow in docs/RELEASE_GUIDE.md and expose a make release target
- set project app name
  - set CFBundleDisplayName and CFBundleName to WhisperX
  - increment scheme order hint in user data
- Initial Commit

## [0.0.0-alpha.21] - 2026-01-12

### Added
- add auto-update and release flow
  - implement UpdateService to track and install GitHub releases
  - add update settings and manual check UI to SettingsView
  - support background auto-updates and update notifications
  - add GitHub Actions workflow for automated DMG releases
  - update README with installation and security instructions
  - prepare CHANGELOG for initial v0.1.0 public release
- add recording sound feedback
  - implement SoundFeedbackService using system AIFF sounds
  - play "Tink" on recording start and "Purr" on stop
  - add 150ms delay to start flow so sound isn't muted
  - update README warning block to GitHub alert syntax
- add system audio muting for recording
  - implement SystemAudioMuter using CoreAudio APIs
  - mute default output device when recording starts
  - restore previous mute state when recording ends
  - integrate muter service into AppDelegate lifecycle
  - add logging for audio state transitions
- polish transcription flow and hud
  - implement hudFeedback state in AppState for success/error cues
  - redesign HUDView to use minimal Capsule style without text preview
  - add timer-based recentering for HUDWindowController
  - update AppDelegate to handle delayed HUD dismissal after feedback
  - simplify labels in SettingsView and add persistent error section
  - update status menu item titles and "Auto Copy" labeling
  - mark all tasks in step-5.md as completed
- add settings and status menu
  - implement hotkey, model, and audio pickers in settings
  - add status menu with auto-copy and copy-last actions
  - support paste-after-copy via accessibility events
  - wire app state to dynamic menu icon and status labels
  - add audio device monitoring and enumeration service
- implement whisperkit transcription
  - implement ModelRunner actor using WhisperKit
  - add WhisperModel metadata and variant support
  - integrate transcription into app lifecycle
  - add audio validation and cancellation support
  - add WhisperKit dependency via SPM
  - update Step 3 specification checklist
- implement recording and hotkeys
  - implement AudioRecorder using AVAudioEngine for 16kHz mono
  - implement HotkeyService using CGEventTap for push-to-talk
  - add PermissionManager for accessibility and microphone
  - add PermissionGuidanceView for user onboarding
  - update HUD with animated recording indicator
  - disable App Sandbox to allow global event monitoring
- implement app scaffolding and lifecycle
  - add AppDelegate with menu bar and window management
  - implement AppState and SettingsStore for state handling
  - add HUD and Settings UI controllers using SwiftUI
  - configure microphone privacy usage in project
  - set up service stubs for audio, hotkey, and model
  - update progress in step-1.md specs

### Fixed
- enforce beta commit count
  - add helper to extract latest alpha/beta tag counts so prereleases can be compared
  - require beta releases to have at least as many commits as the latest alpha before proceeding
- use app support models
  - document that WhisperKit models live in ~/Library/Application Support/whisperX/Models
  - pass the dedicated download base so WhisperKit saves models in Application Support
- reduce hotkey delay
  - lower default hotkey debounce to 20 ms for faster response
  - add 10 ms and 20 ms picks while dropping 150/200 ms options
- allow contents write
  - grant release workflow contents write permission so artifacts can be published
- ignore blank transcription results
  - detect empty text or [BLANK_AUDIO] tokens
  - skip clipboard operations for blank output
  - hide HUD immediately without showing feedback
  - avoid updating lastTranscription with empty strings
- prevent premature hide and improve start
  - add cancelable work items for HUD hide timers
  - reset HUD state immediately on new recording
  - show HUD on press for instant visual feedback
  - handle key release during recording start delay

### Documentation
- refresh readme layout
  - add badges, quick-start tips, and structured sections to clarify install requirements
  - expand models, features, and build instructions while keeping permissions and build notes highlighted
- add project documentation and metadata
  - add README.md with project overview and features
  - add AGENTS.md for AI agent guidance and architecture
  - add CLAUDE.md configuration
  - add MIT license file
- add execution protocol guide
  - add specs/ documentation outlining the linear execution workflow
  - define per-step goals, deliverables, TODOs, and human verification checks
  - describe agent requirements for doc comments, logging, and scoped work

### Maintenance
- add repo boilerplate and documentation
  - add .editorconfig and .gitignore
  - include github issue and pull request templates
  - add changelog, code of conduct, and contributing docs
  - add security policy and reporting instructions

### Other
- feat/add dmg installer (#2)
  * feat(release): add dmg creation
  - install create-dmg in workflow so the packaging step can run consistently on the runner
  - replace hdiutil call with create-dmg options to configure window layout, icon positions, and app link
  * feat(dmg): add makefile and dmg tooling
  - add Makefile for building, dmg packaging, and version helpers
  - add release workflow background asset plus generation script
  * feat(updates): add release channel support
  - detect channel/dev status, persist preference, and show warnings/picker in settings
  - fetch releases by channel, compare semantic versions, and signal stable overrides
  - inject MARKETING_VERSION into builds so CI and local runs embed the right version
  * chore(release): add release guide and script
  - add interactive scripts/release.js to guide tagging, changelog updates, and pushes
  - document the release flow in docs/RELEASE_GUIDE.md and expose a make release target
- set project app name
  - set CFBundleDisplayName and CFBundleName to WhisperX
  - increment scheme order hint in user data
- Initial Commit

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
