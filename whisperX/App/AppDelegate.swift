import AppKit
import SwiftUI
import os

/// Main application delegate managing the menu bar, windows, and app lifecycle.
///
/// Owns all window controllers and handles activation policy switching
/// between accessory mode (menu bar only) and regular mode (with dock icon).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var settingsWindowController: SettingsWindowController!
    private var hudWindowController: HUDWindowController!

    private let settings = SettingsStore()
    private let appState = AppState()

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.app.info("WhisperX launching")

        setupStatusItem()
        setupWindowControllers()

        // Start in accessory mode (no dock icon)
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.app.info("WhisperX terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when windows close; we're a menu bar app
        false
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "WhisperX")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit WhisperX", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu

        Logger.app.debug("Status item configured")
    }

    private func setupWindowControllers() {
        settingsWindowController = SettingsWindowController(settings: settings)
        settingsWindowController.onVisibilityChanged = { [weak self] visible in
            self?.handleSettingsVisibilityChanged(visible)
        }

        hudWindowController = HUDWindowController(appState: appState)

        Logger.app.debug("Window controllers initialized")
    }

    // MARK: - Actions

    @objc private func showSettings() {
        // Switch to regular app mode so dock icon and menu bar appear
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindowController.showSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Window Management

    private func handleSettingsVisibilityChanged(_ visible: Bool) {
        if visible {
            // Already in regular mode from showSettings
        } else {
            // Settings closed, return to accessory mode if no other windows
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    // MARK: - HUD Control (for future use)

    /// Shows the HUD overlay. Called when recording starts.
    func showHUD() {
        hudWindowController.showHUD()
    }

    /// Hides the HUD overlay. Called when recording ends.
    func hideHUD() {
        hudWindowController.hideHUD()
    }
}
