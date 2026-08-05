# Leash

Tell your Mac what you are doing. It keeps you there.

Leash is a native, local-first macOS menu bar app for short focus sessions. It watches which app is active across the whole computer and intervenes when you switch outside the task.

[![CI](https://github.com/ZakKrevitt/theleash/actions/workflows/ci.yml/badge.svg)](https://github.com/ZakKrevitt/theleash/actions/workflows/ci.yml)
[MIT licensed](LICENSE)

## How it works

1. Open Leash from the menu bar.
2. Name the task and set a clear finish line, either one outcome or a checklist.
3. Choose the main app from the apps currently open on your Mac.
4. Select any other open apps the task needs.
5. Choose an intervention and start.

The main app becomes the anchor. The companion stays hidden while you work inside an allowed app. It appears beside the cursor when Leash catches a drift, the timer ends, or you finish.

Control-Option-Command-L releases an active leash from anywhere on the computer. Closing the anchor app also releases the session automatically.

### Catch me

Leash notices an unrelated app, shows what happened beside the cursor, and saves the app in Caught Apps. The prompt repeats your finish line and asks whether it is true. Checklist sessions can finish only after every step is checked.

### Pull me back

Leash saves and hides the unrelated app, then reactivates the anchor app. Hiding is reversible and does not quit the app or discard its work.

### Finishing

Click **Finish** in the active session panel when the finish line is true. Leash records a successful completion, releases the session, and confirms it beside the cursor. When the timer ends, choose whether to finish, add 10 minutes, or release the leash without claiming completion.

## Install

Download the DMG, open it, and drag Leash into the Applications folder. On first launch, open Leash from Applications or Spotlight. Leash lives in the menu bar and does not open a Dock window.

The local installer and ZIP are available in `dist/` after running:

```bash
./scripts/package-macos.sh
open dist/Leash-macOS-v0.1.0.dmg
```

Leash requires macOS 14 or later. Local packaging produces an ad hoc signed universal build for Apple Silicon and Intel Macs. See the [Leash User Guide](website/guide.html) for first-run instructions, session setup, troubleshooting, updates, privacy, and uninstall steps.

## Release packaging

Public packages require a Developer ID Application certificate and a `notarytool` Keychain profile. Store notarization credentials once:

```bash
xcrun notarytool store-credentials leash-notary \
  --apple-id "APPLE_ID" \
  --team-id "TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

Then build, sign, notarize, staple, and validate the release:

```bash
LEASH_SIGNING_IDENTITY="Developer ID Application: NAME (TEAMID)" \
LEASH_NOTARY_PROFILE="leash-notary" \
./scripts/package-macos.sh --release
```

The script outputs a notarized DMG installer, a ZIP fallback, and SHA-256 checksums in `dist/`. See `RELEASE_CHECKLIST.md` before publishing.

Official releases are built from a clean `v<version>` Git tag, signed by Apple Team ID `QWT6LQP2GH`, and embed the exact source commit in `LeashSourceCommit`. See `SECURITY.md` for verification commands.

## Permissions and privacy

Leash works without special permissions. It observes app-level activation through macOS workspace events and does not request Accessibility access.

Leash stores the current session and Caught Apps identities in local `UserDefaults`. It does not read window titles, URLs, page contents, documents, screenshots, clipboard data, or keystrokes. It has no analytics, telemetry, crash reporter, account, or network client. See `PRIVACY.md` for the complete data inventory.

Publishing this source code does not expose data from installed copies. The app has no service that can receive task or app activity. A process that has already compromised the same macOS user account may be able to read that user's local preferences, which is outside Leash's security boundary. See `SECURITY.md` and `ADHD-Leash-threat-model.md` for the verified threat model.

## Current boundary

This release detects changes between macOS apps. It does not yet distinguish unrelated browser tabs inside the same browser. That requires a small browser companion or local screen classification layer. The native app is the source of truth, so either addition can extend the leash without turning it back into a browser-only product.

## Development

Clone the project, run the tests, and open a local ad hoc signed build:

```bash
git clone https://github.com/ZakKrevitt/theleash.git
cd theleash
swift test
./scripts/package-macos.sh
open dist/Leash.app
```

Before submitting a change, run the full local checks:

```bash
./scripts/qa-macos.sh
cd website && npm test
```

The session engine is isolated in `LeashCore` and covered by unit tests. The menu bar app and overlay use SwiftUI and AppKit with no third-party dependencies.

See [CONTRIBUTING.md](CONTRIBUTING.md) before opening an issue or pull request. Security vulnerabilities should be reported privately according to [SECURITY.md](SECURITY.md).

## License and official builds

Leash source code is available under the [MIT License](LICENSE). You may use, modify, and redistribute it under those terms.

Official downloads are Developer ID signed and notarized by Apple Team ID `QWT6LQP2GH`. Payments on the Leash website support development and provide the official packaged download. Building the source yourself does not require payment.

The Leash name and logo identify the official project. Forks may use the MIT-licensed code but must not claim to be official or endorsed builds.
