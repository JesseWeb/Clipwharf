import XCTest
@testable import ClipwharfCore

final class HistoryStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipwharfTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        directory = nil
    }

    private func makeStore(maxItems: Int = HistoryStore.defaultMaxItems) -> HistoryStore {
        HistoryStore(directory: directory, maxItems: maxItems)
    }

    private var blobsDirectory: URL {
        directory.appendingPathComponent(HistoryStore.blobsDirectoryName, isDirectory: true)
    }

    // MARK: - Capture

    func testCaptureKeepsNewestFirst() throws {
        let store = makeStore()

        XCTAssertNotNil(store.capture(CapturedClip(kind: .text, text: "first")))
        XCTAssertNotNil(store.capture(CapturedClip(kind: .text, text: "second")))
        XCTAssertEqual(store.items.map(\.text), ["second", "first"])
        XCTAssertEqual(store.items.map(\.kind), [.text, .text])
    }

    func testDuplicateMovesToTopWithoutAddingAnEntry() throws {
        let store = makeStore()

        store.capture(CapturedClip(kind: .text, text: "first"))
        store.capture(CapturedClip(kind: .text, text: "second"))

        let again = try XCTUnwrap(store.capture(CapturedClip(kind: .text, text: "first")))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.first?.id, again.id)
        XCTAssertEqual(store.items.map(\.text), ["first", "second"])
    }

    func testEmptyCapturesAreIgnored() {
        let store = makeStore()

        XCTAssertNil(store.capture(CapturedClip(kind: .text, text: "   \n  ")))
        XCTAssertNil(store.capture(CapturedClip(kind: .image, imageData: Data())))
        XCTAssertNil(store.capture(CapturedClip(kind: .files, fileURLs: [])))
        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - Pruning

    func testPruneKeepsOnlyNewestEntries() throws {
        let store = makeStore(maxItems: 2)

        store.capture(CapturedClip(kind: .image, imageData: Data([1, 2, 3])))
        store.capture(CapturedClip(kind: .text, text: "second"))
        store.capture(CapturedClip(kind: .text, text: "third"))

        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.map(\.text), ["third", "second"])

        // The pruned image blob is removed too.
        let blobs = try FileManager.default.contentsOfDirectory(atPath: blobsDirectory.path)
        XCTAssertTrue(blobs.isEmpty)
    }

    func testLimitIsAtLeastOne() {
        let store = makeStore(maxItems: 0)
        store.capture(CapturedClip(kind: .text, text: "first"))
        store.capture(CapturedClip(kind: .text, text: "second"))
        XCTAssertEqual(store.items.map(\.text), ["second"])
    }

    // MARK: - Persistence

    func testPersistenceRoundTripForTextImageAndFiles() throws {
        let store = makeStore()
        let imageData = Data([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x01, 0x02])
        let fileURL = URL(fileURLWithPath: "/tmp/Clippings/notes.txt")

        store.capture(CapturedClip(kind: .text, text: "hello"))
        store.capture(
            CapturedClip(kind: .image, imageData: imageData, imageWidth: 64, imageHeight: 32)
        )
        store.capture(CapturedClip(kind: .files, fileURLs: [fileURL]))

        XCTAssertTrue(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent(HistoryStore.indexFileName).path
        ))

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.items.count, 3)
        XCTAssertEqual(reloaded.items.first?.kind, .files)

        let image = try XCTUnwrap(reloaded.items.first(where: { $0.kind == .image }))
        XCTAssertEqual(image.imageWidth, 64)
        XCTAssertEqual(image.imageHeight, 32)
        XCTAssertEqual(
            reloaded.blobData(named: try XCTUnwrap(image.imageFileName)),
            imageData
        )

        let files = try XCTUnwrap(reloaded.items.first(where: { $0.kind == .files }))
        XCTAssertEqual(files.fileURLs, ["/tmp/Clippings/notes.txt"])
        XCTAssertEqual(files.displayTitle, "notes.txt")

        let text = try XCTUnwrap(reloaded.items.first(where: { $0.kind == .text }))
        XCTAssertEqual(text.text, "hello")
    }

    // MARK: - Pinboards

    func testPinningPersistsAndSurvivesReload() throws {
        let store = makeStore()
        let item = try XCTUnwrap(store.capture(CapturedClip(kind: .text, text: "keep me")))

        store.setPinned(true, for: item.id)
        XCTAssertTrue(store.items.first?.isPinned ?? false)
        XCTAssertEqual(store.pinnedItems.map(\.text), ["keep me"])

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.pinnedItems.map(\.text), ["keep me"])

        reloaded.setPinned(false, for: item.id)
        XCTAssertTrue(reloaded.pinnedItems.isEmpty)
        XCTAssertFalse(reloaded.isPinned(item.id))
    }

    func testPinnedEntriesAreNotPruned() throws {
        let store = makeStore(maxItems: 2)

        let pinned = try XCTUnwrap(store.capture(CapturedClip(kind: .text, text: "pinned")))
        store.setPinned(true, for: pinned.id)

        for index in 0..<5 {
            store.capture(CapturedClip(kind: .text, text: "clip \(index)"))
        }

        XCTAssertTrue(store.items.contains(where: { $0.id == pinned.id }))
        XCTAssertEqual(store.pinnedItems.count, 1)
        XCTAssertEqual(store.items.filter { !$0.isPinned }.count, 2)
    }

    func testRecaptureKeepsThePin() throws {
        let store = makeStore()
        let first = try XCTUnwrap(store.capture(CapturedClip(kind: .text, text: "same")))
        store.setPinned(true, for: first.id)

        store.capture(CapturedClip(kind: .text, text: "other"))
        let again = try XCTUnwrap(store.capture(CapturedClip(kind: .text, text: "same")))

        XCTAssertEqual(again.id, first.id)
        XCTAssertTrue(again.isPinned)
        XCTAssertEqual(store.items.first?.id, first.id)
    }

    func testSourceAppIsPersistedAndSearchable() throws {
        let store = makeStore()
        store.capture(
            CapturedClip(
                kind: .text,
                text: "hello",
                sourceBundleID: "com.google.Chrome",
                sourceAppName: "Google Chrome"
            )
        )

        let reloaded = makeStore()
        let item = try XCTUnwrap(reloaded.items.first)
        XCTAssertEqual(item.sourceAppName, "Google Chrome")
        XCTAssertTrue(item.matches(search: "chrome"))
        XCTAssertFalse(item.matches(search: "safari"))
    }

    // MARK: - Blob safety and display

    func testBlobLookupRejectsPathTraversal() {
        let store = makeStore()
        XCTAssertNil(store.blobURL(named: "../history.json"))
        XCTAssertNil(store.blobURL(named: "nested/file.png"))
        XCTAssertNil(store.blobURL(named: ""))
        XCTAssertNotNil(store.blobURL(named: "ok.png"))
    }

    func testDisplayTitles() {
        let text = ClipItem(kind: .text, text: "  Hello\tworld\nsecond line", contentHash: "a")
        XCTAssertEqual(text.displayTitle, "Hello world")

        let image = ClipItem(kind: .image, contentHash: "b", imageWidth: 800, imageHeight: 600)
        XCTAssertEqual(image.displayTitle, "Image · 800 × 600")

        let files = ClipItem(
            kind: .files,
            fileURLs: ["/tmp/a.txt", "/tmp/b.txt", "/tmp/c.txt"],
            contentHash: "c"
        )
        XCTAssertEqual(files.displayTitle, "a.txt, b.txt +1 more")
    }
}

final class ContentHasherTests: XCTestCase {
    func testSameContentHashIsStable() {
        let a = ContentHasher.hash(kind: .text, text: "hello")
        let b = ContentHasher.hash(kind: .text, text: "hello")
        XCTAssertEqual(a, b)
    }

    func testDifferentKindsAndContentDiffer() {
        let text = ContentHasher.hash(kind: .text, text: "hello")
        let image = ContentHasher.hash(kind: .image, text: "hello")
        let other = ContentHasher.hash(kind: .text, text: "hello!")
        XCTAssertNotEqual(text, image)
        XCTAssertNotEqual(text, other)
    }

    func testFileOrderDoesNotAffectHash() {
        let a = ContentHasher.hash(kind: .files, text: nil, fileURLs: [
            URL(fileURLWithPath: "/tmp/a"), URL(fileURLWithPath: "/tmp/b")
        ])
        let b = ContentHasher.hash(kind: .files, text: nil, fileURLs: [
            URL(fileURLWithPath: "/tmp/b"), URL(fileURLWithPath: "/tmp/a")
        ])
        XCTAssertEqual(a, b)
    }
}
