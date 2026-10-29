# Clipwharf

A tiny, local-only clipboard history for macOS.

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/) [![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org) [![Release](https://img.shields.io/github/v/release/JesseWeb/Clipwharf)](https://github.com/JesseWeb/Clipwharf/releases) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)

![Clipwharf: press ⌘⇧V, pick a card, it pastes](docs/demo.gif)

**[English](README.md)** · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Français](README.fr.md) · [Español](README.es.md)

Clipwharf keeps what you copy on your Mac and nowhere else. Copy text, a link,
a color, an image, or a file as usual; press **⌘⇧V**, pick a card, and it goes
back on the clipboard and is pasted into the app you were using.

Clipwharf is an independent clean-room project. It is not affiliated with,
derived from, or endorsed by Paste or any other clipboard manager, and it
contains no code, assets, or icons from them. No account, no cloud, no
telemetry: nothing ever leaves your Mac.

## Features

- **Five card types** — text, link, color, image, and file. Files are previewed
  with QuickLook, the way Finder does it; several copied files become a 2 × 2
  grid with a “+N” badge.
- **Pinboards** — press ⌘P to keep a card. Pinned cards get their own tab and
  are never dropped by the 200-entry history limit.
- **Search** — case-insensitive, all words must match. Matches text, file
  names, link hosts, and the name of the app you copied from.
- **Source app badge** — every card shows which app it came from.
- **Password-manager exclusion** — content copied from 1Password, Bitwarden,
  LastPass, Dashlane, Keychain Access, Passwords, or Keeper is skipped.
- **Launch at login** — menu-bar icon → *Launch at Login*.
- **Local only** — plain JSON index plus a folder of PNG blobs under
  `~/Library/Application Support/Clipwharf`.

## Requirements

- macOS 13 Ventura or newer
- Xcode 15 or newer (Swift 5.9+); the Command Line Tools alone are not enough
  to build the app bundle script comfortably

## Install

**Option 1 — let an AI agent do it (fastest).** Paste this into Claude Code,
Codex, Cursor, or any coding agent that can run shell commands:

> Clone https://github.com/JesseWeb/Clipwharf into a folder, read `AGENTS.md`,
> build `Clipwharf.app` with `./scripts/make-app.sh release`, copy it to
> `/Applications`, launch it, then tell me exactly which Accessibility toggle to
> switch on and how to verify that auto-paste works.

The agent follows [`AGENTS.md`](AGENTS.md), which contains the build steps, the
permission sequence, and the pitfalls. A longer prompt with variations is in
[`docs/ai-install.md`](docs/ai-install.md).

**Option 2 — build it yourself.**

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
./scripts/make-app.sh release      # builds and signs dist/Clipwharf.app
open dist/Clipwharf.app
```

Then drag `dist/Clipwharf.app` into `/Applications` so macOS keeps the app (and
its permissions) in one place.

**Option 3 — there is no download.** Clipwharf publishes no binaries yet: a
notarized build needs a paid Apple Developer account, and shipping an unnotarized
one would greet every user with a Gatekeeper warning. Options 1 and 2 are the
supported paths, and a local build has the advantage of carrying your own code
identity.

## First run

1. A paperclip appears in the menu bar. Clipwharf has no Dock icon and no main
   window; quit it from the right-click menu.
2. Copy some text, an image, or a file, then press **⌘⇧V**.
3. Grant Accessibility so Clipwharf can press ⌘V for you:
   **System Settings → Privacy & Security → Accessibility → switch Clipwharf on.**
   Without it, Clipwharf still puts the clip on your clipboard and asks you to
   press ⌘V yourself.

## Shortcuts

| Key | Action |
|---|---|
| ⌘⇧V | Open or close the strip (global) |
| ← / → | Move the selection |
| ⏎ | Paste the selected card |
| ⌘P | Pin / unpin the selected card |
| ⌘1 / ⌘2 | History / Pinned tab |
| esc | Close the strip |
| click | Paste that card |
| right-click | Pin/Unpin, Copy |

## Where data lives

```
~/Library/Application Support/Clipwharf/
├── history.json   # newest-first index
└── Blobs/         # image payloads (<uuid>.png)
```

Everything is plain JSON and files. Quit Clipwharf and delete that folder to
reset. Nothing is written anywhere else.

## Signing, and why this repository ships source only

- **No binaries and no signing material are committed.** `dist/` is ignored, so
  the repository never contains a `.app`, an `.icns`, or a certificate.
- `scripts/make-app.sh` detects the **building machine's** signing identity: it
  uses an Apple Development certificate if that Mac has one, and otherwise falls
  back to ad-hoc signing. No developer name or team ID is hard-coded.
- So a build on your Mac carries *your* code identity. It does not use, borrow,
  or depend on anybody else's certificate, and the maintainer's certificate is
  irrelevant to your copy.
- **Ad-hoc builds and Accessibility:** macOS ties an Accessibility grant to the
  code identity. An ad-hoc identity changes on every rebuild, so the switch in
  System Settings can look “on” while the new binary is untrusted. Fix it from
  the menu-bar icon → **Fix Accessibility Permission…**, which resets the stale
  record and asks again. Builds signed with a stable certificate keep the grant
  across rebuilds.
- **Distributing a signed `.app` to other people is a different problem:** they
  would need a Developer ID signature plus notarization, and the signing key
  must never be published. This project deliberately avoids that by shipping
  source and letting everyone sign locally.

## Troubleshooting

| Symptom | Fix |
|---|---|
| “Clipwharf needs Accessibility access” although the switch is on | Menu-bar icon → **Fix Accessibility Permission…**, then switch Clipwharf on again |
| ⌘⇧V does nothing | Another clipboard manager (e.g. Paste) owns the shortcut; quit it or use the menu-bar icon |
| “Clipwharf.app would like to access data from other apps” | macOS privacy prompt shown the first time QuickLook previews a file owned by another app — allow it once |
| The strip closes when I click another app | By design: it hides when it loses focus. Press ⌘⇧V to bring it back |
| History looks empty after an update | The index is per-user; check `~/Library/Application Support/Clipwharf/history.json` |

## Development

```sh
swift test                                  # core model, storage, search, classification
swift build -c release --product Clipwharf  # compile only
./scripts/make-app.sh debug                 # debug build of the .app
swift scripts/make-icon.swift               # regenerate Support/AppIcon.png
```

## License

Clipwharf is free software under the **GNU Affero General Public License
v3.0**. You may use it, modify it, and share it — including commercially — as
long as derivative works and network services stay open under the same licence.

Products that cannot accept copyleft can buy a **commercial licence**, which
removes those obligations. Prices and terms are in
[COMMERCIAL.md](COMMERCIAL.md); contributions are covered by
[CONTRIBUTING.md](CONTRIBUTING.md).

Copyright and notices: [NOTICE](NOTICE).
