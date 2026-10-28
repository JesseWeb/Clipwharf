import AppKit
import ClipwharfCore

enum PasteboardWriter {
    enum WriteError: LocalizedError {
        case missingContent
        case unreadableImage

        var errorDescription: String? {
            switch self {
            case .missingContent:
                return "This entry no longer has any content to paste."
            case .unreadableImage:
                return "The saved image could not be read."
            }
        }
    }

    /// Put an entry back on the system pasteboard.
    static func write(_ item: ClipItem, from store: HistoryStore) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            guard let text = item.text, !text.isEmpty else { throw WriteError.missingContent }
            pasteboard.setString(text, forType: .string)

        case .image:
            guard let name = item.imageFileName,
                  let data = store.blobData(named: name),
                  let rep = NSBitmapImageRep(data: data) else {
                throw WriteError.unreadableImage
            }
            pasteboard.setData(data, forType: .png)
            if let tiff = rep.tiffRepresentation {
                pasteboard.setData(tiff, forType: .tiff)
            }

        case .files:
            let urls = (item.fileURLs ?? []).map { URL(fileURLWithPath: $0) }
            guard !urls.isEmpty else { throw WriteError.missingContent }
            pasteboard.writeObjects(urls as [NSURL])
        }
    }
}
