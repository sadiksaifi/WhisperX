import AppKit
import os

// MARK: - ClipboardService

/// Copies transcribed text to the system clipboard.
///
/// Threading: All operations are synchronous and safe to call from any thread.
/// Uses NSPasteboard on macOS.
final class ClipboardService {
    /// Shared singleton instance.
    static let shared = ClipboardService()

    private init() {}

    /// Copies the given text to the system clipboard.
    /// - Parameter text: The text to copy.
    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        Logger.clipboard.info("Copied \(text.count) characters to clipboard")
    }

    /// Simulates a Cmd+V paste action.
    ///
    /// This uses CGEvent to post keyboard events and requires Accessibility permission.
    /// Used for the "paste after copy" feature.
    func paste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 9 = V key
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            Logger.clipboard.error("Failed to create paste key events")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        Logger.clipboard.info("Simulated paste action")
    }
}
