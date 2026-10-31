import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { addVariable, updateVariable, deleteVariable, variablesCard, VARIABLE_LIMIT, VARIABLE_NAME_LIMIT, VARIABLE_DESCRIPTION_LIMIT } from "../../web/js/views/variablesPanel.js";
import { storedFormula, formulaState, writeLevels, effectAt, maxLevel, levelCost, costs, totalCost, benefitTotal, benefitOfLevel, buildFormulaLevels, snapshotLevels, planOf, startValue } from "../../web/js/formulas.js";
import { defaultFormulas, describeError, formulaDefaults, paramDefaults, paramKeys, paramLevels, formulaInputs, paramInputs, fillFromFormula, fillFromParams, formulaDraftChanged, toolOf, savedFormulas, saveFormula, updateSavedFormula, deleteSavedFormula, SAVED_NAME_LIMIT, SAVED_DESCRIPTION_LIMIT, TIP_VARIABLES, variableTip } from "../../web/js/views/planEditor.js";
import { draftKey, pendingLevels, applyLevels } from "../../web/js/views/valueTable.js";
import { COST_VARIABLES, TARGET_VARIABLES, baseValue, roundTo } from "../../web/js/formulas.js";
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
  const levels = buildFormulaLevels(doc, solar, { max: 3, cost: "base * level", target: "value", formula: "start * 0.5" }, "output");
  assert.deepEqual(levels.map((level) => level.cost), [40, 80, 120]);
  assert.deepEqual(levels.map((level) => level.gain), [0.5, 0.5, 0.5]);
  assert.equal(buildFormulaLevels(doc, solar, { max: 1, cost: "0", target: "value", formula: "0" }, "output")[0].cost, 1);
});

test("every target turns the row formula into the gain of the upgrade", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const start = startValue(doc, solar, "output");
  const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-5, `${actual} vs ${expected}`);
  const value = buildFormulaLevels(doc, solar, { max: 2, cost: "10", target: "value", formula: "level * start" }, "output");
  near(value[0].gain, 1);
  near(value[1].gain, 2);
  const efficiency = buildFormulaLevels(doc, solar, { max: 2, cost: "10 * level", target: "efficiency", formula: "1" }, "output");
  near(efficiency[0].gain, 10 / solar.cost);
  near(efficiency[1].gain, 20 / solar.cost);
  const bulwark = find(doc, "bulwark");
  const hull = buildFormulaLevels(doc, bulwark, { max: 1, cost: "build * 2 ^ level", target: "efficiency", formula: "(70 + abs(floor(abs(6.5 - level))) * 10) / 100" }, "hull");
  near(hull[0].gain * 1600, 3840);
  const total = buildFormulaLevels(doc, solar, { max: 2, cost: "10", target: "totalEfficiency", formula: "1" }, "output");
  near(total[0].gain, (solar.cost + 10) / solar.cost - 1);
  near(total[1].gain, 10 / solar.cost);
  const factor = buildFormulaLevels(doc, solar, { max: 3, cost: "10", target: "factor", formula: "2" }, "output");
  assert.deepEqual(factor.map((level) => level.gain), [1, 2, 4]);
});

test("the cost of the row is available in the second formula and start falls back to one", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  assert.equal(startValue(doc, solar, "links"), 1);
  const levels = buildFormulaLevels(doc, solar, { max: 2, cost: "7 * level", target: "value", formula: "cost / 7" }, "links");
  assert.deepEqual(levels.map((level) => level.gain), [1, 2]);
  assert.equal(startValue(doc, find(doc, "bulwark"), "hull"), 1600);
});

