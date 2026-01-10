import ApplicationServices
import Foundation
import os

// MARK: - HotkeyServiceDelegate

/// Delegate protocol for receiving hotkey press/release events.
protocol HotkeyServiceDelegate: AnyObject {
    /// Called when the hotkey is pressed and held past the debounce interval.
    @MainActor func hotkeyDidPress()

    /// Called when the hotkey is released (only if press was triggered).
    @MainActor func hotkeyDidRelease()
}

// MARK: - HotkeyService

/// Global hotkey detection service using CGEventTap.
///
/// ## Implementation Notes
///
/// This service uses `CGEventTap` to capture keyboard events globally. This approach
/// requires Accessibility (Input Monitoring) permission to be granted by the user.
///
/// ### Globe/Fn Key Limitation
/// The Globe/Fn key (CGKeyCode 63) is not reliably capturable on all Mac hardware:
/// - On older Intel Macs, the fn key may send CGKeyCode 63
/// - On Apple Silicon Macs with the new keyboard controller, the fn/Globe key
///   is often intercepted by the system before reaching CGEventTap
/// - Some keyboards (especially non-Apple) may not send this key code at all
///
/// As a fallback, this implementation uses F13 (CGKeyCode 105) if the Globe key
/// cannot be detected. F13-F19 are reliably capturable and rarely used by other apps.
///
/// ### Threading Model
/// - CGEventTap runs on a dedicated background thread with its own CFRunLoop
/// - All delegate callbacks are dispatched to the main thread for UI safety
/// - Debounce timer runs on the main queue
///
/// Requires: Accessibility (Input Monitoring) permission.
final class HotkeyService {
    // MARK: - Configuration

    /// Debounce interval in seconds.
    /// Recording only starts if the key is held for this duration.
    /// This prevents accidental starts from quick taps.
    static let debounceInterval: TimeInterval = 0.1

    /// Primary key code: Right Option key (keyCode 61).
    /// Right Option is ideal for push-to-talk: easy to reach, rarely used alone,
    /// and properly supports hold behavior unlike the Globe key.
    ///
    /// Note: Globe key (179) does NOT support hold - it only sends instant down/up pairs.
    static let primaryKeyCode: CGKeyCode = 61  // Right Option

    /// Alternative: Right Command key (keyCode 54)
    static let alternativeKeyCode: CGKeyCode = 54

    /// Fallback key code: F13 (reliably capturable on all Macs).
    static let fallbackKeyCode: CGKeyCode = 105

    // MARK: - State

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapRunLoop: CFRunLoop?
    private var tapThread: Thread?

    private var isKeyDown = false
    private var debounceWorkItem: DispatchWorkItem?
    private var hasPassedDebounce = false

    private weak var delegate: HotkeyServiceDelegate?

    /// The key code currently being monitored.
    private(set) var activeKeyCode: CGKeyCode

    /// Whether the service is currently running.
    private(set) var isRunning = false

    // MARK: - Initialization

    /// Creates a new hotkey service.
    /// - Parameter delegate: The delegate to receive hotkey events.
    init(delegate: HotkeyServiceDelegate?) {
        self.delegate = delegate
        self.activeKeyCode = Self.primaryKeyCode
    }

    deinit {
        stop()
    }

    // MARK: - Public Methods

    /// Starts the hotkey listener.
    /// - Returns: `true` if started successfully, `false` if Accessibility permission is denied.
    func start() -> Bool {
        guard !isRunning else {
            Logger.hotkey.warning("Hotkey service already running")
            return true
        }

        // Check accessibility permission
        guard AXIsProcessTrusted() else {
            Logger.hotkey.error("Accessibility permission denied - cannot start hotkey service")
            return false
        }

        // Try to create event tap for primary key first
        activeKeyCode = Self.primaryKeyCode
        if !createAndStartEventTap() {
            // Fall back to F13
            Logger.hotkey.warning("Failed to create event tap for Globe key, falling back to F13")
            activeKeyCode = Self.fallbackKeyCode
            if !createAndStartEventTap() {
                Logger.hotkey.error("Failed to create event tap for fallback key")
                return false
            }
        }

        isRunning = true
        Logger.hotkey.info("Hotkey service started (key code: \(self.activeKeyCode))")
        return true
    }

    /// Stops the hotkey listener and cleans up resources.
    func stop() {
        guard isRunning else { return }

        // Cancel any pending debounce
        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        // Stop the run loop
        if let runLoop = tapRunLoop {
            CFRunLoopStop(runLoop)
        }

        // Clean up event tap
        if let source = runLoopSource, let runLoop = tapRunLoop {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
        }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        eventTap = nil
        runLoopSource = nil
        tapRunLoop = nil
        tapThread = nil

        isKeyDown = false
        hasPassedDebounce = false
        isRunning = false

        Logger.hotkey.info("Hotkey service stopped")
    }

    // MARK: - Private Methods

    /// Creates the CGEventTap and starts the dedicated thread.
    private func createAndStartEventTap() -> Bool {
        // Event mask for key down, key up, and flags changed (for modifier keys)
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                     (1 << CGEventType.keyUp.rawValue) |
                                     (1 << CGEventType.flagsChanged.rawValue)

        // Create the event tap
        // Using Unmanaged to pass self to the C callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: Self.eventTapCallback,
            userInfo: selfPtr
        ) else {
            Logger.hotkey.error("Failed to create CGEventTap")
            return false
        }

