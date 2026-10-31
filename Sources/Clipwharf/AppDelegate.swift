import AppKit
import ClipwharfCore

/// Shorthand for the shared localization table.
private let L10n = Localization.shared

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
            self?.presentError(L10n.t("alert.error.loginItem"), error)
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
            presentError(L10n.t("alert.error.restore"), error)
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
        alert.messageText = L10n.t("alert.access.title")
        alert.informativeText = L10n.t("alert.access.body")
        alert.addButton(withTitle: L10n.t("alert.fix"))
        alert.addButton(withTitle: L10n.t("alert.notNow"))

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
            alert.messageText = L10n.t("alert.hotkey.title")
            alert.informativeText = L10n.t("alert.hotkey.body")
            alert.addButton(withTitle: L10n.t("alert.ok"))
            alert.runModal()
        }
    }

    private func showLoginItemApprovalNotice() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.t("alert.login.title")
        alert.informativeText = L10n.t("alert.login.body")
        alert.addButton(withTitle: L10n.t("alert.openSettings"))
        alert.addButton(withTitle: L10n.t("alert.later"))

        if alert.runModal() == .alertFirstButtonReturn {
            LaunchAtLogin.openLoginItemsSettings()
        }
    }

    private func presentError(_ message: String, _ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: L10n.t("alert.ok"))
        alert.runModal()
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Clipwharf"
        alert.informativeText = L10n.t(
            "about.body",
            L10n.t("about.tagline"),
            ClipwharfBuildInfo.version,
            ClipwharfBuildInfo.license,
            ClipwharfBuildInfo.sourceURL
        )
        alert.addButton(withTitle: L10n.t("about.done"))
        alert.runModal()
    }
}
