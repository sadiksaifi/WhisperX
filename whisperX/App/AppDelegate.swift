import AppKit
import SwiftUI
import os

/// Main application delegate managing the menu bar, windows, and app lifecycle.
///
/// Owns all window controllers and handles activation policy switching
/// between accessory mode (menu bar only) and regular mode (with dock icon).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var settingsWindowController: SettingsWindowController!
    private var hudWindowController: HUDWindowController!

    private let settings = SettingsStore()
    private let appState = AppState()

    // MARK: - Services

    private var hotkeyService: HotkeyService!
    private var audioRecorder: AudioRecorder!
    private let permissionManager = PermissionManager()
    private let modelRunner = ModelRunner()
    private let audioDeviceManager = AudioDeviceManager()
    private let systemAudioMuter = SystemAudioMuter()
    private let soundFeedback = SoundFeedbackService()

    // MARK: - Menu Items

    private var statusMenuItem: NSMenuItem!
    private var copyLastMenuItem: NSMenuItem!
    private var autoCopyMenuItem: NSMenuItem!

    /// Window controller for permission guidance dialogs.
    private var permissionWindowController: NSWindowController?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.app.info("WhisperX launching")

        setupServices()
        setupStatusItem()
        setupWindowControllers()

        // Start in accessory mode (no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Check and request permissions
        Task {
            await checkPermissions()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.app.info("WhisperX terminating")

        // Clean up services
        hotkeyService?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when windows close; we're a menu bar app
        false
    }

    // MARK: - Setup

    private func setupServices() {
        audioRecorder = AudioRecorder()

        // Configure hotkey from settings
        hotkeyService = HotkeyService(
            delegate: self,
            keyCode: CGKeyCode(settings.hotkeyKeyCode),
            modifiers: settings.hotkeyModifiers,
            debounceInterval: TimeInterval(settings.hotkeyDebounceMs) / 1000.0
        )

        Logger.app.debug("Services initialized")
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "WhisperX")
            button.image?.isTemplate = true // Ensure monochrome template
        }

        let menu = NSMenu()

        // Status row (non-interactive)
        statusMenuItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        // Auto-copy toggle
        autoCopyMenuItem = NSMenuItem(
            title: "Auto Copy",
            action: #selector(toggleAutoCopy),
            keyEquivalent: ""
        )
        autoCopyMenuItem.state = settings.copyToClipboard ? .on : .off
        menu.addItem(autoCopyMenuItem)

        menu.addItem(.separator())

        // Copy last transcript
        copyLastMenuItem = NSMenuItem(
            title: "Copy Last Transcript",
            action: #selector(copyLastTranscript),
            keyEquivalent: "c"
        )
        copyLastMenuItem.keyEquivalentModifierMask = [.command, .shift]
        copyLastMenuItem.isEnabled = false // Initially disabled
        menu.addItem(copyLastMenuItem)

        // Settings
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))

        menu.addItem(.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit WhisperX", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu

        Logger.app.debug("Status item configured with expanded menu")
    }

    private func setupWindowControllers() {
        settingsWindowController = SettingsWindowController(
            settings: settings,
            appState: appState,
            permissionManager: permissionManager,
            audioDeviceManager: audioDeviceManager
        )
        settingsWindowController.onVisibilityChanged = { [weak self] visible in
            self?.handleSettingsVisibilityChanged(visible)
        }

        hudWindowController = HUDWindowController(appState: appState)

        Logger.app.debug("Window controllers initialized")
    }

    // MARK: - Permissions

    /// Checks and requests necessary permissions on app launch.
    /// Flow: Microphone first (blocking), then Accessibility (blocking with polling).
    private func checkPermissions() async {
        // Step 1: Check and request microphone permission first
        let micStatus = permissionManager.checkMicrophonePermission()
        if micStatus == .notDetermined {
            Logger.app.info("Requesting microphone permission")
            await requestMicrophonePermission()
        } else if micStatus == .denied {
            Logger.audio.warning("Microphone permission denied - show in settings")
        }

        // Step 2: Check accessibility permission (after microphone is handled)
        if !permissionManager.checkAccessibilityPermission() {
            Logger.app.info("Accessibility permission not granted")
            await requestAccessibilityPermission()
        }

        // Step 3: Start hotkey service if accessibility is now granted
        if permissionManager.checkAccessibilityPermission() {
            startHotkeyService()
        } else {
            Logger.hotkey.warning("Hotkey service not started - accessibility permission denied")
        }
    }

    /// Requests microphone permission with a guidance dialog.
    @MainActor
    private func requestMicrophonePermission() async {
        // Show guidance dialog
        let shouldProceed = await showPermissionGuidance(for: .microphone)

        if shouldProceed {
            // Request the actual permission (this shows system dialog)
            let granted = await permissionManager.requestMicrophonePermission()
            Logger.audio.info("Microphone permission granted: \(granted)")
        }
    }

    /// Requests accessibility permission with a guidance dialog and polls until granted.
    @MainActor
    private func requestAccessibilityPermission() async {
        // Show guidance dialog
        let shouldProceed = await showPermissionGuidance(for: .accessibility)

        if shouldProceed {
            // Trigger the system prompt
            permissionManager.openAccessibilitySettings()

            // Poll until permission is granted or user gives up (30 second timeout)
            await pollForAccessibilityPermission(timeout: 30)
        }
    }

    /// Polls for accessibility permission until granted or timeout.
    @MainActor
    private func pollForAccessibilityPermission(timeout: TimeInterval) async {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            try? await Task.sleep(for: .seconds(1))

            if permissionManager.checkAccessibilityPermission() {
                Logger.app.info("Accessibility permission granted")
                return
            }
        }

        Logger.app.warning("Accessibility permission polling timed out")
    }

    /// Shows a guidance dialog for the specified permission type.
    /// Returns true if user clicked "Continue", false if cancelled.
    @MainActor
    private func showPermissionGuidance(for type: PermissionType) async -> Bool {
        return await withCheckedContinuation { continuation in
            let guidanceView = PermissionGuidanceView(
                permissionType: type,
                onContinue: { [weak self] in
                    self?.permissionWindowController?.close()
                    self?.permissionWindowController = nil
                    self?.returnToAccessoryMode()
                    continuation.resume(returning: true)
                },
                onCancel: { [weak self] in
                    self?.permissionWindowController?.close()
                    self?.permissionWindowController = nil
                    self?.returnToAccessoryMode()
                    continuation.resume(returning: false)
                }
            )

            let hostingView = NSHostingView(rootView: guidanceView)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 260),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: true
            )
            window.contentView = hostingView
            window.title = "Permission Required"
            window.center()

            permissionWindowController = NSWindowController(window: window)
            permissionWindowController?.showWindow(nil)

            // Bring to front
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Returns to accessory mode (menu bar only).
    private func returnToAccessoryMode() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// Attempts to start the hotkey service.
    private func startHotkeyService() {
        let started = hotkeyService.start()
        if started {
            Logger.hotkey.info("Hotkey service started successfully")
        } else {
            Logger.hotkey.error("Failed to start hotkey service")
            appState.errorMessage = "Could not start hotkey listener. Please grant Accessibility permission."
        }
    }

    /// Applies current hotkey settings to the hotkey service.
    /// Called when settings window closes to pick up any changes.
    private func applyHotkeySettings() {
        hotkeyService.debounceInterval = TimeInterval(settings.hotkeyDebounceMs) / 1000.0
        hotkeyService.updateHotkey(
            keyCode: CGKeyCode(settings.hotkeyKeyCode),
            modifiers: settings.hotkeyModifiers
        )
        Logger.hotkey.debug("Applied hotkey settings: keyCode=\(self.settings.hotkeyKeyCode), debounce=\(self.settings.hotkeyDebounceMs)ms")
    }

    // MARK: - Actions

    @objc private func showSettings() {
        // Switch to regular app mode so dock icon and menu bar appear
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindowController.showSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func toggleAutoCopy() {
        settings.copyToClipboard.toggle()
        autoCopyMenuItem.state = settings.copyToClipboard ? .on : .off
        Logger.app.debug("Auto-copy toggled: \(self.settings.copyToClipboard)")
    }

    @objc private func copyLastTranscript() {
        guard let text = appState.lastTranscription else {
            Logger.clipboard.debug("No transcript to copy")
            return
        }
        ClipboardService.shared.copy(text)
    }

    // MARK: - Menu State

    /// Updates the status menu item based on current state.
    private func updateStatusMenuItem() {
        switch appState.recordingState {
        case .idle:
            statusMenuItem.title = "Ready"
            statusItem.button?.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "WhisperX")
        case .recording:
            statusMenuItem.title = "Recording..."
            statusItem.button?.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Recording")
        case .transcribing:
            statusMenuItem.title = "Transcribing..."
            statusItem.button?.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Transcribing")
        }
        statusItem.button?.image?.isTemplate = true

        // Enable copy menu item if we have a transcript
        copyLastMenuItem.isEnabled = appState.lastTranscription != nil
    }

    // MARK: - Window Management

    private func handleSettingsVisibilityChanged(_ visible: Bool) {
        if visible {
            // Already in regular mode from showSettings
        } else {
            // Settings closed, apply any changes and return to accessory mode
            applyHotkeySettings()

            // Sync auto-copy menu state with settings
            autoCopyMenuItem.state = settings.copyToClipboard ? .on : .off

            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    // MARK: - HUD Control

    /// Shows the HUD overlay. Called when recording starts.
    func showHUD() {
        hudWindowController.showHUD()
    }

    /// Hides the HUD overlay. Called when recording ends.
    func hideHUD() {
        hudWindowController.hideHUD()
    }

    // MARK: - Transcription

    /// Starts transcription of the recorded audio.
    private func startTranscription(audioURL: URL) {
        appState.recordingState = .transcribing
        updateStatusMenuItem()

        Task {
            do {
                let selectedModel = settings.modelVariant
                Logger.model.info("Transcribing with model: \(selectedModel.displayName)")

                appState.isModelLoading = await modelRunner.isLoading

                let transcription = try await modelRunner.transcribe(
                    audioURL: audioURL,
                    model: selectedModel
                )

                await MainActor.run {
                    appState.lastTranscription = transcription
                    appState.recordingState = .idle
                    appState.isModelLoading = false
                    updateStatusMenuItem()

                    Logger.model.info("Transcription result: \(transcription.prefix(100))...")

                    // Auto-copy to clipboard if enabled
                    if settings.copyToClipboard {
                        ClipboardService.shared.copy(transcription)
                        appState.showCopiedFeedback()

                        // Delay hiding HUD to show "Copied" feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                            self?.hideHUD()
                        }

                        // Paste after copy if enabled
                        if settings.pasteAfterCopy {
                            // Small delay to ensure clipboard is ready
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                ClipboardService.shared.paste()
                            }
                        }
                    } else {
                        hideHUD()
                    }

                    // Clean up temp audio file
                    try? FileManager.default.removeItem(at: audioURL)
                }

            } catch let error as ModelRunnerError {
                await MainActor.run {
                    if case .transcriptionCancelled = error {
                        // Cancelled transcriptions don't show error
                        Logger.model.info("Transcription was cancelled")
                        hideHUD()
                    } else {
                        appState.errorMessage = error.localizedDescription
                        appState.showErrorFeedback()
                        Logger.model.error("Transcription error: \(error.localizedDescription)")

                        // Delay hiding HUD to show "Error" feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                            self?.hideHUD()
                        }
                    }
                    appState.recordingState = .idle
                    appState.isModelLoading = false
                    updateStatusMenuItem()
                }
            } catch {
                await MainActor.run {
                    appState.errorMessage = "Transcription failed: \(error.localizedDescription)"
                    appState.showErrorFeedback()
                    appState.recordingState = .idle
                    appState.isModelLoading = false
                    updateStatusMenuItem()
                    Logger.model.error("Unexpected transcription error: \(error)")

                    // Delay hiding HUD to show "Error" feedback
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        self?.hideHUD()
                    }
                }
            }
        }
    }
}

