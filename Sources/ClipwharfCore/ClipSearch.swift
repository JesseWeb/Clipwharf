import Foundation

// MARK: - History search

/// The plain-text view of a clip used by the history panel's search field.
///
/// Text entries expose their full text. Images and files have no text, so they
/// are searchable by their display title and, for files, by every filename.
public extension ClipItem {
    var searchableText: String {
        switch kind {
        case .text:
            return text ?? ""
        case .image:
            return displayTitle
        case .files:
            var parts = [displayTitle]
            parts.append(contentsOf: fileNames)
            return parts.joined(separator: "\n")
        }
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
