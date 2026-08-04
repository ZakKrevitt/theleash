import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const guideUrl = new URL("../guide.html", import.meta.url);
const indexUrl = new URL("../index.html", import.meta.url);

test("guide navigation points to complete setup sections", async () => {
  const guide = await readFile(guideUrl, "utf8");
  const sectionLinks = [...guide.matchAll(/<a href="#([^"]+)">/g)].map((match) => match[1]);

  for (const sectionId of sectionLinks) {
    assert.match(guide, new RegExp(`id="${sectionId}"`));
  }

  assert.match(guide, /Leash-macOS-v0\.1\.0\.dmg/);
  assert.match(guide, /Control-Option-Command-L/);
  assert.match(guide, /defaults delete com\.zakkrevitt\.leash/);
  assert.doesNotMatch(guide, /\u2014/);
});

test("site footer links to the user guide", async () => {
  const index = await readFile(indexUrl, "utf8");
  assert.match(index, /href="\/guide\.html">Guide<\/a>/);
});
