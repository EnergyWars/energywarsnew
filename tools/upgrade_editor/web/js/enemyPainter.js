import { COLORS as C, rgba, lighten, darken, mix } from "./theme.js";
import { fillPoly, circle, ellipse, line, arc, rect } from "./painter.js";

const TAU = Math.PI * 2;
const BONE = "#e8d8c0";
const GUN = "#1b1b1b";
const GLOW = "#ff4d6d";
const GOLD = "#ffc83d";
const BOSS_RING = 1.4;
const BOSS_ARCS = 4;
const FALLBACK_LOOK = "crawler";
const SHADOW_OFFSET = [4, 7];

export const SHAPES = ["bug", "wasp", "bat", "soldier", "tank", "drone"];

export const LOOKS = {
  crawler: { shape: "bug", body: "#c2352c", shell: "#6e1a14", legs: 3 },
  larva: { shape: "bug", body: "#c9d36a", shell: "#8a9a3a", legs: 2, scale: 0.9 },
  mauler: { shape: "bug", body: "#a8552a", shell: "#6b2f14", legs: 4, horns: 2 },
  beetle: { shape: "bug", body: "#4c3a6e", shell: "#7a5fb0", legs: 3, plates: 1 },
  stalker: { shape: "bug", body: "#2a1838", shell: "#5b2f7a", legs: 4, fangs: true },
  ravager: { shape: "bug", body: "#3d1f2a", shell: "#8a2438", legs: 4, spikes: 3, fangs: true, scale: 1.05 },
  spitter: { shape: "bug", body: "#7aa83a", shell: "#4c6a24", legs: 3, spit: "#d6ff7a" },
  slinger: { shape: "bug", body: "#4f8a6a", shell: "#2c5a44", legs: 3, horns: 1, spit: "#9af0c8" },
  wasp: { shape: "wasp", body: "#f0c330", shell: "#3a2e10", wings: 1, stripes: 2 },
  gnat: { shape: "wasp", body: "#9fe05a", shell: "#2f4a14", wings: 1, stripes: 1, scale: 0.8 },
  nightwing: { shape: "bat", body: "#2b2140", shell: "#6a4a9a" },
  behemoth: { shape: "bug", body: "#5a2a2a", shell: "#8a3a2a", legs: 4, spikes: 5 },
  juggernaut: { shape: "bug", body: "#3a3f4a", shell: "#7a8394", legs: 4, plates: 4, horns: 2 },
  broodmother: { shape: "bug", body: "#6a2a7a", shell: "#a64bbf", legs: 6, spikes: 3, spit: "#f0a0ff" },
  dreadwing: { shape: "bat", body: "#5a1a3a", shell: "#c0305a", spikes: 3, scale: 1.15 },
  soldier: { shape: "soldier", body: "#5c6b3a", shell: "#3c4626", gun: 1.0 },
  raider: { shape: "soldier", body: "#2f3340", shell: "#1a1c24", gun: 1.0, mark: "#ff4d6d" },
  sniper: { shape: "soldier", body: "#3a4a3f", shell: "#1f2a22", gun: 2.2, mark: "#ffd24d" },
  sprinter: { shape: "soldier", body: "#c47a2a", shell: "#7a4a14", gun: 0.0, scale: 0.9, mark: "#fff0c0" },
  saboteur: { shape: "soldier", body: "#2c2c3a", shell: "#16161f", gun: 0.0, mark: "#c070ff" },
  breacher: { shape: "soldier", body: "#6a3a3a", shell: "#3a1f1f", gun: 0.0, plates: 3, scale: 1.1 },
  brute: { shape: "soldier", body: "#4a4f58", shell: "#2a2d33", gun: 0.0, plates: 4, scale: 1.2 },
  colossus: { shape: "soldier", body: "#2f2f36", shell: "#6b6b78", gun: 0.0, plates: 6, mark: "#ff4d6d" },
  reaper: { shape: "bug", body: "#2a0f14", shell: "#c0222e", legs: 6, horns: 2, fangs: true },
  drone: { shape: "drone", body: "#5d6470", shell: "#5d6470", rotors: 4 },
  phantom: { shape: "drone", body: "#5d6470", shell: "#5d6470", rotors: 4, core: "#b57bff" },
  gunship: { shape: "drone", body: "#4a525e", shell: "#2b3140", rotors: 6, gun: 1.2, plates: 2 },
  tank: { shape: "tank", body: "#55603a", shell: "#343b22", barrels: 1 },
  artillery: { shape: "tank", body: "#6a5a3a", shell: "#3a321f", barrels: 1, barrel: 2.3 },
  warlord: { shape: "tank", body: "#6a2f2f", shell: "#3a1818", barrels: 2, plates: 2 },
};

