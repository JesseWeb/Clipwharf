import Foundation

/// Local JSON-backed clipboard history.
///
/// Layout:
///   Application Support/Clipwharf/history.json   — metadata index
///   Application Support/Clipwharf/Blobs/         — PNG payloads
///
/// The store is deliberately simple and main-thread-oriented: captures happen
/// on a short poll, and the index is small. Image bytes are kept out of the
/// JSON document so screenshots do not bloat every save.
public final class HistoryStore {
    public static let indexFileName = "history.json"
    public static let blobsDirectoryName = "Blobs"
    public static let defaultMaxItems = 200

    public let directory: URL
    public let maxItems: Int
    public private(set) var items: [ClipItem] = []
    public private(set) var storageError: String?

    private let fileManager: FileManager
    private let blobsDirectory: URL
    private let indexURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private struct HistoryFile: Codable {
        var version: Int
        var items: [ClipItem]
    }

    public init(
        directory: URL? = nil,
        maxItems: Int = HistoryStore.defaultMaxItems,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.maxItems = max(1, maxItems)
        self.directory = directory ?? AppPaths.defaultDirectory(fileManager: fileManager)
        self.blobsDirectory = self.directory.appendingPathComponent(Self.blobsDirectoryName, isDirectory: true)
        self.indexURL = self.directory.appendingPathComponent(Self.indexFileName, isDirectory: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        createDirectoriesIfNeeded()
        load()
    }

    // MARK: - Capture

    /// Insert a fresh pasteboard read at the top of the history.
    ///
    /// An entry with identical content is moved to the top instead of being
    /// duplicated. Returns `nil` for empty content or a failed blob write.
    @discardableResult
    public func capture(_ clip: CapturedClip) -> ClipItem? {
        guard !clip.isEmpty else { return nil }

        if let existingIndex = items.firstIndex(where: { $0.contentHash == clip.contentHash }) {
            var existing = items.remove(at: existingIndex)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
            persist()
            return existing
        }

        let id = UUID()
        var imageFileName: String?

        if let imageData = clip.imageData, !imageData.isEmpty {
            let name = "\(id.uuidString).png"
            do {
                try imageData.write(to: blobsDirectory.appendingPathComponent(name), options: .atomic)
                imageFileName = name
            } catch {
                storageError = "Could not save image: \(error.localizedDescription)"
                return nil
            }
        }

        let item = ClipItem(
            id: id,
            kind: clip.kind,
            text: clip.text,
            imageFileName: imageFileName,
            fileURLs: clip.fileURLs?.map(\.path),
            createdAt: Date(),
            contentHash: clip.contentHash,
            imageWidth: clip.imageWidth,
            imageHeight: clip.imageHeight
        )

        items.insert(item, at: 0)
        pruneIfNeeded()
        persist()
        return item
    }

    // MARK: - Blob access

    public func blobURL(named name: String) -> URL? {
        guard !name.isEmpty else { return nil }
        // Never allow a crafted history entry to escape the Blobs directory.
        guard name == (name as NSString).lastPathComponent else { return nil }
        return blobsDirectory.appendingPathComponent(name)
    }

    public func blobData(named name: String) -> Data? {
        guard let url = blobURL(named: name) else { return nil }
        return try? Data(contentsOf: url)
    }

    // MARK: - Persistence

    private func createDirectoriesIfNeeded() {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: blobsDirectory, withIntermediateDirectories: true)
        } catch {
            storageError = "Could not create storage folder: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: indexURL.path) else { return }
        do {
            let data = try Data(contentsOf: indexURL)
            let file = try decoder.decode(HistoryFile.self, from: data)
            items = file.items.sorted { $0.createdAt > $1.createdAt }
            let didSanitize = sanitizeLoadedItems()
            let didPrune = pruneIfNeeded()
            if didSanitize || didPrune {
                persist()
            }
        } catch {
            storageError = "Could not read history: \(error.localizedDescription)"
        }
    }

    /// Drop duplicate or unreadable entries left by an interrupted write.
    /// Returns true when an entry was removed.
    @discardableResult
    private func sanitizeLoadedItems() -> Bool {
        var cleaned: [ClipItem] = []
        var seenHashes = Set<String>()
        var removed: [ClipItem] = []

        for item in items {
            guard !item.contentHash.isEmpty, seenHashes.insert(item.contentHash).inserted else {
                removed.append(item)
                continue
            }

            let isUsable: Bool
            switch item.kind {
            case .text:
                isUsable = !(item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .image:
                if let name = item.imageFileName, blobURL(named: name) != nil {
                    isUsable = fileManager.fileExists(atPath: blobsDirectory.appendingPathComponent(name).path)
                } else {
                    isUsable = false
                }
            case .files:
                isUsable = !(item.fileURLs ?? []).isEmpty
            }

            if isUsable {
                cleaned.append(item)
            } else {
                removed.append(item)
            }
        }

        items = cleaned
        deleteBlobs(for: removed)
        return !removed.isEmpty
    }

    private func persist() {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let file = HistoryFile(version: 1, items: items)
            let data = try encoder.encode(file)
            try data.write(to: indexURL, options: .atomic)
            if storageError != nil {
                storageError = nil
            }
        } catch {
            storageError = "Could not save history: \(error.localizedDescription)"
        }
    }

    // MARK: - Pruning

    /// Keep the newest `maxItems` entries and remove older blobs.
    /// Returns true when anything was removed.
    @discardableResult
    private func pruneIfNeeded() -> Bool {
        guard items.count > maxItems else { return false }
        let removed = Array(items[maxItems...])
        items = Array(items.prefix(maxItems))
        deleteBlobs(for: removed)
        return true
    }

    private func deleteBlobs(for items: [ClipItem]) {
        for item in items {
            if let name = item.imageFileName, let url = blobURL(named: name) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
