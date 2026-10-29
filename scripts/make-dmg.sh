#!/bin/bash
#
# Build a drag-to-Applications disk image: dist/Clipwharf-<version>.dmg
#
# Usage: ./scripts/make-dmg.sh [debug|release]
#
# The DMG is signed with the same identity as the app when one is available, so
# Gatekeeper can evaluate it before mounting. For a build other people can open
# without warnings, sign with a Developer ID and run scripts/notarize.sh.

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
./scripts/make-app.sh "$CONFIG"

APP="dist/Clipwharf.app"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")"
DMG="dist/Clipwharf-${VERSION}.dmg"

STAGE="$(mktemp -d)/Clipwharf"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/Clipwharf.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create \
    -volname "Clipwharf" \
    -srcfolder "$STAGE" \
    -fs HFS+ \
    -format UDZO \
    -ov \
    "$DMG" >/dev/null

rm -rf "$(dirname "$STAGE")"

# Sign the image with the same identity as the app, if we have one.
IDENTITY="$(codesign -dv --verbose=4 "$APP" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
if [[ -n "$IDENTITY" && "$IDENTITY" != "adhoc" ]]; then
    if codesign --force --sign "$IDENTITY" --timestamp "$DMG" 2>/dev/null; then
        echo "Signed $DMG with $IDENTITY"
    else
        echo "warning: could not sign the dmg; it will still open locally" >&2
    fi
fi

SIZE="$(du -h "$DMG" | cut -f1)"
echo "Built $DMG ($SIZE)"
echo
echo "Next: ./scripts/notarize.sh \"$DMG\"   (needs a Developer ID build)"
