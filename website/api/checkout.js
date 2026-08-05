import { isLaunchActive, normalizeAmount } from "../pricing.js";

function sendJson(response, status, payload) {
  response.statusCode = status;
  response.setHeader("Content-Type", "application/json; charset=utf-8");
  response.setHeader("Cache-Control", "no-store");
  response.end(JSON.stringify(payload));
}

function siteOrigin(request) {
  if (process.env.PUBLIC_SITE_URL) {
    return new URL(process.env.PUBLIC_SITE_URL).origin;
  }

  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }

  return new URL(request.url, "http://127.0.0.1:4173").origin;
}

export default async function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", "POST");
    sendJson(response, 405, { error: "Method not allowed." });
    return;
  }

  if (process.env.LEASH_DOWNLOADS_ENABLED !== "true") {
    sendJson(response, 503, { error: "The public download is not available yet." });
    return;
  }

  if (!process.env.STRIPE_SECRET_KEY) {
    sendJson(response, 503, { error: "Paid checkout is not connected yet." });
    return;
  }

  try {
    const amount = normalizeAmount(request.body?.amount, isLaunchActive());
    if (amount === 0) {
      sendJson(response, 400, { error: "Free downloads do not need checkout." });
      return;
    }

    const origin = siteOrigin(request);
    const params = new URLSearchParams({
      mode: "payment",
      success_url: `${origin}/?purchase=success`,
      cancel_url: `${origin}/#pricing`,
      "line_items[0][quantity]": "1",
      "line_items[0][price_data][currency]": "eur",
      "line_items[0][price_data][unit_amount]": String(amount * 100),
      "line_items[0][price_data][product_data][name]": "Leash for macOS",
      "line_items[0][price_data][product_data][description]": "Official signed Leash download and project support",
    });

    const stripeResponse = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.STRIPE_SECRET_KEY}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params,
    });
    const session = await stripeResponse.json();

    if (!stripeResponse.ok || !session.url) {
      console.error("Stripe checkout session failed", session.error?.type || stripeResponse.status);
      sendJson(response, 502, { error: "Checkout could not be opened. Please try again." });
      return;
    }

    sendJson(response, 200, { url: session.url });
  } catch (error) {
    sendJson(response, 400, { error: error.message || "Invalid checkout request." });
  }
}
