import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { effectAt, maxLevel, levelCost, costs, totalCost, benefitTotal, benefitOfLevel, buildFormulaLevels, snapshotLevels, planOf } from "../../web/js/formulas.js";
import { defaultFormulas, describeError, formulaDefaults, paramDefaults, paramKeys, paramLevels, formulaInputs, paramInputs, fillFromFormula, fillFromParams, toolOf, rememberFormula, forgetFormula, formulaHistory, HISTORY_LIMIT } from "../../web/js/views/planEditor.js";
import { draftKey, pendingLevels, applyLevels } from "../../web/js/views/valueTable.js";
import { ExpressionError } from "../../web/js/expr.js";
import { create } from "../../web/js/store.js";

function context(doc = fresh()) {
  const store = create(doc, game);
  const ctx = { store, view: { drafts: {}, planErrors: {}, tools: {}, gainModes: {}, hidden: new Set() }, render() {}, toast() {} };
  Object.defineProperty(ctx, "doc", { get: () => store.state.document });
  return ctx;
}

test("tracks without a plan derive their table from the parameters", () => {
  const solar = find(game, "solar");
  assert.equal(planOf(solar, "output"), null);
  assert.equal(maxLevel(game, solar, "output"), 30);
  assert.ok(Math.abs(effectAt(solar, "output", 5, game) - 1.5) < 1e-9);
});

test("formula levels use variables and floor the cost at one", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const levels = buildFormulaLevels(doc, solar, { max: 3, cost: "base * (level + 1)", effect: "1 + 0.5 * level" });
  assert.deepEqual(levels.map((level) => level.cost), [40, 80, 120]);
  assert.deepEqual(levels.map((level) => level.gain), [0.5, 0.5, 0.5]);
  assert.equal(buildFormulaLevels(doc, solar, { max: 1, cost: "0", effect: "level" })[0].cost, 1);
});

test("an effect that does not start at one is normalised to a gain", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  solar.plans = { output: { mode: "table", levels: buildFormulaLevels(doc, solar, { max: 2, cost: "5", effect: "10 + level" }) } };
  assert.equal(effectAt(solar, "output", 0, doc), 1);
  assert.equal(effectAt(solar, "output", 2, doc), 3);
});

test("formula errors are thrown and described", () => {
  const solar = find(fresh(), "solar");
  assert.throws(() => buildFormulaLevels(game, solar, { max: 2, cost: "1 +", effect: "1" }), ExpressionError);
  assert.throws(() => buildFormulaLevels(game, solar, { max: 0, cost: "1", effect: "1" }), (error) => error.code === "MAX");
  assert.throws(() => buildFormulaLevels(game, solar, { max: 500, cost: "1", effect: "1" }), (error) => error.code === "MAX");
  assert.throws(() => describeError(new Error("boom")), /boom/);
  assert.ok(describeError(new ExpressionError("EMPTY")));
  assert.ok(describeError(Object.assign(new Error("MAX"), { code: "MAX" })));
  assert.ok(describeError(Object.assign(new Error("PARAM"), { code: "PARAM" })));
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
  assert.deepEqual(costs(doc, solar, "output"), [10, 30]);
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

test("parameter levels reproduce the game curves for every upgrade", () => {
  for (const entry of game.buildings) {
    for (const track of entry.tracks) {
      const derived = paramLevels(game, entry, paramDefaults(game, entry, track));
      const snapshot = snapshotLevels(game, entry, track);
      assert.equal(derived.length, snapshot.length, `${entry.id}.${track}`);
      derived.forEach((level, index) => {
        assert.equal(level.cost, snapshot[index].cost, `${entry.id}.${track}.${index}`);
        assert.ok(Math.abs(level.gain - snapshot[index].gain) < 1e-5, `${entry.id}.${track}.${index}`);
      });
    }
  }
});

test("default formulas reproduce the game curves too", () => {
  const solar = find(game, "solar");
  const defaults = formulaDefaults(game, solar, "output");
  assert.deepEqual(buildFormulaLevels(game, solar, defaults).map((level) => level.cost), snapshotLevels(game, solar, "output").map((level) => level.cost));
});

test("parameter keys depend on the curve type and invalid parameters are rejected", () => {
  const solar = find(game, "solar");
  const bulwark = find(game, "bulwark");
  assert.deepEqual(paramKeys(paramDefaults(game, solar, "output")), ["max", "step", "price", "growth"]);
  assert.deepEqual(paramKeys(paramDefaults(game, bulwark, "hull")), ["max", "gain", "price", "gain_growth", "growth"]);
  const base = paramDefaults(game, solar, "output");
  for (const patch of [{ max: 0 }, { max: 201 }, { max: 1.5 }]) {
    assert.throws(() => paramLevels(game, solar, { ...base, ...patch }), (error) => error.code === "MAX");
  }
  for (const patch of [{ price: 0 }, { growth: 1 }, { step: -1 }, { step: Number.NaN }]) {
    assert.throws(() => paramLevels(game, solar, { ...base, ...patch }), (error) => error.code === "PARAM");
  }
  const curved = paramDefaults(game, bulwark, "hull");
  assert.throws(() => paramLevels(game, bulwark, { ...curved, gain_growth: 1 }), (error) => error.code === "PARAM");
  assert.throws(() => paramLevels(game, bulwark, { ...curved, gain: 0 }), (error) => error.code === "PARAM");
});

test("legacy formula plans provide their formulas as defaults", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  solar.plans = { output: { mode: "formula", max: 2, cost: "base", effect: "1 + level", levels: [{ cost: 40, gain: 1 }, { cost: 40, gain: 1 }] } };
  assert.deepEqual(formulaDefaults(doc, solar, "output"), { max: 2, cost: "base", effect: "1 + level" });
});

test("tools only fill the table draft and never change the applied values", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  const before = JSON.stringify(ctx.doc.buildings);
  ctx.view.drafts["solar:output:f:cost"] = "base * 3";
  ctx.view.drafts["solar:output:f:effect"] = "1 + level";
  ctx.view.drafts["solar:output:f:max"] = 4;
  fillFromFormula(ctx, solar, "output");
  const draft = pendingLevels(ctx, solar, "output");
  assert.deepEqual(draft.map((level) => level.cost), [120, 120, 120, 120].map((value) => value * 1));
  assert.equal(JSON.stringify(ctx.doc.buildings), before);
  assert.deepEqual(formulaHistory(ctx.doc, "cost"), ["base * 3"]);
  assert.deepEqual(formulaHistory(ctx.doc, "effect"), ["1 + level"]);
  applyLevels(ctx, find(ctx.doc, "solar"), "output");
  assert.equal(planOf(find(ctx.doc, "solar"), "output").levels.length, 4);
  assert.equal(planOf(find(ctx.doc, "solar"), "output").mode, "table");
});

