import Foundation

/// Available Whisper model variants ordered by size/capability.
/// Larger models are more accurate but slower and require more memory.
///
/// Model naming follows WhisperKit conventions for Core ML models hosted
/// on HuggingFace at `argmaxinc/whisperkit-coreml`.
///
/// This enum is nonisolated to allow access from any actor context.
nonisolated enum WhisperModel: String, CaseIterable, Codable, Identifiable, Sendable {
    case tiny = "openai_whisper-tiny"
    case base = "openai_whisper-base"
    case small = "openai_whisper-small"
    case medium = "openai_whisper-medium"
    case large = "openai_whisper-large-v3"
    case largeTurbo = "openai_whisper-large-v3-turbo"

    nonisolated var id: String { rawValue }

    /// Human-readable display name for the model.
    nonisolated var displayName: String {
        switch self {
        case .tiny: return "Tiny"
        case .base: return "Base"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large v3"
        case .largeTurbo: return "Large v3 Turbo"
        }
    }

    /// WhisperKit model identifier used for downloading/loading.
    /// This matches the folder names in the argmaxinc/whisperkit-coreml repo.
    nonisolated var whisperKitModelName: String {
        rawValue
    }

    /// Approximate parameter count in millions.
    nonisolated var parameterCountMillions: Int {
        switch self {
        case .tiny: return 39
        case .base: return 74
        case .small: return 244
        case .medium: return 769
        case .large: return 1550
        case .largeTurbo: return 809
        }
    }

    /// Approximate VRAM/memory requirement in GB.
    nonisolated var memoryRequirementGB: Double {
        switch self {
        case .tiny: return 0.5
        case .base: return 0.7
        case .small: return 1.5
        case .medium: return 3.0
        case .large: return 6.0
        case .largeTurbo: return 3.5
        }
    }

    /// Recommended use case description.
    nonisolated var recommendedUseCase: String {
        switch self {
        case .tiny:
            return "Quick dictation, low-memory devices"
        case .base:
            return "General use, good speed/accuracy balance"
        case .small:
            return "Higher accuracy, reasonable performance"
        case .medium:
            return "Professional transcription, slower"
        case .large:
            return "Maximum accuracy, requires significant memory"
        case .largeTurbo:
            return "Near-large accuracy with faster inference"
        }
    }

    /// Relative speed rating (1-5, higher is faster).
    nonisolated var speedRating: Int {
        switch self {
        case .tiny: return 5
        case .base: return 4
        case .small: return 3
        case .medium: return 2
        case .large: return 1
        case .largeTurbo: return 3
        }
    }

    /// Relative accuracy rating (1-5, higher is better).
    nonisolated var accuracyRating: Int {
        switch self {
        case .tiny: return 1
        case .base: return 2
        case .small: return 3
        case .medium: return 4
        case .large: return 5
        case .largeTurbo: return 5
        }
    }
}
