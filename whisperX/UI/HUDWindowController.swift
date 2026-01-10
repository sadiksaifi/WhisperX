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

    /// Positions the HUD at the bottom center of the active screen.
    ///
    /// ## Multi-Screen Behavior
    /// The HUD appears on the screen where the mouse cursor is currently located.
    /// This ensures the HUD is visible on the display the user is actively using,
    /// rather than always appearing on the primary display. This is particularly
    /// important for users with multi-monitor setups where the primary display
    /// may not be the one they're currently focused on.
    ///
    /// The positioning uses `NSEvent.mouseLocation` to find the cursor location,
    /// then identifies which screen contains that point. If no screen contains
    /// the cursor (edge case), it falls back to `NSScreen.main`.
    private func positionAtBottomCenter() {
        guard let window = window else { return }

        // Find the screen containing the mouse cursor for multi-monitor support.
        // This ensures the HUD appears on the active screen where the user is likely
        // focused, rather than always appearing on the primary display.
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens.first

        guard let targetScreen = screen else {
            Logger.ui.warning("No screen available for HUD positioning")
            return
        }

        let screenFrame = targetScreen.visibleFrame
        let windowSize = window.frame.size

        // Center horizontally, position 80 points from the bottom of the visible area.
        // The visibleFrame excludes the menu bar and dock, so this positions the HUD
        // just above the dock (if present) or near the bottom edge.
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + 80

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
