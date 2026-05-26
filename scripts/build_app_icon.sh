#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$ROOT_DIR/Assets"
SOURCE_SVG="$ASSET_DIR/AppIcon.svg"
SOURCE_PNG="$ASSET_DIR/AppIcon.png"
ICONSET="$ASSET_DIR/AppIcon.iconset"
ICNS="$ASSET_DIR/AppIcon.icns"

if [[ ! -f "$SOURCE_SVG" ]]; then
  echo "Missing icon source: $SOURCE_SVG" >&2
  exit 1
fi

rm -f "$SOURCE_PNG" "$ASSET_DIR/AppIcon.svg.png" "$ICNS"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

qlmanage -t -s 1024 -o "$ASSET_DIR" "$SOURCE_SVG" >/dev/null 2>&1
if [[ ! -f "$ASSET_DIR/AppIcon.svg.png" ]]; then
  echo "QuickLook failed to render $SOURCE_SVG" >&2
  exit 1
fi
mv "$ASSET_DIR/AppIcon.svg.png" "$SOURCE_PNG"

sips -s format png -z 16 16 "$SOURCE_PNG" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -s format png -z 32 32 "$SOURCE_PNG" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -s format png -z 32 32 "$SOURCE_PNG" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -s format png -z 64 64 "$SOURCE_PNG" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -s format png -z 128 128 "$SOURCE_PNG" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -s format png -z 256 256 "$SOURCE_PNG" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -s format png -z 256 256 "$SOURCE_PNG" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -s format png -z 512 512 "$SOURCE_PNG" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -s format png -z 512 512 "$SOURCE_PNG" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -s format png -z 1024 1024 "$SOURCE_PNG" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$ICONSET" -o "$ICNS"
echo "$ICNS"