test("formula errors are thrown and described", () => {
  const solar = find(fresh(), "solar");
  assert.throws(() => buildFormulaLevels(game, solar, { max: 2, cost: "1 +", target: "value", formula: "1" }), ExpressionError);
  assert.throws(() => buildFormulaLevels(game, solar, { max: 0, cost: "1", target: "value", formula: "1" }), (error) => error.code === "MAX");
  assert.throws(() => buildFormulaLevels(game, solar, { max: 500, cost: "1", target: "value", formula: "1" }), (error) => error.code === "MAX");
  assert.throws(() => describeError(new Error("boom")), /boom/);
  assert.ok(describeError(new ExpressionError("EMPTY")));
  assert.ok(describeError(Object.assign(new Error("MAX"), { code: "MAX" })));
  assert.ok(describeError(Object.assign(new Error("PARAM"), { code: "PARAM" })));
  assert.ok(describeError(Object.assign(new Error("TARGET"), { code: "TARGET" })));
  assert.throws(() => buildFormulaLevels(game, solar, { max: 2, cost: "1", target: "nothing", formula: "1" }), (error) => error.code === "TARGET");
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
  assert.match(formulas.cost, /^base \* 0\.3 \* 1\.18\^\(level - 1\)$/);
  assert.match(formulas.formula, /^start \* 0\.04$/);
  assert.equal(formulas.target, "value");
  assert.match(defaultFormulas(doc, find(doc, "bulwark"), "hull").formula, /1\.85\^\(level - 1\)/);
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
  const built = buildFormulaLevels(game, solar, defaults, "output");
  const snapshot = snapshotLevels(game, solar, "output");
  assert.deepEqual(built.map((level) => level.cost), snapshot.map((level) => level.cost));
  built.forEach((level, index) => assert.ok(Math.abs(level.gain - snapshot[index].gain) < 1e-5, `level ${index + 1}`));
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

test("formula defaults carry the stored limits and a value target", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const defaults = formulaDefaults(doc, solar, "output");
  assert.deepEqual(Object.keys(defaults).sort(), ["cost", "formula", "max", "target"]);
  assert.equal(defaults.target, "value");
  assert.equal(defaults.max, maxLevel(doc, solar, "output"));
});

test("own variables of a building are usable in both formulas and listed in the tooltip", () => {
  const ctx = context();
  let added = false;
  ctx.store.update((doc) => {
    added = addVariable(doc, "solar", { name: "Bonus", value: "2.5", description: "Zusatz" });
    addVariable(doc, "solar", { name: "faktor", value: 3 });
  });
  assert.equal(added, true);
  const solar = find(ctx.doc, "solar");
  assert.deepEqual(solar.variables, [{ name: "bonus", value: 2.5, description: "Zusatz" }, { name: "faktor", value: 3, description: "" }]);
  const levels = buildFormulaLevels(ctx.doc, solar, { max: 2, cost: "base * faktor", target: "value", formula: "start * bonus" }, "output");
  assert.equal(levels[0].cost, solar.upgrade_base * 3);
  assert.equal(levels[0].gain, 2.5);
  assert.throws(() => buildFormulaLevels(ctx.doc, find(ctx.doc, "relay"), { max: 1, cost: "bonus", target: "value", formula: "1" }, "output"), ExpressionError);
  assert.ok(variableTip(solar).includes("bonus = 2.5 – Zusatz"));
  assert.ok(variableTip(solar).includes("faktor = 3 – plan.var.custom"));
  assert.ok(!variableTip().includes("bonus"));
});

test("own variables are validated, updatable and deletable", () => {
  const doc = fresh();
  const bad = [{ name: "" }, { name: "level" }, { name: "min" }, { name: "pi" }, { name: "1a" }, { name: "a b" }, { name: "ä" }, { name: "n".repeat(VARIABLE_NAME_LIMIT + 1) }, { name: "ok", value: "" }, { name: "ok", value: "abc" }, { name: "ok", value: Infinity }, { name: "ok", value: 1e16 }];
  for (const item of bad) assert.equal(addVariable(doc, "solar", { value: 1, ...item }), false, JSON.stringify(item));
  assert.equal(addVariable(doc, "missing", { name: "ok", value: 1 }), false);
  assert.equal(addVariable(doc, "solar", { name: "ok_1", value: 1, description: "d".repeat(VARIABLE_DESCRIPTION_LIMIT + 5) }), true);
  assert.equal(find(doc, "solar").variables[0].description.length, VARIABLE_DESCRIPTION_LIMIT);
  assert.equal(addVariable(doc, "solar", { name: "OK_1", value: 2 }), false);
  assert.equal(updateVariable(doc, "solar", "ok_1", { value: "4", description: " neu " }), true);
  assert.deepEqual(find(doc, "solar").variables[0], { name: "ok_1", value: 4, description: "neu" });
  assert.equal(updateVariable(doc, "solar", "ok_1", { value: "x" }), false);
  assert.equal(updateVariable(doc, "solar", "none", { value: 1 }), false);
  assert.equal(updateVariable(doc, "none", "ok_1", { value: 1 }), false);
  for (let index = 1; index < VARIABLE_LIMIT; index += 1) assert.equal(addVariable(doc, "solar", { name: `v${index}`, value: index }), true);
  assert.equal(addVariable(doc, "solar", { name: "extra", value: 1 }), false);
  deleteVariable(doc, "solar", "ok_1");
  assert.equal(find(doc, "solar").variables.length, VARIABLE_LIMIT - 1);
  const single = fresh();
  addVariable(single, "relay", { name: "x", value: 1 });
  deleteVariable(single, "relay", "x");
  assert.equal("variables" in find(single, "relay"), false);
  deleteVariable(single, "relay", "x");
  deleteVariable(single, "none", "x");
});

test("the variables card lists, adds, edits and removes variables", () => {
  const ctx = context();
  const entry = () => find(ctx.doc, "solar");
  ctx.view.collapsed = new Set();
  const press = (root, label, index = 0) => root.findAll((node) => node.tagName === "button" && node.text() === label)[index].dispatch("click");
  let root = variablesCard(ctx, entry());
  assert.ok(root.text().includes("variables.none"));
  root.find((node) => node.attributes["aria-label"] === "variables.name").value = "Bonus";
  root.find((node) => node.attributes["aria-label"] === "variables.value").value = "7";
  press(root, "variables.add");
  assert.equal(entry().variables[0].value, 7);
  root = variablesCard(ctx, entry());
  assert.ok(root.text().includes("bonus"));
  root.find((node) => node.attributes["aria-label"] === "variables.name").value = "level";
  root.find((node) => node.attributes["aria-label"] === "variables.value").value = "1";
  press(root, "variables.add");
  assert.ok(root.findAll((node) => node.className === "field-error").some((node) => node.textContent === "variables.invalid"));
  const description = root.find((node) => node.attributes["aria-label"] === "variables.description" && node.value === "");
  description.value = "Info";
  description.dispatch("change");
  assert.equal(entry().variables[0].description, "Info");
  press(variablesCard(ctx, entry()), "variables.delete");
  assert.equal("variables" in entry(), false);
});

test("the last applied formula is stored per track, prefills the fields and reports the table state", () => {
  const ctx = context();
  const solar = () => find(ctx.doc, "solar");
  assert.equal(storedFormula(solar(), "output"), null);
  assert.equal(formulaState(ctx.doc, solar(), "output"), null);
  assert.equal(formulaDraftChanged(ctx, solar(), "output"), false);
  ctx.view.drafts["solar:output:f:cost"] = "base * 3";
  ctx.view.drafts["solar:output:f:formula"] = "start / 2";
  ctx.view.drafts["solar:output:f:target"] = "efficiency";
  ctx.view.drafts["solar:output:max"] = 3;
  fillFromFormula(ctx, solar(), "output");
  const stored = { max: 3, cost: "base * 3", target: "efficiency", formula: "start / 2" };
  assert.deepEqual(storedFormula(solar(), "output"), stored);
  assert.equal(formulaState(ctx.doc, solar(), "output"), "synced");
  assert.equal(formulaDraftChanged(ctx, solar(), "output"), false);
  ctx.view.drafts["solar:output:f:cost"] = "base * 4";
  assert.equal(formulaDraftChanged(ctx, solar(), "output"), true);
  const fresher = { ...ctx, view: { ...ctx.view, drafts: {} } };
  assert.deepEqual(formulaDefaults(ctx.doc, solar(), "output"), { max: 3, cost: "base * 3", formula: "start / 2", target: "efficiency" });
  assert.deepEqual(formulaInputs(fresher, solar(), "output"), { max: 3, cost: "base * 3", formula: "start / 2", target: "efficiency" });
  ctx.store.update((doc) => {
    const plan = planOf(find(doc, "solar"), "output");
    writeLevels(find(doc, "solar"), "output", plan.levels.map((level, index) => (index === 0 ? { ...level, cost: level.cost + 1 } : level)));
  });
  assert.deepEqual(storedFormula(solar(), "output"), stored);
  assert.equal(formulaState(ctx.doc, solar(), "output"), "modified");
  ctx.store.update((doc) => { find(doc, "solar").upgrade_base += 1; });
  ctx.view.drafts = {};
  ctx.view.drafts["solar:output:f:cost"] = "base * 3";
  ctx.view.drafts["solar:output:f:formula"] = "start / 2";
  ctx.view.drafts["solar:output:f:target"] = "efficiency";
  ctx.view.drafts["solar:output:max"] = 3;
  fillFromFormula(ctx, solar(), "output");
  ctx.store.update((doc) => { find(doc, "solar").plans.output.source.cost = "nonsense ("; });
  assert.equal(formulaState(ctx.doc, solar(), "output"), "modified");
});

test("the formula tool fills the table and applies it at once in one undo step", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts["solar:output:f:cost"] = "base * 3";
  ctx.view.drafts["solar:output:f:formula"] = "start";
  ctx.view.drafts["solar:output:max"] = 4;
  fillFromFormula(ctx, solar, "output");
  assert.equal(pendingLevels(ctx, solar, "output"), null);
  const plan = planOf(find(ctx.doc, "solar"), "output");
  assert.equal(plan.mode, "table");
  assert.deepEqual(plan.levels.map((level) => level.cost), [120, 120, 120, 120]);
  assert.deepEqual(plan.levels.map((level) => level.gain), [1, 1, 1, 1]);
  assert.equal(ctx.store.state.past.length, 1);
  ctx.store.undo();
  assert.equal(planOf(find(ctx.doc, "solar"), "output"), null);
});

