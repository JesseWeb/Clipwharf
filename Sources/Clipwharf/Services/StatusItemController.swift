import AppKit

/// Owns the menu-bar icon. Left-click opens history; right-click shows a
/// short menu. There are deliberately no preference panes.
final class StatusItemController: NSObject {
    var onOpen: (() -> Void)?
    var onAbout: (() -> Void)?
    var onQuit: (() -> Void)?
    /// Called when toggling the login item fails, so the app can explain why.
    var onLaunchAtLoginError: ((Error) -> Void)?
    /// Called when the system still needs the user to approve the login item.
    var onLaunchAtLoginNeedsApproval: (() -> Void)?
    /// Clears the stale Accessibility grant and prompts again.
    var onFixAccessibility: (() -> Void)?

    private let statusItem: NSStatusItem

    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "Clipwharf")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            _ = button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Clipwharf — clipboard history (⌘⇧V)"
        }
    }

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu(from: sender)
        } else {
            onOpen?()
        }
    }

    private func showMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()

        let open = NSMenuItem(title: "Open History (⌘⇧V)", action: #selector(openAction), keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let launchAtLogin = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLogin.state = LaunchAtLogin.isEnabled ? .on : .off
        launchAtLogin.target = self
        menu.addItem(launchAtLogin)

        let fixAccess = NSMenuItem(
            title: "Fix Accessibility Permission…",
            action: #selector(fixAccessibility),
            keyEquivalent: ""
        )
        fixAccess.target = self
        menu.addItem(fixAccess)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About Clipwharf", action: #selector(aboutAction), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit Clipwharf", action: #selector(quitAction), keyEquivalent: "q")
        quit.keyEquivalentModifierMask = [.command]
        quit.target = self
        menu.addItem(quit)

        _ = menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 4),
            in: button
        )
    }

    @objc private func openAction() { onOpen?() }
    @objc private func aboutAction() { onAbout?() }
    @objc private func quitAction() { onQuit?() }
    @objc private func fixAccessibility() { onFixAccessibility?() }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
            if LaunchAtLogin.needsApproval {
                onLaunchAtLoginNeedsApproval?()
            }
        } catch {
            onLaunchAtLoginError?(error)
        }
    }
}
