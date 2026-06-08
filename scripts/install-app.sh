#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/JiggleBreak.app"
INSTALL_DIR="/Applications/JiggleBreak.app"

"$ROOT_DIR/scripts/build-app.sh"

pkill -x JiggleBreak 2>/dev/null || true

rm -rf "$INSTALL_DIR"
cp -R "$APP_DIR" "$INSTALL_DIR"
touch "$INSTALL_DIR"

if [ -x "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" ]; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_DIR"
fi

echo "Installed $INSTALL_DIR"
echo "Launchpad indexes apps in /Applications; it may take a moment to refresh."
