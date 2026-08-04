import { formatCountdown, isLaunchActive, normalizeAmount, STANDARD_PRICE } from "./pricing.js";

const DOWNLOAD_URL = "/download/Leash-macOS-v0.1.0.dmg";
const priceForm = document.querySelector("#price-form");
const optionButtons = [...document.querySelectorAll("[data-amount]")];
const customInput = document.querySelector("#custom-amount");
const priceTotal = document.querySelector("#price-total");
const purchaseButton = document.querySelector("#purchase-button");
const formStatus = document.querySelector("#form-status");
const countdown = document.querySelector("#countdown");

let selectedAmount = STANDARD_PRICE;

function setStatus(message = "", type = "error") {
  formStatus.textContent = message;
  formStatus.classList.toggle("success", type === "success");
}

function syncPrice(amount) {
  const launchActive = isLaunchActive();
  selectedAmount = normalizeAmount(amount, launchActive);
  priceTotal.textContent = `€${selectedAmount}`;
  purchaseButton.textContent = selectedAmount === 0
    ? "Download for €0"
    : `Pay €${selectedAmount} and download`;
  purchaseButton.disabled = false;

  for (const button of optionButtons) {
    const selected = Number(button.dataset.amount) === selectedAmount;
    button.classList.toggle("selected", selected);
    button.setAttribute("aria-pressed", String(selected));
  }
}

function expireLaunchPricing() {
  const fieldset = priceForm.querySelector("fieldset");
  const customPrice = priceForm.querySelector(".custom-price");
  fieldset.hidden = true;
  customPrice.hidden = true;
  document.querySelector(".pricing-intro > p:not(.section-number)").textContent =
    "Launch week is over. Leash is now a one-time €12 purchase.";
  syncPrice(STANDARD_PRICE);
}

function updateCountdown() {
  countdown.textContent = formatCountdown();
  if (!isLaunchActive()) {
    expireLaunchPricing();
  }
}

for (const button of optionButtons) {
  button.addEventListener("click", () => {
    customInput.value = "";
    setStatus();
    syncPrice(button.dataset.amount);
  });
}

customInput.addEventListener("input", () => {
  setStatus();
  if (customInput.value === "") return;

  try {
    syncPrice(customInput.value);
  } catch (error) {
    setStatus(error.message);
    purchaseButton.disabled = true;
  }
});

priceForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  setStatus();

  try {
    const amount = normalizeAmount(selectedAmount, isLaunchActive());

    if (amount === 0) {
      window.location.assign(DOWNLOAD_URL);
      return;
    }

    purchaseButton.disabled = true;
    purchaseButton.textContent = "Opening secure checkout…";

    const response = await fetch("/api/checkout", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ amount }),
    });
    const payload = await response.json().catch(() => ({}));

    if (!response.ok || !payload.url) {
      throw new Error(payload.error || "Checkout is temporarily unavailable.");
    }

    window.location.assign(payload.url);
  } catch (error) {
    const fallback = isLaunchActive() ? " You can still choose €0 during launch week." : "";
    setStatus(`${error.message}${fallback}`);
    syncPrice(selectedAmount);
    purchaseButton.disabled = false;
  }
});

const query = new URLSearchParams(window.location.search);
if (query.get("purchase") === "success") {
  setStatus("Thank you. Your download is starting now.", "success");
  window.setTimeout(() => window.location.assign(DOWNLOAD_URL), 700);
}

syncPrice(STANDARD_PRICE);
updateCountdown();
window.setInterval(updateCountdown, 1000);
