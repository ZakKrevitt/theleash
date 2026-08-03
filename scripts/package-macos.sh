#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_NAME="Leash"
PLIST_PATH="$PROJECT_ROOT/Support/Info.plist"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$PLIST_PATH")"
APP_DIR="$PROJECT_ROOT/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ZIP_PATH="$PROJECT_ROOT/dist/Leash-macOS-v$VERSION.zip"
BUILD_DIR="$PROJECT_ROOT/.build/apple/Products/Release"
RELEASE_MODE=false

if [[ "${1:-}" == "--release" ]]; then
    RELEASE_MODE=true
elif [[ -n "${1:-}" ]]; then
    echo "Usage: $0 [--release]" >&2
    exit 64
fi

if $RELEASE_MODE; then
    : "${LEASH_SIGNING_IDENTITY:?Set LEASH_SIGNING_IDENTITY to a Developer ID Application identity}"
    : "${LEASH_NOTARY_PROFILE:?Set LEASH_NOTARY_PROFILE to a notarytool Keychain profile}"
    if [[ "$LEASH_SIGNING_IDENTITY" != "Developer ID Application:"* ]]; then
        echo "LEASH_SIGNING_IDENTITY must name a Developer ID Application certificate." >&2
        exit 65
    fi
fi

cd "$PROJECT_ROOT"
swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/Leash" "$MACOS_DIR/Leash"
cp "$PROJECT_ROOT/assets/Leash.icns" "$RESOURCES_DIR/Leash.icns"
cp "$PLIST_PATH" "$CONTENTS_DIR/Info.plist"

if $RELEASE_MODE; then
    codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "$LEASH_SIGNING_IDENTITY" \
        "$APP_DIR"
else
    codesign --force --sign - "$APP_DIR"
fi

codesign --verify --deep --strict --verbose=2 "$APP_DIR"
lipo "$MACOS_DIR/Leash" -verify_arch arm64 x86_64
plutil -lint "$CONTENTS_DIR/Info.plist"

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

if $RELEASE_MODE; then
    xcrun notarytool submit \
        "$ZIP_PATH" \
        --keychain-profile "$LEASH_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$APP_DIR"
    xcrun stapler validate "$APP_DIR"

    rm -f "$ZIP_PATH"
    ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
    spctl --assess --type execute --verbose=4 "$APP_DIR"
fi

shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

echo "$APP_DIR"
echo "$ZIP_PATH"
echo "$ZIP_PATH.sha256"
