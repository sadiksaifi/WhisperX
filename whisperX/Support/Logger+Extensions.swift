import Foundation
import os

/// Logging extensions for consistent subsystem and category naming across the app.
///
/// All logger instances are nonisolated to allow logging from any actor or thread.
extension Logger {
    private nonisolated static let subsystem = Bundle.main.bundleIdentifier ?? "com.sadiksaifi.whisperX"

    /// General app lifecycle and coordination logging.
    nonisolated static let app = Logger(subsystem: subsystem, category: "app")

    /// Audio recording and device management.
    nonisolated static let audio = Logger(subsystem: subsystem, category: "audio")

    /// Whisper model loading and inference.
    nonisolated static let model = Logger(subsystem: subsystem, category: "model")

    /// Hotkey detection and handling.
    nonisolated static let hotkey = Logger(subsystem: subsystem, category: "hotkey")

    /// Clipboard operations.
    nonisolated static let clipboard = Logger(subsystem: subsystem, category: "clipboard")

    /// UI and window management.
    nonisolated static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Update checking and installation.
    nonisolated static let update = Logger(subsystem: subsystem, category: "update")
}
