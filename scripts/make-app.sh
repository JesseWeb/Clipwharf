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

# Ad-hoc signature: no Developer ID needed, but a stable code identity helps
# TCC (Accessibility) remember the app between launches.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
echo "Run it with: open \"$APP\""