export function lookKey(enemies, kind) {
  const key = enemies?.[kind]?.look ?? kind;
  return LOOKS[key] ? key : FALLBACK_LOOK;
}

export function lookOf(enemies, kind) {
  return LOOKS[lookKey(enemies, kind)];
}

export function hasLook(key) {
  return Boolean(LOOKS[key]);
}

function stripes(ctx, size, count, color) {
  for (let i = 0; i < count; i += 1) {
    const x = -size * 0.75 + (size * 1.3 * (i + 0.5)) / count;
    line(ctx, x, -size * 0.55, x, size * 0.55, color, 2);
  }
}

function spikes(ctx, size, count) {
  for (let i = 0; i < count; i += 1) {
    const angle = Math.PI * 0.6 + (Math.PI * 0.8 * i) / Math.max(count - 1, 1);
    const sx = Math.cos(angle) * size;
    const sy = Math.sin(angle) * size;
    const length = Math.hypot(sx, sy) || 1;
    const nx = (sy / length) * 5;
    const ny = (-sx / length) * 5;
    fillPoly(ctx, [[sx * 0.8 + nx, sy * 0.8 + ny], [sx * 1.35, sy * 1.35], [sx * 0.8 - nx, sy * 0.8 - ny]], BONE);
  }
}

function horns(ctx, size, count) {
  for (let i = 0; i < count; i += 1) {
    const side = i % 2 === 0 ? -1 : 1;
    const bx = size;
    const by = side * size * 0.2;
    const tx = size * 1.65;
    const ty = side * size * (0.35 + 0.15 * Math.floor(i / 2));
    fillPoly(ctx, [[bx, by - 3], [tx, ty], [bx, by + 3]], BONE);
  }
}

function fangs(ctx, size) {
  for (const side of [-1, 1]) line(ctx, size * 0.9, side * size * 0.3, size * 1.5, side * size * 0.55, "#e8d8f0", 2.5);
}

function bug(ctx, size, time, look) {
  const legs = look.legs ?? 3;
  const swing = Math.sin(time * 18) * size * 0.25;
  const leg = darken(look.body, 0.4);
  for (let i = 0; i < legs; i += 1) {
    const x = size * (0.5 - i / Math.max(legs - 1, 1));
    const phase = i % 2 === 0 ? swing : -swing;
    line(ctx, x, 0, x + phase, size * 1.15, leg, 2.5);
    line(ctx, x, 0, x - phase, -size * 1.15, leg, 2.5);
  }
  ellipse(ctx, -size * 0.15, 0, size, size * 0.8, look.body);
  ellipse(ctx, -size * 0.2, 0, size * 0.75, size * 0.6, look.shell);
  circle(ctx, size * 0.8, 0, size * 0.45, darken(look.body, 0.35));
  stripes(ctx, size, look.plates ?? 0, darken(look.shell, 0.45));
  spikes(ctx, size, look.spikes ?? 0);
  horns(ctx, size, look.horns ?? 0);
  if (look.fangs) fangs(ctx, size);
  if (look.spit) circle(ctx, size * 1.05, 0, size * 0.3, look.spit);
}

