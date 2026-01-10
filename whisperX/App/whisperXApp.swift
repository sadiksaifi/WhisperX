//
//  whisperXApp.swift
//  whisperX
//
//  Created by Sadik Saifi on 09/01/26.
//

import SwiftUI

/// Main entry point for WhisperX.
/// Uses NSApplicationDelegateAdaptor to bridge to AppKit for menu bar management.
@main
struct WhisperXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default windows; AppDelegate manages all windows via AppKit
        Settings {
            EmptyView()
        }
    }
}
