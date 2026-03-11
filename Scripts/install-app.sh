#!/bin/zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP_PATH="$("$ROOT_DIR/Scripts/build-app.sh" | tail -n 1)"
TARGET_DIR="$HOME/Applications"
TARGET_APP_PATH="$TARGET_DIR/BufferSave.app"
mkdir -p "$TARGET_DIR"
pkill -x BufferSave >/dev/null 2>&1 || true
rm -rf "$TARGET_APP_PATH"
ditto "$SOURCE_APP_PATH" "$TARGET_APP_PATH"
echo "$TARGET_APP_PATH"
