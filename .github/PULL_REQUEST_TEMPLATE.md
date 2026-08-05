## What changed

Describe the user-visible outcome and why the change is needed.

## Verification

- [ ] `./scripts/qa-macos.sh`
- [ ] `cd website && npm test`
- [ ] Privacy and security behavior is unchanged, or the relevant documentation is updated
- [ ] No credentials, user data, generated packages, or local environment files are included

## Security review

- [ ] The change is limited to the files and behavior described above
- [ ] Every new data flow, dependency, permission, entitlement, and network request is explained below
- [ ] Workflow actions are GitHub-owned and pinned to full commit SHAs
- [ ] No workflow uses `pull_request_target`, repository write access, or secrets from an outside pull request

Write "None" when there is no security or privacy impact:

<!-- Security and privacy impact -->

## Screenshots

Include before and after screenshots for visible changes, or write "Not applicable."
