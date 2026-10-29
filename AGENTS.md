# AGENTS.md

Instructions for coding agents (Claude Code, Codex, Cursor, Gemini CLI, …) that
are asked to build, install, or modify **Clipwharf**.

Clipwharf is a local-only macOS clipboard-history menu-bar app written in Swift
(SwiftPM package, no third-party dependencies). Everything you need is in this
repository; there is no package registry, no code generation, and no network
access at runtime.

---

## 1. What the user usually wants

> "Install Clipwharf on my Mac."

That means four things, in this order:

1. Build `dist/Clipwharf.app`.
2. Copy it to `/Applications/Clipwharf.app`.
3. Launch it.
4. Walk the user through the Accessibility permission and confirm auto-paste
   actually works.

Do not stop after step 1 or 2 — an installed app that cannot paste is not
finished work.

---

## 2. Preconditions (check, don't install)

Run these and stop with a clear message if they fail:

```sh
sw_vers -productVersion          # must be >= 13.0
xcodebuild -version              # Xcode 15+ (Command Line Tools alone are not enough)
swift --version                  # Swift 5.9+
```

If Xcode is missing, tell the user to install Xcode from the App Store and run
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. Do **not**
try to install Xcode, Homebrew, or any other toolchain yourself.

Pick a working directory the user controls (e.g. `~/Developer/Clipwharf`). Ask
before writing outside it, apart from the `/Applications` copy the task needs.

---

## 3. Build

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
swift test                                  # expect 31 tests, 0 failures
./scripts/make-app.sh release               # -> dist/Clipwharf.app
```

`make-app.sh` does three things:

- `swift build -c release --product Clipwharf`
- assembles `dist/Clipwharf.app` from the binary, `Support/Info.plist`, and an
  `AppIcon.icns` generated from `Support/AppIcon.png`
- code signs the bundle

Signing behaviour: the script picks the **building machine's** identity, an
Apple Development certificate if `security find-identity -v -p codesigning` has
one, otherwise ad-hoc (`codesign --sign -`). Override with
`CLIPWHARF_SIGN_IDENTITY="…"`.

Never hard-code a developer name, team ID, or certificate into this repository,
and never commit `dist/`, `.build/`, or any signed artifact. The repository is
source-only on purpose; see §7.

---

## 4. Install and launch

```sh
pkill -x Clipwharf 2>/dev/null || true
rm -rf /Applications/Clipwharf.app          # only if replacing a previous copy
cp -R dist/Clipwharf.app /Applications/
open /Applications/Clipwharf.app
```

Keep the app at a **stable path** (`/Applications`). macOS records permissions
per app identity *and* location; moving the bundle later forces a re-grant.

Confirm it is running:

```sh
pgrep -x Clipwharf
```

A paperclip icon appears in the menu bar. The app is `LSUIElement`: no Dock
icon, no main window, quit from the right-click menu.

---

## 5. Accessibility permission (the part that usually goes wrong)

Clipwharf synthesises ⌘V with `CGEvent`, which macOS only allows for apps
trusted under **System Settings → Privacy & Security → Accessibility**.

### Steps for the user

1. Press ⌘⇧V (or click the paperclip) and pick a card once. If permission is
   missing, Clipwharf still copies the item and shows a dialog.
2. In that dialog choose **Fix Permission…**. It runs
   `tccutil reset Accessibility dev.clipwharf.Clipwharf`, asks macOS for a fresh
   grant, and opens the Accessibility pane.
3. Switch **Clipwharf** on in the list.

You may open the pane for the user:

```sh
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

You cannot flip the TCC switch programmatically, and you must not try to
disable SIP, edit `TCC.db`, or otherwise bypass the system prompt.

### Diagnosing "the switch is already on but it still asks"

This is expected for **ad-hoc signed** builds. macOS binds the grant to the
code identity; every rebuild produces a new ad-hoc identity, so the row in
Settings belongs to the previous binary. The fix is the in-app
**Fix Accessibility Permission…** item (menu-bar icon → right-click), which
resets the record so a fresh grant can be given.

If the machine has an Apple Development certificate, the build is signed with a
stable identity and the grant survives rebuilds. Verify which identity was used:

```sh
codesign -dv /Applications/Clipwharf.app 2>&1 | grep -E "Authority|Signature|TeamIdentifier"
codesign -d -r- /Applications/Clipwharf.app 2>&1 | grep designated
```

`Signature=adhoc` means a re-grant is needed after every build.

