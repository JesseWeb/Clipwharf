import XCTest
@testable import ClipwharfCore

final class ClipSearchTests: XCTestCase {
    private func text(_ value: String) -> ClipItem {
        ClipItem(kind: .text, text: value, contentHash: "text-\(value)")
    }

    // MARK: - Text

    func testTextSearchIsCaseInsensitive() {
        let item = text("Hello World")
        XCTAssertTrue(item.matches(search: "hello"))
        XCTAssertTrue(item.matches(search: "WORLD"))
        XCTAssertTrue(item.matches(search: "hELLo wORLd"))
    }

    func testMultiWordSearchRequiresEveryTerm() {
        let item = text("Deploy the staging server")
        XCTAssertTrue(item.matches(search: "deploy server"))
        XCTAssertTrue(item.matches(search: "server staging deploy"))
        XCTAssertFalse(item.matches(search: "deploy production"))
        XCTAssertFalse(item.matches(search: "deploy server missing"))
    }

    func testEmptyAndWhitespaceQueriesMatchEverything() {
        let item = text("anything at all")
        XCTAssertTrue(item.matches(search: ""))
        XCTAssertTrue(item.matches(search: "   \n\t "))
    }

    func testTextSearchLooksAtFullTextNotJustTheTitle() {
        let item = text("first line\nneedle on the second line")
        XCTAssertEqual(item.displayTitle, "first line")
        XCTAssertTrue(item.matches(search: "needle"))
    }

    // MARK: - Images

    func testImageMatchesItsDisplayTitle() {
        let item = ClipItem(
            kind: .image,
            contentHash: "image",
            imageWidth: 1440,
            imageHeight: 900
        )
        XCTAssertTrue(item.matches(search: "Image"))
        XCTAssertTrue(item.matches(search: "1440"))
        XCTAssertTrue(item.matches(search: "1440 image"))
        XCTAssertFalse(item.matches(search: "screenshot"))
    }

    // MARK: - Files

    func testFileMatchesEveryFilenameEvenWhenTitleIsTruncated() {
        let item = ClipItem(
            kind: .files,
            fileURLs: ["/tmp/a.txt", "/tmp/b.txt", "/tmp/c.txt"],
            contentHash: "files"
        )
        XCTAssertEqual(item.displayTitle, "a.txt, b.txt +1 more")
        XCTAssertTrue(item.matches(search: "c.txt"))
        XCTAssertTrue(item.matches(search: "b.txt c.txt"))
        XCTAssertFalse(item.matches(search: "missing.txt"))
    }

    func testFileSearchIsCaseInsensitive() {
        let item = ClipItem(
            kind: .files,
            fileURLs: ["/tmp/Quarterly-Report.PDF"],
            contentHash: "file"
        )
        XCTAssertTrue(item.matches(search: "quarterly"))
        XCTAssertTrue(item.matches(search: "report.pdf"))
    }

    func testImageAndFileEntriesMatchEmptyQuery() {
        let image = ClipItem(kind: .image, contentHash: "image")
        let files = ClipItem(
            kind: .files,
            fileURLs: ["/tmp/notes.txt"],
            contentHash: "files"
        )
        XCTAssertTrue(image.matches(search: ""))
        XCTAssertTrue(files.matches(search: ""))
    }
}
