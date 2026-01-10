import AppKit
import SwiftUI
import os

/// Controller for the floating HUD panel.
/// The panel is borderless, non-activating, and anchored to the bottom center of the screen.
@MainActor
final class HUDWindowController: NSWindowController {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false

        super.init(window: panel)

        let hostingView = NSHostingView(rootView: HUDView(appState: appState))
        panel.contentView = hostingView

        positionAtBottomCenter()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows the HUD panel.
    func showHUD() {
        positionAtBottomCenter()
        window?.orderFront(nil)
        Logger.ui.debug("HUD shown")
    }

    /// Hides the HUD panel.
    func hideHUD() {
        window?.orderOut(nil)
        Logger.ui.debug("HUD hidden")
    }

    private func positionAtBottomCenter() {
        guard let window = window, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + 80

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