### Verifying that auto-paste really works

1. Open a plain-text target the user is happy to write into (TextEdit is ideal:
   `open -a TextEdit` then create a new document).
2. `printf 'CLIPWHARF-SMOKE-123' | pbcopy`
3. Wait ~1 s (capture polls every 0.5 s).
4. Press ⌘⇧V, then Return.
5. The text should appear in the document with no permission dialog.

Reading the result back (`osascript -e 'tell application "TextEdit" to get text of document 1'`)
is fine when the user has granted automation permission; otherwise just ask the
user to confirm visually.

---

## 6. First-run behaviour worth knowing

- **Hotkey conflict.** If another clipboard manager (commonly Paste) is running,
  it owns ⌘⇧V and Clipwharf cannot register it; the app warns once. Do not kill
  other apps without asking — offer the menu-bar icon as the alternative.
- **QuickLook privacy prompt.** The first time a file entry is previewed,
  macOS 26 asks "Clipwharf.app would like to access data from other apps".
  That is expected; the user allows it once.
- **No history yet.** A brand-new install shows "No clips yet" until something
  is copied.
- **History location.** `~/Library/Application Support/Clipwharf/history.json`
  plus `Blobs/`. Deleting that folder resets the app.
- **Launch at login** is opt-in via the menu-bar menu; on ad-hoc builds the
  LaunchAgent fallback may be used when `SMAppService` refuses the signature.

---

## 7. Rules for changing the project

- **Source only.** `dist/` and `.build/` are gitignored. Never commit a built
  `.app`, `.icns`, `.dmg`, certificate, `.p12`, or provisioning profile.
- **Never publish someone's signing identity.** The maintainer's certificate
  must not be required to build. Keep the identity detection dynamic.
- **Keep the core dependency-free.** `Sources/ClipwharfCore` has no AppKit
  import on purpose so its tests run on Linux CI.
- **Preserve the local-only promise.** No networking, analytics, telemetry, or
  auto-update code. No account or cloud sync.
- **Keep docs in sync.** User-facing changes belong in `README.md` (six
  languages: English, 简体中文, 繁體中文, 日本語, Français, Español) and in
  `STATUS.md`.
- **Don't clone other clipboard managers.** Clipwharf is a clean-room project:
  no code, assets, icons, sounds, or data formats copied from Paste or similar
  apps. Implement behaviour from first principles.

### Layout

```
Package.swift                     SwiftPM manifest (executable declared on macOS only)
Sources/ClipwharfCore/            model, storage, search, classification (no AppKit)
Sources/Clipwharf/                menu-bar app
  AppDelegate.swift               lifecycle, paste flow, alerts
  Services/ClipboardMonitor.swift 0.5 s NSPasteboard poll
  Services/HotKeyManager.swift    Carbon global ⌘⇧V
  Services/Accessibility.swift    trust checks, ⌘V synthesis, TCC reset
  Services/LaunchAtLogin.swift    SMAppService + LaunchAgent fallback
  Services/StatusItemController.swift  menu-bar item and menu
  Views/PanelView.swift           bottom card strip (SwiftUI)
  Views/FilePreview.swift         QuickLook thumbnails
  Windows/PanelController.swift   the NSPanel itself
Support/Info.plist                bundle metadata (LSUIElement)
Support/AppIcon.png               icon master
scripts/make-app.sh               build + assemble + sign
scripts/make-icon.swift           redraws Support/AppIcon.png
Tests/ClipwharfCoreTests/         31 unit tests
```

### Tests

```sh
swift test                                   # everything
swift test --filter ClipwharfCoreTests       # CI subset
swift build -c release --product Clipwharf   # compile check for the UI target
```

There is no UI test target: verify the panel by hand (§5).

---

## 8. Uninstall

```sh
pkill -x Clipwharf
rm -rf /Applications/Clipwharf.app
rm -rf "$HOME/Library/Application Support/Clipwharf"
rm -f  "$HOME/Library/LaunchAgents/dev.clipwharf.Clipwharf.login.plist"
# then remove Clipwharf from System Settings → General → Login Items and
# System Settings → Privacy & Security → Accessibility
```

---

## 9. Reporting back to the user

When you finish, state plainly:

- where the app was installed and which signing identity was used,
- whether the Accessibility grant is in place and how it was verified,
- any step the user still has to perform themselves (TCC toggle, login item),
- the data folder path and how to reset it.

Do not claim auto-paste works unless you actually observed a paste succeed.
