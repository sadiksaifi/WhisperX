import SwiftUI

/// Installation wizard guiding users to move the app to /Applications.
struct InstallationWizardView: View {
    let location: InstallationLocation
    let onMoveToApplications: () -> Void
    let onOpenDownloads: () -> Void
    let onOpenApplications: () -> Void
    let onLater: () -> Void

    @State private var isAnimating = false
    @State private var isMoving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // App Icon Section
            appIconSection

            // Title and Description
            titleSection

            // Visual Drag Instruction (animated)
            dragInstructionSection

            // Action Buttons
            actionButtonsSection
        }
        .padding(32)
        .frame(width: 480, height: 520)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    // MARK: - App Icon Section

    private var appIconSection: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 128, height: 128)
            .padding(.bottom, 24)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Move to Applications")
                .font(.system(size: 26, weight: .semibold))

            Text(descriptionText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 380)
        }
        .padding(.bottom, 32)
    }

    private var descriptionText: String {
        switch location {
        case .downloads:
            return "WhisperX is running from your Downloads folder. Move it to Applications for the best experience and to receive updates."
        case .dmg:
            return "WhisperX is running from a disk image. Drag it to Applications to complete the installation."
        case .other(let path):
            let folder = (path as NSString).lastPathComponent
            return "WhisperX is running from \(folder). Move it to Applications for the best experience."
        default:
            return ""
        }
    }

    // MARK: - Drag Instruction Section

    private var dragInstructionSection: some View {
        HStack(spacing: 20) {
            // Source: App Icon with label
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .quaternarySystemFill))
                        .frame(width: 88, height: 88)

                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                }

                Text(sourceLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Animated Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.blue)
                .offset(x: isAnimating ? 8 : -8)

            // Destination: Applications Folder
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .quaternarySystemFill))
                        .frame(width: 88, height: 88)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                }

                Text("Applications")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 24)
    }

    private var sourceLabel: String {
        switch location {
        case .downloads:
            return "Downloads"
        case .dmg:
            return "Disk Image"
        case .other:
            return "Current"
        default:
            return "WhisperX"
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Error display
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)
            }

            // Primary and secondary actions
            if location.isReadOnly {
                dmgButtonsSection
            } else {
                normalButtonsSection
            }

            // Later option
            Button("Not Now") {
                onLater()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
    }

    private var normalButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                performMove()
            } label: {
                if isMoving {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Moving...")
                    }
                    .frame(width: 200)
                } else {
                    Text("Move to Applications")
                        .frame(width: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isMoving)

            HStack(spacing: 16) {
                Button("Open Downloads") {
                    onOpenDownloads()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button("Open Applications") {
                    onOpenApplications()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
    }

    private var dmgButtonsSection: some View {
        VStack(spacing: 16) {
            Text("Drag WhisperX from the disk image to your Applications folder.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Show in Finder") {
                    InstallationService.revealInFinder()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Open Applications") {
                    onOpenApplications()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Actions

    private func performMove() {
        isMoving = true
        errorMessage = nil

        Task {
            do {
                let newURL: URL

                if InstallationService.canWriteToApplications() {
                    newURL = try await InstallationService.moveToApplications()
                } else {
                    newURL = try await InstallationService.moveToApplicationsWithPrivileges()
                }

                // Delete original if move was successful
                InstallationService.deleteOriginalBundle()

                // Notify parent and relaunch from new location
                onMoveToApplications()
                InstallationService.relaunch(from: newURL)

            } catch {
                await MainActor.run {
                    isMoving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview("From Downloads") {
    InstallationWizardView(
        location: .downloads,
        onMoveToApplications: {},
        onOpenDownloads: {},
        onOpenApplications: {},
        onLater: {}
    )
}

#Preview("From DMG") {
    InstallationWizardView(
        location: .dmg,
        onMoveToApplications: {},
        onOpenDownloads: {},
        onOpenApplications: {},
        onLater: {}
    )
}
