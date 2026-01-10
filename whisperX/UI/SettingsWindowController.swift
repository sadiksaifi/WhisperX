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
    private let permissionManager: PermissionManager
    private let audioDeviceManager: AudioDeviceManager

    init(settings: SettingsStore, permissionManager: PermissionManager, audioDeviceManager: AudioDeviceManager) {
        self.settings = settings
        self.permissionManager = permissionManager
        self.audioDeviceManager = audioDeviceManager

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )

        window.title = "WhisperX Settings"
        window.center()

        super.init(window: window)

        window.delegate = self

        let hostingView = NSHostingView(rootView: SettingsView(
            settings: settings,
            permissionManager: permissionManager,
            audioDeviceManager: audioDeviceManager
        ))
        window.contentView = hostingView
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
