import AVFoundation
import Foundation
import os

/// Validates audio files before transcription.
///
/// Use this utility to check audio files meet the expected format before
/// sending them to the model runner. While WhisperKit can handle format
/// conversion, pre-validation helps catch issues early.
enum AudioValidator {

    /// Expected sample rate for Whisper models.
    static let expectedSampleRate: Double = 16000

    /// Minimum recording duration in seconds.
    static let minimumDuration: Double = 0.1

    /// Validates that an audio file is suitable for transcription.
    ///
    /// Checks that the file exists, can be read, and has sufficient duration.
    /// Logs warnings if the format differs from the expected 16kHz mono.
    ///
    /// - Parameter url: The audio file URL.
    /// - Throws: `ModelRunnerError.audioFileNotFound` if file doesn't exist,
    ///           `ModelRunnerError.invalidAudioFormat` if format is invalid.
    static func validate(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ModelRunnerError.audioFileNotFound(url)
        }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat

            // Log format info
            Logger.audio.debug("Audio format: \(format.sampleRate)Hz, \(format.channelCount) channels")

            // WhisperKit handles format conversion, but we log warnings
            if format.sampleRate != expectedSampleRate {
                Logger.audio.warning("Audio sample rate \(format.sampleRate) differs from expected \(expectedSampleRate)")
            }

            // Check minimum duration (avoid very short recordings)
            let duration = Double(audioFile.length) / format.sampleRate
            if duration < minimumDuration {
                throw ModelRunnerError.invalidAudioFormat(
                    "Recording too short (\(String(format: "%.2f", duration))s, minimum \(minimumDuration)s)"
                )
            }

            Logger.audio.debug("Audio validated: \(String(format: "%.2f", duration))s duration")

        } catch let error as ModelRunnerError {
            throw error
        } catch {
            throw ModelRunnerError.invalidAudioFormat(error.localizedDescription)
        }
    }

    /// Returns information about an audio file without throwing.
    ///
    /// - Parameter url: The audio file URL.
    /// - Returns: Audio info or nil if file cannot be read.
    static func getInfo(_ url: URL) -> AudioInfo? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let duration = Double(audioFile.length) / format.sampleRate

            return AudioInfo(
                duration: duration,
                sampleRate: format.sampleRate,
                channelCount: Int(format.channelCount),
                url: url
            )
        } catch {
            return nil
        }
    }
}

// MARK: - AudioInfo

/// Information about an audio file.
struct AudioInfo: Sendable {
    /// Duration in seconds.
    let duration: Double

    /// Sample rate in Hz.
    let sampleRate: Double

    /// Number of audio channels.
    let channelCount: Int

    /// File URL.
    let url: URL

    /// Human-readable duration string.
    var formattedDuration: String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration) % 60
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
    }
}
