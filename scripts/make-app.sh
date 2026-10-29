#!/bin/bash
#
# Build Clipwharf.app into dist/.
#
# Usage: ./scripts/make-app.sh [debug|release]
# The app is ad-hoc signed so macOS can remember its Accessibility grant.

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
swift build -c "$CONFIG" --product Clipwharf

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
APP="dist/Clipwharf.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Clipwharf" "$APP/Contents/MacOS/Clipwharf"
cp Support/Info.plist "$APP/Contents/Info.plist"

# App icon: turn Support/AppIcon.png into Contents/Resources/AppIcon.icns.
if [[ -f Support/AppIcon.png ]]; then
    ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    while IFS=: read -r pixels name; do
        sips -z "$pixels" "$pixels" Support/AppIcon.png \
            --out "$ICONSET_DIR/icon_${name}.png" >/dev/null
    done <<'SIZES'
16:16x16
32:16x16@2x
32:32x32
64:32x32@2x
128:128x128
256:128x128@2x
256:256x256
512:256x256@2x
512:512x512
1024:512x512@2x
SIZES
    iconutil -c icns "$ICONSET_DIR" -o "$APP/Contents/Resources/AppIcon.icns"
    rm -rf "$(dirname "$ICONSET_DIR")"
fi

# Ad-hoc signing works, but macOS ties an ad-hoc code identity to the exact
# binary: every rebuild invalidates the Accessibility grant. Prefer a stable
# identity (an Apple Development certificate, if the Mac has one) so TCC keeps
# the grant across rebuilds. Override with CLIPWHARF_SIGN_IDENTITY.
SIGN_ID="${CLIPWHARF_SIGN_IDENTITY:-}"
if [[ -z "$SIGN_ID" ]]; then
    SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/.*"\(Apple Development:.*\)"/\1/p' | head -1)"
fi

if [[ -n "$SIGN_ID" ]]; then
    if codesign --force --sign "$SIGN_ID" "$APP" 2>/dev/null; then
        echo "Signed with $SIGN_ID"
    else
        echo "warning: signing with $SIGN_ID failed; falling back to ad-hoc"
        codesign --force --sign - "$APP" >/dev/null 2>&1 || true
    fi
else
    # Ad-hoc signature: no Developer ID needed, but the Accessibility grant is
    # invalidated whenever the binary changes.
    codesign --force --sign - "$APP" >/dev/null 2>&1 || true
fi

echo "Built $APP"
echo "Run it with: open \"$APP\""
