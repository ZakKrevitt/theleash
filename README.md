# Leash

Tell your Mac what you are doing. It keeps you there.

Leash is a native, local-first macOS menu bar app for short focus sessions. It watches which app is active across the whole computer, keeps the current task beside your cursor, and intervenes when you switch outside the task.

## How it works

1. Open the app where the work should happen.
2. Open Leash from the menu bar.
3. Name the task and optionally define what done means.
4. Select any other apps the task needs.
5. Choose an intervention and start.

The previously active app becomes the anchor. The companion stays hidden while you work inside an allowed app. It appears beside the cursor only when Leash catches a drift or confirms that you finished.

### Catch me

Leash notices an unrelated app, shows what happened beside the cursor, and saves the distraction in Later. The prompt offers **Done** and **Back to task**, so leaving the work becomes a natural completion checkpoint.

### Pull me back

Leash saves and hides the unrelated app, then reactivates the anchor app. Hiding is reversible and does not quit the app or discard its work.

### Finishing

Click **Done** in the active session panel when the definition of done is true. Leash records a successful completion, releases the session, and confirms it beside the cursor. A timer ending only ends the timebox. It does not claim that the task itself is complete.

## Install

The packaged app is available at `dist/Leash.app` after running:

```bash
./scripts/package-macos.sh
open dist/Leash.app
```

Leash requires macOS 14 or later. The local build is ad hoc signed. A public release would need an Apple Developer ID signature and notarization.

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
```

The session engine is isolated in `LeashCore` and covered by unit tests. The menu bar app and overlay use SwiftUI and AppKit with no third-party dependencies.
