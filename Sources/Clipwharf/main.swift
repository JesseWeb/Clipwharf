import AppKit

// A menu-bar-only AppKit application. AppKit owns the status item, hotkey, and
// pasteboard plumbing; SwiftUI hosts the history list.
let clipwharfApplication = NSApplication.shared
let clipwharfAppDelegate = AppDelegate()
clipwharfApplication.delegate = clipwharfAppDelegate
_ = clipwharfApplication.setActivationPolicy(.accessory)
clipwharfApplication.run()
