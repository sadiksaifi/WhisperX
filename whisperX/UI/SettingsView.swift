import SwiftUI

/// Settings interface for configuring WhisperX preferences.
struct SettingsView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section("Hotkey") {
                Text("Push-to-talk hotkey configuration")
                    .foregroundStyle(.secondary)
                // TODO: Add hotkey recorder in Step 2
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
                // TODO: Add device picker in Step 2
            }

            Section("Output") {
                Toggle("Copy to Clipboard", isOn: $settings.copyToClipboard)
            }

            Section("Permissions") {
                VStack(alignment: .leading, spacing: 8) {
                    PermissionRow(
                        title: "Microphone",
                        description: "Required to record audio for transcription."
                    )
                    PermissionRow(
                        title: "Input Monitoring",
                        description: "Required to detect the global hotkey."
                    )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 380)
    }
}

/// Row displaying a permission requirement.
private struct PermissionRow: View {
    let title: String
    let description: String

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
            // TODO: Add permission status check in Step 2
        }
    }
}

#Preview {
    SettingsView(settings: SettingsStore())
}
