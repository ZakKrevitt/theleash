# Leash website

Static landing page and Vercel serverless checkout for Leash.

The primary download is the versioned DMG in `download/`. Keep its SHA-256 file beside it and retain the ZIP as a fallback release artifact.

## Local preview

```bash
npm run serve
```

Paid checkout requires `STRIPE_SECRET_KEY` in the Vercel project environment. The server creates the Checkout Session and validates the selected amount. The browser never receives the secret key.

Downloads remain closed unless `LEASH_DOWNLOADS_ENABLED=true`. Set it only after the published DMG is Developer ID signed, notarized, stapled, and accepted by `spctl` after a fresh browser download.

Pay What You Want runs through August 10, 2026 at 23:59:59 Europe/Berlin. After that deadline, both the interface and checkout endpoint enforce the €12 standard price.

## Checks

```bash
npm test
```
