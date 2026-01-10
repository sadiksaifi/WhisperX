import SwiftUI

/// Settings interface for configuring WhisperX preferences.
///
/// Organized into sections for Hotkey, Model, Audio, Output, and Permissions.
/// Each section is documented inline with its purpose.
struct SettingsView: View {
    @Bindable var settings: SettingsStore
    @Bindable var permissionManager: PermissionManager
    @Bindable var audioDeviceManager: AudioDeviceManager

    var body: some View {
        Form {
            hotkeySection
            modelSection
            audioSection
            outputSection
            permissionsSection
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 520)
        .onAppear {
            audioDeviceManager.startMonitoring()
        }
        .onDisappear {
            audioDeviceManager.stopMonitoring()
        }
    }

    // MARK: - Hotkey Section

    /// Configure the push-to-talk hotkey and debounce timing.
    private var hotkeySection: some View {
        Section("Hotkey") {
            HotkeyPickerView(
                keyCode: $settings.hotkeyKeyCode,
                modifiers: $settings.hotkeyModifiers
            )

            HStack {
                Text("Debounce:")
                Picker("", selection: $settings.hotkeyDebounceMs) {
                    Text("50 ms").tag(50)
                    Text("100 ms").tag(100)
                    Text("150 ms").tag(150)
                    Text("200 ms").tag(200)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 100)

                Spacer()

                Button("Reset to Default") {
                    settings.hotkeyKeyCode = SettingsStore.defaultHotkeyKeyCode
                    settings.hotkeyModifiers = SettingsStore.defaultHotkeyModifiers
                    settings.hotkeyDebounceMs = SettingsStore.defaultDebounceMs
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Hold the key to record, release to stop.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Model Section

    /// Select the Whisper model variant with descriptors.
    private var modelSection: some View {
        Section("Model") {
            Picker("Whisper Model", selection: $settings.modelVariant) {
                ForEach(WhisperModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.menu)

            ModelDescriptorView(model: settings.modelVariant)

            Text(settings.modelVariant.recommendedUseCase)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Audio Section

    /// Select the audio input device.
    private var audioSection: some View {
        Section("Audio Input") {
            AudioDevicePickerView(
                selectedDeviceID: $settings.audioDeviceID,
                devices: audioDeviceManager.inputDevices
            )
        }
    }

    // MARK: - Output Section

    /// Configure clipboard behavior after transcription.
    private var outputSection: some View {
        Section("Output") {
            Toggle("Copy to Clipboard", isOn: $settings.copyToClipboard)

            if settings.copyToClipboard {
                Toggle("Paste after copying", isOn: $settings.pasteAfterCopy)
                    .padding(.leading, 20)
            }
        }
    }

    // MARK: - Permissions Section

    /// Display permission status with fix actions.
    private var permissionsSection: some View {
        Section("Permissions") {
            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(
                    title: "Microphone",
                    description: "Required to record audio for transcription.",
                    status: permissionManager.microphoneStatus,
                    onFix: { permissionManager.openMicrophoneSettings() }
                )
                PermissionRow(
                    title: "Input Monitoring",
                    description: "Required to detect the global hotkey.",
                    status: permissionManager.accessibilityStatus,
                    onFix: { permissionManager.openAccessibilitySettings() }
                )
            }
        }
    }
}

/// Row displaying a permission requirement with live status.
private struct PermissionRow: View {
    let title: String
    let description: String
    let status: PermissionStatus
    let onFix: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusIndicator
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch status {
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .imageScale(.large)
        case .denied:
            Button("Fix") {
                onFix()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        case .notDetermined:
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
                .imageScale(.large)
        case .unknown:
            Image(systemName: "circle.dashed")
                .foregroundStyle(.secondary)
                .imageScale(.large)
        }
    }
}

#Preview {
    SettingsView(
        settings: SettingsStore(),
        permissionManager: PermissionManager(),
        audioDeviceManager: AudioDeviceManager()
    )
}
