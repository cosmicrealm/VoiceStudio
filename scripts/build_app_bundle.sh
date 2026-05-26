#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Voice Studio"
EXECUTABLE_NAME="MacQwenVoice"
APP_VERSION="0.01"
APP_BUILD="1"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SOURCE="$ROOT_DIR/Assets/AppIcon.icns"

cd "$ROOT_DIR"
scripts/build_app_icon.sh >/dev/null
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE="$BIN_DIR/$EXECUTABLE_NAME"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR/backend"

cp "$EXECUTABLE" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"
cp backend/server.py "$RESOURCES_DIR/backend/server.py"
cp backend/__init__.py "$RESOURCES_DIR/backend/__init__.py"
cp "$ICON_SOURCE" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacQwenVoice</string>
    <key>CFBundleIdentifier</key>
    <string>local.macqwenvoice.app</string>
    <key>CFBundleName</key>
    <string>Voice Studio</string>
    <key>CFBundleDisplayName</key>
    <string>Voice Studio</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>__APP_VERSION__</string>
    <key>CFBundleVersion</key>
    <string>__APP_BUILD__</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Voice Studio 需要麦克风权限来录制本地音色克隆参考音频，并支持 Script Studio 语音输入。</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Voice Studio 需要系统语音识别权限，把麦克风输入转换为待生成文字。</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>Voice Studio 默认在“文稿/VoiceStudio/Workspace”保存模型、项目、输出音频和本地数据库。</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>NSQuitAlwaysKeepsWindows</key>
    <false/>
</dict>
</plist>
PLIST

perl -0pi -e "s/__APP_VERSION__/$APP_VERSION/g; s/__APP_BUILD__/$APP_BUILD/g" "$CONTENTS_DIR/Info.plist"

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "$APP_DIR"
