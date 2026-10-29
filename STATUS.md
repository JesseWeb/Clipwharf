# Clipwharf — Status

Updated: 2026-10-28

## Locked scope

Clipwharf does exactly two things:

1. Keep a local history of copied text, images, and file references (newest
   first, up to 200 entries, de-duplicated, JSON + PNG blobs).
2. Open that history with the global **⌘⇧V** shortcut, filter it with a simple
   text search, and pick an entry; Clipwharf restores it to the pasteboard and
   pastes it into the previous app.

Everything else from the earlier Paste-like plan was removed. The project name
remains Clipwharf. The license is the source-available terms in
`LICENSE`: personal, non-commercial use only, no redistribution.

## Done

### Storage and model (`Sources/ClipwharfCore`)

- `ClipItem` / `CapturedClip` for text, link, color, image, and file entries,
  plus the source app, pin state, and `#RRGGBB` for colors.
- `ClipClassifier`: colors (`#1A2B3C`, `1a2b3c`; bare digit-only codes stay
  text) and links (single-line http/https with a host).
- `ClipSearch`: case-insensitive term matching where every whitespace-separated
  word must appear. Text/link/color entries search their text; images and files
  search their display title and file names; every kind also matches the source
  app name and the link host.
- `ContentHasher` (FNV-1a) for local duplicate collapsing.
- `HistoryStore`: atomic JSON index, PNG blob directory, newest-first ordering,
  duplicate-to-top behavior, 200-entry pruning that never drops pinned entries,
  pin/unpin persistence, blob-name path-traversal guard, tolerant decoding of
  older history files, and cleanup of unreadable or duplicate records on load.
  Pruned records have their blob files removed.
- `AppPaths` resolves `~/Library/Application Support/Clipwharf`.
- Core target has no AppKit dependency and is covered by unit tests.

### Capture (`Sources/Clipwharf/Services/ClipboardMonitor.swift`)

- Polls `NSPasteboard` every 0.5 s.
- Captures file URLs first, then PNG/TIFF images (stored as PNG), then text.
  Empty/whitespace-only text is ignored.
- Text is classified into link, color, or plain text at capture time.
- Records the frontmost app's bundle id and name for every entry.
- Skips captures made by password managers (fixed bundle-id list).
- Suppresses re-capture of Clipwharf's own pasteboard writes.

### History UI (`Sources/Clipwharf/Views`, `Windows`)

- Full-width strip anchored to the bottom of the active screen, rounded top
  corners, 300 pt tall — the layout Paste uses. The panel activates the app so
  the search field, arrow keys, and card clicks all work.
- Two tabs: **History** (⌘1) and **Pinned** (⌘2, with a count badge).
- Search field in the header with a clear button and a live "N of M" count.
- Horizontal row of cards, newest first: a tinted kind/time band with the source
  app icon, a preview, and a footer (character count, file path, `RGB …`, or
  `W × H`). Selected card gets an accent border and shadow.
- ⌘P pins or unpins the selected card; the context menu offers Pin/Unpin and
  Copy.
- Arrow keys move the selection within the filtered strip, Return pastes, Esc
  closes, clicking a card pastes.
- Empty state and no-matches state are centered in the strip; the Pinned tab
  has its own empty state.

### Global shortcut and paste

- Carbon `RegisterEventHotKey` for ⌘⇧V (`HotKeyManager`).
- Re-activates the previously frontmost app, then posts ⌘V with `CGEvent`
  (`Accessibility.swift`).
- If Accessibility is not granted, the clip is still placed on the pasteboard
  and the user is told to press ⌘V; a "Grant Access…" button triggers the macOS
  permission prompt.
- If ⌘⇧V is already taken, a one-time alert explains that the menu-bar icon
  still works.

### Menu bar and lifecycle

- `LSUIElement` / `.accessory` app: no Dock icon, no main window.
- Paperclip status item: left-click opens history; right-click menu has Open
  History, Launch at Login, About, and Quit.
