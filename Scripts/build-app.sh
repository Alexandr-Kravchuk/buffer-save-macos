#!/bin/zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/Build/BufferSave.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
cd "$ROOT_DIR"
swift build -c release >&2
BUILD_DIR="$(swift build -c release --show-bin-path)"
ICON_PATH="$("$ROOT_DIR/Scripts/build-icon.sh" | tail -n 1)"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
cp "$BUILD_DIR/BufferSave" "$MACOS_DIR/BufferSave"
cp "$ROOT_DIR/App/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ICON_PATH" "$RESOURCES_DIR/BufferSave.icns"
chmod +x "$MACOS_DIR/BufferSave"
echo "$APP_DIR"
