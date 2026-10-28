import Combine
import Foundation
import ClipwharfCore

/// View state for the history panel: newest-first items, the search query, and
/// one keyboard selection over the visible (filtered) list.
final class PanelModel: ObservableObject {
    @Published private(set) var items: [ClipItem] = []
    @Published var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            ensureSelectionIsVisible()
        }
    }
    @Published var selection: UUID?
    /// Bumped whenever the panel opens so the search field can take focus.
    @Published private(set) var focusRequest = 0

    var onActivate: ((ClipItem) -> Void)?

    /// Items matching the current query, newest first.
    var filteredItems: [ClipItem] {
        guard isFiltering else { return items }
        return items.filter { $0.matches(search: query) }
    }

    var isFiltering: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func reload(_ items: [ClipItem]) {
        self.items = items
        query = ""
        selection = items.first?.id
        focusRequest += 1
    }

    func clearSearch() {
        query = ""
    }

    func moveSelection(by delta: Int) {
        let visible = filteredItems
        guard !visible.isEmpty else { return }

        guard let index = visible.firstIndex(where: { $0.id == selection }) else {
            selection = delta < 0 ? visible.last?.id : visible.first?.id
            return
        }

        let next = (index + delta + visible.count) % visible.count
        selection = visible[next].id
    }

    func activateSelection() {
        guard let item = filteredItems.first(where: { $0.id == selection }) else { return }
        onActivate?(item)
    }

    func activate(_ item: ClipItem) {
        onActivate?(item)
    }

    /// Keep the keyboard selection on a visible row after the query changes.
    private func ensureSelectionIsVisible() {
        let visible = filteredItems
        if let selection, visible.contains(where: { $0.id == selection }) { return }
        selection = visible.first?.id
    }
}
