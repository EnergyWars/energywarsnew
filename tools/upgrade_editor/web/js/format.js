export function number(value, digits = 2) {
  if (value === undefined || value === null) return "–";
  if (typeof value !== "number") return String(value);
  if (Number.isInteger(value)) return String(value);
  const fixed = value.toFixed(digits);
  return fixed.includes(".") ? fixed.replace(/\.?0+$/, "") : fixed;
}

export function compact(value) {
  return Math.abs(value) >= 10000 ? `${(value / 1000).toFixed(1).replace(/\.0$/, "")}k` : String(Math.round(value));
}

export const DEFAULT_CELL = 56;

export const LENGTH_STATS = new Set(["range", "build_radius", "vision", "attack.range", "attack.min_range", "attack.splash", "heal.range", "shield.radius"]);

export function cellSize(doc) {
  return doc?.system?.cell ?? DEFAULT_CELL;
}

export function toCells(pixels, cell) {
  return Math.round((pixels / cell) * 10000) / 10000;
}

export function fromCells(cells, cell) {
  return Math.round(cells * cell * 1000) / 1000;
}

export function percentDigits(value) {
  const size = Math.abs(value);
  if (size >= 100) return 0;
  if (size >= 10) return 1;
  return 2;
}

export function percent(value) {
  return value === null || value === undefined ? "–" : `${number(value, percentDigits(value))} %`;
}

export function signedPercent(value) {
  if (value === null || value === undefined) return "–";
  return `${value > 0 ? "+" : ""}${percent(value)}`;
}
