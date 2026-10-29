import AppKit
import ClipwharfCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store: HistoryStore
    private let panelController: PanelController
    private let monitor = ClipboardMonitor()
    private let hotKeyManager = HotKeyManager()

    private var statusController: StatusItemController?
    private var previousApp: NSRunningApplication?
    private var didShowHotKeyWarning = false
    private var didShowAccessibilityNotice = false

    override init() {
        let store = HistoryStore()
        self.store = store
        self.panelController = PanelController(store: store)
        super.init()
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = NSApp.setActivationPolicy(.accessory)
        panelController.onPaste = { [weak self] item in
            self?.paste(item)
        }
        panelController.onClose = { [weak self] in
            self?.closePanel()
        }

        monitor.onCapture = { [weak self] clip in
            _ = self?.store.capture(clip)
        }
        monitor.start()

        let statusController = StatusItemController()
        statusController.onOpen = { [weak self] in self?.togglePanel() }
        statusController.onAbout = { [weak self] in self?.showAbout() }
        statusController.onQuit = { NSApp.terminate(nil) }
        statusController.onLaunchAtLoginError = { [weak self] error in
            self?.presentError("Could not update the login item", error)
        }
        statusController.onLaunchAtLoginNeedsApproval = { [weak self] in
            self?.showLoginItemApprovalNotice()
        }
        statusController.onFixAccessibility = { [weak self] in
            self?.repairAccessibilityPermission()
        }
        self.statusController = statusController

        hotKeyManager.onHotKey = { [weak self] in self?.togglePanel() }
        if !hotKeyManager.register() {
            showHotKeyWarningOnce()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        hotKeyManager.unregister()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { togglePanel() }
        return true
    }

    // MARK: - Panel

    private func togglePanel() {
        if panelController.isVisible {
            closePanel()
            return
        }

        let front = NSWorkspace.shared.frontmostApplication
        if front?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previousApp = front
        }
        panelController.show()
    }

    private func closePanel() {
        panelController.hide()
        if let previousApp {
            _ = previousApp.activate(options: [.activateIgnoringOtherApps])
        }
    }

    // MARK: - Paste

    private func paste(_ item: ClipItem) {
        let target = previousApp
        panelController.hide()

        do {
            try PasteboardWriter.write(item, from: store)
            monitor.noteOwnWrite()
        } catch {
            presentError("Could not restore this clip", error)
            return
        }

        guard let target,
              target.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            // Nothing to paste into; the entry is on the clipboard.
            closePanel()
            return
        }

        guard AccessibilityPermission.isTrusted else {
            if showAccessibilityNotice() {
                _ = target.activate(options: [.activateIgnoringOtherApps])
            }
            return
        }

        _ = target.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            KeyboardSynth.sendCommandV()
        }
    }

    // MARK: - Alerts

    /// Returns true when the target app should be re-activated afterwards.
    private func showAccessibilityNotice() -> Bool {
        guard !didShowAccessibilityNotice else { return true }
        didShowAccessibilityNotice = true

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Clipwharf needs Accessibility access to auto-paste"
        alert.informativeText = """
        The clip is on your clipboard — press ⌘V to paste it now.

        If System Settings already shows Clipwharf switched on, that grant belongs \
        to an older build: rebuilding the app gives it a new code identity. \
        Use “Fix Permission…” to clear the stale entry and grant access again.
        """
        alert.addButton(withTitle: "Fix Permission…")
        alert.addButton(withTitle: "Not Now")

        if alert.runModal() == .alertFirstButtonReturn {
            repairAccessibilityPermission()
            return false
        }
        return true
    }

    /// Clears the stale Accessibility record and asks for a fresh grant.
    func repairAccessibilityPermission() {
        _ = AccessibilityPermission.resetGrant()
        _ = AccessibilityPermission.requestTrustPrompt()
        AccessibilityPermission.openSettings()
    }

    private func showHotKeyWarningOnce() {
        guard !didShowHotKeyWarning else { return }
        didShowHotKeyWarning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "⌘⇧V is already in use"
            alert.informativeText = """
            Another app has claimed the global shortcut, so Clipwharf could not \
            register it. You can still open history from the paperclip menu-bar icon.
            """
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showLoginItemApprovalNotice() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Approve Clipwharf in Login Items"
        alert.informativeText = """
        macOS added Clipwharf to your login items but needs you to allow it.

        Turn on Clipwharf under System Settings → General → Login Items.
        """
        alert.addButton(withTitle: "Open Settings…")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            LaunchAtLogin.openLoginItemsSettings()
        }
    }

    private func presentError(_ message: String, _ error: Error) {        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Clipwharf"
        alert.informativeText = """
        \(ClipwharfBuildInfo.tagline)

        Version \(ClipwharfBuildInfo.version) · \(ClipwharfBuildInfo.license)
        Free and local. No accounts, no cloud, no tracking.

        Source: \(ClipwharfBuildInfo.sourceURL)
        """
        alert.addButton(withTitle: "Done")
        alert.runModal()
    }
}
