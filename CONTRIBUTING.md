# Contributing to Clipwharf

Thanks for wanting to help. This project is small on purpose: a local-only
clipboard history for macOS, no accounts, no cloud, no telemetry. Please read the
scope before writing code.

By opening a pull request you agree to the [Contributor License
Agreement](#contributor-license-agreement) at the bottom of this file.

## Before you start

- **Bug reports and ideas** — open an issue. Say which macOS version, which
  build (`codesign -dv /Applications/Clipwharf.app` shows the identity), and what
  you expected.
- **Large changes** — open an issue first. The project deliberately keeps a
  narrow surface; a 1,500-line refactor will probably be declined even if it is
  good code.
- **Security issues** — do not open a public issue. Contact the maintainer
  privately through the address on their GitHub profile.

## Scope rules

Features that fit:

- clipboard capture, storage, search, and the bottom card strip
- new content types that macOS can put on the pasteboard
- performance, accessibility, and correctness fixes
- documentation and translations

Features that do not fit:

- any network access, sync, telemetry, analytics, or auto-update
- accounts, licensing checks inside the app, or paywalls
- anything copied from another clipboard manager (code, assets, icons, sounds)
- a settings window with dozens of toggles

## Development

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
swift test                                  # 31 core tests, no UI
swift build -c release --product Clipwharf  # type-checks the AppKit/SwiftUI target
./scripts/make-app.sh release               # builds and signs dist/Clipwharf.app
```

Requirements: macOS 13+, Xcode 15+ (Swift 5.9+).

`Sources/ClipwharfCore` must stay free of AppKit imports — that is what lets the
tests run on Linux CI. UI work belongs in `Sources/Clipwharf`.

## Before you open a pull request

- [ ] `swift test` passes.
- [ ] `swift build -c release --product Clipwharf` passes (tests do not
      type-check the UI target).
- [ ] The panel still works by hand: ⌘⇧V, ←/→, ⏎, ⌘P, ⌘1/⌘2, esc.
- [ ] New behaviour has a test when it lives in `ClipwharfCore`.
- [ ] User-facing changes update `README.md` **and** the five translations
      (`README.zh-CN.md`, `README.zh-TW.md`, `README.ja.md`, `README.fr.md`,
      `README.es.md`). English is the source of truth.
- [ ] No build products, signing material, or screenshots of your own clipboard
      contents are committed.

Use a short, imperative commit subject. Keep unrelated changes in separate
commits.

## Style

- Swift 5.9 compatible, no third-party dependencies.
- Follow the existing file layout and naming; comments explain *why*, not *what*.
- Keep user-visible strings plain and short; the UI is in English.
- Prefer small, testable types in `ClipwharfCore` over logic inside views.

## Contributor License Agreement

To keep the project able to offer commercial licences (see
[COMMERCIAL.md](COMMERCIAL.md)), the maintainer needs broader rights in
contributions than the public licence grants. This is a licence, **not** a
copyright assignment: you keep your copyright.

By submitting a contribution (pull request, patch, or code in an issue) you
represent and agree that:

1. **You have the right to submit it.** The work is yours, or you have permission
   from the copyright holder, and it does not knowingly infringe anyone's rights.
2. **Copyright licence.** You grant JesseWeb and Clipwharf contributors a
   perpetual, worldwide, non-exclusive, royalty-free, irrevocable copyright
   licence to reproduce, prepare derivative works of, publicly display, publicly
   perform, sublicense, distribute, and **relicense** your contribution, under
   this project's public licence or under any other terms, including commercial
   terms.
3. **Patent licence.** You grant a perpetual, worldwide, non-exclusive,
   royalty-free, irrevocable patent licence to make, use, sell, offer for sale,
   import, and otherwise transfer your contribution, limited to patent claims you
   own or control that are necessarily infringed by your contribution alone or by
   its combination with this project.
4. **Moral rights.** To the extent the law allows, you waive, and agree not to
   assert, moral rights in your contribution.
5. **No warranty.** The contribution is provided "as is", without warranty of any
   kind, and you are not required to provide support for it.
6. **No obligation.** The maintainer is not obliged to merge, keep, or maintain
   your contribution.

### How to accept

Add this line to your pull request description:

```
I agree to the Clipwharf CLA (CONTRIBUTING.md).
```

That statement, together with your GitHub account and the commits in the pull
request, is the record of your agreement. If you contribute on behalf of an
employer, make sure you are allowed to grant these rights — otherwise have the
employer sign a corporate CLA by opening an issue.

## Licence of your contribution

Your contribution is published under the project's
[LICENSE](LICENSE) like the rest of the code. Nothing in this file changes the
rights of people who merely use Clipwharf.
