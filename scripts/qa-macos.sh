#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_DIR="$PROJECT_ROOT/dist/Leash.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/Leash"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$PROJECT_ROOT/Support/Info.plist")"
ARCHIVE="$PROJECT_ROOT/dist/Leash-macOS-v$VERSION.zip"
DISK_IMAGE="$PROJECT_ROOT/dist/Leash-macOS-v$VERSION.dmg"
MOUNT_DIR=""

cleanup() {
    if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
        hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
        rmdir "$MOUNT_DIR" 2>/dev/null || true
    fi
}

trap cleanup EXIT

cd "$PROJECT_ROOT"

forbidden_source_pattern='import (Network|OSLog)|URLSession|NW(Connection|Listener|Browser|PathMonitor)|CFStreamCreate|CFSocketCreate|socket\(|Logger\(|os_log\(|NSLog\(|print\(|Telemetry|Analytics|Sentry|Crashlytics|Mixpanel|Amplitude|PostHog|Segment'
if rg -n "$forbidden_source_pattern" Sources --glob '*.swift'; then
    echo "Privacy gate found networking, telemetry, or activity logging code." >&2
    exit 1
fi
if rg -n '\.package[[:space:]]*\(' Package.swift; then
    echo "Privacy gate found an external Swift package dependency." >&2
    exit 1
fi

swift test
swift build -c release -Xswiftc -warnings-as-errors
"$PROJECT_ROOT/scripts/package-macos.sh"

lipo "$EXECUTABLE" -verify_arch arm64 x86_64
codesign --verify --deep --strict --verbose=2 "$APP_DIR"
plutil -lint "$APP_DIR/Contents/Info.plist"

[[ "$(plutil -extract CFBundleIdentifier raw "$APP_DIR/Contents/Info.plist")" == "com.zakkrevitt.leash" ]]
[[ "$(plutil -extract LSUIElement raw "$APP_DIR/Contents/Info.plist")" == "true" ]]
[[ "$(plutil -extract LSMinimumSystemVersion raw "$APP_DIR/Contents/Info.plist")" == "14.0" ]]
if plutil -extract NSAccessibilityUsageDescription raw "$APP_DIR/Contents/Info.plist" >/dev/null 2>&1; then
    echo "Packaged app declares an Accessibility permission it does not use." >&2
    exit 1
fi
expected_source_commit="$(git rev-parse --verify HEAD)"
if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    expected_source_commit="$expected_source_commit-dirty"
fi
[[ "$(plutil -extract LeashSourceCommit raw "$APP_DIR/Contents/Info.plist")" == "$expected_source_commit" ]]

(
    cd "$PROJECT_ROOT/dist"
    shasum -a 256 -c "${ARCHIVE:t}.sha256"
    shasum -a 256 -c "${DISK_IMAGE:t}.sha256"
)
unzip -tq "$ARCHIVE"
hdiutil verify "$DISK_IMAGE"

MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/leash-qa-mount.XXXXXX")"
hdiutil attach "$DISK_IMAGE" -nobrowse -readonly -mountpoint "$MOUNT_DIR" -quiet
[[ -d "$MOUNT_DIR/Leash.app" ]]
[[ -L "$MOUNT_DIR/Applications" ]]
[[ "$(readlink "$MOUNT_DIR/Applications")" == "/Applications" ]]
[[ -f "$MOUNT_DIR/Leash User Guide.html" ]]
cmp "$MOUNT_DIR/Leash User Guide.html" "$PROJECT_ROOT/website/guide.html"
codesign --verify --deep --strict --verbose=2 "$MOUNT_DIR/Leash.app"
[[ "$(plutil -extract CFBundleIdentifier raw "$MOUNT_DIR/Leash.app/Contents/Info.plist")" == "com.zakkrevitt.leash" ]]
cleanup
MOUNT_DIR=""

if rg -n $'\u2014' Sources Tests scripts Support README.md PRIVACY.md RELEASE_CHECKLIST.md CHANGELOG.md SECURITY.md ADHD-Leash-threat-model.md website/guide.html website/index.html website/test/guide.test.js; then
    echo "Release text contains a forbidden em dash." >&2
    exit 1
fi

echo "Automated QA passed for $APP_DIR"
