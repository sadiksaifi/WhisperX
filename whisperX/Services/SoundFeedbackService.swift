import AudioToolbox
import os

/// Service for playing audio feedback sounds during recording events.
///
/// Uses macOS system sounds for subtle, consistent feedback.
/// Uses AudioServices for reliable, synchronous playback.
@MainActor
final class SoundFeedbackService {
    /// Sound ID for recording start (Tink).
    private var startSoundID: SystemSoundID = 0

    /// Sound ID for recording stop (Purr).
    private var stopSoundID: SystemSoundID = 0

    init() {
        // Load Tink sound for recording start
        let tinkURL = URL(fileURLWithPath: "/System/Library/Sounds/Tink.aiff")
        AudioServicesCreateSystemSoundID(tinkURL as CFURL, &startSoundID)
        if startSoundID == 0 {
            Logger.audio.warning("Could not load start feedback sound (Tink)")
        }

        // Load Purr sound for recording stop
        let purrURL = URL(fileURLWithPath: "/System/Library/Sounds/Purr.aiff")
        AudioServicesCreateSystemSoundID(purrURL as CFURL, &stopSoundID)
        if stopSoundID == 0 {
            Logger.audio.warning("Could not load stop feedback sound (Purr)")
        }
    }

    deinit {
        if startSoundID != 0 {
            AudioServicesDisposeSystemSoundID(startSoundID)
        }
        if stopSoundID != 0 {
            AudioServicesDisposeSystemSoundID(stopSoundID)
        }
    }

    /// Plays the recording start feedback sound (Tink).
    func playStartSound() {
        guard startSoundID != 0 else { return }
        AudioServicesPlaySystemSound(startSoundID)
        Logger.audio.debug("Played start feedback sound (Tink)")
    }

    /// Plays the recording stop feedback sound (Purr).
    func playStopSound() {
        guard stopSoundID != 0 else { return }
        AudioServicesPlaySystemSound(stopSoundID)
        Logger.audio.debug("Played stop feedback sound (Purr)")
    }
}
