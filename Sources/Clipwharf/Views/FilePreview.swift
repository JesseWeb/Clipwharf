import AppKit
import QuickLookThumbnailing
import SwiftUI

/// A QuickLook thumbnail for a file on disk, the same way Finder previews it.
///
/// Images, PDFs, videos, Keynote/Pages files and other previewable types render
/// their first page; anything QuickLook cannot render falls back to the file
/// icon from `NSWorkspace`.
struct FileThumbnail: View {
    let url: URL
    /// Requested size in points. QuickLook renders at this size times the
    /// screen scale, so 200×150 stays sharp on Retina displays.
    var pointSize: CGSize = CGSize(width: 200, height: 150)

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .task(id: url.path) {
            await load()
        }
    }

    private func load() async {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: pointSize,
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: .thumbnail
        )

        if let representation = try? await QLThumbnailGenerator.shared
            .generateBestRepresentation(for: request) {
            image = representation.nsImage
            return
        }

        // Not previewable (or unreadable): show the file's icon instead.
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = pointSize
        image = icon
    }
}
