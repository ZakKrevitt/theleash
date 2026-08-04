# Leash website

Static landing page and Vercel serverless checkout for Leash.

## Local preview

```bash
npm run serve
```

Paid checkout requires `STRIPE_SECRET_KEY` in the Vercel project environment. The server creates the Checkout Session and validates the selected amount. The browser never receives the secret key.

Pay What You Want runs through August 10, 2026 at 23:59:59 Europe/Berlin. After that deadline, both the interface and checkout endpoint enforce the €12 standard price.

## Checks

```bash
npm test
```
