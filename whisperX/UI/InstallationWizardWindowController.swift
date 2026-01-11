import AppKit
import SwiftUI
import os

/// Controller for the installation wizard window.
/// Presents a centered, titled window for guiding users through installation.
@MainActor
final class InstallationWizardWindowController: NSWindowController, NSWindowDelegate {

    private var continuation: CheckedContinuation<InstallationResult, Never>?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )

        window.title = "Install WhisperX"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows the wizard and waits for user decision.
    func showWizard() async -> InstallationResult {
        let location = InstallationLocation.detect()

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            let wizardView = InstallationWizardView(
                location: location,
                onMoveToApplications: { [weak self] in
                    self?.handleMoveToApplications()
                },
                onOpenDownloads: {
                    InstallationService.openDownloadsFolder()
                },
                onOpenApplications: {
                    InstallationService.openApplicationsFolder()
                },
                onLater: { [weak self] in
                    self?.handleLater()
                }
            )

            let hostingView = NSHostingView(rootView: wizardView)
            window?.contentView = hostingView
            window?.center()

            // Show window and bring to front
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - Actions

    private func handleMoveToApplications() {
        // Resume continuation - app will relaunch so we mark as moved
        continuation?.resume(returning: .moved)
        continuation = nil
        window?.close()
    }

    private func handleLater() {
        continuation?.resume(returning: .later)
        continuation = nil
        window?.close()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // If window is closed without explicit action, treat as "run from current"
        if continuation != nil {
            continuation?.resume(returning: .runFromCurrent)
            continuation = nil
        }

        // Return to accessory mode
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }

        Logger.ui.debug("Installation wizard closed")
    }
}
