import Foundation

// MARK: - History search

/// The plain-text view of a clip used by the history panel's search field.
///
/// Text, link, and color entries expose their text. Images and files have no
/// text of their own, so they are searchable by display title and filenames.
/// Every kind also matches the app it was copied from, so typing "safari" or
/// "chrome" narrows the strip the way Paste's search does.
public extension ClipItem {
    var searchableText: String {
        var parts: [String] = []

        switch kind {
        case .text, .link, .color:
            parts.append(text ?? "")
            if let colorHex { parts.append(colorHex) }
        case .image:
            parts.append(displayTitle)
        case .files:
            parts.append(displayTitle)
            parts.append(contentsOf: fileNames)
        }

        if let sourceAppName { parts.append(sourceAppName) }
        if let sourceBundleID { parts.append(sourceBundleID) }
        if let linkHost { parts.append(linkHost) }
        parts.append(kind.label)

        return parts.joined(separator: "\n")
    }

    /// True when every whitespace-separated term in `query` appears somewhere
    /// in `searchableText`. Matching is case-insensitive; an empty or
    /// whitespace-only query matches everything.
    func matches(search query: String) -> Bool {
        let terms = query
            .split(whereSeparator: \.isWhitespace)
            .map { String($0).lowercased() }
        guard !terms.isEmpty else { return true }

        let haystack = searchableText.lowercased()
        return terms.allSatisfy { haystack.contains($0) }
    }
}