        eventTap = tap

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        // Start dedicated thread for the event tap
        tapThread = Thread { [weak self] in
            guard let self = self, let source = self.runLoopSource else { return }

            self.tapRunLoop = CFRunLoopGetCurrent()
            CFRunLoopAddSource(self.tapRunLoop!, source, .commonModes)

            // Enable the tap
            CGEvent.tapEnable(tap: tap, enable: true)

            // Run the loop
            CFRunLoopRun()
        }
        tapThread?.name = "com.whisperx.hotkey"
        tapThread?.qualityOfService = .userInteractive
        tapThread?.start()

        return true
    }

    /// Static callback function for CGEventTap.
    /// This is a C-style function pointer required by the CGEvent API.
    private static let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
        guard let userInfo = userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let service = Unmanaged<HotkeyService>.fromOpaque(userInfo).takeUnretainedValue()

        // Handle tap being disabled by the system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            service.handleTapDisabled()
            return Unmanaged.passUnretained(event)
        }

        // Handle regular key events (keyDown/keyUp)
        if type == .keyDown || type == .keyUp {
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

            guard !isRepeat else {
                return Unmanaged.passUnretained(event)
            }

            guard keyCode == service.activeKeyCode else {
                return Unmanaged.passUnretained(event)
            }

            let eventType = type == .keyDown ? "DOWN" : "UP"
            Logger.hotkey.info("🔑 Key \(eventType): keyCode=\(keyCode)")

            if type == .keyDown {
                service.handleKeyDown()
            } else {
                service.handleKeyUp()
            }

            return nil
        }

        // Handle modifier key events (flagsChanged) - for Option, Command, Shift, Control
        if type == .flagsChanged {
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

            guard keyCode == service.activeKeyCode else {
                return Unmanaged.passUnretained(event)
            }

            let flags = event.flags
            let isPressed = service.isModifierPressed(keyCode: keyCode, flags: flags)
            let eventType = isPressed ? "DOWN" : "UP"
            Logger.hotkey.info("🔑 Modifier \(eventType): keyCode=\(keyCode)")

            if isPressed {
                service.handleKeyDown()
            } else {
                service.handleKeyUp()
            }

            // Don't consume modifier events (let them pass through)
            return Unmanaged.passUnretained(event)
        }

        return Unmanaged.passUnretained(event)
    }

    /// Determines if a modifier key is pressed based on flags.
    private func isModifierPressed(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        switch keyCode {
        case 54, 55: // Right Command (54), Left Command (55)
            return flags.contains(.maskCommand)
        case 56, 60: // Left Shift (56), Right Shift (60)
            return flags.contains(.maskShift)
        case 58, 61: // Left Option (58), Right Option (61)
            return flags.contains(.maskAlternate)
        case 59, 62: // Left Control (59), Right Control (62)
            return flags.contains(.maskControl)
        case 57: // Caps Lock
            return flags.contains(.maskAlphaShift)
        case 63: // Fn key (legacy)
            return flags.contains(.maskSecondaryFn)
        default:
            return false
        }
    }

    /// Timestamp when key was pressed (for timing analysis)
    private var keyDownTime: Date?

    /// Handles key down event with debounce logic.
    private func handleKeyDown() {
        // Already down, ignore (shouldn't happen with repeat filtering)
        guard !isKeyDown else { return }
        isKeyDown = true
        hasPassedDebounce = false
        keyDownTime = Date()

        Logger.hotkey.info("Key down detected, starting debounce (100ms)")

        // Cancel any existing debounce
        debounceWorkItem?.cancel()

        // Start debounce timer on main queue
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Verify key is still held
            guard self.isKeyDown else {
                Logger.hotkey.debug("Key released before debounce completed")
                return
            }

            self.hasPassedDebounce = true
            Logger.hotkey.info("Debounce passed, triggering press")

            // Dispatch to main actor
            DispatchQueue.main.async {
                Task { @MainActor in
                    self.delegate?.hotkeyDidPress()
                }
            }
        }

        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.debounceInterval, execute: workItem)
    }

    /// Handles key up event.
    private func handleKeyUp() {
        guard isKeyDown else { return }
        isKeyDown = false

        // Calculate hold duration
        let holdDuration = keyDownTime.map { Date().timeIntervalSince($0) * 1000 } ?? 0
        Logger.hotkey.info("Key up after \(String(format: "%.0f", holdDuration))ms hold")

        // Cancel debounce if it hasn't fired yet
        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        if hasPassedDebounce {
            Logger.hotkey.info("Key released after debounce, triggering release")

            // Dispatch to main actor
            DispatchQueue.main.async {
                Task { @MainActor in
                    self.delegate?.hotkeyDidRelease()
                }
            }
        } else {
            Logger.hotkey.debug("Key released before debounce (\(String(format: "%.0f", holdDuration))ms < 100ms), ignoring")
        }

        hasPassedDebounce = false
        keyDownTime = nil
    }

    /// Handles the event tap being disabled by the system.
    private func handleTapDisabled() {
        Logger.hotkey.warning("Event tap disabled by system, attempting to re-enable")

        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}
