import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { effectAt, maxLevel, mode, levelCost, costs, totalCost, benefitTotal, benefitOfLevel, buildFormulaLevels, snapshotLevels, planOf } from "../../web/js/formulas.js";
import { switchMode, applyFormula, defaultFormulas, describeError, rememberFormula, forgetFormula, formulaHistory, matchesFormula, resetToFormula, pendingPatch, applyPending, HISTORY_LIMIT } from "../../web/js/views/planEditor.js";
import { ExpressionError } from "../../web/js/expr.js";
import { create } from "../../web/js/store.js";

test("params mode is the default", () => {
  const solar = find(game, "solar");
  assert.equal(mode(solar, "output"), "params");
  assert.equal(planOf(solar, "output"), null);
  assert.equal(maxLevel(game, solar, "output"), 30);
  assert.ok(Math.abs(effectAt(solar, "output", 5, game) - 1.5) < 1e-9);
});

test("switching to a table keeps costs and effects", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const before = costs(doc, solar, "output");
  const effect = effectAt(solar, "output", 7, doc);
  switchMode(doc, solar, "output", "table");
  assert.equal(mode(solar, "output"), "table");
  assert.deepEqual(costs(doc, solar, "output"), before);
  assert.ok(Math.abs(effectAt(solar, "output", 7, doc) - effect) < 1e-5);
});

test("switching to a formula keeps costs and effects", () => {
  const doc = fresh();
  const zapper = find(doc, "zapper");
  const before = costs(doc, zapper, "power");
  switchMode(doc, zapper, "power", "formula");
  const plan = planOf(zapper, "power");
  assert.equal(plan.mode, "formula");
  applyFormula(doc, zapper, "power", {});
  assert.deepEqual(costs(doc, zapper, "power"), before);
  assert.ok(Math.abs(effectAt(zapper, "power", 10, doc) - 2) < 1e-5);
});

test("curve tracks convert to formulas too", () => {
  const doc = fresh();
  const wall = find(doc, "bulwark");
  const before = costs(doc, wall, "hull");
  const effect = effectAt(wall, "hull", 8, doc);
  switchMode(doc, wall, "hull", "formula");
  applyFormula(doc, wall, "hull", {});
  assert.deepEqual(costs(doc, wall, "hull"), before);
  assert.ok(Math.abs(effectAt(wall, "hull", 8, doc) - effect) < 1e-3);
});

test("switching back to params removes the plan", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  switchMode(doc, solar, "output", "table");
  switchMode(doc, solar, "output", "params");
  assert.equal(solar.plans, undefined);
  switchMode(doc, solar, "output", "params");
  assert.equal(solar.plans, undefined);
});

test("switching between table and formula keeps formula text", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  switchMode(doc, solar, "output", "formula");
  applyFormula(doc, solar, "output", { cost: "base * level + 1", effect: "1 + level" });
  switchMode(doc, solar, "output", "table");
  switchMode(doc, solar, "output", "formula");
  assert.equal(solar.plans.output.mode, "formula");
});

test("formula levels use variables and floor the cost at one", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  solar.plans = { output: { mode: "formula", max: 3, cost: "base * (level + 1)", effect: "1 + 0.5 * level", levels: [] } };
  const levels = buildFormulaLevels(doc, solar, solar.plans.output);
  assert.deepEqual(levels.map((level) => level.cost), [40, 80, 120]);
  assert.deepEqual(levels.map((level) => level.gain), [0.5, 0.5, 0.5]);
  const cheap = buildFormulaLevels(doc, solar, { max: 1, cost: "0", effect: "level" });
  assert.equal(cheap[0].cost, 1);
});

test("an effect that does not start at one is normalised to a gain", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  solar.plans = { output: { mode: "table", levels: buildFormulaLevels(doc, solar, { max: 2, cost: "5", effect: "10 + level" }) } };
  assert.equal(effectAt(solar, "output", 0, doc), 1);
  assert.equal(effectAt(solar, "output", 2, doc), 3);
});

test("formula errors are thrown before the document changes", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  switchMode(doc, solar, "output", "formula");
  const store = create(doc, game);
  assert.throws(() => store.update((d) => applyFormula(d, find(d, "solar"), "output", { cost: "1 +" })), ExpressionError);
  assert.equal(planOf(find(store.state.document, "solar"), "output").cost, planOf(solar, "output").cost);
  assert.ok(!store.canUndo());
  assert.throws(() => store.update((d) => applyFormula(d, find(d, "solar"), "output", { max: 0 })), (error) => error.code === "MAX");
  assert.throws(() => store.update((d) => applyFormula(d, find(d, "solar"), "output", { max: 500 })), (error) => error.code === "MAX");
});

