import Foundation

// MARK: - Kind

/// The kinds of clipboard content Clipwharf stores.
public enum ClipKind: String, Codable, Sendable {
    case text
    case image
    case files

    public var label: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .files: return "Files"
        }
    }
}

// MARK: - Item

/// One saved clipboard entry.
///
/// Images live in a separate blob file; this struct is the small JSON record
/// that points at it. File entries store absolute paths as strings.
public struct ClipItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var kind: ClipKind
    /// Plain text for `.text` entries.
    public var text: String?
    /// File name inside the store's `Blobs` directory, for `.image` entries.
    public var imageFileName: String?
    /// Absolute paths of the referenced files, for `.files` entries.
    public var fileURLs: [String]?
    public var createdAt: Date
    public var contentHash: String
    public var imageWidth: Int?
    public var imageHeight: Int?

    public init(
        id: UUID = UUID(),
        kind: ClipKind,
        text: String? = nil,
        imageFileName: String? = nil,
        fileURLs: [String]? = nil,
        createdAt: Date = Date(),
        contentHash: String,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageFileName = imageFileName
        self.fileURLs = fileURLs
        self.createdAt = createdAt
        self.contentHash = contentHash
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }

    // MARK: Display helpers

    public var fileNames: [String] {
        (fileURLs ?? []).map { URL(fileURLWithPath: $0).lastPathComponent }
    }

    public var displayTitle: String {
        switch kind {
        case .text:
            let normalized = (text ?? "")
                .replacingOccurrences(of: "\r\n", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return "Empty text" }

            let firstLine = normalized
                .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init) ?? normalized
            let cleaned = firstLine
                .replacingOccurrences(of: "\t", with: " ")
                .trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { return "Whitespace" }
            return cleaned.count > 160 ? String(cleaned.prefix(160)) + "…" : cleaned

        case .image:
            if let width = imageWidth, let height = imageHeight {
                return "Image · \(width) × \(height)"
            }
            return "Image"

        case .files:
            let names = fileNames
            guard !names.isEmpty else { return "Files" }
            if names.count == 1 { return names[0] }
            let head = names.prefix(2).joined(separator: ", ")
            return names.count > 2 ? "\(head) +\(names.count - 2) more" : head
        }
    }

    public var kindLabel: String {
        kind.label
    }
}

// MARK: - Captured data

/// A fresh read from `NSPasteboard`, before it becomes a persisted `ClipItem`.
public struct CapturedClip: Sendable {
    public var kind: ClipKind
    public var text: String?
    public var imageData: Data?
    public var fileURLs: [URL]?
    public var imageWidth: Int?
    public var imageHeight: Int?
    public let contentHash: String

    public init(
        kind: ClipKind,
        text: String? = nil,
        imageData: Data? = nil,
        fileURLs: [URL]? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil
    ) {
        self.kind = kind
        self.text = text
        self.imageData = imageData
        self.fileURLs = fileURLs
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.contentHash = ContentHasher.hash(
            kind: kind,
            text: text,
            imageData: imageData,
            fileURLs: fileURLs
        )
    }

    public var isEmpty: Bool {
        switch kind {
        case .text:
            return (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .image:
            return imageData?.isEmpty ?? true
        case .files:
            return fileURLs?.isEmpty ?? true
        }
    }
}

// MARK: - Stable content hashing

/// A small, dependency-free FNV-1a 64-bit hash.
///
/// Used only to collapse consecutive duplicate entries locally. It is not a
/// security primitive.
public enum ContentHasher {
    public static func hash(
        kind: ClipKind,
        text: String?,
        imageData: Data? = nil,
        fileURLs: [URL]? = nil
    ) -> String {
        var value: UInt64 = 0xcbf2_9ce4_8422_2325
        let prime: UInt64 = 0x0000_0100_0000_01b3

        func feed(_ byte: UInt8) {
            value ^= UInt64(byte)
            value = value &* prime
        }

        func feed(_ data: Data) {
            for byte in data { feed(byte) }
        }

        func feed(_ string: String) {
            for byte in string.utf8 { feed(byte) }
        }

        feed(kind.rawValue)
        feed(UInt8(0xff))
        if let text { feed(text) }
        feed(UInt8(0xfe))
        if let imageData { feed(imageData) }
        feed(UInt8(0xfd))
        if let fileURLs {
            for path in fileURLs.map(\.path).sorted() {
                feed(path)
                feed(UInt8(0x00))
            }
        }

        return String(format: "%016llx", value)
    }
}
