import test from "node:test";
import assert from "node:assert/strict";
import { fresh, find } from "./data.js";
import { COST_TYPES, VALUE_TYPES, TOLERANCE, fitCost, fitValue, generateGoal, goalTotals, withinTolerance } from "../../web/js/targetFit.js";
import { goalDefaults } from "../../web/js/views/goalTool.js";
import { buildFormulaLevels, deriveRows, startValue, baseValue } from "../../web/js/formulas.js";

const goal = (overrides = {}) => ({ max: 12, costMode: "factor", cost: 40, valueMode: "factor", value: 6, costType: "linear", valueType: "constant", ...overrides });

test("every cost curve and every benefit curve reaches the goal within one percent", () => {
  const doc = fresh();
  const bulwark = find(doc, "bulwark");
  for (const costType of COST_TYPES) {
    for (const valueType of VALUE_TYPES) {
      const result = generateGoal(doc, bulwark, "hull", goal({ costType, valueType }));
      assert.ok(Math.abs(result.costDeviation) <= TOLERANCE, `${costType} cost ${result.costDeviation}`);
      assert.ok(Math.abs(result.valueDeviation) <= TOLERANCE, `${valueType} value ${result.valueDeviation}`);
      assert.ok(withinTolerance(result));
      assert.equal(result.target, "value");
      const levels = buildFormulaLevels(doc, bulwark, { max: 12, cost: result.cost, target: "value", formula: result.formula }, "hull");
      const last = deriveRows(bulwark, levels, startValue(doc, bulwark, "hull"), baseValue(doc, bulwark, "hull")).at(-1);
      assert.equal(last.spent, result.spent);
    }
  }
});

test("absolute and factor goals are equivalent", () => {
  const doc = fresh();
  const bulwark = find(doc, "bulwark");
  const factor = generateGoal(doc, bulwark, "hull", goal());
  const { totalCost, totalValue } = goalTotals(doc, bulwark, "hull", goal());
  const absolute = generateGoal(doc, bulwark, "hull", goal({ costMode: "absolute", cost: totalCost, valueMode: "absolute", value: totalValue }));
  assert.equal(absolute.cost, factor.cost);
  assert.equal(absolute.formula, factor.formula);
  assert.equal(totalCost, 40 * bulwark.cost);
  assert.equal(totalValue, 6 * baseValue(doc, bulwark, "hull"));
});

test("small goals with integer cost rounding still land within tolerance", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const result = generateGoal(doc, solar, "output", goal({ max: 5, costMode: "absolute", cost: solar.cost + 60, valueMode: "absolute", value: baseValue(doc, solar, "output") + 7, costType: "exponential", valueType: "diminishing" }));
  assert.ok(withinTolerance(result));
});

test("invalid goals are rejected with a code", () => {
  const doc = fresh();
  const bulwark = find(doc, "bulwark");
  const core = find(doc, "core");
  const code = (run) => { try { run(); } catch (error) { return error.code; } return null; };
  assert.equal(code(() => generateGoal(doc, bulwark, "hull", goal({ max: 0 }))), "MAX");
  assert.equal(code(() => generateGoal(doc, bulwark, "hull", goal({ max: 1.5 }))), "MAX");
  assert.equal(code(() => generateGoal(doc, bulwark, "hull", goal({ cost: NaN }))), "GOAL_NUMBER");
  assert.equal(code(() => generateGoal(doc, bulwark, "hull", goal({ cost: "5" }))), "GOAL_NUMBER");
  assert.equal(code(() => generateGoal(doc, bulwark, "hull", goal({ costMode: "absolute", cost: bulwark.cost + 3 }))), "GOAL_COST");
  assert.equal(code(() => generateGoal(doc, bulwark, "hull", goal({ valueMode: "factor", value: 1 }))), "GOAL_VALUE");
  assert.equal(code(() => generateGoal(doc, core, "hull", goal())), "GOAL_BASE");
  assert.equal(code(() => generateGoal(doc, find(doc, "solar"), "armor", goal({ valueMode: "factor" }))), "GOAL_BASE");
});

test("unknown curve types fall back to the first type and fitting is exact for smooth curves", () => {
  assert.equal(fitCost("nope", 100, 5, 1.18), fitCost("linear", 100, 5, 1.18));
  assert.equal(fitValue("nope", 10, 4, 1.18), fitValue("constant", 10, 4, 1.18));
  assert.equal(fitValue("constant", 10, 4, 1.18), "2.5");
  assert.equal(fitCost("linear", 30, 4, 1.18), "3 * level");
});

test("goal defaults start from the current table", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  const defaults = goalDefaults(doc, solar, "output");
  assert.equal(defaults.costMode, "absolute");
  assert.ok(defaults.cost >= solar.cost);
  assert.equal(defaults.costType, COST_TYPES[0]);
  assert.equal(defaults.valueType, VALUE_TYPES[0]);
});