test("errors are described and unknown errors rethrown", () => {
  assert.throws(() => describeError(new Error("boom")), /boom/);
});

test("table plans drive cost, benefit and totals", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  solar.plans = { output: { mode: "table", levels: [{ cost: 10, gain: 1 }, { cost: 30, gain: 1 }] } };
  assert.equal(maxLevel(doc, solar, "output"), 2);
  assert.equal(totalCost(doc, solar, "output"), 40);
  assert.equal(levelCost(doc, solar, "output", 1), 30);
  assert.equal(levelCost(doc, solar, "output", 9), 30);
  assert.equal(effectAt(solar, "output", 9, doc), 3);
  assert.equal(benefitTotal(doc, solar, "output"), 200 / 40 * 1000);
  assert.ok(benefitOfLevel(doc, solar, "output", 0) > benefitOfLevel(doc, solar, "output", 1));
});

test("snapshot covers every level and default formulas mirror the parameters", () => {
  const doc = fresh();
  const relay = find(doc, "relay");
  assert.equal(snapshotLevels(doc, relay, "range").length, 15);
  const formulas = defaultFormulas(doc, relay, "range");
  assert.match(formulas.cost, /^base \* 0\.3 \* 1\.18\^level$/);
  assert.match(formulas.effect, /^1 \+ 0\.04 \* level$/);
  assert.match(defaultFormulas(doc, find(doc, "bulwark"), "hull").effect, /\(1\.85\^level - 1\)/);
});

function formulaSolar() {
  const doc = fresh();
  const solar = find(doc, "solar");
  switchMode(doc, solar, "output", "formula");
  applyFormula(doc, solar, "output", { cost: "base * (level + 1)", effect: "1 + 0.5 * level" });
  return { doc, solar };
}

test("a formula fills every level once and levels stay editable", () => {
  const { doc, solar } = formulaSolar();
  const plan = planOf(solar, "output");
  assert.ok(matchesFormula(doc, solar, "output"));
  plan.levels[1].cost = 999;
  plan.levels[2].gain = 0.25;
  assert.equal(levelCost(doc, solar, "output", 1), 999);
  assert.ok(!matchesFormula(doc, solar, "output"));
  assert.equal(plan.cost, "base * (level + 1)");
});

test("reset restores all values from the stored formula", () => {
  const { doc, solar } = formulaSolar();
  const original = JSON.stringify(planOf(solar, "output").levels);
  planOf(solar, "output").levels[0].cost = 5;
  resetToFormula(doc, solar, "output");
  assert.equal(JSON.stringify(planOf(solar, "output").levels), original);
  assert.ok(matchesFormula(doc, solar, "output"));
});

test("a new formula recalculates all manual values", () => {
  const { doc, solar } = formulaSolar();
  planOf(solar, "output").levels[0].cost = 5;
  applyFormula(doc, solar, "output", { cost: "base * 2" });
  assert.equal(levelCost(doc, solar, "output", 0), solar.upgrade_base * 2);
});

test("applied formulas are remembered, newest first, without duplicates", () => {
  const { doc } = formulaSolar();
  assert.deepEqual(formulaHistory(doc, "cost"), ["base * (level + 1)"]);
  assert.deepEqual(formulaHistory(doc, "effect"), ["1 + 0.5 * level"]);
  const solar = find(doc, "solar");
  applyFormula(doc, solar, "output", { cost: "base * 2" });
  applyFormula(doc, solar, "output", { cost: "base * (level + 1)" });
  assert.deepEqual(formulaHistory(doc, "cost"), ["base * (level + 1)", "base * 2"]);
});

test("invalid formulas are not remembered", () => {
  const { doc, solar } = formulaSolar();
  assert.throws(() => applyFormula(doc, solar, "output", { cost: "base *" }));
  assert.ok(!formulaHistory(doc, "cost").includes("base *"));
});

