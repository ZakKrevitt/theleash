# Leash 0.1.0 Release Checklist

## Pre-release

- [ ] Install a valid Developer ID Application certificate.
- [ ] Store App Store Connect notarization credentials in a Keychain profile.
- [ ] Run `./scripts/qa-macos.sh` successfully.
- [ ] Run `LEASH_SIGNING_IDENTITY="Developer ID Application: NAME (TEAMID)" LEASH_NOTARY_PROFILE="leash-notary" ./scripts/package-macos.sh --release` successfully.
- [ ] Confirm `spctl` accepts the packaged app.
- [ ] Confirm the SHA-256 checksum matches the release archive.
- [ ] Test with a clean macOS user account after downloading the archive through a browser.
- [ ] Complete the manual QA matrix below.
- [ ] Review `PRIVACY.md` and `CHANGELOG.md`.

## Manual QA matrix

- [ ] First launch explains behavior, privacy, Accessibility, and the emergency release shortcut.
- [ ] Continue works with Accessibility disabled.
- [ ] Optional Accessibility request opens the macOS permission flow.
- [ ] A session cannot start without a task or anchor app.
- [ ] The companion remains hidden while the anchor or another allowed app is active.
- [ ] Catch me shows the drift prompt without hiding the unrelated app.
- [ ] Pull me back hides the unrelated app and restores the anchor.
- [ ] Done releases the session from the menu.
- [ ] Done releases the session from the drift prompt.
- [ ] Ending the timer releases the session without claiming completion.
- [ ] Control-Option-Command-L releases the active session from another app.
- [ ] Closing the anchor app releases the session.
- [ ] Stop and Quit leave no overlay or delayed focus action behind.
- [ ] Full-screen apps and every connected display remain usable.
- [ ] Restarting after a forced process termination safely restores or expires the session.
- [ ] Validate on macOS 14, macOS 15, and macOS 26.
- [ ] Validate on Apple Silicon and Intel hardware.

## Release

- [ ] Upload the notarized archive and checksum to an HTTPS download page.
- [ ] Download the uploaded artifact and verify its checksum.
- [ ] Open the downloaded app and repeat the critical smoke test.
- [ ] Publish the privacy policy and release notes beside the download.
- [ ] Keep the previous notarized archive available for rollback.

## Rollback triggers

Replace the download with the previous notarized version if any of these occur:

- Leash continues hiding or activating apps after a session ends.
- Stop, Quit, or the emergency shortcut cannot release a session.
- The app crashes during ordinary session setup or intervention.
- Gatekeeper rejects the downloaded archive.
- User data outside Leash is changed or lost.
