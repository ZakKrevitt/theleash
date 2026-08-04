#!/bin/zsh
set -euo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

PROJECT_ROOT="${0:A:h:h}"
APP_NAME="Leash"
PLIST_PATH="$PROJECT_ROOT/Support/Info.plist"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$PLIST_PATH")"
APP_DIR="$PROJECT_ROOT/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ZIP_PATH="$PROJECT_ROOT/dist/Leash-macOS-v$VERSION.zip"
DMG_PATH="$PROJECT_ROOT/dist/Leash-macOS-v$VERSION.dmg"
DMG_VOLUME_NAME="Leash $VERSION"
GUIDE_PATH="$PROJECT_ROOT/website/guide.html"
BUILD_DIR="$PROJECT_ROOT/.build/apple/Products/Release"
EXPECTED_TEAM_ID="QWT6LQP2GH"
RELEASE_MODE=false
DMG_STAGING_DIR=""

cleanup() {
    if [[ -n "$DMG_STAGING_DIR" && -d "$DMG_STAGING_DIR" ]]; then
        rm -rf "$DMG_STAGING_DIR"
    fi
}

trap cleanup EXIT

create_dmg() {
    DMG_STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/leash-dmg.XXXXXX")"
    ditto "$APP_DIR" "$DMG_STAGING_DIR/$APP_NAME.app"
    ln -s /Applications "$DMG_STAGING_DIR/Applications"
    cp "$GUIDE_PATH" "$DMG_STAGING_DIR/Leash User Guide.html"

    rm -f "$DMG_PATH"
    hdiutil create \
        -volname "$DMG_VOLUME_NAME" \
        -srcfolder "$DMG_STAGING_DIR" \
        -format UDZO \
        -imagekey zlib-level=9 \
        "$DMG_PATH"

    cleanup
    DMG_STAGING_DIR=""
}

if [[ "${1:-}" == "--release" ]]; then
    RELEASE_MODE=true
elif [[ -n "${1:-}" ]]; then
    echo "Usage: $0 [--release]" >&2
    exit 64
fi

cd "$PROJECT_ROOT"

if $RELEASE_MODE; then
    : "${LEASH_SIGNING_IDENTITY:?Set LEASH_SIGNING_IDENTITY to a Developer ID Application identity}"
    : "${LEASH_NOTARY_PROFILE:?Set LEASH_NOTARY_PROFILE to a notarytool Keychain profile}"
    if [[ "$LEASH_SIGNING_IDENTITY" != "Developer ID Application:"* ]]; then
        echo "LEASH_SIGNING_IDENTITY must name a Developer ID Application certificate." >&2
        exit 65
    fi

    if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
        echo "Release builds require a clean Git worktree." >&2
        exit 66
    fi

    expected_tag="v$VERSION"
    if [[ "$(git tag --points-at HEAD --list "$expected_tag")" != "$expected_tag" ]]; then
        echo "Release commit must be tagged $expected_tag." >&2
        exit 67
    fi
fi

SOURCE_COMMIT="$(git rev-parse --verify HEAD)"
if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    SOURCE_COMMIT="$SOURCE_COMMIT-dirty"
fi
swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/Leash" "$MACOS_DIR/Leash"
cp "$PROJECT_ROOT/assets/Leash.icns" "$RESOURCES_DIR/Leash.icns"
cp "$PLIST_PATH" "$CONTENTS_DIR/Info.plist"
plutil -insert LeashSourceCommit -string "$SOURCE_COMMIT" "$CONTENTS_DIR/Info.plist"

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

if $RELEASE_MODE; then
    signature_details="$(codesign -d --verbose=4 "$APP_DIR" 2>&1)"
    if [[ "$signature_details" != *"TeamIdentifier=$EXPECTED_TEAM_ID"* ]]; then
        echo "Release signature is not owned by Apple team $EXPECTED_TEAM_ID." >&2
        exit 68
    fi
    if [[ "$signature_details" != *"flags=0x10000(runtime)"* ]]; then
        echo "Release signature does not enable Hardened Runtime." >&2
        exit 69
    fi
    if [[ "$signature_details" != *"Timestamp="* ]]; then
        echo "Release signature does not contain a secure timestamp." >&2
        exit 70
    fi
fi

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

unzip -tq "$ZIP_PATH"
create_dmg

if $RELEASE_MODE; then
    codesign \
        --force \
        --timestamp \
        --sign "$LEASH_SIGNING_IDENTITY" \
        "$DMG_PATH"
    codesign --verify --strict --verbose=2 "$DMG_PATH"

    xcrun notarytool submit \
        "$DMG_PATH" \
        --keychain-profile "$LEASH_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
    spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
fi

hdiutil verify "$DMG_PATH"
(
    cd "$PROJECT_ROOT/dist"
    shasum -a 256 "${ZIP_PATH:t}" > "${ZIP_PATH:t}.sha256"
    shasum -a 256 "${DMG_PATH:t}" > "${DMG_PATH:t}.sha256"
)

echo "$APP_DIR"
echo "$ZIP_PATH"
echo "$ZIP_PATH.sha256"
echo "$DMG_PATH"
echo "$DMG_PATH.sha256"
