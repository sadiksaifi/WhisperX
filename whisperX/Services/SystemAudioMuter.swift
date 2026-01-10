import AudioToolbox
import CoreAudio
import os

/// Service for muting/unmuting system audio output during recording.
///
/// Threading: This class is `@MainActor` for consistent access from AppDelegate.
/// Uses CoreAudio APIs to control the default output device's mute state.
@MainActor
final class SystemAudioMuter {
    /// Stores the mute state before we muted, for restoration.
    private var previousMuteState: Bool?

    /// Whether we currently have system audio muted.
    private var isMutedByUs: Bool = false

    // MARK: - Public Methods

    /// Mutes system audio, saving the current state for later restoration.
    func muteSystemAudio() {
        guard let deviceID = getDefaultOutputDeviceID() else {
            Logger.audio.warning("Could not get default output device for muting")
            return
        }

        // Save current state before muting
        previousMuteState = getMuteState(deviceID)

        // Mute the output
        if setMuteState(true, deviceID) {
            isMutedByUs = true
            Logger.audio.debug("System audio muted for recording")
        } else {
            Logger.audio.warning("Failed to mute system audio")
        }
    }

    /// Restores system audio to its previous state before we muted.
    func restoreSystemAudio() {
        guard isMutedByUs else {
            // We didn't mute, nothing to restore
            return
        }

        guard let deviceID = getDefaultOutputDeviceID() else {
            Logger.audio.warning("Could not get default output device for unmuting")
            return
        }

        // Restore to previous state (or unmute if we didn't capture state)
        let targetState = previousMuteState ?? false

        if setMuteState(targetState, deviceID) {
            Logger.audio.debug("System audio restored (muted: \(targetState))")
        } else {
            Logger.audio.warning("Failed to restore system audio state")
        }

        // Reset our tracking state
        previousMuteState = nil
        isMutedByUs = false
    }

    // MARK: - Private Methods

    /// Gets the default output device ID.
    private func getDefaultOutputDeviceID() -> AudioDeviceID? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )

        guard status == noErr, deviceID != 0 else {
            Logger.audio.error("Failed to get default output device: \(status)")
            return nil
        }

        return deviceID
    }

    /// Gets the current mute state of the specified output device.
    private func getMuteState(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Check if property is supported
        guard AudioObjectHasProperty(deviceID, &propertyAddress) else {
            Logger.audio.debug("Device does not support mute property")
            return false
        }

        var isMuted: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &isMuted
        )

        guard status == noErr else {
            Logger.audio.error("Failed to get mute state: \(status)")
            return false
        }

        return isMuted != 0
    }

    /// Sets the mute state of the specified output device.
    /// Returns true if successful.
    @discardableResult
    private func setMuteState(_ muted: Bool, _ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Check if property is supported and settable
        guard AudioObjectHasProperty(deviceID, &propertyAddress) else {
            Logger.audio.debug("Device does not support mute property")
            return false
        }

        var isSettable: DarwinBoolean = false
        let settableStatus = AudioObjectIsPropertySettable(deviceID, &propertyAddress, &isSettable)
        guard settableStatus == noErr, isSettable.boolValue else {
            Logger.audio.debug("Mute property is not settable")
            return false
        }

        var muteValue: UInt32 = muted ? 1 : 0

        let status = AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &muteValue
        )

        guard status == noErr else {
            Logger.audio.error("Failed to set mute state: \(status)")
            return false
        }

        return true
    }
}
