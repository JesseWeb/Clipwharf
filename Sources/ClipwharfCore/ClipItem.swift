import Foundation

// MARK: - Kind

/// The kinds of clipboard content Clipwharf stores.
public enum ClipKind: String, Codable, Sendable, CaseIterable {
    case text
    case link
    case image
    case files
    case color

    public var label: String {
        switch self {
        case .text: return "Text"
        case .link: return "Link"
        case .image: return "Image"
        case .files: return "File"
        case .color: return "Color"
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
    /// Plain text for `.text`, `.link`, and `.color` entries.
    public var text: String?
    /// File name inside the store's `Blobs` directory, for `.image` entries.
    public var imageFileName: String?
    /// Absolute paths of the referenced files, for `.files` entries.
    public var fileURLs: [String]?
    public var createdAt: Date
    public var contentHash: String
    public var imageWidth: Int?
    public var imageHeight: Int?

    /// Bundle identifier and display name of the app that was frontmost when
    /// the entry was copied. Used for the source badge on each card and as an
    /// extra search field.
    public var sourceBundleID: String?
    public var sourceAppName: String?

    /// Pinboards: pinned entries stay out of pruning and get their own tab.
    public var isPinned: Bool
    public var pinnedAt: Date?

    /// `#RRGGBB` for `.color` entries.
    public var colorHex: String?

    public init(
        id: UUID = UUID(),
        kind: ClipKind,
        text: String? = nil,
        imageFileName: String? = nil,
        fileURLs: [String]? = nil,
        createdAt: Date = Date(),
        contentHash: String,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        sourceBundleID: String? = nil,
        sourceAppName: String? = nil,
        isPinned: Bool = false,
        pinnedAt: Date? = nil,
        colorHex: String? = nil
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
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.isPinned = isPinned
        self.pinnedAt = pinnedAt
        self.colorHex = colorHex
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id, kind, text, imageFileName, fileURLs, createdAt, contentHash
        case imageWidth, imageHeight, sourceBundleID, sourceAppName
        case isPinned, pinnedAt, colorHex
    }

    /// Tolerant decoding so a history written by an older build still loads.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(ClipKind.self, forKey: .kind)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        fileURLs = try container.decodeIfPresent([String].self, forKey: .fileURLs)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        contentHash = try container.decode(String.self, forKey: .contentHash)
        imageWidth = try container.decodeIfPresent(Int.self, forKey: .imageWidth)
        imageHeight = try container.decodeIfPresent(Int.self, forKey: .imageHeight)
        sourceBundleID = try container.decodeIfPresent(String.self, forKey: .sourceBundleID)
        sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
    }

    // MARK: Display helpers

    public var fileNames: [String] {
        (fileURLs ?? []).map { URL(fileURLWithPath: $0).lastPathComponent }
    }

    public var displayTitle: String {
        switch kind {
        case .text, .link, .color:
            let normalized = (text ?? "")
                .replacingOccurrences(of: "\r\n", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return "Empty text" }
            if kind == .color { return colorHex ?? normalized }

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
            guard !names.isEmpty else { return "File" }
            if names.count == 1 { return names[0] }
            let head = names.prefix(2).joined(separator: ", ")
            return names.count > 2 ? "\(head) +\(names.count - 2) more" : head
        }
    }

    public var kindLabel: String {
        kind.label
    }

    /// Host of a `.link` entry, or nil when the text is not a URL.
    public var linkHost: String? {
        guard kind == .link, let text else { return nil }
        return URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines))?.host
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
    public var sourceBundleID: String?
    public var sourceAppName: String?
    public var colorHex: String?
    public let contentHash: String

    public init(
        kind: ClipKind,
        text: String? = nil,
        imageData: Data? = nil,
        fileURLs: [URL]? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        sourceBundleID: String? = nil,
        sourceAppName: String? = nil,
        colorHex: String? = nil
    ) {
        self.kind = kind
        self.text = text
        self.imageData = imageData
        self.fileURLs = fileURLs
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.colorHex = colorHex
        self.contentHash = ContentHasher.hash(
            kind: kind,
            text: text,
            imageData: imageData,
            fileURLs: fileURLs
        )
    }

    /// Classifies plain text as a color, a link, or plain text.
    public init(
        text: String,
        sourceBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hex = ClipClassifier.colorHex(in: trimmed)
        let kind: ClipKind = hex != nil
            ? .color
            : (ClipClassifier.isLink(trimmed) ? .link : .text)
        self.init(
            kind: kind,
            text: kind == .color ? (hex ?? text) : text,
            sourceBundleID: sourceBundleID,
            sourceAppName: sourceAppName,
            colorHex: hex
        )
    }

    public var isEmpty: Bool {
        switch kind {
        case .text, .link, .color:
            return (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .image:
            return imageData?.isEmpty ?? true
        case .files:
            return fileURLs?.isEmpty ?? true
        }
    }
}

// MARK: - Classification

/// Recognizes the text shapes that deserve their own card type.
public enum ClipClassifier {
    /// `#1A2B3C`, `1a2b3c` and `1A2B3C` are colors; a plain six-digit number
    /// such as `235442` stays text, which keeps verification codes out of the
    /// color swatches.
    public static func colorHex(in text: String) -> String? {
        let candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.contains(where: \.isWhitespace) else { return nil }

        let digits: Substring
        if candidate.hasPrefix("#") {
            digits = candidate.dropFirst()
        } else {
            digits = candidate[...]
        }

        guard digits.count == 6,
              digits.allSatisfy({ $0.isHexDigit }),
              candidate.hasPrefix("#") || digits.contains(where: { $0.isLetter })
        else { return nil }

        return "#" + digits.uppercased()
    }

    /// HTTP(S) URL on a single line.
    public static func isLink(_ text: String) -> Bool {
        let candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.contains(where: \.isWhitespace), candidate.count <= 2048 else {
            return false
        }
        let lower = candidate.lowercased()
        guard lower.hasPrefix("http://") || lower.hasPrefix("https://") else { return false }
        return URL(string: candidate)?.host?.isEmpty == false
    }
}

// MARK: - Stable content hashing

/// A small, dependency-free FNV-1a 64-bit hash.
///
/// Used only to collapse duplicate entries locally. It is not a security
/// primitive.
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
