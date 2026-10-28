import AppKit
import SwiftUI
import ClipwharfCore

/// Borderless panel that can still become key so arrow keys and Return work.
private final class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Hosts the SwiftUI history list in a floating panel.
final class PanelController: NSObject, NSWindowDelegate {
    var onPaste: ((ClipItem) -> Void)?
    var onClose: (() -> Void)?

    private let store: HistoryStore
    private let model = PanelModel()
    private var panel: HistoryPanel?
    private var keyMonitor: Any?

    init(store: HistoryStore) {
        self.store = store
        super.init()
        model.onActivate = { [weak self] item in
            self?.onPaste?(item)
        }
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func show() {
        model.reload(store.items)

        let panel = panel ?? makePanel()
        self.panel = panel
        position(panel)

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        installKeyMonitor()
    }

    func hide() {
        removeKeyMonitor()
        panel?.orderOut(nil)
    }

    // MARK: - Panel construction

    private func makePanel() -> HistoryPanel {
        let panel = HistoryPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        panel.contentViewController = NSHostingController(rootView: PanelView(model: model))
        return panel
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            panel.center()
            return
        }
        let origin = NSPoint(
            x: visible.midX - panel.frame.width / 2,
            y: visible.midY - panel.frame.height / 2 + 70
        )
        panel.setFrameOrigin(origin)
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }

            switch event.keyCode {
            case 126: // up arrow
                self.model.moveSelection(by: -1)
                return nil
            case 125: // down arrow
                self.model.moveSelection(by: 1)
                return nil
            case 36, 76: // return, keypad enter
                self.model.activateSelection()
                return nil
            case 53: // escape
                self.onClose?()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
