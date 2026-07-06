#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Pomodoro"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"
MACOS="$APP/Contents/MacOS"
RES="$APP/Contents/Resources"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RES"

echo "▶︎ コンパイル中…"
swiftc -O -swift-version 5 -parse-as-library \
  -o "$MACOS/$APP_NAME" \
  Sources/*.swift \
  -framework SwiftUI -framework AppKit -framework AVFoundation \
  -framework UserNotifications -framework ServiceManagement

cp Info.plist "$APP/Contents/Info.plist"
if [ -f AppIcon.icns ]; then
  cp AppIcon.icns "$RES/AppIcon.icns"
fi

echo "▶︎ 署名中（アドホック）…"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✅ 完成: $APP"
echo "   起動: open \"$APP\"  → 画面右上のメニューバーに 🍅 が出ます"
