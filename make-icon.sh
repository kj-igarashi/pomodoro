#!/bin/bash
# 添付画像から macOS 用の AppIcon.icns を生成する。
# 画像四隅の黒い余白を透明化し、角丸カードだけをアイコンにする。
set -euo pipefail
cd "$(dirname "$0")"

SRC="${1:-icon-source.png}"
MASTER="/tmp/pomo_icon_master.png"

W=$(sips -g pixelWidth "$SRC" | awk '/pixelWidth/{print $2}')
H=$(sips -g pixelHeight "$SRC" | awk '/pixelHeight/{print $2}')

echo "▶︎ 黒い角を透明化中… (${W}x${H})"
magick "$SRC" -alpha set -fuzz 12% -fill none \
  -draw "color 0,0 floodfill" \
  -draw "color $((W-1)),0 floodfill" \
  -draw "color 0,$((H-1)) floodfill" \
  -draw "color $((W-1)),$((H-1)) floodfill" \
  "$MASTER"

echo "   角のピクセル: $(magick "$MASTER" -format 'p{0,0}=%[pixel:p{0,0}]' info:)"

ICONSET="Pomodoro.iconset"
rm -rf "$ICONSET"; mkdir "$ICONSET"
gen() { sips -z "$1" "$1" "$MASTER" --out "$ICONSET/$2" >/dev/null; }
gen 16   icon_16x16.png
gen 32   icon_16x16@2x.png
gen 32   icon_32x32.png
gen 64   icon_32x32@2x.png
gen 128  icon_128x128.png
gen 256  icon_128x128@2x.png
gen 256  icon_256x256.png
gen 512  icon_256x256@2x.png
gen 512  icon_512x512.png
gen 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET" -o AppIcon.icns
rm -rf "$ICONSET"
echo "✅ AppIcon.icns 生成完了"
