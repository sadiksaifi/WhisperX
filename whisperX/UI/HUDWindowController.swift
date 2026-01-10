import AppKit
import SwiftUI
import Combine
import os

/// Controller for the floating HUD panel.
/// The panel is borderless, non-activating, and anchored to the bottom center of the screen.
@MainActor
final class HUDWindowController: NSWindowController {
    private let appState: AppState
    private var stateObservation: AnyCancellable?

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
        observeStateChanges()
    }

    /// Observe state changes to recenter HUD when content size changes.
    private func observeStateChanges() {
        // Use a timer to periodically check and recenter if visible
        // This ensures the HUD stays centered when content changes
        stateObservation = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      let window = self.window,
                      window.isVisible else { return }
                self.positionAtBottomCenter()
            }
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
        guard let window = window,
              let hostingView = window.contentView as? NSHostingView<HUDView> else { return }

        // Force layout and get intrinsic content size
        hostingView.layoutSubtreeIfNeeded()
        let contentSize = hostingView.fittingSize

        // Find the screen containing the mouse cursor for multi-monitor support.
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens.first

        guard let targetScreen = screen else {
            Logger.ui.warning("No screen available for HUD positioning")
            return
        }

        let screenFrame = targetScreen.frame
        let visibleFrame = targetScreen.visibleFrame

        // Calculate position: center of HUD aligns with center of screen
        let hudWidth = contentSize.width
        let hudHeight = contentSize.height
        let screenCenterX = screenFrame.origin.x + screenFrame.width / 2
        let x = screenCenterX - hudWidth / 2
        let y = visibleFrame.minY + 40

        // Set frame with exact size and position
        // SwiftUI handles content animation, we just keep the window centered
        let hudFrame = NSRect(x: x, y: y, width: hudWidth, height: hudHeight)
        window.setFrame(hudFrame, display: false)
    }
}
