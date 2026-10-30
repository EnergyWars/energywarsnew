import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { deriveRows, editLevel, writeLevels, gainBase, referenceCost, snapshotLevels, planOf } from "../../web/js/formulas.js";
import { pendingLevels, applyLevels, discardLevels, draftKey, gainView, gainModeKey } from "../../web/js/views/valueTable.js";
import { detailPairs, toggleSeries, chartSeries } from "../../web/js/views/buildingView.js";
import { toggleKey, isCollapsed } from "../../web/js/views/components.js";
import { create } from "../../web/js/store.js";

const near = (actual, expected, message) => assert.ok(Math.abs(actual - expected) < 1e-6, `${message ?? ""} ${actual} vs ${expected}`);
const entry = (cost = 10, upgradeBase = 5) => ({ id: "x", cost, upgrade_base: upgradeBase });
const levels = () => [{ cost: 8, gain: 0.4 }, { cost: 16, gain: 0.4 }];

test("derived rows contain every value of a level", () => {
  const [first, second] = deriveRows(entry(), levels());
  assert.equal(first.spent, 8);
  near(first.effect, 1.4);
  near(first.single, 50);
  near(first.total, (1.4 / 1.8) * 100);
  assert.equal(second.spent, 24);
  near(second.effect, 1.8);
  near(second.single, 25);
  near(second.total, (1.8 / 3.4) * 100);
  near(second.benefit, ((0.4 / 1.4) * 100) / 16 * 1000);
});

test("rows fall back to the upgrade base and have no factors without any reference", () => {
  near(referenceCost(entry(0, 10)), 10);
  assert.equal(deriveRows(entry(0, 0), levels())[0].single, null);
  assert.equal(deriveRows(entry(0, 0), levels())[0].total, null);
});

test("editing cost, total cost and effect recalculates dependent values", () => {
  let next = editLevel(entry(), levels(), 0, "cost", 20.4);
  assert.equal(next[0].cost, 20);
  next = editLevel(entry(), levels(), 1, "spent", 40);
  assert.equal(next[1].cost, 32);
  next = editLevel(entry(), levels(), 1, "effect", 2);
  near(next[1].gain, 0.6);
  near(deriveRows(entry(), next)[1].effect, 2);
  next = editLevel(entry(), levels(), 0, "gain", 0.25);
  near(deriveRows(entry(), next)[1].effect, 1.65);
  assert.equal(levels()[0].gain, 0.4);
});

test("editing a factor changes the cost and keeps the benefit", () => {
  let next = editLevel(entry(), levels(), 0, "single", 100);
  assert.equal(next[0].cost, 4);
  near(deriveRows(entry(), next)[0].single, 100);
  next = editLevel(entry(), levels(), 1, "total", 60);
  near(deriveRows(entry(), next)[1].total, 60, "total");
  near(next[1].gain, 0.4);
});

test("invalid edits are ignored or clamped", () => {
  assert.deepEqual(editLevel(entry(), levels(), 0, "cost", Number.NaN), levels());
  assert.deepEqual(editLevel(entry(), levels(), 5, "cost", 3), levels());
  assert.equal(editLevel(entry(), levels(), 0, "cost", -5)[0].cost, 1);
  assert.equal(editLevel(entry(), levels(), 1, "spent", 3)[1].cost, 1);
  assert.deepEqual(editLevel(entry(), levels(), 0, "single", 0), levels());
  assert.deepEqual(editLevel(entry(), [{ cost: 4, gain: 0 }], 0, "single", 50), [{ cost: 4, gain: 0 }]);
  assert.deepEqual(editLevel(entry(0, 0), levels(), 0, "total", 50), levels());
  assert.deepEqual(editLevel(entry(), levels(), 0, "unknown", 5), levels());
});

test("writing levels keeps the mode and syncs the formula length", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  writeLevels(solar, "output", [{ cost: 3, gain: 0.1 }]);
  assert.equal(planOf(solar, "output").mode, "table");
  solar.plans.output = { mode: "formula", max: 2, cost: "1", effect: "1", levels: levels() };
  writeLevels(solar, "output", [...levels(), { cost: 1, gain: 0.1 }]);
  assert.equal(planOf(solar, "output").max, 3);
});

