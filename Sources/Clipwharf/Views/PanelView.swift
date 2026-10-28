import Foundation
import SwiftUI
import ClipwharfCore

struct PanelView: View {
    @ObservedObject var model: PanelModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 420, height: 460)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12))
        )
        .onAppear { focusSearchField() }
        .onChange(of: model.focusRequest) { _ in focusSearchField() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Clipwharf")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Text(countLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 9)
    }

    private var countLabel: String {
        if model.isFiltering {
            return "\(model.filteredItems.count) of \(model.items.count)"
        }
        return model.items.count == 1 ? "1 entry" : "\(model.items.count) entries"
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Search clips", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($searchFocused)
            if !model.query.isEmpty {
                Button {
                    model.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if model.items.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "paperclip")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.tertiary)
                Text("No clips yet")
                    .font(.headline)
                Text("Copy text, an image, or files, then press ⌘⇧V.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.filteredItems.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.tertiary)
                Text("No matches")
                    .font(.headline)
                Text("No clips match this search.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(model.filteredItems) { item in
                            ClipRow(item: item, isSelected: model.selection == item.id)
                                .id(item.id)
                                .onTapGesture { model.activate(item) }
                        }
                    }
                    .padding(6)
                }
                .onChange(of: model.selection) { selection in
                    guard let selection else { return }
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(selection, anchor: .center)
                    }
                }
            }
        }
    }

    private func focusSearchField() {
        DispatchQueue.main.async {
            searchFocused = true
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Text("↑↓ Select")
            Text("⏎ Paste")
            Text("esc Close")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct ClipRow: View {
    let item: ClipItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.20) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private var iconName: String {
        switch item.kind {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .files: return "doc.on.doc"
        }
    }

    private var subtitle: String {
        var parts = [item.kindLabel]
        if item.kind == .files, let count = item.fileURLs?.count, count > 1 {
            parts.append("\(count) files")
        }
        parts.append(item.createdAt.formatted(date: .omitted, time: .shortened))
        return parts.joined(separator: " · ")
    }
}
