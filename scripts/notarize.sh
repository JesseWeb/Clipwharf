#!/bin/bash
#
# Notarize and staple a Clipwharf disk image.
#
# Usage:
#   ./scripts/notarize.sh dist/Clipwharf-1.0.0.dmg
#
# Credentials, pick one:
#
#   App-specific password (easiest):
#     APPLE_ID=you@example.com
#     APPLE_TEAM_ID=ABCDE12345
#     APPLE_APP_PASSWORD=abcd-efgh-ijkl-mnop
#
#   App Store Connect API key (best for CI):
#     NOTARY_KEY_PATH=/path/AuthKey_XXXX.p8
#     NOTARY_KEY_ID=XXXX
#     NOTARY_ISSUER=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#
# The app inside the DMG must be signed with a "Developer ID Application"
# certificate and the hardened runtime; scripts/make-app.sh does that
# automatically when such an identity is present.

set -euo pipefail

DMG="${1:-}"
if [[ -z "$DMG" || ! -f "$DMG" ]]; then
    echo "usage: $0 <path/to/Clipwharf-x.y.z.dmg>" >&2
    exit 64
fi

# --- Preflight ---------------------------------------------------------------

MOUNT_POINT="$(mktemp -d)/mnt"
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT_POINT" >/dev/null
APP_PATH="$MOUNT_POINT/Clipwharf.app"

if [[ ! -d "$APP_PATH" ]]; then
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
    echo "error: $DMG does not contain Clipwharf.app" >&2
    exit 1
fi

AUTHORITY="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
HARDENED="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -c "flags=0x10000(runtime)" || true)"
hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true

if [[ "$AUTHORITY" != Developer\ ID\ Application:* ]]; then
    cat >&2 <<EOF
error: the app is signed with "${AUTHORITY:-no identity}".
Notarization needs a "Developer ID Application" certificate.

Install one (Apple Developer Program, \$99/year), then rebuild:
  CLIPWHARF_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \\
    ./scripts/make-dmg.sh release
EOF
    exit 1
fi

if [[ "$HARDENED" == "0" ]]; then
    echo "error: the hardened runtime flag is missing; rebuild so codesign adds --options runtime" >&2
    exit 1
fi

# --- Submit ------------------------------------------------------------------

if [[ -n "${NOTARY_KEY_PATH:-}" && -n "${NOTARY_KEY_ID:-}" && -n "${NOTARY_ISSUER:-}" ]]; then
    echo "Submitting with an App Store Connect API key…"
    xcrun notarytool submit "$DMG" \
        --key "$NOTARY_KEY_PATH" \
        --key-id "$NOTARY_KEY_ID" \
        --issuer "$NOTARY_ISSUER" \
        --wait
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
    echo "Submitting with an app-specific password…"
    xcrun notarytool submit "$DMG" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait
else
    cat >&2 <<'EOF'
error: no notarization credentials found.

Set either:
  APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD
or:
  NOTARY_KEY_PATH, NOTARY_KEY_ID, NOTARY_ISSUER
EOF
    exit 1
fi

# --- Staple and verify -------------------------------------------------------

xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"

echo
echo "Notarized and stapled: $DMG"