test("absolute gains use the base value of the track", () => {
  const hull = find(game, "bulwark");
  assert.equal(gainBase(game, hull, "hull"), hull.hp);
  const zapper = find(game, "zapper");
  assert.equal(gainBase(game, zapper, "range"), zapper.stats.attack.range / game.system.cell);
  assert.equal(gainBase(game, zapper, "power"), zapper.stats.attack.damage);
  assert.equal(gainBase(game, find(game, "plasma"), "splash"), find(game, "plasma").stats.attack.splash / game.system.cell);
  assert.equal(gainBase(game, find(game, "relay"), "range"), find(game, "relay").stats.range / game.system.cell);
  assert.equal(gainBase(game, find(game, "shield"), "range"), find(game, "shield").stats.shield.radius / game.system.cell);
  assert.equal(gainBase(game, find(game, "healer"), "range"), find(game, "healer").stats.heal.range / game.system.cell);
  assert.equal(gainBase(game, find(game, "exporter"), "rate"), find(game, "exporter").stats.export);
  assert.equal(gainBase(game, find(game, "solar"), "output"), find(game, "solar").stats.output);
  assert.equal(gainBase(game, find(game, "battery"), "capacity"), find(game, "battery").stats.capacity);
  assert.equal(gainBase(game, find(game, "zapper"), "crit"), null);
  assert.equal(gainBase(undefined, { hp: 10, stats: {} }, "hull"), 10);
});

test("gain view converts between factor and absolute values", () => {
  const factor = gainView(10, "factor");
  assert.equal(factor.show(0.4), 0.4);
  assert.equal(factor.parse(0.4), 0.4);
  const absolute = gainView(10, "absolute");
  assert.equal(absolute.show(0.4), 4);
  assert.equal(absolute.parse(4), 0.4);
  assert.equal(gainView(null, "absolute").absolute, false);
});

function context(doc) {
  const store = create(doc, doc);
  const ctx = { store, view: { drafts: {}, gainModes: {}, hidden: new Set() }, render() {}, toast() {} };
  Object.defineProperty(ctx, "doc", { get: () => store.state.document });
  return ctx;
}

test("table drafts apply only on request and become a table plan", () => {
  const ctx = context(fresh());
  const solar = find(ctx.doc, "solar");
  const before = JSON.stringify(snapshotLevels(ctx.doc, solar, "output"));
  const draftLevels = snapshotLevels(ctx.doc, solar, "output").map((level) => ({ ...level }));
  draftLevels[0].cost = 999;
  ctx.view.drafts[draftKey(solar, "output")] = { base: before, levels: draftLevels };
  assert.equal(pendingLevels(ctx, solar, "output")[0].cost, 999);
  assert.equal(planOf(solar, "output"), null);
  applyLevels(ctx, solar, "output");
  const applied = find(ctx.doc, "solar");
  assert.equal(planOf(applied, "output").mode, "table");
  assert.equal(planOf(applied, "output").levels[0].cost, 999);
  assert.equal(ctx.view.drafts[draftKey(solar, "output")], undefined);
  applyLevels(ctx, applied, "output");
  assert.equal(ctx.store.state.past.length, 1);
});

test("a draft is dropped when the underlying levels changed meanwhile", () => {
  const ctx = context(fresh());
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts[draftKey(solar, "output")] = { base: "[]", levels: [{ cost: 1, gain: 0.1 }] };
  assert.equal(pendingLevels(ctx, solar, "output"), null);
  assert.equal(ctx.view.drafts[draftKey(solar, "output")], undefined);
  assert.equal(pendingLevels(ctx, solar, "output"), null);
});

test("discard removes the draft", () => {
  const ctx = context(fresh());
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts[draftKey(solar, "output")] = { base: "x", levels: [] };
  discardLevels(ctx, solar, "output");
  assert.deepEqual(ctx.view.drafts, {});
  assert.equal(gainModeKey(solar, "output"), "solar:output");
});

test("tooltip lists every value of a level and series can be toggled", () => {
  const rows = deriveRows(entry(), levels());
  const pairs = detailPairs(rows[1]);
  assert.equal(pairs.length, 7);
  assert.ok(pairs.every(([label, value]) => label && value));
  const ctx = context(fresh());
  toggleSeries(ctx, "cost");
  assert.ok(ctx.view.hidden.has("cost"));
  toggleSeries(ctx, "cost");
  assert.ok(!ctx.view.hidden.has("cost"));
  const series = chartSeries(rows);
  assert.deepEqual(series.map((item) => item.key), ["cost", "spent", "effect", "factorLevel", "factorTotal"]);
  assert.equal(series[3].values.length, 2);
});

test("sections and tracks can be collapsed and expanded again", () => {
  const set = new Set();
  assert.equal(toggleKey(set, "a"), true);
  assert.equal(toggleKey(set, "a"), false);
  assert.equal(set.size, 0);
  const ctx = { view: { collapsed: new Set(["stats:solar"]) } };
  assert.equal(isCollapsed(ctx, "stats:solar"), true);
  assert.equal(isCollapsed(ctx, "upgrades:solar"), false);
});
