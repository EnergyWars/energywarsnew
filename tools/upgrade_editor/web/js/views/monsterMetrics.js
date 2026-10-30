import { t } from "../i18n.js";
import { number, percent } from "../format.js";

const times = (digits) => (value) => `×${number(value, digits)}`;

export const MONSTER_METRICS = [
  { key: "hp", color: "var(--series-level)", digits: 2, factor: true, format: (value) => number(value, 1) },
  { key: "damage", color: "var(--series-cost-factor)", digits: 2, factor: true, format: (value) => number(value, 1) },
  { key: "speed", color: "var(--series-gain)", digits: 2, factor: true, format: (value) => number(value, 1) },
  { key: "armor", color: "var(--series-total)", digits: 2, factor: true, format: (value) => number(value, 1) },
  { key: "reduction", color: "var(--series-effect)", digits: 2, factor: false, format: percent },
  { key: "effectiveHp", color: "var(--series-spent)", digits: 2, factor: true, format: (value) => number(value, 1) },
  { key: "dps", color: "var(--series-spent-factor)", digits: 2, factor: true, format: (value) => number(value, 1) },
  { key: "bounty", color: "var(--series-cost)", digits: 0, factor: false, format: (value) => number(value, 0) },
];

export const MONSTER_KEYS = MONSTER_METRICS.map((metric) => metric.key);
export const MONSTER_COLUMNS = [{ key: "row" }, ...MONSTER_METRICS];

export function visibleMonsterColumns(hidden) {
  return MONSTER_COLUMNS.filter((column) => column.key === "row" || !hidden.has(column.key));
}

export function metricFormat(metric, mode) {
  return mode === "factor" && metric.factor ? times(2) : metric.format;
}

export function editStatOf(key) {
  if (key === "reduction") return "armor";
  if (key === "effectiveHp") return "hp";
  if (key === "dps") return "damage";
  return key;
}

export function rowName(row) {
  return `${t("monsters.level")} ${row.level + 1} · ${t(row.night ? "monsters.night" : "monsters.day")}`;
}

export function cellTip(key, row) {
  const description = t(`monsters.desc.${key}`);
  if (key === "bounty") return `${description} ${t("monsters.edit.bounty")}`;
  const stat = t(`monsters.col.${editStatOf(key)}`);
  const target = row.night ? "night" : row.level === 0 ? "base" : "level";
  const via = key === editStatOf(key) ? "" : `${t(`monsters.edit.via.${key}`)} `;
  return `${description} ${via}${t(`monsters.edit.${target}`, { stat, level: row.level + 1 })}`;
}
