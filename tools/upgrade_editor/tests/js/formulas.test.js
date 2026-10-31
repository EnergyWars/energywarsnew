import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { levelFactors, multiplier, levelCost, costs, totalCost, benefitOfLevel, benefitTotal, trackConfig, usage } from "../../web/js/formulas.js";

test("costs match the costs exported from the game", () => {
  for (const entry of game.buildings) {
    for (const track of entry.tracks) {
      assert.deepEqual(costs(game, entry, track), game.check[entry.id][track], `${entry.id}.${track}`);
    }
  }
});

test("linear multiplier", () => {
  assert.equal(multiplier({ step: 0.1 }, 5), 1.5);
});

test("geometric multiplier of curves", () => {
  const wall = trackConfig(game, find(game, "bulwark"), "hull");
  assert.equal(multiplier(wall, 0), 1);
  assert.ok(Math.abs(multiplier(wall, 1) - 3) < 1e-9);
  assert.ok(multiplier(wall, 8) > multiplier(wall, 7));
});

test("track config prefers the building curve", () => {
  assert.equal(trackConfig(game, find(game, "bulwark"), "hull").gain, 2);
  assert.equal(trackConfig(game, find(game, "solar"), "hull").step, 0.15);
});

test("cost never drops below one", () => {
  const doc = fresh();
  find(doc, "solar").upgrade_base = 1;
  doc.tracks.output.price = 0.001;
  assert.equal(levelCost(doc, find(doc, "solar"), "output", 0), 1);
});

test("changing a value changes costs", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const before = totalCost(doc, solar, "output");
  doc.tracks.output.price *= 2;
  assert.ok(totalCost(doc, solar, "output") > before * 1.9);
});

test("track specific growth overrides the system growth", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const before = levelCost(doc, solar, "links", 3);
  doc.system.track_growth = 3;
  assert.equal(levelCost(doc, solar, "links", 3), before);
  assert.notEqual(levelCost(doc, solar, "output", 3), game.check.solar.output[3]);
});

test("benefit decreases when the price rises", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const before = benefitTotal(doc, solar, "output");
  doc.tracks.output.price *= 2;
  assert.ok(benefitTotal(doc, solar, "output") < before);
  assert.ok(benefitOfLevel(doc, solar, "output", 0) > benefitOfLevel(doc, solar, "output", 20));
});

test("usage lists buildings sharing a track", () => {
  assert.ok(usage(game, "hull").length > 5);
  assert.deepEqual(usage(game, "chain"), ["tesla"]);
  const armored = usage(game, "armor");
  assert.equal(armored.length, game.buildings.length);
  assert.ok(armored.includes("bulwark") && armored.includes("solar") && armored.includes("core"));
});

test("armour track gains are relative like every percentage track", () => {
  const config = trackConfig(game, find(game, "zapper"), "armor");
  assert.equal(config, game.tracks.armor);
  assert.ok(Math.abs(multiplier(config, 20) - 4) < 1e-9);
});

function tableEntry(buildCost, levels) {
  return { id: "x", cost: buildCost, plans: { hull: { mode: "table", levels } } };
}

test("level factor compares benefit and cost relative to the base values", () => {
  const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9, `${actual} vs ${expected}`);
  near(levelFactors(game, tableEntry(10, [{ cost: 4, gain: 0.4 }]), "hull")[0].single, 100);
  near(levelFactors(game, tableEntry(10, [{ cost: 2, gain: 0.4 }]), "hull")[0].single, 200);
  near(levelFactors(game, tableEntry(10, [{ cost: 4, gain: 0.2 }]), "hull")[0].single, 50);
});

test("total factor accumulates benefit and cost of all levels up to a level", () => {
  const factors = levelFactors(game, tableEntry(10, [{ cost: 8, gain: 0.4 }, { cost: 16, gain: 0.4 }]), "hull");
  assert.ok(Math.abs(factors[0].single - 50) < 1e-9);
  assert.ok(Math.abs(factors[1].single - 25) < 1e-9);
  assert.ok(Math.abs(factors[0].total - (14 / 18) * 100) < 1e-9);
  assert.ok(Math.abs(factors[1].total - (18 / 34) * 100) < 1e-9);
});

test("buildings without build cost use the upgrade base as reference", () => {
  const entry = { ...tableEntry(0, [{ cost: 4, gain: 0.4 }]), upgrade_base: 10 };
  const [first] = levelFactors(game, entry, "hull");
  assert.ok(Math.abs(first.single - 100) < 1e-9);
  assert.ok(Math.abs(first.total - (1.4 / 1.4) * 100) < 1e-9);
});

test("factors are empty without any reference cost", () => {
  const entry = { ...tableEntry(0, [{ cost: 4, gain: 0.4 }]), upgrade_base: 0 };
  assert.deepEqual(levelFactors(game, entry, "hull"), [{ single: null, total: null }]);
});

test("every building has finite factors", () => {
  for (const entry of game.buildings) {
    for (const item of levelFactors(game, entry, entry.tracks[0])) assert.ok(Number.isFinite(item.single) && Number.isFinite(item.total), entry.id);
  }
});

test("parameter upgrades have factors for every level", () => {
  const solar = find(game, "solar");
  const factors = levelFactors(game, solar, "output");
  assert.equal(factors.length, trackConfig(game, solar, "output").max);
  assert.ok(factors.every((item) => item.single > 0 && item.total > 0));
});
