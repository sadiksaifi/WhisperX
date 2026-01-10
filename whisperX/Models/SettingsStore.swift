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
        static let modelVariant = "modelVariant"
        static let audioDeviceID = "audioDeviceID"
        static let copyToClipboard = "copyToClipboard"
    }

    // MARK: - Properties

    /// Virtual key code for the push-to-talk hotkey (e.g., kVK_Space = 49).
    var hotkeyKeyCode: UInt16 {
        didSet { defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode) }
    }

    /// Modifier flags for the hotkey (e.g., NSEvent.ModifierFlags.control.rawValue).
    var hotkeyModifiers: UInt {
        didSet { defaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
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

    // MARK: - Private

    private let defaults: UserDefaults

    // MARK: - Initialization

    /// Creates a settings store backed by the specified UserDefaults suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load persisted values with sensible defaults
        self.hotkeyKeyCode = UInt16(defaults.integer(forKey: Keys.hotkeyKeyCode))
        self.hotkeyModifiers = UInt(defaults.integer(forKey: Keys.hotkeyModifiers))

        if let variantRaw = defaults.string(forKey: Keys.modelVariant),
           let variant = WhisperModel(rawValue: variantRaw) {
            self.modelVariant = variant
        } else {
            self.modelVariant = .base
        }

        self.audioDeviceID = defaults.string(forKey: Keys.audioDeviceID)
        self.copyToClipboard = defaults.object(forKey: Keys.copyToClipboard) as? Bool ?? true
    }
}
