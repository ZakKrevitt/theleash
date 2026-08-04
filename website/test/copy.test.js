import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const publicFiles = [
  "../index.html",
  "../guide.html",
  "../privacy.html",
  "../security.html",
  "../styles.css",
];

test("public pages avoid typographic slop", async () => {
  const contents = await Promise.all(
    publicFiles.map((file) => readFile(new URL(file, import.meta.url), "utf8")),
  );
  const site = contents.join("\n");

  assert.doesNotMatch(site, /<em>/);
  assert.doesNotMatch(site, /text-transform:\s*uppercase/);
  assert.doesNotMatch(site, />\s*\d{2}\s*\//);
  assert.doesNotMatch(site, />\s*(?:LEGAL|SETUP)\s*\//);
  assert.doesNotMatch(site, /<button[^>]*data-amount[^>]*>[^<]+<small>/);
  assert.doesNotMatch(site, /\u2014/);
});
