import AppKit
import SwiftUI
import ClipwharfCore

/// Borderless panel that can still become key so arrow keys and Return work.
private final class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Hosts the SwiftUI history strip in a floating panel pinned to the bottom of
/// the screen, the way Paste lays out its clipboard history.
final class PanelController: NSObject, NSWindowDelegate {
    var onPaste: ((ClipItem) -> Void)?
    var onClose: (() -> Void)?

    private let store: HistoryStore
    private let model: PanelModel
    private var panel: HistoryPanel?
    private var keyMonitor: Any?

    init(store: HistoryStore) {
        self.store = store
        self.model = PanelModel(store: store)
        super.init()
        model.onActivate = { [weak self] item in
            self?.onPaste?(item)
        }
        model.onPinChange = { [weak self] item, pinned in
            guard let self else { return }
            _ = self.store.setPinned(pinned, for: item.id)
            self.model.applyStoreItems(self.store.items)
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
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: PanelLayout.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        panel.contentViewController = NSHostingController(rootView: PanelView(model: model))
        return panel
    }

    /// Full width of the active screen, flush with the bottom of the visible area.
    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            panel.center()
            return
        }
        let frame = NSRect(
            x: visible.minX,
            y: visible.minY,
            width: visible.width,
            height: PanelLayout.height
        )
        panel.setFrame(frame, display: false)
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }

            switch event.keyCode {
            case 123, 126: // left arrow, up arrow
                self.model.moveSelection(by: -1)
                return nil
            case 124, 125: // right arrow, down arrow
                self.model.moveSelection(by: 1)
                return nil
            case 36, 76: // return, keypad enter
                self.model.activateSelection()
                return nil
            case 35 where event.modifierFlags.contains(.command): // ⌘P
                self.model.togglePinSelection()
                return nil
            case 18 where event.modifierFlags.contains(.command): // ⌘1 history
                self.model.tab = .history
                return nil
            case 19 where event.modifierFlags.contains(.command): // ⌘2 pinned
                self.model.tab = .pinned
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
