import Foundation

/// Runtime application state shared across the app.
/// Holds transient state that doesn't persist between launches.
@Observable
@MainActor
final class AppState {
    /// Current recording/transcription status.
    var recordingState: RecordingState = .idle

    /// The most recent transcription result, if any.
    var lastTranscription: String?

    /// Whether the model is currently loading.
    var isModelLoading: Bool = false

    /// Error message to display, if any.
    var errorMessage: String?

    /// URL of the most recent audio recording, if any.
    /// Set after recording stops, used by the transcription pipeline.
    var lastRecordingURL: URL?
}

// MARK: - RecordingState

/// Represents the current state of the recording pipeline.
enum RecordingState: Equatable {
    /// No recording in progress.
    case idle

    /// Actively recording audio.
    case recording

    /// Processing recorded audio through the model.
    case transcribing
}
