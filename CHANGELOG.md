# Changelog

## Unreleased

- Added the MIT License and public contribution guidelines.
- Added GitHub issue forms, a pull request template, and continuous integration.
- Expanded source and binary privacy gates against network, cloud, web view, telemetry, and common shell-execution APIs.
- Clarified that public source code cannot access data from installed copies.
- Clarified that website payments support development and the official signed download, while source code remains free under MIT.

## 0.1.0

- Added computer-wide task sessions with Catch me and Pull me back modes.
- Kept the companion hidden while working inside allowed apps.
- Added explicit Done controls in the menu and drift prompt.
- Added an emergency release shortcut with Control-Option-Command-L.
- Added automatic release when the anchor app closes.
- Added first-launch privacy onboarding.
- Opened onboarding automatically on the first launch.
- Required an explicit main app instead of guessing the anchor.
- Kept Catch me visible until the user answers or returns to an allowed app.
- Made Caught Apps available after a session, with one-click reopening for apps still running.
- Added an in-app warning when a browser anchor cannot detect tab changes.
- Added universal Apple Silicon and Intel packaging.
- Added Developer ID signing and notarization automation.
- Added a drag-to-Applications DMG installer with an offline user guide.
- Added checked fallback registration for the emergency release shortcut.
- Limited untrusted app metadata and persisted state to prevent resource exhaustion.
- Removed focused window title collection and the Accessibility permission request.
- Removed the stale Accessibility usage description from the app bundle.
- Added automated privacy gates against networking, telemetry, and activity logging APIs.
- Added fail-open anchor handling.
- Pinned official releases to Apple Team ID `QWT6LQP2GH` and embedded source provenance.
