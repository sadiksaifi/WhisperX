//
//  UpdateSectionView.swift
//  whisperX
//

import SwiftUI

/// Settings section for update preferences and manual update checking.
struct UpdateSectionView: View {
    @Bindable var settings: SettingsStore
    let updateState: UpdateCheckState
    let currentVersion: String
    let onCheckForUpdates: () -> Void
    let onDownloadUpdate: () -> Void
    let onInstallUpdate: () -> Void

    var body: some View {
        Section("Updates") {
            // Version display
            HStack {
                Text("Current Version")
                Spacer()
                Text(currentVersion)
                    .foregroundStyle(.secondary)
            }

            // Dev build warning
            if settings.isDevBuild {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(.purple)
                    Text("This is a development build. It may be unstable and is not intended for regular use.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Update channel picker
            Picker("Update Channel", selection: $settings.updateChannel) {
                Text("Stable").tag(ReleaseChannel.stable)
                Text("Beta").tag(ReleaseChannel.beta)
                // Only show Alpha option if user is running an alpha or dev build
                if settings.detectedChannel == .alpha {
                    Text("Alpha").tag(ReleaseChannel.alpha)
                }
            }

            // Warning for non-stable channels (only if not already showing dev warning)
            if settings.updateChannel != .stable && !settings.isDevBuild {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(settings.updateChannel == .alpha
                         ? "Alpha releases are experimental and may have significant bugs."
                         : "Beta releases may contain bugs and incomplete features.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Check for updates button with state
            HStack {
                updateButton
                Spacer()
                actionButton
            }

            // Stable newer notification
            if case .stableNewer(let stableVersion, _, let currentVer) = updateState {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("A stable release (\(stableVersion)) is available. You're currently on \(currentVer).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Error display
            if case .error(let message) = updateState {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Auto-update toggles
            Toggle("Check for updates on launch", isOn: $settings.checkUpdatesOnLaunch)

            Toggle("Auto-update", isOn: $settings.autoUpdateEnabled)

            if settings.autoUpdateEnabled {
                Text("Updates will be downloaded and installed automatically when available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var updateButton: some View {
        HStack(spacing: 12) {
            Button(action: onCheckForUpdates) {
                switch updateState {
                case .checking:
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking...")
                    }
                default:
                    Text("Check for Updates")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isCheckDisabled)

            // Status indicator (separate from button)
            switch updateState {
            case .available(let version, _):
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text("v\(version) available")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            case .stableNewer(let version, _, _):
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Stable v\(version) available")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            case .upToDate:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Up to date")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch updateState {
        case .available, .stableNewer:
            Button("Download", action: onDownloadUpdate)
                .buttonStyle(.borderedProminent)
        case .downloading(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 60)
                Text("\(Int(progress * 100))%")
                    .monospacedDigit()
                    .font(.caption)
            }
        case .readyToInstall:
            Button("Install & Restart", action: onInstallUpdate)
                .buttonStyle(.borderedProminent)
        case .installing:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Installing...")
                    .font(.caption)
            }
        default:
            EmptyView()
        }
    }

    private var isCheckDisabled: Bool {
        switch updateState {
        case .checking, .downloading, .installing:
            return true
        default:
            return false
        }
    }
}
