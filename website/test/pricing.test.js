import assert from "node:assert/strict";
import test from "node:test";

import { formatCountdown, isLaunchActive, normalizeAmount, STANDARD_PRICE } from "../pricing.js";

test("launch week accepts zero and whole-euro paid amounts", () => {
  assert.equal(normalizeAmount(0, true), 0);
  assert.equal(normalizeAmount("12", true), 12);
});

test("pricing rejects invalid and unsafe amounts", () => {
  assert.throws(() => normalizeAmount(-1, true), /between/);
  assert.throws(() => normalizeAmount(1.5, true), /whole-euro/);
  assert.throws(() => normalizeAmount(101, true), /between/);
  assert.throws(() => normalizeAmount("nope", true), /valid/);
});

test("after launch week only the standard price is accepted", () => {
  assert.equal(normalizeAmount(STANDARD_PRICE, false), STANDARD_PRICE);
  assert.throws(() => normalizeAmount(0, false), /after launch week/);
  assert.throws(() => normalizeAmount(20, false), /after launch week/);
});

test("launch deadline is inclusive and countdown expires cleanly", () => {
  assert.equal(isLaunchActive(new Date("2026-08-10T21:59:59Z")), true);
  assert.equal(isLaunchActive(new Date("2026-08-10T22:00:00Z")), false);
  assert.equal(formatCountdown(new Date("2026-08-10T22:00:00Z")), "Launch week has ended");
});
