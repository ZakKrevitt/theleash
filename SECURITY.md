# Security Policy

## Supported version

Security fixes are provided for the latest published Leash release.

## Reporting a vulnerability

Send security reports to zak.krevitt@gmail.com. Include the affected version, reproduction steps, and impact. Please do not publish an exploitable report before a fix is available.

## Identifying an official build

Leash is open source, so third parties can compile or modify it. An official binary must satisfy all of these checks:

- Bundle identifier: `com.zakkrevitt.leash`
- Apple Team ID: `QWT6LQP2GH`
- Valid Developer ID signature and Apple notarization
- Source commit embedded in the `LeashSourceCommit` Info.plist key
- SHA-256 checksum matching the value published with the release

Inspect an installed application with:

```bash
codesign -d --verbose=4 /Applications/Leash.app
spctl --assess --type execute --verbose=4 /Applications/Leash.app
plutil -extract LeashSourceCommit raw /Applications/Leash.app/Contents/Info.plist
```

Builds with another Team ID are unofficial forks, even if they use the same name or bundle identifier.

## Data handling

Leash has no account, server, analytics, telemetry, crash reporter, or network client. Task state and app-level identities are stored only in local macOS preferences. Leash does not request Accessibility permission or read focused window titles, URLs, page contents, documents, screenshots, clipboard data, or keystrokes.

Publishing the source repository does not provide access to installed copies. There is no Leash user database, inbound listener, sync service, or outbound runtime connection for an attacker, maintainer, or contributor to query.

Local preferences are protected by the macOS user account boundary. A malicious process that is already running as the same macOS user may be able to read or alter those preferences. Leash does not claim to protect data after the user's operating system account has been compromised. Avoid putting passwords, recovery codes, or other secrets in task text.

Every release must pass `./scripts/qa-macos.sh`. The script rejects networking, telemetry, activity logging, automatic crash reporting, common shell-execution APIs, web views, cloud SDKs, and external Swift packages in the Mac runtime.