function wasp(ctx, size, time, look) {
  const flap = 0.5 + 0.5 * Math.abs(Math.sin(time * 40));
  for (let pair = 0; pair < (look.wings ?? 1); pair += 1) {
    for (const side of [-1, 1]) ellipse(ctx, -size * 0.3 * pair, side * size * 0.9, size * 0.7, size * 0.9 * flap, "rgba(230,242,255,0.45)");
  }
  ellipse(ctx, -size * 0.3, 0, size * 1.1, size * 0.55, look.body);
  for (let i = 0; i < (look.stripes ?? 2); i += 1) {
    const x = -size * (0.1 + i * 0.5);
    line(ctx, x, -size * 0.5, x, size * 0.5, look.shell, 3);
  }
  circle(ctx, size * 0.75, 0, size * 0.45, look.shell);
}

function bat(ctx, size, time, look) {
  const flap = 0.6 + 0.4 * Math.sin(time * 16);
  for (const side of [-1, 1]) {
    fillPoly(ctx, [[size * 0.3, side * size * 0.2], [-size * 0.2, side * size * 1.9 * flap], [-size * 0.9, side * size * 0.9 * flap], [-size * 0.5, side * size * 0.2]], look.shell);
  }
  ellipse(ctx, -size * 0.1, 0, size * 0.8, size * 0.45, look.body);
  circle(ctx, size * 0.7, 0, size * 0.4, darken(look.body, 0.3));
  for (let i = 0; i < (look.spikes ?? 0); i += 1) {
    const x = -size * 0.8 + size * 0.35 * i;
    fillPoly(ctx, [[x, -size * 0.2], [x - size * 0.3, 0], [x, size * 0.2]], BONE);
  }
}

function soldier(ctx, size, look) {
  const helmet = look.shell;
  ellipse(ctx, 0, 0, size * 0.7, size * 1.1, look.body);
  const plates = look.plates ?? 0;
  for (let i = 0; i < plates; i += 1) {
    const y = -size * 0.9 + (size * 1.8 * (i + 0.5)) / plates;
    line(ctx, -size * 0.45, y, size * 0.45, y, lighten(helmet, 0.25), 3);
  }
  const gun = look.gun ?? 0;
  if (gun > 0) line(ctx, size * 0.2, size * 0.45, size * (0.2 + 1.3 * gun), size * 0.45, GUN, 3.5);
  circle(ctx, 0, 0, size * 0.6, helmet);
  circle(ctx, -size * 0.1, -size * 0.1, size * 0.2, lighten(helmet, 0.2));
  if (look.mark) line(ctx, size * 0.2, -size * 0.3, size * 0.5, -size * 0.3, look.mark, 3);
}

function tank(ctx, size, look) {
  const hx = size * 1.25;
  const hy = size * 0.95;
  rect(ctx, -hx, -hy - 4, hx * 2, 8, look.shell);
  rect(ctx, -hx, hy - 4, hx * 2, 8, look.shell);
  rect(ctx, -hx * 0.95, -hy * 0.8, hx * 1.9, hy * 1.6, look.body);
  const plates = look.plates ?? 0;
  for (let i = 0; i < plates; i += 1) {
    const x = -hx * 0.7 + (hx * 1.4 * (i + 0.5)) / plates;
    rect(ctx, x - 3, -hy * 0.8, 6, hy * 1.6, lighten(look.shell, 0.15));
  }
  const barrels = look.barrels ?? 1;
  const length = size * 1.7 * (look.barrel ?? 1);
  for (let i = 0; i < barrels; i += 1) {
    const y = barrels === 1 ? 0 : -size * 0.3 + size * 0.6 * (i / (barrels - 1));
    line(ctx, 0, y, length, y, "#22261a", barrels === 1 ? 6 : 4);
  }
  circle(ctx, 0, 0, size * 0.55, lighten(look.body, 0.15));
  circle(ctx, -size * 0.1, 0, size * 0.2, GLOW);
}

