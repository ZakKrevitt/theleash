# Leash Privacy

Effective August 3, 2026

Leash is a local-first macOS application. It does not create an account, run analytics, display advertising, or send data over the network.

## Data Leash uses

Leash reads the names and bundle identifiers of running applications so it can tell whether the active app belongs inside the current task. If you optionally grant Accessibility permission, Leash also reads the title of the focused window when it catches a drift.

Leash does not take screenshots, read page contents, inspect documents, record keystrokes, or collect browsing history.

## Storage

The current session and the Later list are stored locally in macOS `UserDefaults`. This data remains on the Mac and is not shared with the developer or third parties.

You can clear the Later list inside Leash. Removing the application and its preferences deletes the remaining local data.

## Accessibility permission

Accessibility permission is optional. App-level detection and intervention continue to work without it. You can grant or revoke the permission at any time in System Settings under Privacy & Security, Accessibility.

## Contact

Privacy and support questions can be sent to zak.krevitt@gmail.com.
