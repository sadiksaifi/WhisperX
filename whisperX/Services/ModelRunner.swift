import Foundation

// MARK: - ModelRunner
/// Loads and runs the Whisper model for speech-to-text transcription.
///
/// Threading: Model inference runs on a background Task to avoid blocking the UI.
/// Results are published on the main actor.
///
/// Memory: Model loading is deferred until first use; unloads on memory pressure.
final class ModelRunner {
    // TODO: Implement in Step 3
}
