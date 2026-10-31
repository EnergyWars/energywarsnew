import { compute } from "./expr.js";

export const DEFAULT_GROWTH = 1.18;
export const MAX_LEVELS = 200;
export const FORMULA_TARGETS = ["value", "efficiency", "totalEfficiency", "factor"];
export const COST_VARIABLES = ["level", "base", "build", "max", "growth", "start"];
export const TARGET_VARIABLES = ["level", "max", "base", "build", "growth", "start", "cost"];

export function trackConfig(doc, entry, track) {
  return entry.curves?.[track] ?? doc.tracks[track];
}

export function planOf(entry, track) {
  return entry.plans?.[track] ?? null;
}

export function multiplier(config, level) {
  if (config.gain !== undefined) {
    const growth = config.gain_growth;
    return 1 + config.gain * (growth ** level - 1) / (growth - 1);
  }
  return 1 + config.step * level;
}

function paramCost(doc, entry, track, level) {
  const config = trackConfig(doc, entry, track);
  const growth = config.growth ?? doc.system.track_growth;
  return Math.max(Math.round(entry.upgrade_base * config.price * growth ** level), 1);
}

export function effectAt(entry, track, level, doc) {
  const plan = planOf(entry, track);
  if (!plan) return multiplier(trackConfig(doc, entry, track), level);
  let total = 1;
  for (let index = 0; index < Math.min(level, plan.levels.length); index += 1) total += plan.levels[index].gain;
  return total;
}

export function maxLevel(doc, entry, track) {
  const plan = planOf(entry, track);
  return plan ? plan.levels.length : trackConfig(doc, entry, track).max;
}

export function levelCost(doc, entry, track, level) {
  const plan = planOf(entry, track);
  if (!plan) return paramCost(doc, entry, track, level);
  return plan.levels[Math.min(level, plan.levels.length - 1)].cost;
}

export function costs(doc, entry, track) {
  return Array.from({ length: maxLevel(doc, entry, track) }, (_, level) => levelCost(doc, entry, track, level));
}

export function totalCost(doc, entry, track) {
  return costs(doc, entry, track).reduce((sum, value) => sum + value, 0);
}

export function benefitOfLevel(doc, entry, track, level) {
  const before = effectAt(entry, track, level, doc);
  const gain = (effectAt(entry, track, level + 1, doc) - before) / before * 100;
  return gain / levelCost(doc, entry, track, level) * 1000;
}

export function benefitTotal(doc, entry, track) {
  const max = maxLevel(doc, entry, track);
  const gain = (effectAt(entry, track, max, doc) - 1) * 100;
  return gain / totalCost(doc, entry, track) * 1000;
}

export function usage(doc, track) {
  return doc.buildings.filter((entry) => entry.tracks.includes(track)).map((entry) => entry.id);
}

export function startValue(doc, entry, track) {
  return track ? gainBase(doc, entry, track) ?? 1 : 1;
}

export function scopeFor(doc, entry, max, level, track = null) {
  return { level, base: entry.upgrade_base, build: entry.cost, max, growth: doc.system.track_growth, start: startValue(doc, entry, track) };
}

export function gainFor(target, amount, row) {
  const { start, cost, effectBefore, spent, reference } = row;
  if (target === "value") return amount / start;
  if (target === "efficiency") return (amount * cost) / reference;
  if (target === "totalEfficiency") return (amount * spent) / reference - effectBefore;
  if (target === "factor") return (amount - 1) * effectBefore;
  throw Object.assign(new Error("TARGET"), { code: "TARGET" });
}

export function buildFormulaLevels(doc, entry, plan, track = null) {
  const max = plan.max;
  if (!Number.isInteger(max) || max < 1 || max > MAX_LEVELS) throw Object.assign(new Error("MAX"), { code: "MAX" });
  const target = plan.target ?? FORMULA_TARGETS[0];
  if (!FORMULA_TARGETS.includes(target)) throw Object.assign(new Error("TARGET"), { code: "TARGET" });
  const start = startValue(doc, entry, track);
  const reference = referenceCost(entry) > 0 ? referenceCost(entry) : 1;
  const levels = [];
  let effect = 1;
  let spent = purchasePrice(entry);
  for (let index = 0; index < max; index += 1) {
    const scope = scopeFor(doc, entry, max, index + 1, track);
    const cost = Math.max(Math.round(compute(plan.cost, scope)), 1);
    spent += cost;
    const amount = compute(plan.formula, { ...scope, cost });
    const gain = roundTo(gainFor(target, amount, { start, cost, effectBefore: effect, spent, reference }));
    levels.push({ cost, gain });
    effect += gain;
  }
  return levels;
}

export function roundTo(value, digits = 6) {
  return Math.round(value * 10 ** digits) / 10 ** digits;
}

export function snapshotLevels(doc, entry, track) {
  const max = maxLevel(doc, entry, track);
  return Array.from({ length: max }, (_, level) => ({
    cost: levelCost(doc, entry, track, level),
    gain: roundTo(effectAt(entry, track, level + 1, doc) - effectAt(entry, track, level, doc)),
  }));
}

export function purchasePrice(entry) {
  return Number.isFinite(entry.cost) && entry.cost > 0 ? entry.cost : 0;
}

export function referenceCost(entry) {
  return entry.cost > 0 ? entry.cost : entry.upgrade_base;
}