function drone(ctx, size, time, look) {
  const rotors = look.rotors ?? 4;
  const arm = darken(look.body, 0.4);
  for (let i = 0; i < rotors; i += 1) {
    const angle = (TAU * (i + 0.5)) / rotors;
    const ax = Math.cos(angle) * size * 0.95;
    const ay = Math.sin(angle) * size * 0.95;
    line(ctx, 0, 0, ax, ay, arm, 3);
    circle(ctx, ax, ay, size * 0.5, `rgba(217,230,255,${0.25 + 0.15 * Math.abs(Math.sin(time * 50 + i))})`);
  }
  rect(ctx, -size * 0.55, -size * 0.45, size * 1.1, size * 0.9, look.body);
  const plates = look.plates ?? 0;
  for (let i = 0; i < plates; i += 1) {
    const y = -size * 0.3 + (size * 0.6 * i) / Math.max(plates - 1, 1);
    line(ctx, -size * 0.5, y, size * 0.5, y, lighten(look.shell, 0.2), 2);
  }
  const gun = look.gun ?? 0;
  if (gun > 0) line(ctx, size * 0.3, 0, size * (0.3 + gun), 0, GUN, 3.5);
  circle(ctx, size * 0.35, 0, size * 0.2, GLOW);
  if (look.core) circle(ctx, 0, 0, size * 0.35, rgba(look.core, 0.8));
}

function bossRing(ctx, cx, cy, size, time) {
  const pulse = 0.55 + 0.25 * Math.sin(time * 4);
  arc(ctx, cx, cy, size * BOSS_RING, 0, TAU, rgba(C.danger, pulse * 0.6), 2);
  for (let i = 0; i < BOSS_ARCS; i += 1) {
    const from = time * 0.8 + (TAU * i) / BOSS_ARCS;
    arc(ctx, cx, cy, size * (BOSS_RING + 0.18), from, from + TAU / 10, rgba(GOLD, pulse), 3);
  }
}

function eyes(ctx, size, shape, night) {
  const mode = ["bug", "wasp", "bat"].includes(shape) ? "head" : shape === "soldier" ? "face" : "none";
  if (mode === "none") return;
  const color = mix("#ffd933", "#ff4033", night);
  const x = size * (mode === "head" ? 0.95 : 0.35);
  for (const side of [-1, 1]) {
    const y = side * size * 0.22;
    if (night > 0.2) circle(ctx, x, y, size * 0.3, rgba(color, 0.25 * night));
    circle(ctx, x, y, Math.max(size * 0.1, 1.5), color);
  }
}

export function paintEnemy(ctx, look, { boss = false, air = false } = {}, cx, cy, radius, heading, time, night = 0) {
  const size = radius * (look.scale ?? 1);
  const lift = air ? 3 : 1;
  ellipse(ctx, cx + SHADOW_OFFSET[0] * lift, cy + SHADOW_OFFSET[1] * lift, size, size * 0.75, C.shadow);
  if (boss) bossRing(ctx, cx, cy, size, time);
  ctx.save();
  ctx.translate(cx, cy);
  ctx.rotate(heading);
  if (look.shape === "bug") bug(ctx, size, time, look);
  else if (look.shape === "wasp") wasp(ctx, size, time, look);
  else if (look.shape === "bat") bat(ctx, size, time, look);
  else if (look.shape === "soldier") soldier(ctx, size, look);
  else if (look.shape === "tank") tank(ctx, size, look);
  else if (look.shape === "drone") drone(ctx, size, time, look);
  eyes(ctx, size, look.shape, night);
  ctx.restore();
}

export function paintMonster(ctx, enemies, kind, cx, cy, radius, heading, time, night = 0) {
  const definition = enemies?.[kind] ?? {};
  paintEnemy(ctx, lookOf(enemies, kind), { boss: Boolean(definition.boss), air: definition.class === "air" }, cx, cy, radius, heading, time, night);
}
