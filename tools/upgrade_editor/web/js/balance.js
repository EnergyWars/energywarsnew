import { snapshotLevels, deriveRows } from "./formulas.js";
import { mitigate } from "./armor.js";
import { monsterRow } from "./monsters.js";
import { extraEntries, spawnerCounts } from "./waves.js";

export const BALANCE_RULES = {
  minLevelShare: 25,
  killSeconds: 20,
  bossKillSeconds: 90,
  bossFirstDay: 3,
  tick: 1 / 30,
};

export const CATEGORIES = ["upgrades", "monsters", "starters", "bosses"];

function median(values) {
  const sorted = [...values].sort((low, high) => low - high);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}

function trackRows(doc) {
  const result = [];
  for (const entry of doc.buildings) {
    for (const track of entry.tracks) {
      const rows = deriveRows(entry, snapshotLevels(doc, entry, track)).filter((row) => row.single !== null && Number.isFinite(row.single));
      result.push({ entry, track, rows });
    }
  }
  return result;
}

export function levelMedians(doc) {
  const byLevel = new Map();
  for (const { rows } of trackRows(doc)) {
    for (const row of rows) {
      if (!byLevel.has(row.level)) byLevel.set(row.level, []);
      byLevel.get(row.level).push(row.single);
    }
  }
  return new Map([...byLevel].map(([level, values]) => [level, median(values)]));
}

export function upgradeWarnings(doc, rules = BALANCE_RULES) {
  const warnings = [];
  const medians = levelMedians(doc);
  const limit = (level) => (medians.get(level) * rules.minLevelShare) / 100;
  for (const { entry, track, rows } of trackRows(doc)) {
    const weak = rows.filter((row) => row.single < limit(row.level));
    if (!weak.length) continue;
    const worst = weak.reduce((low, row) => (row.single / limit(row.level) < low.single / limit(low.level) ? row : low));
    warnings.push({ type: "upgrade", building: entry.id, track, first: weak[0].level, count: weak.length, levels: rows.length, worst: worst.single, worstLevel: worst.level, typical: medians.get(worst.level) });
  }
  return warnings;
}

export function armedBuildings(doc) {
  return doc.buildings.filter((entry) => Number(entry.stats?.attack?.damage) > 0);
}

export function towerDps(entry, armor, config, tick = BALANCE_RULES.tick) {
  const attack = entry.stats?.attack;
  const damage = Number(attack?.damage);
  if (!(damage > 0)) return 0;
  const cooldown = Number(attack.cooldown);
  if (!(cooldown > 0)) return mitigate(damage * tick, armor, config) / tick;
  return mitigate(damage, armor, config) / cooldown;
}

export function bestTower(doc, armor, rules = BALANCE_RULES) {
  let best = null;
  for (const entry of armedBuildings(doc)) {
    const dps = towerDps(entry, armor, doc.armor, rules.tick);
    if (!best || dps > best.dps) best = { id: entry.id, dps };
  }
  return best;
}

function raids(enemy, level) {
  return enemy.class === "air" && !enemy.boss && spawnerCounts(level)[enemy.faction] > 0;
}

export function appearances(doc, kind) {
  const enemy = doc.enemies[kind];
  if (!enemy) return [];
  const found = new Map();
  const add = (level, night) => found.set(`${level}:${night}`, { level, night });
  (doc.levels ?? []).forEach((level, index) => {
    const waves = level.waves ?? {};
    for (const entry of waves.roster ?? []) if (entry[0] === kind) add(index, false);
    for (const entry of waves.night_roster ?? []) if (entry[0] === kind) add(index, true);
    for (const entry of extraEntries(level)) if (entry.kind === kind) add(index, Boolean(entry.night));
    if (raids(enemy, level)) add(index, Boolean(enemy.nocturnal));
  });
  return [...found.values()];
}

export function killTime(doc, kind, level, night, rules = BALANCE_RULES) {
  const row = monsterRow(doc.enemies[kind], doc.armor, level, night);
  const best = bestTower(doc, row.armor, rules);
  const towerRate = best?.dps ?? 0;
  return { level, night, hp: row.hp, armor: row.armor, reduction: row.reduction, effectiveHp: row.effectiveHp, tower: best?.id ?? null, towerDps: towerRate, seconds: towerRate > 0 ? row.hp / towerRate : Infinity };
}

export function monsterWarnings(doc, rules = BALANCE_RULES) {
  const warnings = [];
  const last = Math.max((doc.levels?.length ?? 1) - 1, 0);
  for (const [kind, enemy] of Object.entries(doc.enemies ?? {})) {
    const places = appearances(doc, kind);
    const cases = places.length ? places : [{ level: last, night: Boolean(enemy.nocturnal) }];
    const worst = cases.map((place) => killTime(doc, kind, place.level, place.night, rules)).reduce((high, item) => (item.seconds > high.seconds ? item : high));
    const limit = enemy.boss ? rules.bossKillSeconds : rules.killSeconds;
    if (worst.seconds > limit) warnings.push({ type: "monster", monster: kind, boss: Boolean(enemy.boss), limit, appears: places.length > 0, ...worst });
  }
  return warnings.sort((a, b) => b.seconds / b.limit - a.seconds / a.limit);
}

const ROSTERS = [["roster", false], ["night_roster", true]];

export function starterWarnings(doc) {
  const warnings = [];
  (doc.levels ?? []).forEach((level, index) => {
    for (const [field, night] of ROSTERS) {
      const list = Array.isArray(level.waves?.[field]) ? level.waves[field] : [];
      if (list.some((entry) => Number(entry[1]) <= 0)) continue;
      const tiers = list.map((entry) => Number(entry[1])).filter(Number.isFinite);
      warnings.push({ type: "starter", level: index, levelId: level.id, night, lowest: tiers.length ? Math.min(...tiers) : null });
    }
  });
  return warnings;
}

export function bossWarnings(doc, rules = BALANCE_RULES) {
  const warnings = [];
  (doc.levels ?? []).forEach((level, index) => {
    for (const [field, night] of ROSTERS) {
      for (const entry of level.waves?.[field] ?? []) {
        const day = Number(entry[1]) + 1;
        if (doc.enemies?.[entry[0]]?.boss && day < rules.bossFirstDay) warnings.push({ type: "boss", source: "roster", level: index, levelId: level.id, monster: entry[0], day, night });
      }
    }
    for (const entry of extraEntries(level)) {
      if (doc.enemies?.[entry.kind]?.boss && Number(entry.day) < rules.bossFirstDay) warnings.push({ type: "boss", source: "extra", level: index, levelId: level.id, monster: entry.kind, day: Number(entry.day), night: Boolean(entry.night) });
    }
  });
  return warnings;
}

export function checkBalance(doc, rules = BALANCE_RULES) {
  const result = {
    upgrades: upgradeWarnings(doc, rules),
    monsters: monsterWarnings(doc, rules),
    starters: starterWarnings(doc),
    bosses: bossWarnings(doc, rules),
  };
  result.total = CATEGORIES.reduce((sum, key) => sum + result[key].length, 0);
  return result;
}
