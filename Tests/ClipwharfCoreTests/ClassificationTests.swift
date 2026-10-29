import XCTest
@testable import ClipwharfCore

final class ClassificationTests: XCTestCase {
    // MARK: - Colors

    func testHashPrefixedHexIsAColor() {
        XCTAssertEqual(ClipClassifier.colorHex(in: "#1A2B3C"), "#1A2B3C")
        XCTAssertEqual(ClipClassifier.colorHex(in: "  #1a2b3c  "), "#1A2B3C")
    }

    func testBareHexWithLettersIsAColor() {
        XCTAssertEqual(ClipClassifier.colorHex(in: "1a2b3c"), "#1A2B3C")
        XCTAssertEqual(ClipClassifier.colorHex(in: "ABCDEF"), "#ABCDEF")
    }

    func testBareDigitsStayText() {
        XCTAssertNil(ClipClassifier.colorHex(in: "235442"),
                     "A six-digit verification code must not become a swatch")
    }

    func testShorthandAndSurroundedCodesStayText() {
        XCTAssertNil(ClipClassifier.colorHex(in: "#FFF"))
        XCTAssertNil(ClipClassifier.colorHex(in: "rgb(26, 43, 60)"))
        XCTAssertNil(ClipClassifier.colorHex(in: "color #1A2B3C please"))
        XCTAssertNil(ClipClassifier.colorHex(in: "#GGGGGG"))
    }

    // MARK: - Links

    func testHTTPURLsAreLinks() {
        XCTAssertTrue(ClipClassifier.isLink("https://apple.com/mac"))
        XCTAssertTrue(ClipClassifier.isLink("http://localhost:8969/stream"))
    }

    func testNonLinksStayText() {
        XCTAssertFalse(ClipClassifier.isLink("See https://apple.com"))
        XCTAssertFalse(ClipClassifier.isLink("ftp://apple.com"))
        XCTAssertFalse(ClipClassifier.isLink("https://"))
        XCTAssertFalse(ClipClassifier.isLink("apple.com"))
        XCTAssertFalse(ClipClassifier.isLink("https://example.com/" + String(repeating: "a", count: 2100)))
    }

    // MARK: - Capture classification

    func testCapturedTextIsClassified() {
        XCTAssertEqual(CapturedClip(text: "#FF8800").kind, .color)
        XCTAssertEqual(CapturedClip(text: "#FF8800").text, "#FF8800")
        XCTAssertEqual(CapturedClip(text: "https://example.com").kind, .link)
        XCTAssertEqual(CapturedClip(text: "hello").kind, .text)
    }

    func testClassificationKeepsTheOriginalLinkText() {
        let clip = CapturedClip(text: "https://example.com/a?b=1")
        XCTAssertEqual(clip.kind, .link)
        XCTAssertEqual(clip.text, "https://example.com/a?b=1")
    }
}