test("history entries can be deleted and the list is capped", () => {
  const doc = fresh();
  rememberFormula(doc, "cost", "a");
  rememberFormula(doc, "cost", "b");
  rememberFormula(doc, "cost", "   ");
  forgetFormula(doc, "cost", "a");
  assert.deepEqual(formulaHistory(doc, "cost"), ["b"]);
  forgetFormula(doc, "effect", "x");
  forgetFormula(doc, "cost", "missing");
  for (let index = 0; index < HISTORY_LIMIT + 5; index += 1) rememberFormula(doc, "effect", `1 + ${index}`);
  assert.equal(formulaHistory(doc, "effect").length, HISTORY_LIMIT);
  assert.equal(formulaHistory(doc, "effect")[0], `1 + ${HISTORY_LIMIT + 4}`);
});

test("matchesFormula is false for broken formulas", () => {
  const { doc, solar } = formulaSolar();
  planOf(solar, "output").cost = "base *";
  assert.ok(!matchesFormula(doc, solar, "output"));
});

function context(doc) {
  const store = create(doc, doc);
  return { doc: store.state.document, store, view: { drafts: {}, planErrors: {} }, render() {}, toast() {} };
}

test("typed formulas only apply after pressing apply", () => {
  const { doc, solar } = formulaSolar();
  const ctx = context(doc);
  const entry = find(ctx.doc, "solar");
  const before = JSON.stringify(planOf(entry, "output").levels);
  ctx.view.drafts["solar:output:cost"] = "base * 3";
  ctx.view.drafts["solar:output:max"] = planOf(entry, "output").max;
  assert.deepEqual(pendingPatch(ctx.view.drafts, entry, "output"), { cost: "base * 3" });
  assert.equal(JSON.stringify(planOf(entry, "output").levels), before);
  assert.deepEqual(formulaHistory(ctx.doc, "cost"), ["base * (level + 1)"]);
  applyPending(ctx, entry, "output");
  const applied = find(ctx.store.state.document, "solar");
  assert.equal(planOf(applied, "output").cost, "base * 3");
  assert.equal(levelCost(ctx.store.state.document, applied, "output", 0), applied.upgrade_base * 3);
  assert.deepEqual(ctx.view.drafts, {});
  assert.equal(formulaHistory(ctx.store.state.document, "cost")[0], "base * 3");
  assert.ok(solar);
});

test("an invalid draft reports an error and keeps the old values", () => {
  const { doc } = formulaSolar();
  const ctx = context(doc);
  const entry = find(ctx.doc, "solar");
  ctx.view.drafts["solar:output:effect"] = "1 +";
  applyPending(ctx, entry, "output");
  assert.ok(ctx.view.planErrors["solar:output:apply"]);
  assert.equal(planOf(find(ctx.store.state.document, "solar"), "output").effect, "1 + 0.5 * level");
  assert.equal(ctx.view.drafts["solar:output:effect"], "1 +");
});

test("applying without pending changes does nothing", () => {
  const { doc } = formulaSolar();
  const ctx = context(doc);
  applyPending(ctx, find(ctx.doc, "solar"), "output");
  assert.equal(ctx.store.state.past.length, 0);
});

test("switching tabs restores the applied formula and its values", () => {
  const { doc, solar } = formulaSolar();
  const memory = {};
  const applied = JSON.stringify(planOf(solar, "output"));
  switchMode(doc, solar, "output", "table", memory);
  planOf(solar, "output").levels[0].cost = 777;
  switchMode(doc, solar, "output", "params", memory);
  assert.equal(solar.plans, undefined);
  switchMode(doc, solar, "output", "formula", memory);
  assert.equal(JSON.stringify(planOf(solar, "output")), applied);
  switchMode(doc, solar, "output", "table", memory);
  assert.equal(planOf(solar, "output").levels[0].cost, 777);
});

test("an empty memory behaves like before and memories are per track", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const memory = {};
  switchMode(doc, solar, "output", "formula", memory);
  switchMode(doc, solar, "output", "params", memory);
  switchMode(doc, solar, "capacity", "table", memory);
  assert.equal(planOf(solar, "capacity").mode, "table");
  assert.equal(planOf(solar, "output"), null);
  switchMode(doc, solar, "output", "table", memory);
  assert.equal(planOf(solar, "output").mode, "table");
  const stored = memory["solar:output:formula"];
  stored.cost = "changed";
  switchMode(doc, solar, "output", "formula", memory);
  assert.equal(planOf(solar, "output").cost, "changed");
  planOf(solar, "output").cost = "again";
  assert.equal(memory["solar:output:formula"].cost, "changed");
});
