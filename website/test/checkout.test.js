import assert from "node:assert/strict";
import test from "node:test";

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
  delete process.env.STRIPE_SECRET_KEY;
  const response = responseRecorder();

  await handler({ method: "POST", url: "https://example.com/api/checkout", body: { amount: 12 } }, response);

  assert.equal(response.statusCode, 503);
  assert.match(response.body.error, /not connected/);
  if (previousKey) process.env.STRIPE_SECRET_KEY = previousKey;
});

test("checkout sends a validated euro amount to Stripe", async () => {
  const previousKey = process.env.STRIPE_SECRET_KEY;
  const previousFetch = global.fetch;
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
});
