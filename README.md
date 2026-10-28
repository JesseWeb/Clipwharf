# Clipwharf

A tiny, local-only clipboard history for macOS. Copy things as usual, press
**⌘⇧V**, type to filter if you like, pick an entry, and Clipwharf puts it back
on the clipboard and pastes it into the app you were using.

Clipwharf is an independent clean-room project. It is not affiliated with,
derived from, or endorsed by Paste or any other clipboard manager.

## What it does

That is the whole product:

1. **Keeps a clipboard history** of text, images, and file references in a
   local JSON index plus a folder of PNG blobs.
2. **⌘⇧V opens a simple searchable history panel.** Type in the search field to
   narrow the list, then use ↑/↓ and Return, or click an entry. Clipwharf
   restores it to the pasteboard and sends ⌘V to the previous app. Esc closes
   the panel.

Search is case-insensitive. Separate words are treated as terms and every term
must match. Text entries match their full copied text; image and file entries,
which have no text of their own, match their display title or filename.

History holds the newest 200 entries and de-duplicates repeated copies.
Everything stays on your Mac.

## What it deliberately does not do

No pins or favorites, no kind or pinned-only filters, no pause-capture setting,
no password-manager detection or password exclusion, no sync, no settings
window, no rich-text formatting, no clear/delete UI, no cloud service, no
analytics. Those are out of scope for this minimal version, not "coming soon".

Because there is no password exclusion, an app that copies a password to the
normal system pasteboard will be captured like any other text. History rolls
over after 200 entries; to wipe it immediately, quit Clipwharf and delete its
data folder (see below).

## Requirements

- macOS 13 Ventura or newer
- Xcode 15 or newer (Swift 5.9+), or the matching Swift toolchain

## Build and run

### Xcode

```sh
open Package.swift
```

Choose the **Clipwharf** scheme and press Run. Clipwharf is a menu-bar app
(`LSUIElement`); it has no Dock icon and no main window.

### Command line

```sh
swift run Clipwharf
```

### A double-clickable .app

```sh
./scripts/make-app.sh
open dist/Clipwharf.app
```

The script builds a release binary, assembles `dist/Clipwharf.app` with
`Support/Info.plist`, and ad-hoc signs it. A stable signature helps macOS
remember the Accessibility permission.

## Using it

- Copy text, an image, or files in Finder. Each new clipboard item is captured
  within about half a second.
- Press **⌘⇧V** anywhere. The newest entry is selected and the search field has
  focus.
- Type to filter. Matching is case-insensitive and all words must match. Use the
  **×** button in the field to clear it.
- **↑ / ↓** move the selection, **Return** pastes, **Esc** closes. Clicking a row
  pastes it.
- The paperclip in the menu bar opens the same panel. Right-click it for
  **About** and **Quit**.

If another app already owns ⌘⇧V, Clipwharf will warn you at launch and the
menu-bar icon still works.

### Accessibility permission

macOS only lets an app synthesize ⌘V if it is trusted for Accessibility. The
first time you pick an entry without that permission, Clipwharf still puts the
entry on your clipboard and tells you to press ⌘V yourself. To enable auto-paste:

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Add/enable Clipwharf (or the terminal app, when running via `swift run`).
3. Try again.

Clipwharf only uses this permission to post ⌘V. If you rebuild and macOS forgets
the grant, toggle Clipwharf off and on in that list.

## Where data lives

```
~/Library/Application Support/Clipwharf/
├── history.json   # newest-first metadata index
└── Blobs/         # image payloads (<uuid>.png)
```

The format is plain JSON and files on disk. Quit Clipwharf and delete that
folder to reset everything. Nothing is written anywhere else and there is no
network code in the app.

## Project layout

```
Package.swift
Sources/ClipwharfCore/     # storage, model, search; no AppKit, unit-testable
  AppPaths.swift
  ClipItem.swift
  ClipSearch.swift
  HistoryStore.swift
Sources/Clipwharf/         # menu-bar executable
  AppDelegate.swift
  main.swift
  Services/                # pasteboard polling, global hotkey, status item
  Views/                   # SwiftUI search field and history list
  Windows/                 # floating panel controller
Tests/ClipwharfCoreTests/
Support/Info.plist
scripts/make-app.sh
```

## Tests

```sh
swift test
```

The core target has no AppKit dependency, so the model, storage, and search
tests also run on Linux. The macOS executable is built only on macOS.

## License

MIT. See [LICENSE](LICENSE).
