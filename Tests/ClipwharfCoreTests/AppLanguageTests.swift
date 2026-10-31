import XCTest
@testable import ClipwharfCore

final class AppLanguageTests: XCTestCase {
    func testChineseVariantsSplitByScript() {
        XCTAssertEqual(AppLanguage.resolve(preferred: ["zh-Hans-CN"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["zh-Hant-TW"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["zh-HK"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["zh-MO"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["zh-CN"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["zh"]), .simplifiedChinese)
    }

    func testRegionCodesMapToLanguages() {
        XCTAssertEqual(AppLanguage.resolve(preferred: ["ja-JP"]), .japanese)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["fr-FR"]), .french)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["es-419"]), .spanish)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["en-GB"]), .english)
    }

    func testUnsupportedFallsBackToEnglish() {
        XCTAssertEqual(AppLanguage.resolve(preferred: ["de-DE"]), .english)
        XCTAssertEqual(AppLanguage.resolve(preferred: []), .english)
    }

    func testFirstSupportedPreferenceWins() {
        XCTAssertEqual(AppLanguage.resolve(preferred: ["de-DE", "fr-FR", "en-US"]), .french)
        XCTAssertEqual(AppLanguage.resolve(preferred: ["ko-KR", "zh-Hant-HK"]), .traditionalChinese)
    }

    func testSystemSelectionFollowsPreferences() {
        XCTAssertEqual(
            AppLanguage.effective(selection: .system, preferred: ["ja-JP"]),
            .japanese
        )
    }

    func testExplicitSelectionBeatsPreferences() {
        XCTAssertEqual(
            AppLanguage.effective(selection: .spanish, preferred: ["ja-JP"]),
            .spanish
        )
    }

    func testEveryLanguageHasADisplayName() {
        for language in AppLanguage.allCases {
            XCTAssertFalse(language.displayName.isEmpty)
        }
        XCTAssertEqual(AppLanguage.simplifiedChinese.displayName, "简体中文")
        XCTAssertEqual(AppLanguage.traditionalChinese.displayName, "繁體中文")
    }
}