test("the parameter tool fills the table from its own inputs", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts["solar:output:p:max"] = 3;
  ctx.view.drafts["solar:output:p:step"] = 0.5;
  ctx.view.drafts["solar:output:p:price"] = 1;
  ctx.view.drafts["solar:output:p:growth"] = 2;
  assert.equal(paramInputs(ctx, solar, "output").max, 3);
  fillFromParams(ctx, solar, "output");
  const draft = pendingLevels(ctx, solar, "output");
  assert.deepEqual(draft.map((level) => level.cost), [40, 80, 160]);
  assert.deepEqual(draft.map((level) => level.gain), [0.5, 0.5, 0.5]);
  assert.equal(planOf(solar, "output"), null);
  assert.equal(ctx.store.state.past.length, 0);
});

test("invalid tool inputs report an error and keep the table untouched", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts["solar:output:f:effect"] = "1 +";
  fillFromFormula(ctx, solar, "output");
  assert.ok(ctx.view.planErrors["solar:output:fill"]);
  assert.equal(ctx.view.drafts[draftKey(solar, "output")], undefined);
  assert.deepEqual(formulaHistory(ctx.doc, "effect"), []);
  ctx.view.drafts["solar:output:p:price"] = 0;
  fillFromParams(ctx, solar, "output");
  assert.ok(ctx.view.planErrors["solar:output:fill"]);
  assert.equal(ctx.view.drafts[draftKey(solar, "output")], undefined);
  delete ctx.view.drafts["solar:output:p:price"];
  fillFromParams(ctx, solar, "output");
  assert.equal(ctx.view.planErrors["solar:output:fill"], undefined);
  assert.ok(pendingLevels(ctx, solar, "output"));
});

test("tool inputs fall back to the current values and the tool is remembered per track", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  assert.deepEqual(formulaInputs(ctx, solar, "output"), formulaDefaults(ctx.doc, solar, "output"));
  assert.equal(toolOf(ctx.view, solar, "output"), "params");
  ctx.view.tools["solar:output:tool"] = "formula";
  assert.equal(toolOf(ctx.view, solar, "output"), "formula");
  assert.equal(toolOf(ctx.view, solar, "capacity"), "params");
});

test("applied formulas are remembered, newest first, without duplicates", () => {
  const doc = fresh();
  rememberFormula(doc, "cost", "base * 2");
  rememberFormula(doc, "cost", "base * 3");
  rememberFormula(doc, "cost", "base * 2");
  assert.deepEqual(formulaHistory(doc, "cost"), ["base * 2", "base * 3"]);
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
