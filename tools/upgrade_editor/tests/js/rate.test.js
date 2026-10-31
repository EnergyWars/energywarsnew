import test from "node:test";
import assert from "node:assert/strict";
import { fresh } from "./data.js";
import { ratePerSecond, cooldownFor, gainBase, startValue, baseValue, deriveRowsFromBase, snapshotLevels } from "../../web/js/formulas.js";
import { COOLDOWN_COLUMN } from "../../web/js/views/valueTable.js";
import { RATE_STATS } from "../../web/js/views/rateField.js";

test("rate and cooldown are inverse and reject non-positive input", () => {
  assert.equal(ratePerSecond(0.5), 2);
  assert.equal(ratePerSecond(0), null);
  assert.equal(ratePerSecond(NaN), null);
  assert.equal(cooldownFor(2), 0.5);
  assert.equal(cooldownFor(4 / 3), 0.75);
  assert.equal(cooldownFor(0), null);
  assert.equal(cooldownFor(-1), null);
  assert.deepEqual([...RATE_STATS], ["attack.cooldown", "heal.cooldown"]);
});

test("the speed track starts at shots per second and shows the cooldown as a derived column", () => {
  const doc = fresh();
  const entry = doc.buildings.find((item) => item.stats.attack?.cooldown > 0 && item.tracks.includes("speed"));
  assert.ok(entry);
  const rate = 1 / entry.stats.attack.cooldown;
  assert.ok(Math.abs(gainBase(doc, entry, "speed") - rate) < 1e-9);
  assert.ok(Math.abs(startValue(doc, entry, "speed") - rate) < 1e-9);
  const rows = deriveRowsFromBase(entry, snapshotLevels(doc, entry, "speed"), startValue(doc, entry, "speed"), baseValue(doc, entry, "speed"));
  const level1 = rows[1];
  assert.ok(Math.abs(ratePerSecond(level1.totalValue) - 1 / level1.totalValue) < 1e-12);
  assert.ok(level1.totalValue > rate);
  assert.equal(COOLDOWN_COLUMN.readonly, true);
  assert.equal(COOLDOWN_COLUMN.format(0.5), "0.5");
});

test("the range base is the beam range when a building has one, otherwise the attack range", () => {
  const doc = fresh();
  const core = doc.buildings.find((item) => item.id === "core");
  const zapper = doc.buildings.find((item) => item.id === "zapper");
  const cell = doc.system.cell;
  assert.ok(Math.abs(gainBase(doc, core, "range") - core.stats.range / cell) < 1e-9);
  core.stats.range = 4 * cell;
  assert.ok(Math.abs(startValue(doc, core, "range") - 4) < 1e-9);
  assert.ok(Math.abs(gainBase(doc, zapper, "range") - zapper.stats.attack.range / cell) < 1e-9);
});
