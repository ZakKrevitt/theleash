import { formatCountdown, isLaunchActive, normalizeAmount, STANDARD_PRICE } from "./pricing.js";

const DOWNLOAD_URL = "/download/Leash-macOS-v0.1.0.dmg";
const priceForm = document.querySelector("#price-form");
const optionButtons = [...document.querySelectorAll("[data-amount]")];
const customInput = document.querySelector("#custom-amount");
const priceTotal = document.querySelector("#price-total");
const purchaseButton = document.querySelector("#purchase-button");
const formStatus = document.querySelector("#form-status");
const countdown = document.querySelector("#countdown");
const countdownPanel = document.querySelector(".countdown");
const pricingTitle = document.querySelector("#pricing-title");
const pricingCopy = document.querySelector("#pricing-copy");
const releaseStatus = document.querySelector("#release-status");
const compatibility = document.querySelector("#compatibility");
const fieldset = priceForm.querySelector("fieldset");
const customPrice = priceForm.querySelector(".custom-price");
const purchaseSummaryLabel = document.querySelector(".purchase-summary > span");
const purchaseSucceeded = new URLSearchParams(window.location.search).get("purchase") === "success";

let selectedAmount = STANDARD_PRICE;
let downloadAvailable = false;
let paidCheckoutAvailable = false;

function setStatus(message = "", type = "error") {
  formStatus.textContent = message;
  formStatus.classList.toggle("success", type === "success");
}

function syncPrice(amount) {
  const launchActive = isLaunchActive();
  selectedAmount = normalizeAmount(amount, launchActive);
  priceTotal.textContent = `€${selectedAmount}`;
  purchaseButton.textContent = selectedAmount === 0
    ? "Download Leash"
    : `Pay €${selectedAmount} and download`;
  purchaseButton.disabled = false;

  for (const button of optionButtons) {
    const selected = Number(button.dataset.amount) === selectedAmount;
    button.classList.toggle("selected", selected);
    button.setAttribute("aria-pressed", String(selected));
  }
}

function expireLaunchPricing() {
  fieldset.hidden = true;
  customPrice.hidden = true;
  pricingCopy.textContent = "Launch week is over. Leash is now a one-time €12 purchase.";
  if (paidCheckoutAvailable) syncPrice(STANDARD_PRICE);
}

function updateCountdown() {
  countdown.textContent = formatCountdown();
  if (!isLaunchActive()) expireLaunchPricing();
}

function pauseDownloads(message = "Release status could not be checked. Try again shortly.") {
  downloadAvailable = false;
  paidCheckoutAvailable = false;
  priceForm.hidden = true;
  releaseStatus.hidden = false;
  countdownPanel.hidden = true;
  pricingTitle.textContent = "The public build is being signed.";
  pricingCopy.textContent = "Leash is ready on the Mac. The download opens after Apple accepts the installer.";
  compatibility.textContent = message;
}

function enableFreeDownload() {
  fieldset.disabled = false;
  for (const button of optionButtons) {
    button.hidden = Number(button.dataset.amount) !== 0;
  }
  customPrice.hidden = true;
  purchaseSummaryLabel.textContent = "Your download";
  syncPrice(0);
}

async function loadReleaseStatus() {
  try {
    const response = await fetch("/api/config", { headers: { Accept: "application/json" } });
    const config = await response.json().catch(() => ({}));
    if (!response.ok || !config.downloadAvailable) {
      pauseDownloads("Public download paused until Apple notarization is complete.");
      return;
    }

    downloadAvailable = true;
    paidCheckoutAvailable = Boolean(config.paidCheckoutAvailable);
    priceForm.hidden = false;
    releaseStatus.hidden = true;
    priceForm.setAttribute("aria-busy", "false");
    fieldset.disabled = false;
    purchaseButton.disabled = false;
    compatibility.innerHTML = `Requires macOS 14 or later. <a href="${DOWNLOAD_URL}.sha256">Verify SHA-256</a>`;

    if (purchaseSucceeded) {
      setStatus("Thank you. Your download is starting now.", "success");
      window.setTimeout(() => window.location.assign(DOWNLOAD_URL), 700);
    }

    if (paidCheckoutAvailable) {
      syncPrice(STANDARD_PRICE);
    } else if (isLaunchActive()) {
      pricingTitle.textContent = "Download Leash free.";
      pricingCopy.textContent = "Paid checkout is offline. The app is the same complete build.";
      enableFreeDownload();
    } else {
      pauseDownloads("Paid checkout is temporarily unavailable.");
    }
  } catch {
    pauseDownloads();
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
    if (!downloadAvailable) {
      throw new Error("The public download is not available yet.");
    }
    const amount = normalizeAmount(selectedAmount, isLaunchActive());

    if (amount === 0) {
      window.location.assign(DOWNLOAD_URL);
      return;
    }

    if (!paidCheckoutAvailable) {
      throw new Error("Paid checkout is temporarily unavailable.");
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
    setStatus(error.message);
    syncPrice(selectedAmount);
  }
});

updateCountdown();
window.setInterval(updateCountdown, 1000);
loadReleaseStatus();
