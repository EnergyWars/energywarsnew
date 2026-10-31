import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { translate } from "../../web/js/i18n.js";
import { game } from "./data.js";

const read = (code) => JSON.parse(readFileSync(new URL(`../../web/i18n/${code}.json`, import.meta.url), "utf8"));
const dictionary = { de: read("de"), en: read("en") };

test("both languages define the same keys", () => {
  assert.deepEqual(Object.keys(dictionary.de).sort(), Object.keys(dictionary.en).sort());
});

test("translate falls back to english, then to the key", () => {
  const partial = { de: {}, en: { a: "Hello {name}" } };
  assert.equal(translate(partial, "de", "a", { name: "X" }), "Hello X");
  assert.equal(translate(partial, "de", "missing"), "missing");
  assert.equal(translate(partial, "en", "a"), "Hello {name}");
});

test("german texts are used when present", () => {
  assert.equal(translate(dictionary, "de", "action.save"), "Speichern");
});

test("every model error code has a translation", () => {
  for (const code of ["SCHEMA", "GROWTH", "TRACK_SET", "BUILDING_SET", "TYPE", "UNKNOWN_KEY", "MAX", "PRICE", "POSITIVE", "MISSING", "COST", "UPGRADE_BASE", "HP", "TRACKS", "CURVE_SET", "CURVE_TRACK", "SAVED_FORMULAS", "VARIABLES"]) {
    assert.ok(dictionary.de[`error.${code}`], code);
  }
});

test("every base value and input has a description in both languages", () => {
  const paths = new Set();
  for (const entry of game.buildings) {
    for (const [key, value] of Object.entries(entry.stats)) {
      if (value !== null && typeof value === "object") Object.keys(value).forEach((inner) => paths.add(`${key}.${inner}`));
      else paths.add(key);
    }
  }
  const keys = [...paths].map((path) => `desc.stat.${path}`);
  keys.push("desc.cost", "desc.upgradeBase", "desc.hp", "field.armor", "desc.armor", "plan.target", "plan.targetFormula", "error.TARGET", "desc.cell.cost", "desc.cell.gain", "desc.tracksTable", "plan.saveFormula", "plan.applySaved", "plan.saveName", "plan.saveDescription", "plan.saveConfirm", "plan.saveCancel", "plan.saveFailed", "plan.savedNone", "variables.title", "variables.hint", "variables.none", "variables.name", "variables.value", "variables.description", "variables.add", "variables.delete", "variables.invalid", "plan.var.custom", "plan.savedTitleCost", "plan.savedTitleMetric", "modal.close", "tab.formulas", "formulas.intro", "formulas.cost", "formulas.metric", "saved.edit", "saved.new", "saved.formula", "saved.target", "saved.manage", "plan.savedApply", "plan.savedDelete", "plan.tool", "plan.tools", "plan.fill", "error.PARAM", "chart.hide", "chart.show", "chart.last", "stat.totalEffect", "action.expand", "action.collapse");
  for (const key of ["max", "step", "price", "growth", "energy"]) keys.push(`desc.track.${key}`);
  for (const key of ["level", "cost", "spent", "value", "totalValue", "efficiency", "totalEfficiency", "factor"]) keys.push(`values.col.${key}`, `values.desc.${key}`);
  keys.push("plan.variablesHelp", "plan.operatorsHelp", "plan.operatorsTip", ...["level", "base", "build", "max", "growth", "start", "cost", "pi", "e"].map((name) => `plan.var.${name}`));
  keys.push("values.floor", "values.round", "values.ceil", "values.referenceCost", "values.title", "values.base", "values.noBase", "values.apply", "values.discard", "values.add", "values.remove", "values.pending", "values.applied");
  for (const key of keys) {
    assert.ok(dictionary.de[key], `de ${key}`);
    assert.ok(dictionary.en[key], `en ${key}`);
  }
});
