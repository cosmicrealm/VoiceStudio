#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Voice Studio"
RELEASE_VERSION="0.01"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ARCHIVE_NAME="Voice-Studio-${RELEASE_VERSION}-macOS-arm64.zip"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"
DEMO_AUDIO_PATH="$DIST_DIR/Voice-Studio-${RELEASE_VERSION}-dialogue-demo.webm"
DEMO_AUDIO_CHECKSUM_PATH="$DEMO_AUDIO_PATH.sha256"
DEMO_TRANSCRIPT_PATH="$DIST_DIR/Voice-Studio-${RELEASE_VERSION}-dialogue-demo.transcript.json"
DEMO_PLAYER_PATH="$DIST_DIR/Voice-Studio-${RELEASE_VERSION}-dialogue-demo.html"
DEMO_PLAYER_CHECKSUM_PATH="$DEMO_PLAYER_PATH.sha256"

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/build_app_bundle.sh" >/dev/null

rm -f "$ARCHIVE_PATH" "$CHECKSUM_PATH"
rm -rf "$DIST_DIR/MacQwenVoice.app"
ditto -c -k --norsrc --keepParent "$APP_DIR" "$ARCHIVE_PATH"
(cd "$DIST_DIR" && shasum -a 256 "$ARCHIVE_NAME") > "$CHECKSUM_PATH"

if [[ -f "$DEMO_AUDIO_PATH" ]]; then
  demo_player_args=(
    "$ROOT_DIR/scripts/build_demo_player.py"
    --audio "$DEMO_AUDIO_PATH" \
    --output "$DEMO_PLAYER_PATH"
  )
  if [[ -f "$DEMO_TRANSCRIPT_PATH" ]]; then
    demo_player_args+=(--transcript-json "$DEMO_TRANSCRIPT_PATH")
  fi
  python3 "${demo_player_args[@]}"
  (cd "$DIST_DIR" && shasum -a 256 "$(basename "$DEMO_AUDIO_PATH")") > "$DEMO_AUDIO_CHECKSUM_PATH"
  (cd "$DIST_DIR" && shasum -a 256 "$(basename "$DEMO_PLAYER_PATH")") > "$DEMO_PLAYER_CHECKSUM_PATH"
fi

echo "$ARCHIVE_PATH"
echo "$CHECKSUM_PATH"
if [[ -f "$DEMO_PLAYER_PATH" ]]; then
  echo "$DEMO_PLAYER_PATH"
  echo "$DEMO_PLAYER_CHECKSUM_PATH"
fi
