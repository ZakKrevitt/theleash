# Contributing to Leash

Thanks for helping make Leash better. Bug reports, focused feature proposals, documentation fixes, and small pull requests are welcome.

## Before opening an issue

- Search existing issues first.
- Report security vulnerabilities privately by following [SECURITY.md](SECURITY.md).
- Keep feature proposals within Leash's current boundary: a native, local-first macOS focus tool.

## Local setup

Leash requires macOS 14 or later and a local Xcode toolchain with Swift 6 support.

```bash
git clone https://github.com/ZakKrevitt/theleash.git
cd theleash
swift test
./scripts/package-macos.sh
open dist/Leash.app
```

The website uses Node's built-in test runner and has no package dependencies:

```bash
cd website
npm test
```

## Privacy and security rules

Leash's local-only design is a product requirement. A contribution must not add networking, analytics, telemetry, advertising, activity logging, automatic crash reporting, or an external Swift dependency without an explicit maintainer decision and corresponding updates to the privacy policy and threat model.

Do not collect window titles, URLs, page contents, document contents, screenshots, clipboard data, or keystrokes. Do not add a macOS permission unless the feature cannot work safely without it and the permission is approved before implementation.

Never include real credentials, signing material, user data, or local environment files in a commit.

## Pull requests

Keep changes narrow and explain the user-visible outcome. Add or update tests for changed behavior. Before requesting review, run:

```bash
./scripts/qa-macos.sh
cd website && npm test
```

The QA script tests the session engine, builds a warnings-as-errors universal app, checks privacy constraints, validates the app bundle, and verifies the local DMG and ZIP.

When you open a pull request, GitHub gives its workflows read-only repository access and no release or deployment credentials. The maintainer reviews workflow changes before allowing code from an outside contributor to run. Quality, dependency, and CodeQL checks then run against the proposed commit. Passing checks do not guarantee acceptance. The code owner reviews the complete diff and may request a smaller change or additional evidence before merging.

Submitting a pull request does not grant repository, release, deployment, or user-data access. Contributors never gain access to data from installed copies because Leash has no user service or remote data store.

Maintainers follow [OPEN_SOURCE_CHECKLIST.md](OPEN_SOURCE_CHECKLIST.md) for every outside contribution.

By contributing, you agree that your contribution is licensed under the [MIT License](LICENSE).
