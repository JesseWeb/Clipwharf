import AppKit
import Combine
import Foundation
import ClipwharfCore

/// The two surfaces of the strip: everything you copied, and the pins you keep.
enum PanelTab: String, CaseIterable, Identifiable {
    case history
    case pinned

    var id: String { rawValue }

    /// Lookup key; the view localizes it.
    var titleKey: String {
        switch self {
        case .history: return "panel.tab.history"
        case .pinned: return "panel.tab.pinned"
        }
    }

    var symbolName: String {
        switch self {
        case .history: return "clock"
        case .pinned: return "pin"
        }
    }
}

/// View state for the history panel: newest-first items, the search query, the
/// active tab, and one keyboard selection over the visible (filtered) cards.
final class PanelModel: ObservableObject {
    @Published private(set) var items: [ClipItem] = []
    @Published var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            ensureSelectionIsVisible()
        }
    }
    @Published var tab: PanelTab = .history {
        didSet {
            guard tab != oldValue else { return }
            selection = visibleItems.first?.id
        }
    }
    @Published var selection: UUID?
    /// The moment the panel was opened. Cards take it as an input so relative
    /// timestamps are recomputed on every open instead of being frozen by
    /// SwiftUI's diffing (nothing else in the card changes).
    @Published private(set) var referenceDate = Date()
    /// Bumped whenever the panel opens so the search field can take focus.
    @Published private(set) var focusRequest = 0

    var onActivate: ((ClipItem) -> Void)?
    var onPinChange: ((ClipItem, Bool) -> Void)?

    private let store: HistoryStore
    private var thumbnailCache: [UUID: NSImage] = [:]

    init(store: HistoryStore) {
        self.store = store
    }

    /// Items of the active tab, newest first (pins newest-pin first).
    var tabItems: [ClipItem] {
        switch tab {
        case .history: return items
        case .pinned: return items.filter(\.isPinned).sorted {
            ($0.pinnedAt ?? $0.createdAt) > ($1.pinnedAt ?? $1.createdAt)
        }
        }
    }

    /// Items matching the current query within the active tab.
    var visibleItems: [ClipItem] {
        guard isFiltering else { return tabItems }
        return tabItems.filter { $0.matches(search: query) }
    }

    /// Kept for the view's older call sites.
    var filteredItems: [ClipItem] { visibleItems }

    var isFiltering: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var pinnedCount: Int {
        items.filter(\.isPinned).count
    }

    /// Decoded image for `.image` entries, cached for the panel's lifetime.
    func previewImage(for item: ClipItem) -> NSImage? {
        guard item.kind == .image, let name = item.imageFileName else { return nil }
        if let cached = thumbnailCache[item.id] { return cached }
        guard let data = store.blobData(named: name), let image = NSImage(data: data) else {
            return nil
        }
        thumbnailCache[item.id] = image
        return image
    }

    func reload(_ items: [ClipItem]) {
        self.items = items
        referenceDate = Date()
        query = ""
        if tab == .pinned, !items.contains(where: \.isPinned) {
            tab = .history
        }
        selection = visibleItems.first?.id
        focusRequest += 1

        let liveIDs = Set(items.map(\.id))
        thumbnailCache = thumbnailCache.filter { liveIDs.contains($0.key) }
    }

    /// Refresh after a pin change without resetting the query or the tab.
    func applyStoreItems(_ items: [ClipItem]) {
        self.items = items
        if let selection, !visibleItems.contains(where: { $0.id == selection }) {
            self.selection = visibleItems.first?.id
        }
    }

    /// Recompute relative timestamps while the panel stays open.
    func refreshReferenceDate() {
        referenceDate = Date()
    }

    func clearSearch() {
        query = ""
    }

    func moveSelection(by delta: Int) {
        let visible = visibleItems
        guard !visible.isEmpty else { return }

        guard let index = visible.firstIndex(where: { $0.id == selection }) else {
            selection = delta < 0 ? visible.last?.id : visible.first?.id
            return
        }

        let next = (index + delta + visible.count) % visible.count
        selection = visible[next].id
    }

    func activateSelection() {
        guard let item = visibleItems.first(where: { $0.id == selection }) else { return }
        onActivate?(item)
    }

    func activate(_ item: ClipItem) {
        onActivate?(item)
    }

    /// Toggle the pin on the selected card (⌘P).
    func togglePinSelection() {
        guard let item = visibleItems.first(where: { $0.id == selection }) else { return }
        togglePin(item)
    }

    func togglePin(_ item: ClipItem) {
        let pinned = !item.isPinned
        onPinChange?(item, pinned)
    }

    /// Keep the keyboard selection on a visible card after the query changes.
    private func ensureSelectionIsVisible() {
        let visible = visibleItems
        if let selection, visible.contains(where: { $0.id == selection }) { return }
        selection = visible.first?.id
    }
}