// MARK: - HotkeyServiceDelegate

extension AppDelegate: HotkeyServiceDelegate {
    func hotkeyDidPress() {
        Logger.hotkey.info("Hotkey pressed - starting recording")

        // Cancel any in-progress transcription
        Task {
            await modelRunner.cancelCurrentTranscription()
        }

        // Play feedback sound first, then delay slightly before muting
        // so the sound has time to play
        soundFeedback.playStartSound()

        // Small delay to let the sound play before muting system audio
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }

            // Mute system audio to prevent background audio from being recorded
            self.systemAudioMuter.muteSystemAudio()

            self.appState.recordingState = .recording
            self.appState.lastTranscription = nil  // Clear previous result
            self.showHUD()
            self.updateStatusMenuItem()

            do {
                let url = try self.audioRecorder.startRecording()
                self.appState.lastRecordingURL = url
                Logger.audio.info("Recording started: \(url.lastPathComponent)")
            } catch {
                Logger.audio.error("Failed to start recording: \(error)")
                self.appState.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                self.appState.showErrorFeedback()
                self.appState.recordingState = .idle
                self.updateStatusMenuItem()

                // Restore system audio on error
                self.systemAudioMuter.restoreSystemAudio()

                // Delay hiding HUD to show "Error" feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    self?.hideHUD()
                }
            }
        }
    }

    func hotkeyDidRelease() {
        Logger.hotkey.info("Hotkey released - stopping recording")

        guard appState.recordingState == .recording else {
            Logger.hotkey.debug("Not recording, ignoring release")
            return
        }

        // Restore system audio now that recording is done
        systemAudioMuter.restoreSystemAudio()

        // Play feedback sound after restoring audio so user hears it
        soundFeedback.playStopSound()

        do {
            let url = try audioRecorder.stopRecording()
            appState.lastRecordingURL = url
            Logger.audio.info("Recording stopped: \(url.lastPathComponent)")

            // Log file info for verification
            logRecordingInfo(url)

            // Start transcription pipeline
            startTranscription(audioURL: url)

        } catch {
            Logger.audio.error("Failed to stop recording: \(error)")
            appState.errorMessage = "Failed to stop recording: \(error.localizedDescription)"
            appState.showErrorFeedback()
            appState.recordingState = .idle
            updateStatusMenuItem()

            // Delay hiding HUD to show "Error" feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.hideHUD()
            }
        }
    }

    /// Logs information about the completed recording for verification.
    private func logRecordingInfo(_ url: URL) {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attrs[.size] as? Int64 {
                let sizeKB = Double(size) / 1024.0
                let duration = Double(size) / (16000.0 * 4.0) // 16kHz, Float32 (4 bytes)
                Logger.audio.info("Recording: \(String(format: "%.1f", sizeKB)) KB, ~\(String(format: "%.1f", duration))s")
            }
        } catch {
            Logger.audio.debug("Could not read recording attributes: \(error)")
        }
    }
}
