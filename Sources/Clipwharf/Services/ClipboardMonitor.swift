import AppKit
import ClipwharfCore

/// Polls `NSPasteboard` for new text, images, and file references.
///
/// macOS has no clipboard-change notification, so a 0.5 s poll is the standard
/// low-cost approach. The monitor remembers the last change count so its own
/// pasteboard writes (from Clipwharf) are not captured again.
final class ClipboardMonitor {
    var onCapture: ((CapturedClip) -> Void)?

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

        if let clip = readClip() {
            onCapture?(clip)
        }
    }

    private func readClip() -> CapturedClip? {
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
                return CapturedClip(kind: .files, fileURLs: urls)
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
                imageHeight: rep?.pixelsHigh
            )
        }

        if let tiff = pasteboard.data(forType: .tiff),
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            return CapturedClip(
                kind: .image,
                imageData: png,
                imageWidth: rep.pixelsWide,
                imageHeight: rep.pixelsHigh
            )
        }

        if let string = pasteboard.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return CapturedClip(kind: .text, text: string)
            }
        }

        return nil
    }
}
