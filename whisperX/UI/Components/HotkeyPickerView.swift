import AppKit
import SwiftUI

/// A control for capturing and displaying a hotkey configuration.
///
/// When clicked, enters capture mode and records the next keypress.
/// Validates against unsupported keys (Globe/Fn) and allows modifier keys
/// as standalone triggers.
///
/// ## Limitations
/// - Globe/Fn key (keyCodes 63, 179) cannot be used - does not support hold behavior on Apple Silicon
/// - Escape cancels capture mode without changing the hotkey
struct HotkeyPickerView: View {
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt

    @State private var isCapturing = false
    @State private var errorMessage: String?
    @State private var eventMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Push-to-talk key:")

                Spacer()

                Button {
                    startCapture()
                } label: {
                    Text(isCapturing ? "Press a key..." : displayName)
                        .foregroundStyle(isCapturing ? .secondary : .primary)
                        .frame(minWidth: 120)
                }
                .buttonStyle(.bordered)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onDisappear {
            stopCapture()
        }
    }

    /// Human-readable display name for the current hotkey.
    private var displayName: String {
        keyCodeToDisplayName(keyCode: keyCode, modifiers: modifiers)
    }

    // MARK: - Capture Logic

    private func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        errorMessage = nil

        // Use local event monitor to capture key events while settings window is focused
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            handleKeyEvent(event)
            return nil // Consume the event
        }
    }

    private func stopCapture() {
        isCapturing = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Escape cancels capture
        if event.keyCode == 53 { // Escape
            stopCapture()
            return
        }

        // Handle modifier key press (flagsChanged event)
        if event.type == .flagsChanged {
            // Only accept if this is a modifier key being pressed (not released)
            let modifierKeyCode = event.keyCode

            // Check if this modifier is now active
            if isModifierKeyPressed(keyCode: modifierKeyCode, flags: event.modifierFlags) {
                if validateAndSetHotkey(keyCode: modifierKeyCode, modifiers: 0) {
                    stopCapture()
                }
            }
            return
        }

        // Handle regular key press
        let newKeyCode = event.keyCode
        let newModifiers = event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue

        if validateAndSetHotkey(keyCode: UInt16(newKeyCode), modifiers: UInt(newModifiers)) {
            stopCapture()
        }
    }

    /// Checks if a modifier key is currently pressed based on flags.
    private func isModifierKeyPressed(keyCode: UInt16, flags: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case 54, 55: // Right/Left Command
            return flags.contains(.command)
        case 56, 60: // Left/Right Shift
            return flags.contains(.shift)
        case 58, 61: // Left/Right Option
            return flags.contains(.option)
        case 59, 62: // Left/Right Control
            return flags.contains(.control)
        default:
            return false
        }
    }

    /// Validates the hotkey and sets it if valid.
    /// - Returns: `true` if the hotkey was set, `false` if invalid.
    private func validateAndSetHotkey(keyCode newKeyCode: UInt16, modifiers newModifiers: UInt) -> Bool {
        // Reject Globe/Fn key - does not support hold behavior on Apple Silicon
        if newKeyCode == 63 || newKeyCode == 179 {
            errorMessage = "Globe/Fn key cannot be used - it doesn't support hold behavior"
            return false
        }

        // Reject Caps Lock (57) - toggling behavior is confusing for push-to-talk
        if newKeyCode == 57 {
            errorMessage = "Caps Lock cannot be used as a hotkey"
            return false
        }

        // Accept the hotkey
        keyCode = newKeyCode
        modifiers = newModifiers
        errorMessage = nil
        return true
    }

    // MARK: - Display Helpers

    /// Converts a key code and modifiers to a human-readable string.
    private func keyCodeToDisplayName(keyCode: UInt16, modifiers: UInt) -> String {
        var parts: [String] = []

        // Add modifier symbols
        let modFlags = NSEvent.ModifierFlags(rawValue: modifiers)
        if modFlags.contains(.control) { parts.append("⌃") }
        if modFlags.contains(.option) { parts.append("⌥") }
        if modFlags.contains(.shift) { parts.append("⇧") }
        if modFlags.contains(.command) { parts.append("⌘") }

        // Add key name
        let keyName = keyCodeToName(keyCode)
        parts.append(keyName)

        return parts.joined()
    }

    /// Converts a key code to its name.
    private func keyCodeToName(_ keyCode: UInt16) -> String {
        switch keyCode {
        // Modifier keys (when used as standalone triggers)
        case 54: return "Right ⌘"
        case 55: return "Left ⌘"
        case 56: return "Left ⇧"
        case 60: return "Right ⇧"
        case 58: return "Left ⌥"
        case 61: return "Right ⌥"
        case 59: return "Left ⌃"
        case 62: return "Right ⌃"

        // Function keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 105: return "F13"
        case 107: return "F14"
        case 113: return "F15"
        case 106: return "F16"
        case 64: return "F17"
        case 79: return "F18"
        case 80: return "F19"

        // Special keys
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 117: return "Forward Delete"
        case 53: return "Escape"

        // Arrow keys
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"

        // Letter keys
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"

        // Number keys
        case 29: return "0"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"

        default:
            return "Key \(keyCode)"
        }
    }
}

#Preview {
    HotkeyPickerView(
        keyCode: .constant(61),
        modifiers: .constant(0)
    )
    .padding()
    .frame(width: 400)
}
