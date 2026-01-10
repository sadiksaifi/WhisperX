import Foundation

/// Available Whisper model variants ordered by size/capability.
/// Larger models are more accurate but slower and require more memory.
enum WhisperModel: String, CaseIterable, Codable {
    case tiny
    case base
    case small
    case medium
    case large

    /// Human-readable display name for the model.
    var displayName: String {
        rawValue.capitalized
    }
}
