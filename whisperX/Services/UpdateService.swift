//
//  UpdateService.swift
//  whisperX
//

import AppKit
import Foundation
import os

/// Protocol for receiving update events.
@MainActor
protocol UpdateServiceDelegate: AnyObject {
    func updateService(_ service: UpdateService, didChangeState state: UpdateCheckState)
    func updateService(_ service: UpdateService, didFindUpdate release: GitHubRelease)
    func updateServiceDidCompleteInstallation(_ service: UpdateService)
}

/// Handles checking for updates, downloading, and installing new versions from GitHub releases.
///
/// ## Threading Model
/// - Uses Swift actor for internal state management
/// - Delegate callbacks dispatched to MainActor
/// - Download progress reported on MainActor
///
/// ## GitHub API
/// - Uses unauthenticated requests (60 requests/hour limit)
/// - Caches last check time to avoid excessive requests
/// - Respects rate limit headers
actor UpdateService {

    // MARK: - Configuration

    private static let githubRepo = "sadiksaifi/WhisperX"
    private static let apiBaseURL = "https://api.github.com/repos/\(githubRepo)/releases"
    private static let minimumCheckInterval: TimeInterval = 3600 // 1 hour

    // MARK: - State

    private weak var delegate: UpdateServiceDelegate?
    private var currentState: UpdateCheckState = .idle
    private var lastCheckTime: Date?
    private var availableRelease: GitHubRelease?
    private var downloadTask: Task<Void, Error>?
    private var downloadedFileURL: URL?

    // MARK: - Initialization

    init(delegate: UpdateServiceDelegate?) {
        self.delegate = delegate
        Logger.update.debug("UpdateService initialized")
    }

    /// Sets the delegate for receiving update events.
    func setDelegate(_ delegate: UpdateServiceDelegate?) {
        self.delegate = delegate
    }

    // MARK: - Public API

    /// Checks for updates from GitHub releases based on the specified channel.
    /// - Parameters:
    ///   - channel: The release channel to check for updates.
    ///   - force: If true, ignores minimum check interval.
    func checkForUpdates(channel: ReleaseChannel, force: Bool = false) async throws {
        // Rate limit local checks
        if !force, let lastCheck = lastCheckTime,
           Date().timeIntervalSince(lastCheck) < Self.minimumCheckInterval {
            Logger.update.debug("Skipping check - too soon since last check")
            return
        }

        await updateState(.checking)

        do {
            let releases = try await fetchAllReleases()
            lastCheckTime = Date()

            guard let currentVersion = getCurrentAppVersion() else {
                throw UpdateError.versionParsingFailed
            }

            // Find the best release for the user's channel
            let result = findBestRelease(
                from: releases,
                forChannel: channel,
                currentVersion: currentVersion
            )

            switch result {
            case .updateAvailable(let release, let version):
                availableRelease = release
                await updateState(.available(version: release.tagName, release: release))
                await notifyUpdateAvailable(release)
                Logger.update.info("Update available: \(release.tagName) (current: \(currentVersion.description))")

            case .stableNewer(let stableRelease, let stableVersion):
                // User is on pre-release but stable is newer
                availableRelease = stableRelease
                await updateState(.stableNewer(
                    stableVersion: stableRelease.tagName,
                    stableRelease: stableRelease,
                    currentVersion: currentVersion.description
                ))
                Logger.update.info("Stable version \(stableRelease.tagName) is newer than current pre-release \(currentVersion.description)")

            case .upToDate:
                await updateState(.upToDate)
                Logger.update.info("App is up to date (current: \(currentVersion.description))")
            }
        } catch {
            let message = (error as? UpdateError)?.errorDescription ?? error.localizedDescription
            await updateState(.error(message: message))
            throw error
        }
    }

    /// Downloads the latest release asset.
    func downloadUpdate() async throws {
        guard let release = availableRelease,
              let asset = findCompatibleAsset(in: release) else {
            throw UpdateError.noCompatibleAsset
        }

        await updateState(.downloading(progress: 0))

        guard let url = URL(string: asset.browserDownloadUrl) else {
            throw UpdateError.downloadFailed(underlying: "Invalid download URL")
        }

        do {
            let localURL = try await downloadFile(from: url, expectedSize: asset.size)
            downloadedFileURL = localURL
            await updateState(.readyToInstall)
            Logger.update.info("Download complete: \(localURL.lastPathComponent)")
        } catch {
            let message = (error as? UpdateError)?.errorDescription ?? error.localizedDescription
            await updateState(.error(message: message))
            throw error
        }
    }

    /// Installs the downloaded update by replacing the app bundle.
    func installUpdate() async throws {
        guard let downloadedFile = downloadedFileURL else {
            throw UpdateError.installationFailed(underlying: "No downloaded file")
        }

        await updateState(.installing)

        do {
            try await performInstallation(from: downloadedFile)
            await notifyInstallationComplete()
        } catch {
            let message = (error as? UpdateError)?.errorDescription ?? error.localizedDescription
            await updateState(.error(message: message))
            throw error
        }
    }

    /// Cancels any in-progress download.
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        Task { await updateState(.idle) }
    }

    /// Returns the current update state.
    func getState() -> UpdateCheckState {
        currentState
    }

    /// Returns the available release if one was found.
    func getAvailableRelease() -> GitHubRelease? {
        availableRelease
    }

    // MARK: - Private Methods

    /// Result of searching for the best update.
    private enum UpdateSearchResult {
        case updateAvailable(release: GitHubRelease, version: SemanticVersion)
        case stableNewer(stableRelease: GitHubRelease, stableVersion: SemanticVersion)
        case upToDate
    }

    /// Fetches all releases from GitHub (limited to most recent 30).
    private func fetchAllReleases() async throws -> [GitHubRelease] {
        guard let url = URL(string: "\(Self.apiBaseURL)?per_page=30") else {
            throw UpdateError.networkError(underlying: "Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("WhisperX-Updater", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.networkError(underlying: "Invalid response")
        }

        // Handle rate limiting
        if httpResponse.statusCode == 403 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Int($0) }
            throw UpdateError.rateLimited(retryAfter: retryAfter)
        }

        // Handle 404 - no releases yet
        if httpResponse.statusCode == 404 {
            throw UpdateError.noReleasesFound
        }

        guard httpResponse.statusCode == 200 else {
            throw UpdateError.networkError(underlying: "HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let releases = try decoder.decode([GitHubRelease].self, from: data)

        if releases.isEmpty {
            throw UpdateError.noReleasesFound
        }

        return releases
    }

    /// Finds the best release for the given channel and current version.
    private func findBestRelease(
        from releases: [GitHubRelease],
        forChannel channel: ReleaseChannel,
        currentVersion: SemanticVersion
    ) -> UpdateSearchResult {
        // Parse all releases into (release, version) tuples
        let parsedReleases: [(GitHubRelease, SemanticVersion)] = releases.compactMap { release in
            guard let version = SemanticVersion(string: release.tagName) else { return nil }
            return (release, version)
        }

        // Find the latest stable release
        let latestStable = parsedReleases
            .filter { $0.1.channel == .stable }
            .max { $0.1 < $1.1 }

        // Filter releases based on channel preference
        let eligibleReleases: [(GitHubRelease, SemanticVersion)]
        switch channel {
        case .stable:
            // Only stable releases
            eligibleReleases = parsedReleases.filter { $0.1.channel == .stable }
        case .beta:
            // Beta and stable releases
            eligibleReleases = parsedReleases.filter { $0.1.channel == .stable || $0.1.channel == .beta }
        case .alpha:
            // All releases (alpha, beta, stable)
            eligibleReleases = parsedReleases
        }

        // Find the newest eligible release
        guard let (bestRelease, bestVersion) = eligibleReleases.max(by: { $0.1 < $1.1 }) else {
            return .upToDate
        }

        // Check if update is available
        if bestVersion > currentVersion {
            return .updateAvailable(release: bestRelease, version: bestVersion)
        }

        // Special case: user is on pre-release, check if stable is newer
        if currentVersion.channel != .stable,
           let (stableRelease, stableVersion) = latestStable,
           stableVersion > currentVersion {
            return .stableNewer(stableRelease: stableRelease, stableVersion: stableVersion)
        }

        return .upToDate
    }

    private func getCurrentAppVersion() -> SemanticVersion? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return SemanticVersion(string: version)
    }

    private func findCompatibleAsset(in release: GitHubRelease) -> GitHubAsset? {
        // Prefer .dmg, fall back to .zip
        let dmgAsset = release.assets.first { $0.name.hasSuffix(".dmg") }
        let zipAsset = release.assets.first { $0.name.hasSuffix(".zip") }
        return dmgAsset ?? zipAsset
    }

    private func downloadFile(from url: URL, expectedSize: Int) async throws -> URL {
        Logger.update.info("Starting download from: \(url.absoluteString)")

        let (localURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed(underlying: "Download failed")
        }

        // Verify file size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: localURL.path),
           let size = attrs[.size] as? Int,
           size != expectedSize {
            Logger.update.warning("Downloaded file size mismatch: expected \(expectedSize), got \(size)")
        }

        // Move to a known location
        let destURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("whisperx-update")
            .appendingPathExtension(url.pathExtension)

        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: localURL, to: destURL)

        return destURL
    }

    private func performInstallation(from fileURL: URL) async throws {
        let appBundle = Bundle.main.bundleURL
        let appName = appBundle.lastPathComponent
        let parentDir = appBundle.deletingLastPathComponent()

        Logger.update.info("Installing update from: \(fileURL.path)")
        Logger.update.info("App bundle: \(appBundle.path)")

        // Create helper script that:
        // 1. Waits for app to quit
        // 2. Replaces the app bundle
        // 3. Relaunches the app
        // 4. Cleans up

        let scriptContent: String

        if fileURL.pathExtension == "dmg" {
            scriptContent = """
            #!/bin/bash
            set -e
            LOG_FILE="/tmp/whisperx-update.log"
            echo "$(date): Starting update installation" > "$LOG_FILE"

            sleep 2

            # Mount DMG (note: -quiet suppresses output, so we don't use it)
            MOUNT_OUTPUT=$(hdiutil attach "\(fileURL.path)" -nobrowse 2>&1)
            if [ $? -ne 0 ]; then
                echo "$(date): Failed to mount DMG: $MOUNT_OUTPUT" >> "$LOG_FILE"
                exit 1
            fi

            MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | tail -1 | cut -f3)
            echo "$(date): Mount point: $MOUNT_POINT" >> "$LOG_FILE"

            if [ -z "$MOUNT_POINT" ]; then
                echo "$(date): Failed to get mount point from output" >> "$LOG_FILE"
                exit 1
            fi

            if [ -d "$MOUNT_POINT/\(appName)" ]; then
                echo "$(date): Found app at $MOUNT_POINT/\(appName)" >> "$LOG_FILE"
                rm -rf "\(appBundle.path)"
                cp -R "$MOUNT_POINT/\(appName)" "\(parentDir.path)/"
                hdiutil detach "$MOUNT_POINT" -quiet
                rm -f "\(fileURL.path)"

                # Clear stale TCC entries to avoid "ghost permissions" after update
                # Without code signing, macOS sees the new binary as a different app
                echo "$(date): Clearing stale TCC entries" >> "$LOG_FILE"
                tccutil reset Accessibility com.sadiksaifi.whisperX 2>/dev/null || true
                tccutil reset Microphone com.sadiksaifi.whisperX 2>/dev/null || true

                echo "$(date): Update installed successfully, launching app" >> "$LOG_FILE"
                open "\(appBundle.path)"
            else
                echo "$(date): App not found in DMG at $MOUNT_POINT/\(appName)" >> "$LOG_FILE"
                ls -la "$MOUNT_POINT" >> "$LOG_FILE" 2>&1
                hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null
                exit 1
            fi
            rm -f "$0"
            """
        } else {
            // ZIP file
            scriptContent = """
            #!/bin/bash
            set -e
            LOG_FILE="/tmp/whisperx-update.log"
            echo "$(date): Starting update installation (ZIP)" > "$LOG_FILE"

            sleep 2

            TEMP_DIR=$(mktemp -d)
            echo "$(date): Extracting to $TEMP_DIR" >> "$LOG_FILE"

            unzip -q "\(fileURL.path)" -d "$TEMP_DIR"
            if [ $? -ne 0 ]; then
                echo "$(date): Failed to extract ZIP" >> "$LOG_FILE"
                rm -rf "$TEMP_DIR"
                exit 1
            fi

            if [ -d "$TEMP_DIR/\(appName)" ]; then
                echo "$(date): Found app at $TEMP_DIR/\(appName)" >> "$LOG_FILE"
                rm -rf "\(appBundle.path)"
                mv "$TEMP_DIR/\(appName)" "\(parentDir.path)/"
                rm -rf "$TEMP_DIR"
                rm -f "\(fileURL.path)"

                # Clear stale TCC entries to avoid "ghost permissions" after update
                # Without code signing, macOS sees the new binary as a different app
                echo "$(date): Clearing stale TCC entries" >> "$LOG_FILE"
                tccutil reset Accessibility com.sadiksaifi.whisperX 2>/dev/null || true
                tccutil reset Microphone com.sadiksaifi.whisperX 2>/dev/null || true

                echo "$(date): Update installed successfully, launching app" >> "$LOG_FILE"
                open "\(appBundle.path)"
            else
                echo "$(date): App not found in ZIP at $TEMP_DIR/\(appName)" >> "$LOG_FILE"
                ls -la "$TEMP_DIR" >> "$LOG_FILE" 2>&1
                rm -rf "$TEMP_DIR"
                exit 1
            fi
            rm -f "$0"
            """
        }

        // Write and execute script
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("whisperx-update.sh")

        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptURL.path
        )

        Logger.update.info("Launching update script and terminating app")

        // Launch script and quit app
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        try process.run()

        // Quit the app - the script will handle the rest
        await MainActor.run {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - State Updates

    private func updateState(_ newState: UpdateCheckState) async {
        currentState = newState
        let delegate = self.delegate
        let service = self
        await MainActor.run {
            delegate?.updateService(service, didChangeState: newState)
        }
    }

    private func notifyUpdateAvailable(_ release: GitHubRelease) async {
        let delegate = self.delegate
        let service = self
        await MainActor.run {
            delegate?.updateService(service, didFindUpdate: release)
        }
    }

    private func notifyInstallationComplete() async {
        let delegate = self.delegate
        let service = self
        await MainActor.run {
            delegate?.updateServiceDidCompleteInstallation(service)
        }
    }
}
