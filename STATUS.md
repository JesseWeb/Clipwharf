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
remains Clipwharf and the license remains MIT.

## Done

### Storage and model (`Sources/ClipwharfCore`)

- `ClipItem` / `CapturedClip` for text, image, and file entries.
- `ClipSearch`: case-insensitive term matching where every whitespace-separated
  word must appear. Text entries search their full text; images and files search
  their display title and all file names.
- `ContentHasher` (FNV-1a) for local duplicate collapsing.
- `HistoryStore`: atomic JSON index, PNG blob directory, newest-first ordering,
  duplicate-to-top behavior, 200-entry pruning, blob-name path-traversal guard,
  and cleanup of unreadable or duplicate records on load. Pruned records have
  their blob files removed.
- `AppPaths` resolves `~/Library/Application Support/Clipwharf`.
- Core target has no AppKit dependency and is covered by unit tests.

### Capture (`Sources/Clipwharf/Services/ClipboardMonitor.swift`)

- Polls `NSPasteboard` every 0.5 s.
- Captures file URLs first, then PNG/TIFF images (stored as PNG), then plain
  text. Empty/whitespace-only text is ignored.
- Suppresses re-capture of Clipwharf's own pasteboard writes.

### History UI (`Sources/Clipwharf/Views`, `Windows`)

- Borderless floating `NSPanel` hosting a SwiftUI list (420 × 460).
- Search field under the header, focused when the panel opens, with a clear
  button and a live "N of M" count. Filtering applies as you type.
- Newest-first list with kind icon, title, kind/time subtitle, selection
  highlight, empty state, no-matches state, and `↑↓ / ⏎ / esc` footer hints.
- Arrow keys move the selection within the filtered list, Return pastes, Esc
  closes, clicking a row pastes.
- No pin buttons, kind/pinned filter controls, thumbnails grid, or settings.

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
  History, About, and Quit.
- Clipboard polling stops and the hotkey unregisters on quit.

### Packaging and docs

- `Package.swift` opens directly in Xcode; executable target is declared only
  on macOS so the core tests also run on Linux.
- `Support/Info.plist` + `scripts/make-app.sh` produce an ad-hoc-signed
  `dist/Clipwharf.app`.
- `README.md` covers build/run, usage, Accessibility, data location, scope, and
  license.
- MIT `LICENSE` retained.

## Verification

Performed in this Linux environment (Swift 6.1.2):

- `swift test` — **19 tests, 0 failures**. Covers capture ordering, duplicate
  collapsing, empty input, pruning + blob cleanup, limit clamping, full
  persistence round-trip for text/image/files, blob path safety, display titles,
  hashing, and search (case-insensitive text, multi-word AND, full-text matching,
  image titles, and filenames beyond the truncated display title).
- `swiftc -frontend -parse` on every `Sources/Clipwharf/**/*.swift` file —
  clean. This checks syntax only; AppKit/SwiftUI type-checking requires macOS.
- The macOS executable was **not compiled or run** here because no macOS SDK is
  available in this container. A first build in Xcode on a Mac is the remaining
  verification step.

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

## Removed by the scope change

- Pin/favorite support and pinned-item pruning rules.
- Advanced query syntax and kind/pinned-only filter controls (a simple text
  search is in scope).
- Pause-capture and all capture settings.
- Password-manager detection and confidential/concealed pasteboard heuristics.
- Rich text (RTF) storage.
- Source-app attribution.
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
- Ad-hoc signing only; no Developer ID/notarization. Accessibility grants may
  need to be re-enabled after rebuilding.
- No app icon, launch-at-login, or menu-bar appearance customization.
- No single-instance guard; run one copy at a time.

## Next step

Build once on macOS and run the manual smoke test above. If it passes, the
project is at the requested minimal scope; further features should stay out
unless the scope is explicitly widened again.
