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

    /// Opens System Settings → Privacy & Security → Accessibility.
    static func openSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Clears the stale TCC record for this bundle identifier.
    ///
    /// Ad-hoc signed builds get a new code identity every time the binary is
    /// rebuilt, so the entry System Settings keeps is for the *previous*
    /// binary: it can look enabled while macOS still refuses the running copy.
    /// Resetting the record and granting again fixes that. Returns true when
    /// `tccutil` ran successfully.
    @discardableResult
    static func resetGrant(bundleID: String = Bundle.main.bundleIdentifier ?? "dev.clipwharf.Clipwharf") -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleID]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
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
