import Foundation
import os

/// Logging extensions for consistent subsystem and category naming across the app.
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sadiksaifi.whisperX"

    /// General app lifecycle and coordination logging.
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Audio recording and device management.
    static let audio = Logger(subsystem: subsystem, category: "audio")

    /// Whisper model loading and inference.
    static let model = Logger(subsystem: subsystem, category: "model")

    /// Hotkey detection and handling.
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")

    /// Clipboard operations.
    static let clipboard = Logger(subsystem: subsystem, category: "clipboard")

    /// UI and window management.
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
