import Foundation
import SwiftUI

/// Central storage for user preferences, persisted via UserDefaults.
/// Thread-safe for UI access; all properties trigger view updates via @Observable.
@Observable
@MainActor
final class SettingsStore {
    // MARK: - Keys

    private enum Keys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hotkeyDebounceMs = "hotkeyDebounceMs"
        static let modelVariant = "modelVariant"
        static let audioDeviceID = "audioDeviceID"
        static let copyToClipboard = "copyToClipboard"
        static let pasteAfterCopy = "pasteAfterCopy"
        static let checkUpdatesOnLaunch = "checkUpdatesOnLaunch"
        static let autoUpdateEnabled = "autoUpdateEnabled"
    }

    // MARK: - Defaults

    /// Default hotkey: Right Option key (keyCode 61).
    static let defaultHotkeyKeyCode: UInt16 = 61
    static let defaultHotkeyModifiers: UInt = 0
    static let defaultDebounceMs: Int = 100

    // MARK: - Properties

    /// Virtual key code for the push-to-talk hotkey (e.g., kVK_Space = 49).
    var hotkeyKeyCode: UInt16 {
        didSet { defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode) }
    }

    /// Modifier flags for the hotkey (e.g., NSEvent.ModifierFlags.control.rawValue).
    var hotkeyModifiers: UInt {
        didSet { defaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
    }

    /// Debounce interval in milliseconds before recording starts (default 100ms).
    /// Prevents accidental starts from quick taps.
    var hotkeyDebounceMs: Int {
        didSet { defaults.set(hotkeyDebounceMs, forKey: Keys.hotkeyDebounceMs) }
    }

    /// Selected Whisper model variant.
    var modelVariant: WhisperModel {
        didSet { defaults.set(modelVariant.rawValue, forKey: Keys.modelVariant) }
    }

    /// Preferred audio input device identifier, or nil for system default.
    var audioDeviceID: String? {
        didSet { defaults.set(audioDeviceID, forKey: Keys.audioDeviceID) }
    }

    /// Whether to automatically copy transcribed text to the clipboard.
    var copyToClipboard: Bool {
        didSet { defaults.set(copyToClipboard, forKey: Keys.copyToClipboard) }
    }

    /// Whether to automatically paste after copying to clipboard.
    /// Requires `copyToClipboard` to be enabled.
    var pasteAfterCopy: Bool {
        didSet { defaults.set(pasteAfterCopy, forKey: Keys.pasteAfterCopy) }
    }

    /// Whether to check for updates when the app launches.
    var checkUpdatesOnLaunch: Bool {
        didSet { defaults.set(checkUpdatesOnLaunch, forKey: Keys.checkUpdatesOnLaunch) }
    }

    /// Whether to automatically download and install updates without confirmation.
    var autoUpdateEnabled: Bool {
        didSet { defaults.set(autoUpdateEnabled, forKey: Keys.autoUpdateEnabled) }
    }

    // MARK: - Private

    private let defaults: UserDefaults

    // MARK: - Initialization

    /// Creates a settings store backed by the specified UserDefaults suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load persisted values with sensible defaults
        let storedKeyCode = defaults.integer(forKey: Keys.hotkeyKeyCode)
        self.hotkeyKeyCode = storedKeyCode > 0 ? UInt16(storedKeyCode) : Self.defaultHotkeyKeyCode
        self.hotkeyModifiers = UInt(defaults.integer(forKey: Keys.hotkeyModifiers))

        let storedDebounce = defaults.integer(forKey: Keys.hotkeyDebounceMs)
        self.hotkeyDebounceMs = storedDebounce > 0 ? storedDebounce : Self.defaultDebounceMs

        if let variantRaw = defaults.string(forKey: Keys.modelVariant),
           let variant = WhisperModel(rawValue: variantRaw) {
            self.modelVariant = variant
        } else {
            self.modelVariant = .base
        }

        self.audioDeviceID = defaults.string(forKey: Keys.audioDeviceID)
        self.copyToClipboard = defaults.object(forKey: Keys.copyToClipboard) as? Bool ?? true
        self.pasteAfterCopy = defaults.object(forKey: Keys.pasteAfterCopy) as? Bool ?? false
        self.checkUpdatesOnLaunch = defaults.object(forKey: Keys.checkUpdatesOnLaunch) as? Bool ?? true
        self.autoUpdateEnabled = defaults.object(forKey: Keys.autoUpdateEnabled) as? Bool ?? false
    }
}
