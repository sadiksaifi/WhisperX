import SwiftUI

/// Pre-flight dialog explaining why a permission is needed before triggering the system prompt.
/// Shown only once per permission type to guide the user through the permission flow.
struct PermissionGuidanceView: View {
    let permissionType: PermissionType
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("Not Now") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Open Settings") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 360)
    }

    // MARK: - Content Properties

    private var iconName: String {
        switch permissionType {
        case .accessibility:
            return "keyboard"
        case .microphone:
            return "mic.fill"
        }
    }

    private var title: String {
        switch permissionType {
        case .accessibility:
            return "Input Monitoring Required"
        case .microphone:
            return "Microphone Access Required"
        }
    }

    private var description: String {
        switch permissionType {
        case .accessibility:
            return "WhisperX needs Input Monitoring permission to detect when you press the hotkey. This allows the app to start recording when you hold down the trigger key."
        case .microphone:
            return "WhisperX needs Microphone access to record your voice for transcription. Your audio is processed locally and never sent to external servers."
        }
    }
}

#Preview("Accessibility") {
    PermissionGuidanceView(
        permissionType: .accessibility,
        onContinue: {},
        onCancel: {}
    )
}

#Preview("Microphone") {
    PermissionGuidanceView(
        permissionType: .microphone,
        onContinue: {},
        onCancel: {}
    )
}
