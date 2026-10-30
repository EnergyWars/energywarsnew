import test from "node:test";
import assert from "node:assert/strict";
import { load, setLanguage } from "../../web/js/i18n.js";
import { descriptionText } from "../../web/js/views/buildingView.js";

const names = {
  BUILDING_ZAPPER_DESC: { en: "Cheap bolts.", de: "Günstige Blitze." },
  BUILDING_LASER_DESC: { en: "Steady beam." },
};

test("description follows the language and falls back to english", async () => {
  globalThis.fetch = async () => ({ json: async () => ({}) });
  await load("en");
  setLanguage("en");
  assert.equal(descriptionText(names, "zapper"), "Cheap bolts.");
  setLanguage("de");
  assert.equal(descriptionText(names, "zapper"), "Günstige Blitze.");
  assert.equal(descriptionText(names, "laser"), "Steady beam.");
});

test("missing description yields an empty string", () => {
  assert.equal(descriptionText(names, "tesla"), "");
  assert.equal(descriptionText({}, "tesla"), "");
});
