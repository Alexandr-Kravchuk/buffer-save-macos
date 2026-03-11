#!/bin/zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$("$ROOT_DIR/Scripts/install-app.sh" | tail -n 1)"
open "$APP_PATH"
