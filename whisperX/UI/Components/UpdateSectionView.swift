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

            // Check for updates button with state
            HStack {
                updateButton
                Spacer()
                actionButton
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
        Button(action: onCheckForUpdates) {
            switch updateState {
            case .checking:
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking...")
                }
            case .available(let version, _):
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Update Available: \(version)")
                }
            case .upToDate:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Up to Date")
                }
            case .error:
                Text("Check for Updates")
            default:
                Text("Check for Updates")
            }
        }
        .buttonStyle(.bordered)
        .disabled(isCheckDisabled)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch updateState {
        case .available:
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
