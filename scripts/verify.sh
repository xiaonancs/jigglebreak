#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/build-app.sh"

/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$ROOT_DIR/.build/JiggleBreak.app/Contents/Info.plist" >/dev/null
test -f "$ROOT_DIR/.build/JiggleBreak.app/Contents/Resources/AppIcon.icns"

echo "Verification passed."
