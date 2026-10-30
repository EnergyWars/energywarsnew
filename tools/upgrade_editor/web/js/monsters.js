import { reduction, armorForReduction } from "./armor.js";

export const BUFF_STATS = ["hp", "damage", "speed", "armor"];
export const STAT_COLUMNS = ["hp", "damage", "speed", "armor"];
export const CLASSES = ["melee", "ranged", "air"];
export const FACTIONS = ["nest", "camp"];
export const FLAGS = ["boss", "nocturnal", "sabotage"];
export const SCOPES = ["night", "level"];
const LOWEST_BUFF = -1;
const PRECISION = 1e6;

const clone = (value) => JSON.parse(JSON.stringify(value));
const round6 = (value) => Math.round(value * PRECISION) / PRECISION;

export function buffValue(enemy, scope, stat) {
  return Number(enemy.buffs?.[scope]?.[stat] ?? 0);
}

export function buffFactor(enemy, stat, night, level) {
  const nightBonus = night ? buffValue(enemy, "night", stat) : 0;
  const levelBonus = buffValue(enemy, "level", stat) * Math.max(level, 0);
  return Math.max(1 + nightBonus, 0) * Math.max(1 + levelBonus, 0);
}

export function statAt(enemy, stat, night, level) {
  return Number(enemy[stat]) * buffFactor(enemy, stat, night, level);
}

export function monsterRow(enemy, config, level, night) {
  const hp = statAt(enemy, "hp", night, level);
  const damage = statAt(enemy, "damage", night, level);
  const armor = statAt(enemy, "armor", night, level);
  const share = reduction(armor, config);
  return {
    index: level * 2 + (night ? 1 : 0),
    level,
    night,
    hp,
    damage,
    speed: statAt(enemy, "speed", night, level),
    armor,
    reduction: share * 100,
    effectiveHp: hp / (1 - share),
    dps: damage / Number(enemy.cooldown),
    bounty: Number(enemy.bounty),
  };
}

export function monsterRows(enemy, config, levelCount) {
  const rows = [];
  for (let level = 0; level < Math.max(levelCount, 1); level += 1) {
    rows.push(monsterRow(enemy, config, level, false), monsterRow(enemy, config, level, true));
  }
  return rows;
}

export function baseRow(enemy, config) {
  return monsterRow(enemy, config, 0, false);
}

export function editTarget(row) {
  if (row.night) return "night";
  return row.level === 0 ? "base" : "level";
}

function editStat(enemy, stat, night, level, value) {
  if (!Number.isFinite(value) || value < 0) return null;
  const next = clone(enemy);
  const base = Number(enemy[stat]);
  const positive = stat === "hp" || stat === "speed";
  if (!night && level === 0) {
    if (positive && value <= 0) return null;
    next[stat] = round6(value);
    return next;
  }
  if (!(base > 0) || value <= 0) return null;
  next.buffs = clone(enemy.buffs ?? {});
  next.buffs.night ??= {};
  next.buffs.level ??= {};
  if (night) {
    const levelPart = Math.max(1 + buffValue(enemy, "level", stat) * level, 0);
    if (levelPart <= 0) return null;
    const buff = value / (base * levelPart) - 1;
    if (buff <= LOWEST_BUFF) return null;
    next.buffs.night[stat] = round6(buff);
    return next;
  }
  const buff = (value / base - 1) / level;
  if (buff <= LOWEST_BUFF) return null;
  next.buffs.level[stat] = round6(buff);
  return next;
}

export function editMonster(enemy, config, row, key, value) {
  if (!Number.isFinite(value)) return null;
  const { level, night } = row;
  if (STAT_COLUMNS.includes(key)) return editStat(enemy, key, night, level, value);
  if (key === "reduction") {
    const armor = armorForReduction(value / 100, config);
    return armor === null ? null : editStat(enemy, "armor", night, level, armor);
  }
  if (key === "effectiveHp") {
    if (value <= 0) return null;
    return editStat(enemy, "hp", night, level, value * (1 - reduction(statAt(enemy, "armor", night, level), config)));
  }
  if (key === "dps") return value < 0 ? null : editStat(enemy, "damage", night, level, value * Number(enemy.cooldown));
  if (key === "bounty") {
    if (value < 0) return null;
    const next = clone(enemy);
    next.bounty = Math.round(value);
    return next;
  }
  return null;
}

export function factorBase(key, enemy, config) {
  const base = baseRow(enemy, config);
  return ["hp", "damage", "speed", "armor", "effectiveHp", "dps"].includes(key) ? base[key] : null;
}

export function columnView(key, enemy, config, mode) {
  const base = mode === "factor" ? factorBase(key, enemy, config) : null;
  const usable = base !== null && base > 0;
  return {
    converted: usable,
    blocked: mode === "factor" && base !== null && !usable,
    show: (value) => (usable ? value / base : value),
    parse: (value) => (usable ? value * base : value),
  };
}

export function setBase(enemy, key, value) {
  if (!Number.isFinite(value)) return false;
  if (["hp", "speed", "radius", "cooldown"].includes(key) && value <= 0) return false;
  if (["damage", "reach", "armor", "bounty"].includes(key) && value < 0) return false;
  enemy[key] = key === "bounty" ? Math.round(value) : value;
  return true;
}

export function setBuff(enemy, scope, stat, value) {
  if (!Number.isFinite(value) || value <= LOWEST_BUFF) return false;
  enemy.buffs ??= {};
  enemy.buffs[scope] ??= {};
  enemy.buffs[scope][stat] = round6(value);
  return true;
}

export function setFlag(enemy, flag, on) {
  if (on) enemy[flag] = true;
  else delete enemy[flag];
}

export function filterMonsters(enemies, names, { query = "", klass = "all", faction = "all", kind = "all" } = {}, nameOf = (key) => key) {
  const needle = query.trim().toLowerCase();
  return Object.entries(enemies)
    .filter(([key, enemy]) => {
      if (klass !== "all" && enemy.class !== klass) return false;
      if (faction !== "all" && enemy.faction !== faction) return false;
      if (kind === "boss" && !enemy.boss) return false;
      if (kind === "normal" && enemy.boss) return false;
      if (kind === "night" && !enemy.nocturnal) return false;
      if (kind === "day" && enemy.nocturnal) return false;
      if (!needle) return true;
      return `${key} ${nameOf(key)}`.toLowerCase().includes(needle);
    })
    .map(([key]) => key);
}
