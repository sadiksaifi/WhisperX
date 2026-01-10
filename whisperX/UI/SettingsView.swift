import SwiftUI

/// Settings interface for configuring WhisperX preferences.
struct SettingsView: View {
    @Bindable var settings: SettingsStore
    @Bindable var permissionManager: PermissionManager

    var body: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Push-to-talk key:")
                    Spacer()
                    Text("Right Option (⌥)")
                        .foregroundStyle(.secondary)
                }
                Text("Hold the key to record, release to stop.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Model") {
                Picker("Whisper Model", selection: $settings.modelVariant) {
                    ForEach(WhisperModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Audio") {
                Text("Audio input device selection")
                    .foregroundStyle(.secondary)
                // TODO: Add device picker in Step 3
            }

            Section("Output") {
                Toggle("Copy to Clipboard", isOn: $settings.copyToClipboard)
            }

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
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
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
    SettingsView(settings: SettingsStore(), permissionManager: PermissionManager())
}
