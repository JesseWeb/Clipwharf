# Building and distributing Clipwharf

> **Status: tier one only.** Releases currently ship an **ad-hoc signed** DMG.
> It works, but macOS turns the first launch into a right-click and the
> Accessibility grant has to be re-done after each update. The notarization steps
> below are the upgrade path, waiting on a paid Apple Developer account ($99/year).

Two audiences build this project:

- **Yourself**, for your own Mac. `./scripts/make-app.sh release` is enough, and
  the Accessibility grant is what you have to look after.
- **Other people**, when you publish a download. That needs a Developer ID
  signature and notarization, otherwise Gatekeeper blocks the app on every other
  machine.

This document covers the second case.

> The repository never contains binaries: `dist/` is gitignored and the DMG is
> built by CI on each tag. Without signing secrets the workflow publishes an
> ad-hoc build; with them it notarizes.

## What you need

| Item | Why | Cost |
|---|---|---|
| Apple Developer Program membership | Issues the Developer ID certificate | $99 / year |
| `Developer ID Application` certificate | Signs the app and the DMG | included |
| Notarization credentials | `notarytool` authentication | included |

An **Apple Development** certificate is not enough: it signs builds for your own
devices only and notarization rejects it. `scripts/notarize.sh` checks this
before submitting.

## One-time setup

1. In Xcode → Settings → Accounts, select your team → **Manage Certificates** →
   **+** → **Developer ID Application**.
2. Export it: Keychain Access → *My Certificates* → the certificate → right
   click → **Export "…"** → save as `Certificates.p12` with a password.
3. Keep that file out of the repository. It contains your private key.

Check what the machine has:

```sh
security find-identity -v -p codesigning
```

## Build a signed, universal DMG

```sh
CLIPWHARF_ARCHS="arm64 x86_64" ./scripts/make-dmg.sh release
```

`make-app.sh` picks the identity in this order:

1. `CLIPWHARF_SIGN_IDENTITY`, if set
2. `Developer ID Application` (adds `--options runtime --timestamp`)
3. `Apple Development` (stable local identity for the TCC grant)
4. ad-hoc

With a Developer ID present you get `dist/Clipwharf-<version>.dmg` containing
the app and an `Applications` symlink, both signed, with the hardened runtime
enabled — the prerequisite for notarization.

## Notarize

```sh
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="ABCDE12345"
export APPLE_APP_PASSWORD="abcd-efgh-ijkl-mnop"   # appleid.apple.com → App-Specific Passwords

./scripts/notarize.sh dist/Clipwharf-1.0.0.dmg
```

Or with an App Store Connect API key, which is what CI should use:

```sh
export NOTARY_KEY_PATH="$HOME/keys/AuthKey_ABC123.p8"
export NOTARY_KEY_ID="ABC123"
export NOTARY_ISSUER="00000000-0000-0000-0000-000000000000"
```

The script mounts the DMG, checks the app's authority and hardened-runtime flag,
submits with `notarytool --wait`, then staples and assesses the ticket. A
successful run ends with:

```
The staple and validate action worked!
dist/Clipwharf-1.0.0.dmg: accepted
source=Notarized Developer ID
```

## Verify like a user would

On a Mac that has never seen the build:

```sh
xcrun stapler validate Clipwharf-1.0.0.dmg
spctl --assess --type open --context context:primary-signature --verbose=2 Clipwharf-1.0.0.dmg
open Clipwharf-1.0.0.dmg      # should mount and run with no warning
```

If Gatekeeper still complains, the usual causes are: an upstream app was signed
before the last rebuild, a resource changed after signing, or the DMG was
re-created after stapling.

## Continuous delivery

`.github/workflows/release.yml` runs on `v*` tags. It builds a universal app,
signs it, notarizes the DMG, staples it, and attaches the result to the GitHub
Release. Without signing secrets it does nothing, so forks stay green.

Add these repository secrets (Settings → Secrets and variables → Actions):

| Secret | How to produce it |
|---|---|
| `MACOS_CERT_P12` | `base64 -i Certificates.p12 \| pbcopy` |
| `MACOS_CERT_PASSWORD` | the export password from Keychain Access |
| `APPLE_ID` | your Apple ID |
| `APPLE_TEAM_ID` | ten-character team identifier |
| `APPLE_APP_PASSWORD` | an app-specific password |

To cut a release:

```sh
git tag -a v1.0.1 -m "Clipwharf 1.0.1"
git push origin v1.0.1
```

The workflow creates or updates the release and uploads `Clipwharf-<version>.dmg`.

## Licensing note

Clipwharf is AGPL-3.0, so **you are allowed to redistribute a build** as long as
the licence and notices travel with it, and anyone who modifies it publishes
their source. Publishing an official DMG yourself is a convenience for users,
not a restriction on them.

If you would rather not maintain a signed binary, stop here: the README's
source install path is fully supported and needs no Apple account.
