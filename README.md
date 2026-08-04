# Leash

Tell your Mac what you are doing. It keeps you there.

Leash is a native, local-first macOS menu bar app for short focus sessions. It watches which app is active across the whole computer and intervenes when you switch outside the task.

## How it works

1. Open Leash from the menu bar.
2. Name the task and set a clear finish line, either one outcome or a checklist.
3. Choose the main app from the apps currently open on your Mac.
4. Select any other open apps the task needs.
5. Choose an intervention and start.

The main app becomes the anchor. The companion stays hidden while you work inside an allowed app. It appears beside the cursor when Leash catches a drift, the timer ends, or you finish.

Control-Option-Command-L releases an active leash from anywhere on the computer. Closing the anchor app also releases the session automatically.

### Catch me

Leash notices an unrelated app, shows what happened beside the cursor, and saves the distraction in Later. The prompt repeats your finish line and asks whether it is true. Checklist sessions can finish only after every step is checked.

### Pull me back

Leash saves and hides the unrelated app, then reactivates the anchor app. Hiding is reversible and does not quit the app or discard its work.

### Finishing

Click **Finish** in the active session panel when the finish line is true. Leash records a successful completion, releases the session, and confirms it beside the cursor. When the timer ends, choose whether to finish, add 10 minutes, or release the leash without claiming completion.

## Install

The packaged app is available at `dist/Leash.app` after running:

```bash
./scripts/package-macos.sh
open dist/Leash.app
```

Leash requires macOS 14 or later. Local packaging produces an ad hoc signed universal build for Apple Silicon and Intel Macs.

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

The script outputs the notarized archive and a SHA-256 checksum in `dist/`. See `RELEASE_CHECKLIST.md` before publishing.

## Permissions and privacy

App-level enforcement works without special permissions. Accessibility permission is optional and lets Leash add the focused window title to Later, which gives you a more useful record of where you wandered.

Leash stores the current session and Later list in local `UserDefaults`. It does not take screenshots, read page contents, use analytics, create an account, or send data over the network.

## Current boundary

This release detects changes between macOS apps. It does not yet distinguish unrelated browser tabs inside the same browser. That requires a small browser companion or local screen classification layer. The native app is the source of truth, so either addition can extend the leash without turning it back into a browser-only product.

## Development

```bash
swift test
swift build -c release
./scripts/package-macos.sh
./scripts/qa-macos.sh
```

The session engine is isolated in `LeashCore` and covered by unit tests. The menu bar app and overlay use SwiftUI and AppKit with no third-party dependencies.
