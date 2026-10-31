import Foundation

/// Languages the interface is translated into.
///
/// `.system` means "follow the macOS preferred language"; the rest are explicit
/// choices the user can make from the menu bar.
public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case french = "fr"
    case spanish = "es"

    /// Name shown in the language menu, written in that language.
    public var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .french: return "Français"
        case .spanish: return "Español"
        }
    }

    public var localeIdentifier: String {
        switch self {
        case .system: return Locale.current.identifier
        case .english: return "en"
        case .simplifiedChinese: return "zh_Hans"
        case .traditionalChinese: return "zh_Hant"
        case .japanese: return "ja"
        case .french: return "fr"
        case .spanish: return "es"
        }
    }

    /// Languages offered in the menu, in menu order.
    public static var selectable: [AppLanguage] { allCases }

    /// Maps the first matching entry of a preferred-languages list to a
    /// supported language. Unknown languages fall back to English.
    public static func resolve(preferred: [String], fallback: AppLanguage = .english) -> AppLanguage {
        for raw in preferred {
            let tag = raw.lowercased().replacingOccurrences(of: "_", with: "-")
            if tag.hasPrefix("zh") {
                let isTraditional = tag.contains("hant")
                    || tag.contains("-tw") || tag.contains("-hk") || tag.contains("-mo")
                return isTraditional ? .traditionalChinese : .simplifiedChinese
            }
            if tag.hasPrefix("ja") { return .japanese }
            if tag.hasPrefix("fr") { return .french }
            if tag.hasPrefix("es") { return .spanish }
            if tag.hasPrefix("en") { return .english }
        }
        return fallback
    }

    /// The user's preferred languages, unfiltered by this bundle.
    ///
    /// `Locale.preferredLanguages` is narrowed to the bundle's declared
    /// localizations, so an app that ships no `.lproj` folders only ever sees
    /// "en". The raw `AppleLanguages` preference keeps the real order.
    public static var systemPreferredLanguages: [String] {
        if let raw = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           !raw.isEmpty {
            return raw
        }
        return Locale.preferredLanguages
    }

    /// The language actually used to draw the interface.
    public static func effective(
        selection: AppLanguage,
        preferred: [String] = AppLanguage.systemPreferredLanguages
    ) -> AppLanguage {
        switch selection {
        case .system:
            return resolve(preferred: preferred)
        default:
            return selection
        }
    }
}
