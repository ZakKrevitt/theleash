function sendJson(response, status, payload) {
  response.statusCode = status;
  response.setHeader("Content-Type", "application/json; charset=utf-8");
  response.setHeader("Cache-Control", "no-store");
  response.end(JSON.stringify(payload));
}

export default function handler(request, response) {
  if (request.method !== "GET") {
    response.setHeader("Allow", "GET");
    sendJson(response, 405, { error: "Method not allowed." });
    return;
  }

  const downloadAvailable = process.env.LEASH_DOWNLOADS_ENABLED === "true";
  sendJson(response, 200, {
    downloadAvailable,
    paidCheckoutAvailable: downloadAvailable && Boolean(process.env.STRIPE_SECRET_KEY),
  });
}
