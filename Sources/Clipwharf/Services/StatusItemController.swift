import AppKit
import ClipwharfCore

/// Owns the menu-bar icon. Left-click opens history; right-click shows a short
/// menu with the login item, the language picker, and About.
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
    private var l10n: Localization { .shared }

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
            button.toolTip = l10n.t("tooltip")
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
        button.toolTip = l10n.t("tooltip")

        let menu = NSMenu()

        let open = NSMenuItem(
            title: l10n.t("menu.open"),
            action: #selector(openAction),
            keyEquivalent: ""
        )
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let launchAtLogin = NSMenuItem(
            title: l10n.t("menu.launchAtLogin"),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLogin.state = LaunchAtLogin.isEnabled ? .on : .off
        launchAtLogin.target = self
        menu.addItem(launchAtLogin)

        let fixAccess = NSMenuItem(
            title: l10n.t("menu.fixAccess"),
            action: #selector(fixAccessibility),
            keyEquivalent: ""
        )
        fixAccess.target = self
        menu.addItem(fixAccess)

        menu.addItem(languageItem())

        menu.addItem(.separator())

        let about = NSMenuItem(
            title: l10n.t("menu.about"),
            action: #selector(aboutAction),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(
            title: l10n.t("menu.quit"),
            action: #selector(quitAction),
            keyEquivalent: "q"
        )
        quit.keyEquivalentModifierMask = [.command]
        quit.target = self
        menu.addItem(quit)

        _ = menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 4),
            in: button
        )
    }

    /// Language submenu: "System" plus every translated language.
    private func languageItem() -> NSMenuItem {
        let language = NSMenuItem(title: l10n.t("menu.language"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let system = NSMenuItem(
            title: "\(l10n.t("menu.language.system")) — \(AppLanguage.effective(selection: .system).displayName)",
            action: #selector(selectLanguage(_:)),
            keyEquivalent: ""
        )
        system.representedObject = AppLanguage.system.rawValue
        system.state = l10n.selection == .system ? .on : .off
        system.target = self
        submenu.addItem(system)

        submenu.addItem(.separator())

        for appLanguage in AppLanguage.selectable where appLanguage != .system {
            let item = NSMenuItem(
                title: appLanguage.displayName,
                action: #selector(selectLanguage(_:)),
                keyEquivalent: ""
            )
            item.representedObject = appLanguage.rawValue
            item.state = l10n.selection == appLanguage ? .on : .off
            item.target = self
            submenu.addItem(item)
        }

        language.submenu = submenu
        return language
    }

    @objc private func openAction() { onOpen?() }
    @objc private func aboutAction() { onAbout?() }
    @objc private func quitAction() { onQuit?() }
    @objc private func fixAccessibility() { onFixAccessibility?() }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let language = AppLanguage(rawValue: raw) else { return }
        l10n.setLanguage(language)
        statusItem.button?.toolTip = l10n.t("tooltip")
    }

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
