import { compute } from "./expr.js";

export const DEFAULT_GROWTH = 1.18;
export const MAX_LEVELS = 200;
export const COST_VARIABLES = ["level", "base", "build", "max", "growth"];
export const EFFECT_VARIABLES = ["level", "max", "base", "build"];

export function trackConfig(doc, entry, track) {
  return entry.curves?.[track] ?? doc.tracks[track];
}

export function planOf(entry, track) {
  return entry.plans?.[track] ?? null;
}

export function mode(entry, track) {
  return planOf(entry, track)?.mode ?? "params";
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

export function scopeFor(doc, entry, max, level) {
  return { level, base: entry.upgrade_base, build: entry.cost, max, growth: doc.system.track_growth };
}

export function buildFormulaLevels(doc, entry, plan) {
  const max = plan.max;
  if (!Number.isInteger(max) || max < 1 || max > MAX_LEVELS) throw Object.assign(new Error("MAX"), { code: "MAX" });
  const zero = compute(plan.effect, scopeFor(doc, entry, max, 0));
  const levels = [];
  let previous = zero;
  for (let level = 0; level < max; level += 1) {
    const cost = Math.max(Math.round(compute(plan.cost, scopeFor(doc, entry, max, level))), 1);
    const effect = compute(plan.effect, scopeFor(doc, entry, max, level + 1));
    levels.push({ cost, gain: roundTo(effect - previous) });
    previous = effect;
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

export function referenceCost(entry) {
  return entry.cost > 0 ? entry.cost : entry.upgrade_base;
}

export function deriveRows(entry, levels) {
  const build = referenceCost(entry);
  let spent = 0;
  let effect = 1;
  return levels.map((level, index) => {
    const before = effect;
    spent += level.cost;
    effect += level.gain;
    const known = build > 0;
    return {
      level: index + 1,
      cost: level.cost,
      spent,
      gain: level.gain,
      effect,
      benefit: before > 0 ? ((level.gain / before) * 100) / level.cost * 1000 : null,
      single: known ? (level.gain / (level.cost / build)) * 100 : null,
      total: known ? (effect / (1 + spent / build)) * 100 : null,
    };
  });
}

export function levelFactors(doc, entry, track) {
  return deriveRows(entry, snapshotLevels(doc, entry, track)).map(({ single, total }) => ({ single, total }));
}

export const EDITABLE_FIELDS = ["cost", "spent", "gain", "effect", "single", "total"];

export function editLevel(entry, levels, index, field, value) {
  const next = levels.map((level) => ({ ...level }));
  if (!Number.isFinite(value) || !next[index]) return next;
  const build = referenceCost(entry);
  const spentBefore = next.slice(0, index).reduce((sum, level) => sum + level.cost, 0);
  const effectBefore = 1 + next.slice(0, index).reduce((sum, level) => sum + level.gain, 0);
  const level = next[index];
  const costOf = (amount) => Math.max(Math.round(amount), 1);
  if (field === "cost") level.cost = costOf(value);
  else if (field === "gain") level.gain = roundTo(value);
  else if (field === "spent") level.cost = costOf(value - spentBefore);
  else if (field === "effect") level.gain = roundTo(value - effectBefore);
  else if (field === "single" && value > 0 && level.gain > 0 && build > 0) level.cost = costOf((level.gain * build) / (value / 100));
  else if (field === "total" && value > 0 && build > 0 && effectBefore + level.gain > 0) {
    level.cost = costOf(build * ((effectBefore + level.gain) / (value / 100) - 1) - spentBefore);
  }
  return next;
}

export function writeLevels(entry, track, levels) {
  entry.plans = entry.plans ?? {};
  const plan = entry.plans[track];
  if (!plan) {
    entry.plans[track] = { mode: "table", levels };
    return;
  }
  plan.levels = levels;
  if (plan.mode === "formula") plan.max = levels.length;
}

const GAIN_BASES = {
  hull: (entry) => ({ value: entry.hp }),
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
  const base = find ? find(entry) : null;
  if (!base || !Number.isFinite(base.value) || base.value <= 0) return null;
  const cell = doc?.system?.cell ?? 56;
  return base.length ? base.value / cell : base.value;
}