export function deriveRows(entry, levels, start = 1) {
  const build = referenceCost(entry);
  const purchase = purchasePrice(entry);
  let upgrades = 0;
  let effect = 1;
  return levels.map((level, index) => {
    const before = effect;
    upgrades += level.cost;
    effect += level.gain;
    const known = build > 0;
    return {
      level: index + 1,
      cost: level.cost,
      value: level.gain * start,
      efficiency: build > 0 ? (level.gain * build) / level.cost : null,
      totalEfficiency: build > 0 && purchase + upgrades > 0 ? (effect * build) / (purchase + upgrades) : null,
      factor: effect / before,
      costFactor: known ? level.cost / build : null,
      spent: purchase + upgrades,
      spentFactor: known ? (purchase + upgrades) / build : null,
      gain: level.gain,
      effect,
      totalEffect: (effect - 1) * 100,
      unitCost: before > 0 && level.gain > 0 ? level.cost / ((level.gain / before) * 100) : null,
      single: known ? (level.gain / (level.cost / build)) * 100 : null,
      total: known ? (effect / (1 + upgrades / build)) * 100 : null,
    };
  });
}

export function levelFactors(doc, entry, track) {
  return deriveRows(entry, snapshotLevels(doc, entry, track)).map(({ single, total }) => ({ single, total }));
}

export function baseRow(entry, start = 1) {
  const build = referenceCost(entry);
  const purchase = purchasePrice(entry);
  return {
    level: 0,
    cost: null,
    value: null,
    efficiency: null,
    totalEfficiency: build > 0 && purchase > 0 ? build / purchase : null,
    factor: null,
    costFactor: null,
    spent: purchase,
    spentFactor: build > 0 ? purchase / build : null,
    gain: null,
    effect: 1,
    totalEffect: 0,
    unitCost: null,
    single: build > 0 ? 100 : null,
    total: build > 0 ? 100 : null,
  };
}

export function deriveRowsFromBase(entry, levels, start = 1) {
  return [baseRow(entry, start), ...deriveRows(entry, levels, start)];
}

export const EDITABLE_FIELDS = ["cost", "value", "efficiency", "totalEfficiency", "factor", "costFactor", "spent", "spentFactor", "gain", "effect", "totalEffect", "single", "total", "unitCost"];

export function editLevel(entry, levels, index, field, value, start = 1) {
  const next = levels.map((level) => ({ ...level }));
  if (!Number.isFinite(value) || !next[index] || !EDITABLE_FIELDS.includes(field)) return next;
  const build = referenceCost(entry);
  const purchase = purchasePrice(entry);
  const upgradesBefore = next.slice(0, index).reduce((sum, level) => sum + level.cost, 0);
  const effectBefore = 1 + next.slice(0, index).reduce((sum, level) => sum + level.gain, 0);
  const level = next[index];
  const costOf = (amount) => Math.max(Math.round(amount), 1);
  const effectAfter = effectBefore + level.gain;
  const setters = {
    cost: () => costOf(value),
    costFactor: () => (build > 0 ? costOf(value * build) : null),
    spent: () => costOf(value - purchase - upgradesBefore),
    spentFactor: () => (build > 0 ? costOf(value * build - purchase - upgradesBefore) : null),
    single: () => (value > 0 && level.gain > 0 && build > 0 ? costOf((level.gain * build) / (value / 100)) : null),
    total: () => (value > 0 && build > 0 && effectAfter > 0 ? costOf(build * (effectAfter / (value / 100) - 1) - upgradesBefore) : null),
    unitCost: () => (value > 0 && level.gain > 0 && effectBefore > 0 ? costOf(value * ((level.gain / effectBefore) * 100)) : null),
  };
  if (FORMULA_TARGETS.includes(field)) {
    const spent = purchase + upgradesBefore + level.cost;
    level.gain = roundTo(gainFor(field, value, { start, cost: level.cost, effectBefore, spent, reference: build > 0 ? build : 1 }));
  } else if (field === "gain") level.gain = roundTo(value);
  else if (field === "effect") level.gain = roundTo(value - effectBefore);
  else if (field === "totalEffect") level.gain = roundTo(value / 100 + 1 - effectBefore);
  else {
    const cost = setters[field]();
    if (cost !== null) level.cost = cost;
  }
  return next;
}

export function writeLevels(entry, track, levels) {
  entry.plans = entry.plans ?? {};
  entry.plans[track] = { mode: "table", levels };
}

const DEFAULT_ARMOR_UNIT = 10;

const GAIN_BASES = {
  hull: (entry) => ({ value: entry.hp }),
  armor: (entry, doc) => ({ value: doc?.system?.armor_unit ?? DEFAULT_ARMOR_UNIT }),
  output: (entry) => ({ value: entry.stats.output }),
  capacity: (entry) => ({ value: entry.stats.capacity }),
  rate: (entry) => ({ value: entry.stats.export ?? entry.stats.rate }),
  power: (entry) => ({ value: entry.stats.attack?.damage ?? entry.stats.heal?.amount }),
  splash: (entry) => ({ value: entry.stats.attack?.splash, length: true }),
  range: (entry) => {
    if (entry.stats.attack) return { value: entry.stats.attack.range, length: true };
    if (entry.stats.shield) return { value: entry.stats.shield.radius, length: true };
    if (entry.stats.heal) return { value: entry.stats.heal.range, length: true };
    return { value: entry.stats.range, length: true };
  },
};

export function gainBase(doc, entry, track) {
  const find = GAIN_BASES[track];
  const base = find ? find(entry, doc) : null;
  if (!base || !Number.isFinite(base.value) || base.value <= 0) return null;
  const cell = doc?.system?.cell ?? 56;
  return base.length ? base.value / cell : base.value;
}
