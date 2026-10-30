export function number(value, digits = 2) {
  if (value === undefined || value === null) return "–";
  if (typeof value !== "number") return String(value);
  return Number.isInteger(value) ? String(value) : value.toFixed(digits).replace(/\.?0+$/, "");
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
