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

    /// Checks for updates from GitHub releases.
    /// - Parameter force: If true, ignores minimum check interval.
    func checkForUpdates(force: Bool = false) async throws {
        // Rate limit local checks
        if !force, let lastCheck = lastCheckTime,
           Date().timeIntervalSince(lastCheck) < Self.minimumCheckInterval {
            Logger.update.debug("Skipping check - too soon since last check")
            return
        }

        await updateState(.checking)

        do {
            let release = try await fetchLatestRelease()
            lastCheckTime = Date()

            guard let currentVersion = getCurrentAppVersion(),
                  let latestVersion = SemanticVersion(string: release.tagName) else {
                throw UpdateError.versionParsingFailed
            }

            if latestVersion > currentVersion {
                availableRelease = release
                await updateState(.available(version: release.tagName, release: release))
                await notifyUpdateAvailable(release)
                Logger.update.info("Update available: \(release.tagName) (current: \(currentVersion.description))")
            } else {
                await updateState(.upToDate)
                Logger.update.info("App is up to date (current: \(currentVersion.description), latest: \(release.tagName))")
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

    private func fetchLatestRelease() async throws -> GitHubRelease {
        guard let url = URL(string: "\(Self.apiBaseURL)/latest") else {
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
        return try decoder.decode(GitHubRelease.self, from: data)
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
            sleep 2
            MOUNT_POINT=$(hdiutil attach "\(fileURL.path)" -nobrowse -quiet | tail -1 | cut -f3)
            if [ -d "$MOUNT_POINT/\(appName)" ]; then
                rm -rf "\(appBundle.path)"
                cp -R "$MOUNT_POINT/\(appName)" "\(parentDir.path)/"
                hdiutil detach "$MOUNT_POINT" -quiet
                rm -f "\(fileURL.path)"
                open "\(appBundle.path)"
            else
                echo "App not found in DMG"
                hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null
            fi
            rm -f "$0"
            """
        } else {
            // ZIP file
            scriptContent = """
            #!/bin/bash
            sleep 2
            TEMP_DIR=$(mktemp -d)
            unzip -q "\(fileURL.path)" -d "$TEMP_DIR"
            if [ -d "$TEMP_DIR/\(appName)" ]; then
                rm -rf "\(appBundle.path)"
                mv "$TEMP_DIR/\(appName)" "\(parentDir.path)/"
                rm -rf "$TEMP_DIR"
                rm -f "\(fileURL.path)"
                open "\(appBundle.path)"
            else
                echo "App not found in ZIP"
                rm -rf "$TEMP_DIR"
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
