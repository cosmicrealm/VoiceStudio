#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Voice Studio"
RELEASE_VERSION="0.01"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_NAME="Voice-Studio-${RELEASE_VERSION}-macOS-arm64.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
DMG_CHECKSUM_PATH="$DMG_PATH.sha256"
DMG_STAGE_DIR="$DIST_DIR/dmg-stage"
DEMO_SOURCE_AUDIO_PATH="$DIST_DIR/Voice-Studio-${RELEASE_VERSION}-dialogue-demo.webm"
DEMO_AUDIO_PATH="$DIST_DIR/Voice-Studio-${RELEASE_VERSION}-dialogue-demo.mp3"
DEMO_AUDIO_CHECKSUM_PATH="$DEMO_AUDIO_PATH.sha256"

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/build_app_bundle.sh" >/dev/null

rm -f "$DMG_PATH" "$DMG_CHECKSUM_PATH"
rm -f "$DEMO_AUDIO_PATH" "$DEMO_AUDIO_CHECKSUM_PATH"
rm -rf "$DMG_STAGE_DIR"
mkdir -p "$DMG_STAGE_DIR"
cp -R "$APP_DIR" "$DMG_STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME $RELEASE_VERSION" \
  -srcfolder "$DMG_STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null
rm -rf "$DMG_STAGE_DIR"
(cd "$DIST_DIR" && shasum -a 256 "$DMG_NAME") > "$DMG_CHECKSUM_PATH"

if [[ -f "$DEMO_SOURCE_AUDIO_PATH" ]]; then
  ffmpeg -y -loglevel error -i "$DEMO_SOURCE_AUDIO_PATH" -vn -codec:a libmp3lame -b:a 192k "$DEMO_AUDIO_PATH"
fi

if [[ -f "$DEMO_AUDIO_PATH" ]]; then
  (cd "$DIST_DIR" && shasum -a 256 "$(basename "$DEMO_AUDIO_PATH")") > "$DEMO_AUDIO_CHECKSUM_PATH"
fi

echo "$DMG_PATH"
echo "$DMG_CHECKSUM_PATH"
if [[ -f "$DEMO_AUDIO_PATH" ]]; then
  echo "$DEMO_AUDIO_PATH"
  echo "$DEMO_AUDIO_CHECKSUM_PATH"
fi
