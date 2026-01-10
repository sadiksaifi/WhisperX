import Foundation

// MARK: - AudioRecorder
/// Captures audio from the microphone while the push-to-talk key is held.
///
/// Threading: Audio capture runs on a dedicated audio queue managed by AVFoundation.
/// Completion handlers are dispatched to the main actor.
///
/// Requires: Microphone permission (NSMicrophoneUsageDescription).
final class AudioRecorder {
    // TODO: Implement in Step 2
}
