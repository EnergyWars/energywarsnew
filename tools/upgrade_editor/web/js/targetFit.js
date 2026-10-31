import { purchasePrice, baseValue, startValue, deriveRows, buildFormulaLevels, MAX_LEVELS } from "./formulas.js";

export const COST_TYPES = ["linear", "exponential", "quadratic"];
export const VALUE_TYPES = ["constant", "exponential", "diminishing"];
export const GOAL_MODES = ["absolute", "factor"];
export const TOLERANCE = 0.01;

const SIGNIFICANT = 6;
const REFINE_ROUNDS = 40;
const REFINE_TARGET = 0.001;
const DEFAULT_GROWTH = 1.18;

const COST_SHAPES = {
  linear: (level) => level,
  exponential: (level, growth) => growth ** level,
  quadratic: (level) => level ** 2,
};

const VALUE_SHAPES = {
  constant: () => 1,
  exponential: (level, growth) => growth ** level,
  diminishing: (level) => 1 / Math.sqrt(level),
};

const fail = (code) => Object.assign(new Error(code), { code });

function plain(value) {
  const text = Number(value.toPrecision(SIGNIFICANT)).toString();
  return text.includes("e") ? value.toFixed(12).replace(/0+$/, "") : text;
}

function formulaText(kind, type, coefficient, growth) {
  const a = plain(coefficient);
  if (type === "linear") return `${a} * level`;
  if (type === "quadratic") return `${a} * pow(level, 2)`;
  if (type === "diminishing") return `${a} / sqrt(level)`;
  if (type === "constant") return a;
  return `${a} * pow(${plain(growth)}, level)`;
}

function shapeSum(shape, max, growth) {
  let sum = 0;
  for (let level = 1; level <= max; level += 1) sum += shape(level, growth);
  return sum;
}

function costSum(shape, coefficient, max, growth) {
  let sum = 0;
  for (let level = 1; level <= max; level += 1) sum += Math.max(Math.round(Number(plain(coefficient)) * shape(level, growth)), 1);
  return sum;
}

export function fitCost(type, total, max, growth) {
  const shape = COST_SHAPES[type] ?? COST_SHAPES.linear;
  const kind = COST_SHAPES[type] ? type : "linear";
  let coefficient = total / shapeSum(shape, max, growth);
  let best = { coefficient, error: Infinity };
  for (let round = 0; round < REFINE_ROUNDS; round += 1) {
    const sum = costSum(shape, coefficient, max, growth);
    const error = Math.abs(sum - total) / total;
    if (error < best.error) best = { coefficient, error };
    if (error <= REFINE_TARGET) break;
    coefficient *= total / sum;
  }
  return formulaText("cost", kind, best.coefficient, growth);
}

export function fitValue(type, total, max, growth) {
  const shape = VALUE_SHAPES[type] ?? VALUE_SHAPES.constant;
  const kind = VALUE_SHAPES[type] ? type : "constant";
  return formulaText("value", kind, total / shapeSum(shape, max, growth), growth);
}

export function goalTotals(doc, entry, track, goal) {
  const purchase = purchasePrice(entry);
  const base = baseValue(doc, entry, track);
  const numbers = [goal.cost, goal.value].every((value) => typeof value === "number" && Number.isFinite(value));
  if (!numbers) throw fail("GOAL_NUMBER");
  if ((goal.costMode === "factor" && purchase <= 0) || (goal.valueMode === "factor" && base <= 0)) throw fail("GOAL_BASE");
  return {
    purchase,
    base,
    totalCost: goal.costMode === "factor" ? goal.cost * purchase : goal.cost,
    totalValue: goal.valueMode === "factor" ? goal.value * base : goal.value,
  };
}

export function generateGoal(doc, entry, track, goal) {
  const max = Number(goal.max);
  if (!Number.isInteger(max) || max < 1 || max > MAX_LEVELS) throw fail("MAX");
  const { purchase, base, totalCost, totalValue } = goalTotals(doc, entry, track, goal);
  const upgradeCost = totalCost - purchase;
  const upgradeValue = totalValue - base;
  if (!(upgradeCost >= max)) throw fail("GOAL_COST");
  if (!(upgradeValue > 0)) throw fail("GOAL_VALUE");
  const growth = doc.system?.track_growth > 1 ? doc.system.track_growth : DEFAULT_GROWTH;
  const cost = fitCost(goal.costType, upgradeCost, max, growth);
  const formula = fitValue(goal.valueType, upgradeValue, max, growth);
  const levels = buildFormulaLevels(doc, entry, { max, cost, target: "value", formula }, track);
  const rows = deriveRows(entry, levels, startValue(doc, entry, track), base);
  const last = rows[rows.length - 1];
  return {
    max,
    cost,
    formula,
    target: "value",
    spent: last.spent,
    totalValue: last.totalValue,
    costDeviation: last.spent / totalCost - 1,
    valueDeviation: last.totalValue / totalValue - 1,
  };
}

export function withinTolerance(result) {
  return Math.abs(result.costDeviation) <= TOLERANCE && Math.abs(result.valueDeviation) <= TOLERANCE;
}
