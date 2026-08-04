import assert from "node:assert/strict";
import test from "node:test";

import configHandler from "../api/config.js";
import handler from "../api/checkout.js";

function responseRecorder() {
  return {
    headers: {},
    statusCode: 0,
    setHeader(name, value) { this.headers[name] = value; },
    end(body) { this.body = JSON.parse(body); },
  };
}

test("checkout rejects unsupported methods", async () => {
  const response = responseRecorder();
  await handler({ method: "GET", url: "https://example.com/api/checkout" }, response);
  assert.equal(response.statusCode, 405);
  assert.equal(response.headers.Allow, "POST");
});

test("checkout reports missing payment configuration", async () => {
  const previousKey = process.env.STRIPE_SECRET_KEY;
  const previousDownloadState = process.env.LEASH_DOWNLOADS_ENABLED;
  process.env.LEASH_DOWNLOADS_ENABLED = "true";
  delete process.env.STRIPE_SECRET_KEY;
  const response = responseRecorder();

  await handler({ method: "POST", url: "https://example.com/api/checkout", body: { amount: 12 } }, response);

  assert.equal(response.statusCode, 503);
  assert.match(response.body.error, /not connected/);
  if (previousKey) process.env.STRIPE_SECRET_KEY = previousKey;
  if (previousDownloadState) process.env.LEASH_DOWNLOADS_ENABLED = previousDownloadState;
  else delete process.env.LEASH_DOWNLOADS_ENABLED;
});

test("checkout stays closed until a notarized download is enabled", async () => {
  const previousDownloadState = process.env.LEASH_DOWNLOADS_ENABLED;
  delete process.env.LEASH_DOWNLOADS_ENABLED;
  const response = responseRecorder();

  await handler({ method: "POST", url: "https://example.com/api/checkout", body: { amount: 12 } }, response);

  assert.equal(response.statusCode, 503);
  assert.match(response.body.error, /not available/);
  if (previousDownloadState) process.env.LEASH_DOWNLOADS_ENABLED = previousDownloadState;
});

test("checkout sends a validated euro amount to Stripe", async () => {
  const previousKey = process.env.STRIPE_SECRET_KEY;
  const previousDownloadState = process.env.LEASH_DOWNLOADS_ENABLED;
  const previousFetch = global.fetch;
  process.env.LEASH_DOWNLOADS_ENABLED = "true";
  process.env.STRIPE_SECRET_KEY = "sk_test_example";
  let stripeRequest;
  global.fetch = async (url, options) => {
    stripeRequest = { url, options };
    return { ok: true, json: async () => ({ url: "https://checkout.stripe.com/example" }) };
  };
  const response = responseRecorder();

  await handler({ method: "POST", url: "https://leash.example/api/checkout", body: { amount: 12 } }, response);

  assert.equal(response.statusCode, 200);
  assert.equal(response.body.url, "https://checkout.stripe.com/example");
  assert.equal(stripeRequest.url, "https://api.stripe.com/v1/checkout/sessions");
  assert.equal(stripeRequest.options.body.get("line_items[0][price_data][unit_amount]"), "1200");
  assert.equal(stripeRequest.options.body.get("success_url"), "https://leash.example/?purchase=success");

  global.fetch = previousFetch;
  if (previousKey) process.env.STRIPE_SECRET_KEY = previousKey;
  else delete process.env.STRIPE_SECRET_KEY;
  if (previousDownloadState) process.env.LEASH_DOWNLOADS_ENABLED = previousDownloadState;
  else delete process.env.LEASH_DOWNLOADS_ENABLED;
});

test("public config exposes only release availability", () => {
  const previousKey = process.env.STRIPE_SECRET_KEY;
  const previousDownloadState = process.env.LEASH_DOWNLOADS_ENABLED;
  process.env.LEASH_DOWNLOADS_ENABLED = "true";
  process.env.STRIPE_SECRET_KEY = "sk_test_example";
  const response = responseRecorder();

  configHandler({ method: "GET" }, response);

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, {
    downloadAvailable: true,
    paidCheckoutAvailable: true,
  });
  assert.doesNotMatch(JSON.stringify(response.body), /sk_test/);

  if (previousKey) process.env.STRIPE_SECRET_KEY = previousKey;
  else delete process.env.STRIPE_SECRET_KEY;
  if (previousDownloadState) process.env.LEASH_DOWNLOADS_ENABLED = previousDownloadState;
  else delete process.env.LEASH_DOWNLOADS_ENABLED;
});
