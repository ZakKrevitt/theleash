export const LAUNCH_END = new Date("2026-08-10T21:59:59Z");
export const STANDARD_PRICE = 12;
export const MAX_PRICE = 100;

export function isLaunchActive(now = new Date()) {
  return now.getTime() <= LAUNCH_END.getTime();
}

export function normalizeAmount(value, launchActive = true) {
  const amount = Number(value);

  if (!Number.isFinite(amount)) {
    throw new Error("Enter a valid amount.");
  }

  if (!launchActive && amount !== STANDARD_PRICE) {
    throw new Error(`Leash is €${STANDARD_PRICE} after launch week.`);
  }

  if (launchActive && amount === 0) {
    return 0;
  }

  if (!Number.isInteger(amount) || amount < 1 || amount > MAX_PRICE) {
    throw new Error(`Choose a whole-euro amount between €1 and €${MAX_PRICE}.`);
  }

  return amount;
}

export function formatCountdown(now = new Date()) {
  const remaining = Math.max(0, LAUNCH_END.getTime() - now.getTime());

  if (remaining === 0) {
    return "Launch week has ended";
  }

  const days = Math.floor(remaining / 86_400_000);
  const hours = Math.floor((remaining % 86_400_000) / 3_600_000);
  const minutes = Math.floor((remaining % 3_600_000) / 60_000);
  const seconds = Math.floor((remaining % 60_000) / 1000);

  return `${days}d ${hours}h ${minutes}m ${seconds}s`;
}