- Launch at Login registers through `SMAppService`, with a per-user LaunchAgent
  at `~/Library/LaunchAgents/dev.clipwharf.Clipwharf.login.plist` as the
  fallback for ad-hoc signed builds. `requiresApproval` shows a notice that
  opens System Settings → General → Login Items.
- Clipboard polling stops and the hotkey unregisters on quit.

### Packaging and docs

- `Package.swift` opens directly in Xcode; executable target is declared only
  on macOS so the core tests also run on Linux.
- `Support/Info.plist` + `scripts/make-app.sh` produce an ad-hoc-signed
  `dist/Clipwharf.app`, including an `AppIcon.icns` generated from
  `Support/AppIcon.png` (drawn by `scripts/make-icon.swift`).
- `README.md` covers build/run, usage, Accessibility, data location, scope, and
  license.
- `LICENSE` replaced with source-available terms (no commercial use, no
  redistribution, no sublicensing, no resale).

## Verification

Performed in this Linux environment (Swift 6.1.2):

- `swift test` — **31 tests, 0 failures**. Covers capture ordering, duplicate
  collapsing, empty input, pruning + blob cleanup, limit clamping, pin
  persistence/pruning exemption, source-app persistence and search, color and
  link classification, full persistence round-trip for text/image/files, blob
  path safety, display titles, hashing, and search (case-insensitive text,
  multi-word AND, full-text matching, image titles, and filenames beyond the
  truncated display title).
- The macOS app builds, launches, captures, previews, pins, and pastes on
  macOS 26.5 (arm64); the panel was exercised by hand and by synthetic input.

### Manual smoke test on a Mac

1. `open Package.swift`, select the Clipwharf scheme, Run. A paperclip appears
   in the menu bar.
2. Copy plain text, then a screenshot, then a file in Finder. Press ⌘⇧V; three
   entries should appear newest-first and the search field should have focus.
3. Type a word from the text entry: the list should narrow case-insensitively.
   Add a second word that is absent; the list should show "No matches". Clear
   the field with the × button.
4. Search for part of the file name and for "Image"; the file and image entries
   should match their title/filename.
5. Use ↑/↓ and Return. The entry should paste into the previously active app.
6. Grant Accessibility when prompted, then repeat step 5 to confirm auto-paste.
7. Quit and relaunch; history should still be there. To reset, quit Clipwharf
   and delete `~/Library/Application Support/Clipwharf`.

## Re-added in v2

- Pinboards: ⌘P pins a card to its own tab, and pins are exempt from pruning.
- Link and color item types with their own card layouts.
- Source-app attribution (icon badge plus searchable app name).
- A fixed password-manager exclusion list.

## Removed by the scope change

- Advanced query syntax and kind/pinned-only filter controls (a simple text
  search is in scope).
- Pause-capture and all capture settings.
- Rich text (RTF) storage.
- Settings window, first-run preferences flow, configurable history limit.
- Clear-all/delete UI and the unused store methods behind it.
- Any sync/cloud/account surface.

## Known limitations (accepted for this scope)

- Auto-paste needs Accessibility permission; without it, paste is manual ⌘V.
- History size is fixed at 200 entries; there is no preferences UI.
- Plain text only (no RTF/HTML), images (PNG), and file references.
- Capture is poll-based (0.5 s), so extremely fast clipboard turnover can miss
  intermediate values.
- Search is plain substring matching over the current history (no fuzzy
  matching, kind filters, or full-path search).
- No password exclusion by design; apps that put secrets on the general
  pasteboard will be captured. There is also no in-app clear/delete action:
  quit Clipwharf and delete `~/Library/Application Support/Clipwharf` to reset.
- Signed with a local Apple Development certificate when one is available, so the
  Accessibility grant survives rebuilds; otherwise ad-hoc, where every rebuild
  invalidates the grant and **Fix Accessibility Permission…** must be used. No
  Developer ID/notarization, so distributing the build to other Macs needs a
  real signature.
- No menu-bar appearance customization; the icon is a fixed drawn paperclip.
- No single-instance guard; run one copy at a time.

## Next step

Build once on macOS and run the manual smoke test above. If it passes, the
project is at the requested minimal scope; further features should stay out
unless the scope is explicitly widened again.
