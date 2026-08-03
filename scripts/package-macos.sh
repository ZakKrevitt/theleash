#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_NAME="Leash"
APP_DIR="$PROJECT_ROOT/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ZIP_PATH="$PROJECT_ROOT/dist/Leash-macOS-v0.1.0.zip"

cd "$PROJECT_ROOT"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$PROJECT_ROOT/.build/release/Leash" "$MACOS_DIR/Leash"
cp "$PROJECT_ROOT/assets/Leash.icns" "$RESOURCES_DIR/Leash.icns"

cp "$PROJECT_ROOT/Support/Info.plist" "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

echo "$APP_DIR"
echo "$ZIP_PATH"
