import AppKit
import SwiftUI
import ClipwharfCore

/// Shorthand for the shared localization table.
private let L = Localization.shared

/// Shared geometry for the bottom panel, used by both the window and the view.
enum PanelLayout {
    /// Height of the strip that slides up from the bottom of the screen.
    static let height: CGFloat = 300
    static let cardWidth: CGFloat = 220
    static let cardHeight: CGFloat = 196
    static let cornerRadius: CGFloat = 18
    static let cardCornerRadius: CGFloat = 10
}

/// Rounded top corners only, so the strip sits flush with the screen edge.
private struct TopRoundedRectangle: InsettableShape {
    var radius: CGFloat
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> TopRoundedRectangle {
        var copy = self
        copy.insetAmount += amount
        copy.radius = max(0, radius - amount)
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct PanelView: View {
    @ObservedObject var model: PanelModel
    /// Observed so switching the language redraws the strip immediately.
    @ObservedObject private var l10n = Localization.shared
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .frame(maxWidth: .infinity)
        .frame(height: PanelLayout.height)
        .background(.regularMaterial)
        .clipShape(TopRoundedRectangle(radius: PanelLayout.cornerRadius))
        .overlay(
            TopRoundedRectangle(radius: PanelLayout.cornerRadius)
                .strokeBorder(Color.primary.opacity(0.10))
        )
        .onAppear { focusSearchField() }
        .onChange(of: model.focusRequest) { _ in focusSearchField() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "paperclip")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Clipwharf")
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(width: 120, alignment: .leading)

            tabs

            Spacer(minLength: 12)

            searchField
                .frame(width: 300)

            Text(countLabel)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var tabs: some View {
        HStack(spacing: 2) {
            ForEach(PanelTab.allCases) { tab in
                let isActive = model.tab == tab
                HStack(spacing: 4) {
                    Image(systemName: tab.symbolName)
                        .font(.system(size: 9, weight: .semibold))
                    Text(l10n.t(tab.titleKey))
                        .font(.system(size: 11, weight: .medium))
                    if tab == .pinned, model.pinnedCount > 0 {
                        Text("\(model.pinnedCount)")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(Color.primary.opacity(0.12))
                            )
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isActive ? Color.primary.opacity(0.10) : Color.clear)
                )
                .contentShape(Rectangle())
                .onTapGesture { model.tab = tab }
                .help(tab == .history ? "History (⌘1)" : "Pinned (⌘2)")
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private var countLabel: String {
        let visible = model.visibleItems.count
        if model.isFiltering {
            return l10n.t("panel.count.filtered", visible, model.tabItems.count)
        }
        return l10n.t(visible == 1 ? "panel.count.one" : "panel.count.other", visible)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField(l10n.t("panel.search"), text: $model.query)
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
                .help(l10n.t("panel.clearSearch"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        )
    }

    // MARK: - Cards

    @ViewBuilder
    private var content: some View {
        if model.tabItems.isEmpty {
            switch model.tab {
            case .history:
                emptyState(
                    icon: "paperclip",
                    title: l10n.t("panel.empty.clips.title"),
                    subtitle: l10n.t("panel.empty.clips.body")
                )
            case .pinned:
                emptyState(
                    icon: "pin",
                    title: l10n.t("panel.empty.pins.title"),
                    subtitle: l10n.t("panel.empty.pins.body")
                )
            }
        } else if model.visibleItems.isEmpty {
            emptyState(
                icon: "magnifyingglass",
                title: l10n.t("panel.empty.matches.title"),
                subtitle: l10n.t("panel.empty.matches.body")
            )
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(model.visibleItems) { item in
                            ClipCard(
                                item: item,
                                isSelected: model.selection == item.id,
                                thumbnail: model.previewImage(for: item)
                            )
                            .id(item.id)
                            .onTapGesture { model.activate(item) }
                            .contextMenu {
                                Button(l10n.t(item.isPinned ? "card.unpin" : "card.pin")) {
                                    model.togglePin(item)
                                }
                                Button(l10n.t("card.copy")) {
                                    model.activate(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                }
                .onChange(of: model.selection) { selection in
                    guard let selection else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(selection, anchor: .center)
                    }
                }
            }
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 16) {
            Text(l10n.t("panel.footer.select"))
            Text(l10n.t("panel.footer.pin"))
            Text(l10n.t("panel.footer.tabs"))
            Text(l10n.t("panel.footer.paste"))
            Text(l10n.t("panel.footer.close"))
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    private func focusSearchField() {
        DispatchQueue.main.async {
            searchFocused = true
        }
    }
}

// MARK: - Card

private struct ClipCard: View {
    let item: ClipItem
    let isSelected: Bool
    let thumbnail: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBand
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
            footerLabel
        }
        .frame(width: PanelLayout.cardWidth, height: PanelLayout.cardHeight)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: PanelLayout.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PanelLayout.cardCornerRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.primary.opacity(0.10),
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
        .shadow(color: .black.opacity(isSelected ? 0.22 : 0.10),
                radius: isSelected ? 8 : 4,
                y: 2)
        .contentShape(RoundedRectangle(cornerRadius: PanelLayout.cardCornerRadius, style: .continuous))
    }

    private var headerBand: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 9, weight: .semibold))
            Text(kindLabel)
                .font(.system(size: 10, weight: .semibold))

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8, weight: .semibold))
            }

            Spacer(minLength: 4)

            if item.sourceAppName != nil {
                SourceAppIcon(bundleID: item.sourceBundleID, name: item.sourceAppName ?? "")
                Text(L.relativeTime(for: item.createdAt))
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            } else {
                Text(L.relativeTime(for: item.createdAt))
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(kindTint.opacity(isSelected ? 0.30 : 0.16))
    }

    @ViewBuilder
    private var preview: some View {
        switch item.kind {
        case .text:
            Text(item.text ?? "")
                .font(.system(size: 11))
                .lineLimit(12)
                .multilineTextAlignment(.leading)
                .padding(9)

        case .link:
            linkPreview

        case .color:
            colorPreview

        case .image:
            if let thumbnail {
                // Color.clear takes the proposed size; the image is drawn in an
                // overlay so its intrinsic size cannot stretch the card layout
                // (which used to push the header band out of the clipped area).
                Color.clear
                    .overlay {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                centeredIcon("photo")
            }

        case .files:
            filePreview
        }
    }

    private var linkPreview: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: "globe")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.secondary)
            Text(item.linkHost ?? "Link")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            Text(item.text ?? "")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(6)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(9)
    }

    private var colorPreview: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(swatchColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.15))
                )
            Text(item.colorHex ?? "")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var swatchColor: Color {
        let hex = (item.colorHex ?? "#888888").replacingOccurrences(of: "#", with: "")
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return .gray }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    private func centeredIcon(_ name: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: name)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var kindLabel: String {
        switch item.kind {
        case .text: return L.t("card.kind.text")
        case .link: return L.t("card.kind.link")
        case .image: return L.t("card.kind.image")
        case .files: return L.t("card.kind.files")
        case .color: return L.t("card.kind.color")
        }
    }

    private var iconName: String {
        switch item.kind {
        case .text: return "text.alignleft"
        case .link: return "link"
        case .image: return "photo"
        case .files: return "doc.on.doc"
        case .color: return "paintpalette"
        }
    }

    private var kindTint: Color {
        switch item.kind {
        case .text: return .gray
        case .link: return .blue
        case .image: return .purple
        case .files: return .orange
        case .color: return swatchColor
        }
    }

    // MARK: - Files

    private var fileURLs: [URL] {
        (item.fileURLs ?? []).map { URL(fileURLWithPath: $0) }
    }

    /// One file gets its QuickLook preview; several get a 2 × 2 thumbnail grid.
    @ViewBuilder
    private var filePreview: some View {
        let urls = fileURLs
        if urls.isEmpty {
            centeredIcon("doc")
        } else if urls.count == 1, let url = urls.first {
            FileThumbnail(url: url, pointSize: CGSize(width: 200, height: 150))
                .padding(8)
        } else {
            let shown = Array(urls.prefix(4))
            let rows = (shown.count + 1) / 2
            VStack(spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<2, id: \.self) { column in
                            let index = row * 2 + column
                            if index < shown.count {
                                FileThumbnail(
                                    url: shown[index],
                                    pointSize: CGSize(width: 88, height: 66)
                                )
                            }
                        }
                    }
                }
            }
            .padding(8)
            .overlay(alignment: .bottomTrailing) {
                if urls.count > shown.count {
                    Text("+\(urls.count - shown.count)")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.55), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(12)
                }
            }
        }
    }

    // MARK: - Footer

    /// Paste shows the file path under a file preview, the hex under a color,
    /// and a plain count for text and images.
    @ViewBuilder
    private var footerLabel: some View {
        let text: String = {
            if item.kind == .files, let path = item.fileURLs?.first, item.fileURLs?.count == 1 {
                return path
            }
            return footerText
        }()

        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.05))
            .help(text)
    }

    private var footerText: String {
        switch item.kind {
        case .text:
            let count = (item.text ?? "").count
            return L.t(count == 1 ? "card.characters.one" : "card.characters.other", count)
        case .link:
            return item.linkHost ?? "Link"
        case .color:
            if let hex = item.colorHex,
               let value = UInt32(hex.replacingOccurrences(of: "#", with: ""), radix: 16) {
                let r = (value >> 16) & 0xFF
                let g = (value >> 8) & 0xFF
                let b = value & 0xFF
                return L.t("card.rgb", r, g, b)
            }
            return "Color"
        case .image:
            if let width = item.imageWidth, let height = item.imageHeight {
                return "\(width) × \(height)"
            }
            return L.t("card.image")
        case .files:
            let count = item.fileURLs?.count ?? 0
            return L.t(count == 1 ? "card.files.one" : "card.files.other", count)
        }
    }
}

// MARK: - Source app badge

/// The copying app's icon, resolved from its bundle identifier at display time
/// so no icon data has to be stored in the history index.
private struct SourceAppIcon: View {
    let bundleID: String?
    let name: String

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .frame(width: 12, height: 12)
            .help(name)
    }

    private var icon: NSImage {
        if let bundleID,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSImage(systemSymbolName: "app", accessibilityDescription: name)
            ?? NSImage()
    }
}
