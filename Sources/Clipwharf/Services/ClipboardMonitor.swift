import AppKit
import ClipwharfCore

/// Polls `NSPasteboard` for new text, images, links, colors, and files.
///
/// macOS has no clipboard-change notification, so a 0.5 s poll is the standard
/// low-cost approach. The monitor remembers the last change count so its own
/// pasteboard writes (from Clipwharf) are not captured again.
final class ClipboardMonitor {
    var onCapture: ((CapturedClip) -> Void)?

    /// Apps that only ever put secrets on the pasteboard. Copied content from
    /// these is skipped, the same way Paste ignores password managers.
    static let excludedBundleIdentifiers: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass",
        "com.dashlane.dashlanephonefinal",
        "com.apple.keychainaccess",
        "com.apple.Passwords",
        "com.keepersecurity.passwordmanager.mac"
    ]

    private let pasteboard: NSPasteboard
    private var timer: Timer?
    private var lastChangeCount: Int

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Call after Clipwharf writes to the pasteboard so the write is ignored.
    func noteOwnWrite() {
        lastChangeCount = pasteboard.changeCount
    }

    private func poll() {
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        let source = currentSource()
        if let bundleID = source.bundleID,
           Self.excludedBundleIdentifiers.contains(bundleID) {
            return
        }

        if let clip = readClip(source: source) {
            onCapture?(clip)
        }
    }

    /// The app that was frontmost when the pasteboard changed.
    ///
    /// The panel itself can be frontmost when the user re-copies something from
    /// Clipwharf, so Clipwharf is reported as "no source" rather than being
    /// attributed to the entry.
    private func currentSource() -> (bundleID: String?, name: String?) {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return (nil, nil)
        }
        return (app.bundleIdentifier, app.localizedName)
    }

    private func readClip(source: (bundleID: String?, name: String?)) -> CapturedClip? {
        // Files first: Finder puts both file URLs and a text representation on
        // the pasteboard, and the file reference is the more useful entry.
        if let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) {
            let urls: [URL] = objects.compactMap { object -> URL? in
                guard let nsURL = object as? NSURL else { return nil }
                return nsURL as URL
            }.filter(\.isFileURL)
            if !urls.isEmpty {
                return CapturedClip(
                    kind: .files,
                    fileURLs: urls,
                    sourceBundleID: source.bundleID,
                    sourceAppName: source.name
                )
            }
        }

        // Images: prefer PNG, convert TIFF-only sources (e.g. screenshots from
        // some apps) so the stored blob is always viewable.
        if let png = pasteboard.data(forType: .png), !png.isEmpty {
            let rep = NSBitmapImageRep(data: png)
            return CapturedClip(
                kind: .image,
                imageData: png,
                imageWidth: rep?.pixelsWide,
                imageHeight: rep?.pixelsHigh,
                sourceBundleID: source.bundleID,
                sourceAppName: source.name
            )
        }

        if let tiff = pasteboard.data(forType: .tiff),
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            return CapturedClip(
                kind: .image,
                imageData: png,
                imageWidth: rep.pixelsWide,
                imageHeight: rep.pixelsHigh,
                sourceBundleID: source.bundleID,
                sourceAppName: source.name
            )
        }

        if let string = pasteboard.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                // Classifies colors and links, otherwise stays plain text.
                return CapturedClip(
                    text: string,
                    sourceBundleID: source.bundleID,
                    sourceAppName: source.name
                )
            }
        }

        return nil
    }
}
