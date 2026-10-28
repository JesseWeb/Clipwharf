import AppKit
import Carbon

/// Registers the global ⌘⇧V shortcut with Carbon's hotkey API.
///
/// Carbon is still the only system API for a true global hotkey that does not
/// require an event tap or accessibility permission.
final class HotKeyManager {
    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    @discardableResult
    func register() -> Bool {
        guard hotKeyRef == nil else { return true }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.fire()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard handlerStatus == noErr else { return false }

        // "CLPW"
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C_5057), id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            if let handler = handlerRef {
                RemoveEventHandler(handler)
                handlerRef = nil
            }
            return false
        }
        return true
    }

    func unregister() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
        }
        if let handler = handlerRef {
            RemoveEventHandler(handler)
            handlerRef = nil
        }
    }

    deinit {
        unregister()
    }

    private func fire() {
        onHotKey?()
    }
}
