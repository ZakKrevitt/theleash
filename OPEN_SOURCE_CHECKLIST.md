# Open-source maintainer checklist

Use this checklist for every outside contribution. A green automated check means that a tool found no known problem. It does not prove that a change is safe.

## Repository controls

- [x] The repository is public under the MIT License.
- [x] `main` blocks force pushes and deletion.
- [x] Every file has `@ZakKrevitt` as its code owner.
- [x] Outside contributors require code-owner approval before merge.
- [x] Stale approvals are dismissed when a contributor pushes again.
- [x] Unresolved review conversations block merge.
- [x] GitHub Actions receives a read-only repository token by default.
- [x] Workflows may use only GitHub-owned actions, pinned to full commit SHAs.
- [x] Workflows from every outside contributor require maintainer approval before they run.
- [x] Secret scanning, push protection, Dependabot, and private vulnerability reporting are enabled.
- [x] Quality, dependency review, and CodeQL checks are required before merge.
- [x] Official binaries are signed, notarized, and tied to a source commit.

## When a pull request arrives

1. Read the description and inspect the **Files changed** tab before running any contributor code.
2. Confirm that the change is focused and that every changed file is relevant to the stated result.
3. Treat the contributor's identity, account age, popularity, and confidence as context, not proof of safety.
4. Do not approve the workflow run until the workflow and script changes in the diff are understood.
5. Wait for every required check to run against the latest commit.
6. Review the complete diff yourself. Automation supports this review but cannot replace it.
7. Approve only after the privacy, security, behavior, and test questions below have clear answers.
8. Squash merge so the final commit is easy to audit and revert.

## Stop and investigate

Do not run or merge the pull request when it contains an unexplained item from this list:

- Encoded, encrypted, minified, generated, or binary content
- A download, installer, executable, archive, or large media file
- Obfuscated names or code that hides control flow
- New networking, telemetry, logging, updater, web view, cloud, or process-launching code
- New access to environment variables, the filesystem, Keychain, clipboard, screen, input, or user documents
- New macOS permissions, entitlements, background services, launch agents, or login items
- A new dependency, package registry, build plugin, or GitHub Action
- A GitHub Action that is not pinned to a full commit SHA
- `pull_request_target`, write permissions, secrets, deployment credentials, or release credentials in a PR workflow
- Changes to signing, notarization, checksums, release scripts, privacy gates, or branch protections
- Tests removed, weakened, skipped, or changed without a behavior reason
- A large refactor mixed into an unrelated feature or bug fix

Ask for a smaller, transparent change. Close and report a contribution that attempts to conceal behavior or obtain credentials.

## Privacy and security review

- [ ] No task text, app activity, credentials, or real user data is included in code, fixtures, logs, screenshots, or issue text.
- [ ] No data leaves the installed Mac app.
- [ ] No account, listener, sync service, telemetry, analytics, advertising, or crash reporter is added.
- [ ] No window title, URL, page, document, screenshot, clipboard, or keystroke collection is added.
- [ ] Local state remains bounded, validated, and limited to the documented data inventory.
- [ ] New input has explicit size and structure limits.
- [ ] Invalid persisted state fails open without trapping the user in a session.
- [ ] Emergency Release, Stop, and Quit continue to work.
- [ ] Any security or privacy boundary change updates `PRIVACY.md`, `SECURITY.md`, and `ADHD-Leash-threat-model.md`.

## Code and dependency review

- [ ] The implementation is the smallest change that solves the stated problem.
- [ ] Every new dependency is necessary, actively maintained, license-compatible, and reviewed at the pinned version.
- [ ] Package lockfiles and resolved versions change exactly as expected.
- [ ] GitHub Actions are GitHub-owned and pinned to reviewed commit SHAs.
- [ ] Network calls in the website use fixed trusted origins and do not expose server credentials to the browser.
- [ ] Server errors do not return secrets, provider responses, stack traces, or user-supplied private data.
- [ ] No sensitive value is printed by tests, build scripts, CI, or release scripts.

## Behavior verification

- [ ] A bug fix has a test or reproducible failing command that fails before the fix and passes after it.
- [ ] New behavior has focused tests for success, empty, and error paths where applicable.
- [ ] `./scripts/qa-macos.sh` passes.
- [ ] `cd website && npm test` passes.
- [ ] CodeQL reports no new alert.
- [ ] Dependency Review reports no unexpected package or known moderate-or-higher vulnerability.
- [ ] The final reviewed commit is still the pull request head after all checks complete.

## After merge

- [ ] Confirm the protected `main` checks pass again.
- [ ] Verify production when website code changed.
- [ ] Build public binaries only from a clean version tag.
- [ ] Sign and notarize official binaries with Apple Team ID `QWT6LQP2GH`.
- [ ] Verify checksums, embedded source commit, Gatekeeper acceptance, and download behavior before enabling downloads.
- [ ] Revert or disable the affected release immediately if the production result differs from the reviewed change.

## Account security

Repository controls cannot protect the project if the maintainer account is compromised. Keep passkeys or two-factor authentication enabled, review active sessions and authorized applications, and never approve a sign-in or workflow run that you did not initiate.
