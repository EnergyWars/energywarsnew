export const COLORS = {
  background: "#0b1020", surface: "#141b2e", surfaceVariant: "#1d2640", outline: "#3a4770",
  onSurface: "#eef3ff", onSurfaceVariant: "#a9b4d0", energy: "#3ee8ff", energyCore: "#e6fdff",
  gold: "#ffc83d", goldDark: "#b8860b", danger: "#ff4d6d", success: "#4be38a", warning: "#ffb020",
  plasmaOrange: "#ff8a3d", shieldBlue: "#5aa9ff", onAccent: "#08111f",
  metal: "#8b97ad", metalDark: "#4a5468", metalDeep: "#2b3244",
  solarCell: "#1f4fa8", solarLine: "#7fb2ff", water: "#2f6f9a", waterDeep: "#1d4a72", waterLight: "#9fdcff",
  rock: "#6d717c", rockDark: "#4b4e57", trunk: "#4a3522", flame: "#ff7a1a", flameCore: "#ffe27a",
  lampLight: "#ffe9a8", lampOff: "#5a5446", shadow: "rgba(0,0,0,0.3)",
};

export const BUILDING_COLORS = {
  core: "#3ee8ff", solar: "#ffc83d", relay: "#7fdfff", battery: "#4be38a", zapper: "#9ff3ff", laser: "#ff5d7a",
  tesla: "#b57bff", plasma: "#ff8a3d", shield: "#5aa9ff", exporter: "#ffc83d", water: "#4fb3ff", fire: "#ff7a1a",
  lamp: "#ffe9a8", healer: "#6dff9e", bulwark: "#ff9f43", bastion: "#ffb86b", rover: "#c6ff5a",
};

export function buildingColor(kind) {
  return BUILDING_COLORS[kind] ?? COLORS.energy;
}

export function parse(hex) {
  const value = hex.replace("#", "");
  return [0, 2, 4].map((offset) => parseInt(value.slice(offset, offset + 2), 16));
}

export function rgba(hex, alpha = 1) {
  const [r, g, b] = parse(hex);
  return `rgba(${r},${g},${b},${alpha})`;
}

function toHex(channels) {
  return `#${channels.map((c) => Math.round(Math.min(255, Math.max(0, c))).toString(16).padStart(2, "0")).join("")}`;
}

export function lighten(hex, amount) {
  return toHex(parse(hex).map((c) => c + (255 - c) * amount));
}

export function darken(hex, amount) {
  return toHex(parse(hex).map((c) => c * (1 - amount)));
}

export function mix(from, to, amount) {
  const a = parse(from);
  const b = parse(to);
  return toHex(a.map((c, index) => c + (b[index] - c) * amount));
}