test("filling replaces a pending table draft instead of keeping it", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts[draftKey(solar, "output")] = { base: "stale", levels: [{ cost: 1, gain: 9 }] };
  ctx.view.drafts["solar:output:max"] = 2;
  fillFromParams(ctx, solar, "output");
  assert.equal(ctx.view.drafts[draftKey(solar, "output")], undefined);
  assert.equal(planOf(find(ctx.doc, "solar"), "output").levels.length, 2);
});

test("the parameter tool fills the table from its own inputs and applies it", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts["solar:output:max"] = 3;
  ctx.view.drafts["solar:output:p:step"] = 0.5;
  ctx.view.drafts["solar:output:p:price"] = 1;
  ctx.view.drafts["solar:output:p:growth"] = 2;
  assert.equal(paramInputs(ctx, solar, "output").max, 3);
  fillFromParams(ctx, solar, "output");
  assert.equal(pendingLevels(ctx, solar, "output"), null);
  const plan = planOf(find(ctx.doc, "solar"), "output");
  assert.deepEqual(plan.levels.map((level) => level.cost), [40, 80, 160]);
  assert.deepEqual(plan.levels.map((level) => level.gain), [0.5, 0.5, 0.5]);
  assert.equal(ctx.store.state.past.length, 1);
});

