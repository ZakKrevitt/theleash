# Leash Privacy

Effective August 3, 2026

Leash is a local-only macOS application. It does not create an account, run analytics, include telemetry or crash-reporting software, display advertising, or send data over the network.

## Data Leash uses

Leash uses only the information required to run a focus session:

| Data | Why it is used | Where it is stored | Sent anywhere |
|---|---|---|---|
| Task and optional completion text | Shows the task and restores an interrupted session | Local macOS preferences | Never |
| App name and bundle identifier | Recognizes allowed apps and lists caught apps in Caught Apps | Local macOS preferences | Never |
| Duration, mode, and catch count | Enforces and restores the current session | Local macOS preferences | Never |

Leash does not request Accessibility permission. It does not read window titles, URLs, page contents, document contents, screenshots, clipboard data, or keystrokes. It does not collect browsing history.

## Storage

The current session and Caught Apps identities are stored locally in macOS `UserDefaults` so they can survive an app restart. This data is available only to processes running as your macOS user and is never shared with the developer or third parties by Leash.

You can clear Caught Apps inside Leash. Removing the application and its preferences deletes the remaining local data.

## Network and diagnostics

Leash contains no network client, analytics endpoint, telemetry SDK, advertising SDK, or automatic crash reporter. It does not log task text or app activity. If you choose to email a support report, only the information you put in that message is received by the developer.

## Contact

Privacy and support questions can be sent to zak.krevitt@gmail.com.
