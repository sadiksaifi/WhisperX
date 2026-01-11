import AppKit
import SwiftUI
import os

/// Controller for the Settings window.
/// Notifies a delegate when visibility changes for activation policy management.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    /// Called when the settings window visibility changes.
    var onVisibilityChanged: ((Bool) -> Void)?

    private let settings: SettingsStore
    private let appState: AppState
    private let permissionManager: PermissionManager
    private let audioDeviceManager: AudioDeviceManager

    // Update callbacks
    var updateState: UpdateCheckState = .idle
    var onCheckForUpdates: () -> Void = {}
    var onDownloadUpdate: () -> Void = {}
    var onInstallUpdate: () -> Void = {}

    // Keep reference to hosting view for updates
    private var hostingView: NSHostingView<SettingsView>?

    init(
        settings: SettingsStore,
        appState: AppState,
        permissionManager: PermissionManager,
        audioDeviceManager: AudioDeviceManager
    ) {
        self.settings = settings
        self.appState = appState
        self.permissionManager = permissionManager
        self.audioDeviceManager = audioDeviceManager

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 620),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )

        window.title = "WhisperX Settings"
        window.center()

        super.init(window: window)

        window.delegate = self

        updateHostingView()
    }

    /// Updates the hosting view with current state.
    func updateHostingView() {
        let settingsView = SettingsView(
            settings: settings,
            appState: appState,
            permissionManager: permissionManager,
            audioDeviceManager: audioDeviceManager,
            updateState: updateState,
            onCheckForUpdates: { [weak self] in self?.onCheckForUpdates() },
            onDownloadUpdate: { [weak self] in self?.onDownloadUpdate() },
            onInstallUpdate: { [weak self] in self?.onInstallUpdate() }
        )

        if let existingHostingView = hostingView {
            existingHostingView.rootView = settingsView
        } else {
            let newHostingView = NSHostingView(rootView: settingsView)
            hostingView = newHostingView
            window?.contentView = newHostingView
        }
    }

    /// Updates the displayed update state.
    func updateUpdateState(_ state: UpdateCheckState) {
        updateState = state
        updateHostingView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows the settings window and notifies the delegate.
    func showSettings() {
        // Refresh permission status when showing settings
        permissionManager.refreshAccessibilityStatus()
        permissionManager.refreshMicrophoneStatus()

        window?.center()
        window?.makeKeyAndOrderFront(nil)
        onVisibilityChanged?(true)
        Logger.ui.debug("Settings window shown")
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        onVisibilityChanged?(false)
        Logger.ui.debug("Settings window closed")
    }
}