test("invalid tool inputs report an error and change nothing", () => {
  const ctx = context();
  const solar = find(ctx.doc, "solar");
  const before = JSON.stringify(ctx.doc.buildings);
  ctx.view.drafts["solar:output:f:formula"] = "1 +";
  fillFromFormula(ctx, solar, "output");
  assert.ok(ctx.view.planErrors["solar:output:fill"]);
  assert.equal(JSON.stringify(ctx.doc.buildings), before);
  ctx.view.drafts["solar:output:p:price"] = 0;
  fillFromParams(ctx, solar, "output");
  assert.ok(ctx.view.planErrors["solar:output:fill"]);
  assert.equal(JSON.stringify(ctx.doc.buildings), before);
  assert.equal(ctx.store.state.past.length, 0);
  delete ctx.view.drafts["solar:output:p:price"];
  fillFromParams(ctx, solar, "output");
  assert.equal(ctx.view.planErrors["solar:output:fill"], undefined);
  assert.ok(planOf(find(ctx.doc, "solar"), "output"));
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

test("named formulas are saved with description and target, replaced by name and deleted", () => {
  const doc = fresh();
  assert.deepEqual(savedFormulas(doc, "cost"), []);
  assert.equal(saveFormula(doc, "cost", { name: "  Doppelt ", formula: " build * 2 ^ level ", description: " teuer " }), true);
  assert.deepEqual(savedFormulas(doc, "cost"), [{ name: "Doppelt", formula: "build * 2 ^ level", description: "teuer" }]);
  assert.equal(saveFormula(doc, "metric", { name: "Welle", formula: "level", description: "", target: "efficiency" }), true);
  assert.deepEqual(savedFormulas(doc, "metric"), [{ name: "Welle", formula: "level", description: "", target: "efficiency" }]);
  assert.equal(saveFormula(doc, "cost", { name: "doppelt", formula: "base", description: "neu" }), true);
  assert.deepEqual(savedFormulas(doc, "cost").map((item) => [item.name, item.formula]), [["doppelt", "base"]]);
  assert.equal(saveFormula(doc, "cost", { name: "   ", formula: "base" }), false);
  assert.equal(saveFormula(doc, "cost", { name: "x", formula: "  " }), false);
  deleteSavedFormula(doc, "metric", "Welle");
  deleteSavedFormula(doc, "metric", "unknown");
  deleteSavedFormula(doc, "other", "x");
  assert.deepEqual(savedFormulas(doc, "metric"), []);
  assert.equal(savedFormulas(doc, "cost").length, 1);
});

test("saved formulas can be updated in place, renamed and are validated", () => {
  const doc = fresh();
  saveFormula(doc, "cost", { name: "A", formula: "base", description: "" });
  saveFormula(doc, "cost", { name: "B", formula: "base * 2", description: "" });
  assert.equal(updateSavedFormula(doc, "cost", "A", { name: "C", formula: "base * 3", description: "neu" }), true);
  assert.deepEqual(savedFormulas(doc, "cost").map((item) => item.name), ["C", "B"]);
  assert.equal(updateSavedFormula(doc, "cost", "C", { name: "b", formula: "1" }), false);
  assert.equal(updateSavedFormula(doc, "cost", "C", { name: "C", formula: "1 +" }), false);
  assert.equal(updateSavedFormula(doc, "cost", "missing", { name: "Z", formula: "1" }), false);
  assert.equal(updateSavedFormula(doc, "cost", "B", { name: "B", formula: "base * 2", description: "x" }), true);
  assert.equal(saveFormula(doc, "cost", { name: "D", formula: "(" }), false);
  assert.equal(saveFormula(doc, "metric", { name: "E", formula: "1", target: "nonsense" }), false);
  assert.equal(saveFormula(doc, "metric", { name: "E", formula: "1", target: "factor" }), true);
});

test("any number of formulas can be saved while name and description are capped", () => {
  const doc = fresh();
  for (let index = 0; index < 200; index += 1) assert.equal(saveFormula(doc, "cost", { name: `f${index}`, formula: "1" }), true);
  assert.equal(savedFormulas(doc, "cost").length, 200);
  assert.equal(saveFormula(doc, "cost", { name: "f0", formula: "2" }), true);
  assert.equal(savedFormulas(doc, "cost").length, 200);
  const other = fresh();
  saveFormula(other, "cost", { name: "n".repeat(SAVED_NAME_LIMIT + 20), formula: "1", description: "d".repeat(SAVED_DESCRIPTION_LIMIT + 20) });
  assert.equal(savedFormulas(other, "cost")[0].name.length, SAVED_NAME_LIMIT);
  assert.equal(savedFormulas(other, "cost")[0].description.length, SAVED_DESCRIPTION_LIMIT);
});

test("the variable tooltip lists every formula variable with an explanation", () => {
  const lines = variableTip().split("\n");
  assert.equal(lines.length, TIP_VARIABLES.length);
  for (const [index, name] of TIP_VARIABLES.entries()) assert.ok(lines[index].startsWith(`${name} – `) && lines[index].length > name.length + 4);
  for (const name of [...COST_VARIABLES, ...TARGET_VARIABLES]) assert.ok(TIP_VARIABLES.includes(name), name);
});

test("build is the building cost in the cost formula and the initial attribute value in the benefit formula", () => {
  const doc = fresh();
  const bulwark = find(doc, "bulwark");
  const hull = buildFormulaLevels(doc, bulwark, { max: 1, cost: "build", target: "value", formula: "build" }, "hull");
  assert.equal(hull[0].cost, bulwark.cost);
  assert.equal(hull[0].gain, roundTo(baseValue(doc, bulwark, "hull") / startValue(doc, bulwark, "hull")));
  const armor = buildFormulaLevels(doc, bulwark, { max: 1, cost: "10", target: "value", formula: "build" }, "armor");
  assert.equal(armor[0].gain, roundTo(bulwark.armor / doc.system.armor_unit));
});
