export const CURVE_MAX = 300;
export const CURVE_STEP = 10;

export function reduction(armor, config) {
  const value = Number(armor);
  if (!(value > 0)) return 0;
  return Math.min(Math.max(value / (value + Number(config.constant)), 0), Number(config.max_reduction));
}

export function mitigate(amount, armor, config, share = 1) {
  if (!(amount > 0)) return 0;
  if (!(Number(armor) > 0)) return amount;
  const reduced = amount * (1 - reduction(armor, config));
  return Math.min(amount, Math.max(reduced, Number(config.min_damage) * Math.max(share, 0)));
}

export function armorForReduction(share, config) {
  if (!(share >= 0) || share >= Number(config.max_reduction)) return null;
  return (Number(config.constant) * share) / (1 - share);
}

export function curveRows(config, max = CURVE_MAX, step = CURVE_STEP) {
  const rows = [];
  for (let armor = 0; armor <= max; armor += step) {
    const share = reduction(armor, config);
    rows.push({ armor, reduction: share * 100, taken: (1 - share) * 100, durability: 1 / (1 - share), capped: armor > 0 && armor / (armor + Number(config.constant)) > Number(config.max_reduction) });
  }
  return rows;
}

export function example(config, armor, damage) {
  const share = reduction(armor, config);
  const reduced = damage * (1 - share);
  const result = mitigate(damage, armor, config);
  return { reduction: share * 100, reduced, result, floored: damage > 0 && reduced < Number(config.min_damage) && result > reduced };
}

export function armorEntries(doc) {
  const buildings = doc.buildings.map((entry) => ({ type: "building", id: entry.id, armor: Number(entry.armor ?? 0) }));
  const monsters = Object.entries(doc.enemies).map(([kind, enemy]) => ({ type: "monster", id: kind, armor: Number(enemy.armor ?? 0) }));
  return [...buildings, ...monsters];
}

export function setArmor(doc, type, id, value) {
  if (!Number.isFinite(value) || value < 0) return false;
  const target = type === "building" ? doc.buildings.find((entry) => entry.id === id) : doc.enemies[id];
  if (!target) return false;
  target.armor = value;
  return true;
}
