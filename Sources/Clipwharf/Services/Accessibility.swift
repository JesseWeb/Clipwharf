import AppKit
import ApplicationServices
import Carbon

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Ask macOS to add Clipwharf to the Accessibility list. The system shows
    /// its own prompt with a shortcut to System Settings.
    @discardableResult
    static func requestTrustPrompt() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

/// Sends the system paste shortcut to whichever app is frontmost.
enum KeyboardSynth {
    static func sendCommandV() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }

        let key = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)
    }
}
