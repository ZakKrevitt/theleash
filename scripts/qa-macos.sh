#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_DIR="$PROJECT_ROOT/dist/Leash.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/Leash"

cd "$PROJECT_ROOT"

swift test
"$PROJECT_ROOT/scripts/package-macos.sh"

lipo "$EXECUTABLE" -verify_arch arm64 x86_64
codesign --verify --deep --strict --verbose=2 "$APP_DIR"
plutil -lint "$APP_DIR/Contents/Info.plist"

[[ "$(plutil -extract CFBundleIdentifier raw "$APP_DIR/Contents/Info.plist")" == "com.zakkrevitt.leash" ]]
[[ "$(plutil -extract LSUIElement raw "$APP_DIR/Contents/Info.plist")" == "true" ]]
[[ "$(plutil -extract LSMinimumSystemVersion raw "$APP_DIR/Contents/Info.plist")" == "14.0" ]]

if rg -n $'\u2014' Sources Tests scripts Support README.md PRIVACY.md RELEASE_CHECKLIST.md CHANGELOG.md; then
    echo "Release text contains a forbidden em dash." >&2
    exit 1
fi

echo "Automated QA passed for $APP_DIR"
