import { COLORS as C, buildingColor, rgba, lighten, darken, mix } from "./theme.js";

const TAU = Math.PI * 2;
const SHADOW_OFFSET = [4, 7];

function polygonPoints(cx, cy, radius, sides, rotation = 0) {
  return Array.from({ length: sides }, (_, i) => [cx + Math.cos(rotation + (TAU * i) / sides) * radius, cy + Math.sin(rotation + (TAU * i) / sides) * radius]);
}

function fillPoly(ctx, points, color) {
  ctx.beginPath();
  points.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)));
  ctx.closePath();
  ctx.fillStyle = color;
  ctx.fill();
}

function poly(ctx, cx, cy, radius, sides, rotation, color) {
  fillPoly(ctx, polygonPoints(cx, cy, radius, sides, rotation), color);
}

function circle(ctx, cx, cy, radius, color) {
  ctx.beginPath();
  ctx.arc(cx, cy, Math.max(radius, 0), 0, TAU);
  ctx.fillStyle = color;
  ctx.fill();
}

function ellipse(ctx, cx, cy, rx, ry, color) {
  ctx.beginPath();
  ctx.ellipse(cx, cy, Math.max(rx, 0.01), Math.max(ry, 0.01), 0, 0, TAU);
  ctx.fillStyle = color;
  ctx.fill();
}

function line(ctx, x1, y1, x2, y2, color, width) {
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.lineCap = "round";
  ctx.stroke();
}

function arc(ctx, cx, cy, radius, start, end, color, width) {
  ctx.beginPath();
  ctx.arc(cx, cy, radius, start, end);
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.lineCap = "round";
  ctx.stroke();
}

function rect(ctx, x, y, w, h, color) {
  ctx.fillStyle = color;
  ctx.fillRect(x, y, w, h);
}

function strokeRect(ctx, x, y, w, h, color, width) {
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.strokeRect(x, y, w, h);
}

function glow(ctx, cx, cy, radius, color, strength = 1) {
  circle(ctx, cx, cy, radius * 2.2, rgba(color, 0.07 * strength));
  circle(ctx, cx, cy, radius * 1.5, rgba(color, 0.16 * strength));
  circle(ctx, cx, cy, radius, rgba(color, 0.9 * strength));
  circle(ctx, cx, cy, radius * 0.45, rgba(C.energyCore, strength));
}

function shadow(ctx, cx, cy, radius, lift = 1) {
  ellipse(ctx, cx + SHADOW_OFFSET[0] * lift, cy + SHADOW_OFFSET[1] * lift, radius, radius * 0.75, C.shadow);
}

function base(ctx, cx, cy, radius, sides = 8) {
  shadow(ctx, cx, cy, radius);
  poly(ctx, cx, cy, radius, sides, Math.PI / sides, C.metalDeep);
  poly(ctx, cx, cy, radius * 0.84, sides, Math.PI / sides, C.metalDark);
}

function flames(ctx, cx, cy, radius, time, strength = 1) {
  for (let i = 0; i < 5; i += 1) {
    const phase = time * 9 + i * 1.7;
    const sway = Math.sin(phase) * radius * 0.25;
    const bx = cx + (i - 2) * radius * 0.35;
    const by = cy + radius * 0.3;
    const height = radius * (1.1 + 0.5 * Math.abs(Math.sin(phase * 1.3))) * strength;
    const left = [bx - radius * 0.28, by];
    const right = [bx + radius * 0.28, by];
    fillPoly(ctx, [left, [bx + sway, by - height], right], rgba(C.flame, 0.85));
    const lerp = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
    fillPoly(ctx, [lerp(left, right, 0.3), lerp([bx, by], [bx + sway, by - height], 0.6), lerp(left, right, 0.7)], rgba(C.flameCore, 0.9));
  }
}

const painters = {
  core(ctx, cx, cy, r, time, fill) {
    shadow(ctx, cx, cy, r);
    poly(ctx, cx, cy, r, 6, Math.PI / 6, C.metalDeep);
    poly(ctx, cx, cy, r * 0.86, 6, Math.PI / 6, C.metalDark);
    const outline = polygonPoints(cx, cy, r * 0.86, 6, Math.PI / 6);
    ctx.beginPath();
    outline.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)));
    ctx.closePath();
    ctx.strokeStyle = rgba(C.energy, 0.8);
    ctx.lineWidth = 3;
    ctx.stroke();
    arc(ctx, cx, cy, r * 0.62, -Math.PI / 2, -Math.PI / 2 + TAU * clamp(fill), C.energy, 5);
    glow(ctx, cx, cy, r * 0.34 * (1 + 0.08 * Math.sin(time * 4)), C.energy);
  },
  solar(ctx, cx, cy, r, time, fill, aim, light) {
    shadow(ctx, cx, cy, r);
    const half = r * 0.9;
    rect(ctx, cx - half, cy - half, half * 2, half * 2, C.metalDark);
    const inner = half * 0.86;
    rect(ctx, cx - inner, cy - inner, inner * 2, inner * 2, mix(C.solarCell, "#3d74d9", light * 0.5));
    for (let i = 1; i < 3; i += 1) {
      const offset = -inner + (inner * 2 * i) / 3;
      line(ctx, cx + offset, cy - inner, cx + offset, cy + inner, rgba(C.solarLine, 0.55), 1.5);
      line(ctx, cx - inner, cy + offset, cx + inner, cy + offset, rgba(C.solarLine, 0.55), 1.5);
    }
    if (light > 0.05) {
      const sweep = (((time * 0.35) % 1) + 1) % 1 * 2 - 0.5;
      const ax = cx - inner + inner * 2 * sweep;
      const dx = -inner * 0.6;
      const dy = inner * 2;
      const scale = Math.min(1, (inner * 1.2) / Math.hypot(dx, dy));
      line(ctx, ax, cy - inner, ax + dx * scale, cy - inner + dy * scale, `rgba(255,255,255,${0.35 * light})`, 4);
      circle(ctx, cx + inner * 0.7, cy - inner * 0.7, 3, rgba(C.gold, light));
    }
  },
  relay(ctx, cx, cy, r, time, fill) {
    shadow(ctx, cx, cy, r * 0.9);
    circle(ctx, cx, cy, r, C.metalDeep);
    for (let i = 0; i < 3; i += 1) {
      const angle = -Math.PI / 2 + (TAU * i) / 3;
      const tx = cx + Math.cos(angle) * r;
      const ty = cy + Math.sin(angle) * r;
      line(ctx, cx, cy, tx, ty, C.metal, 4);
      circle(ctx, tx, ty, 3.5, C.metal);
    }
    glow(ctx, cx, cy, r * (0.3 + 0.12 * fill) * (1 + 0.1 * Math.sin(time * 6 + cy)), C.energy, 0.5 + fill * 0.5);
  },
  battery(ctx, cx, cy, r, time, fill) {
    shadow(ctx, cx, cy, r);
    const w = r * 1.3;
    const h = r * 1.85;
    const x = cx - w / 2;
    const y = cy - h / 2;
    rect(ctx, x, y, w, h, C.metalDeep);
    rect(ctx, cx - w * 0.22, y - 6, w * 0.44, 6, C.metal);
    const level = clamp(fill);
    rect(ctx, x + 4, y + 4, w - 8, h - 8, "#0d1a14");
    const inner = h - 8;
    rect(ctx, x + 4, y + 4 + inner * (1 - level), w - 8, inner * level, mix(C.success, C.energy, level * 0.4));
    for (let i = 1; i < 4; i += 1) line(ctx, x + 4, y + 4 + (inner * i) / 4, x + w - 4, y + 4 + (inner * i) / 4, "rgba(0,0,0,0.35)", 2);
    strokeRect(ctx, x, y, w, h, C.metal, 2);
  },
  zapper(ctx, cx, cy, r, time, fill) {
    base(ctx, cx, cy, r);
    for (let i = 0; i < 3; i += 1) arc(ctx, cx, cy, r * (0.72 - i * 0.14), 0, TAU, rgba(C.energy, 0.25 + i * 0.15), 2.5);
    glow(ctx, cx, cy, r * 0.28 * (0.85 + 0.15 * Math.sin(time * 23)), buildingColor("zapper"), 0.35 + fill * 0.65);
  },
  laser(ctx, cx, cy, r, time, fill, aim) {
    base(ctx, cx, cy, r, 6);
    const dx = Math.cos(aim);
    const dy = Math.sin(aim);
    line(ctx, cx, cy, cx + dx * r * 1.15, cy + dy * r * 1.15, C.metalDeep, 10);
    line(ctx, cx, cy, cx + dx * r * 1.1, cy + dy * r * 1.1, C.metal, 6);
    circle(ctx, cx, cy, r * 0.5, C.metal);
    circle(ctx, cx, cy, r * 0.32, C.metalDark);
    glow(ctx, cx + dx * r * 1.1, cy + dy * r * 1.1, 4, buildingColor("laser"), 0.3 + fill * 0.7);
  },
  tesla(ctx, cx, cy, r, time, fill) {
    base(ctx, cx, cy, r, 10);
    const color = buildingColor("tesla");
    for (let i = 0; i < 3; i += 1) circle(ctx, cx, cy, r * (0.7 - i * 0.16), darken(color, 0.55 - i * 0.15));
    if (fill > 0.2) {
      for (let i = 0; i < 3; i += 1) {
        const angle = time * 7 + i * 2.1 + Math.sin(time * 13 + i) * 0.8;
        line(ctx, cx + Math.cos(angle) * r * 0.25, cy + Math.sin(angle) * r * 0.25, cx + Math.cos(angle + 0.4) * r * 0.95, cy + Math.sin(angle + 0.4) * r * 0.95, rgba(lighten(color, 0.4), 0.8), 1.5);
      }
    }
    glow(ctx, cx, cy, r * 0.24, color, 0.4 + fill * 0.6);
  },
  plasma(ctx, cx, cy, r, time, fill, aim) {
    base(ctx, cx, cy, r, 8);
    const mx = cx + Math.cos(aim) * r * 0.25;
    const my = cy + Math.sin(aim) * r * 0.25;
    circle(ctx, mx, my, r * 0.55, C.metalDeep);
    circle(ctx, mx, my, r * 0.45, C.metal);
    circle(ctx, mx, my, r * 0.3, "#1a0d05");
    circle(ctx, mx, my, r * 0.22, rgba(C.plasmaOrange, 0.3 + fill * 0.7));
  },
  shield(ctx, cx, cy, r, time, fill) {
    base(ctx, cx, cy, r, 8);
    circle(ctx, cx, cy, r * 0.62, rgba(C.shieldBlue, 0.35 + 0.5 * fill));
    arc(ctx, cx, cy, r * 0.62, -2.6, -1.0, "rgba(255,255,255,0.6)", 3);
    arc(ctx, cx, cy, r * 0.75, time * 2, time * 2 + Math.PI * 0.6, rgba(C.shieldBlue, 0.8), 2);
  },
  exporter(ctx, cx, cy, r, time, fill) {
    base(ctx, cx, cy, r, 6);
    for (let i = 0; i < 3; i += 1) {
      const angle = -Math.PI / 2 + (TAU * i) / 3 + Math.PI / 3;
      line(ctx, cx, cy, cx + Math.cos(angle) * r * 0.78, cy + Math.sin(angle) * r * 0.78, C.metal, 3);
    }
    const spin = Math.abs(Math.cos(time * (1.5 + 3 * fill)));
    ellipse(ctx, cx, cy, r * 0.5 * Math.max(spin, 0.2), r * 0.5, C.goldDark);
    ellipse(ctx, cx, cy, r * 0.38 * Math.max(spin, 0.15), r * 0.38, mix(C.gold, "#ffffff", 0.2 * fill));
    arc(ctx, cx, cy, r * 1.12, 0, TAU, rgba(C.metalDeep, 0.85), 6);
    arc(ctx, cx, cy, r * 1.12, -Math.PI / 2, -Math.PI / 2 + TAU * clamp(fill), C.energy, 6);
  },
  water(ctx, cx, cy, r, time) {
    base(ctx, cx, cy, r, 8);
    circle(ctx, cx, cy, r * 0.72, C.waterDeep);
    circle(ctx, cx, cy, r * 0.56, C.water);
    for (let i = 0; i < 6; i += 1) {
      const angle = time * 1.8 + (TAU * i) / 6;
      const tx = cx + Math.cos(angle) * r * 0.7;
      const ty = cy + Math.sin(angle) * r * 0.7;
      line(ctx, cx, cy, tx, ty, C.metal, 3);
      circle(ctx, tx, ty, 3, C.waterLight);
    }
    circle(ctx, cx, cy, r * 0.18, C.metalDark);
  },
  fire(ctx, cx, cy, r, time, fill) {
    shadow(ctx, cx, cy, r);
    poly(ctx, cx, cy, r, 10, 0, C.rockDark);
    poly(ctx, cx, cy, r * 0.78, 10, 0, C.rock);
    circle(ctx, cx, cy, r * 0.6, C.metalDeep);
    for (let i = 0; i < 3; i += 1) {
      const angle = (TAU * i) / 3 + 0.4;
      line(ctx, cx + Math.cos(angle) * r * 0.5, cy + Math.sin(angle) * r * 0.5, cx - Math.cos(angle) * r * 0.5, cy - Math.sin(angle) * r * 0.5, C.trunk, 5);
    }
    if (fill > 0) {
      glow(ctx, cx, cy, r * 0.35, C.flame, 0.6 * fill);
      flames(ctx, cx, cy - r * 0.1, r * 0.45, time, fill);
    } else {
      circle(ctx, cx, cy, r * 0.2, rgba(C.flame, 0.25));
    }
  },
  lamp(ctx, cx, cy, r, time, fill) {
    shadow(ctx, cx, cy, r * 0.7);
    circle(ctx, cx, cy, r * 0.72, C.metalDeep);
    circle(ctx, cx, cy, r * 0.56, C.metalDark);
    const lit = clamp(fill);
    circle(ctx, cx, cy, r * 0.38, mix(C.lampOff, C.lampLight, lit));
    if (lit > 0.05) glow(ctx, cx, cy, r * 0.4 * (1 + 0.04 * Math.sin(time * 11)), C.lampLight, lit);
  },
  healer(ctx, cx, cy, r, time, fill) {
    base(ctx, cx, cy, r, 8);
    const color = buildingColor("healer");
    circle(ctx, cx, cy, r * 0.6, C.metal);
    circle(ctx, cx, cy, r * 0.5, rgba(color, 0.25 + 0.55 * fill));
    const arm = r * 0.36 * (1 + 0.08 * Math.sin(time * 3));
    const width = r * 0.16;
    rect(ctx, cx - arm, cy - width, arm * 2, width * 2, "#fff");
    rect(ctx, cx - width, cy - arm, width * 2, arm * 2, "#fff");
    arc(ctx, cx, cy, r * 0.72, time * 1.5, time * 1.5 + Math.PI * 0.5, rgba(color, 0.8), 2.5);
    arc(ctx, cx, cy, r * 0.72, time * 1.5 + Math.PI, time * 1.5 + Math.PI * 1.5, rgba(color, 0.8), 2.5);
  },
  bastion(ctx, cx, cy, r, time, fill, aim) {
    base(ctx, cx, cy, r, 8);
    const color = buildingColor("bastion");
    rect(ctx, cx - r * 0.78, cy - r * 0.78, r * 1.56, r * 1.56, C.metalDark);
    circle(ctx, cx, cy, r * 0.5, C.metal);
    circle(ctx, cx, cy, r * 0.34, rgba(color, 0.25 + 0.55 * fill));
    line(ctx, cx, cy, cx + Math.cos(aim) * r, cy + Math.sin(aim) * r, C.metalDeep, 5);
    arc(ctx, cx, cy, r * 0.9, time, time + Math.PI * 0.6, rgba(color, 0.8), 2.5);
  },
  rover(ctx, cx, cy, r, time, fill, aim) {
    shadow(ctx, cx, cy, r);
    const color = buildingColor("rover");
    for (const side of [-1, 1]) {
      const tx = cx - r;
      const ty = cy + side * r * 0.62 - r * 0.26;
      rect(ctx, tx, ty, r * 2, r * 0.52, C.metalDeep);
      for (let i = 0; i < 5; i += 1) {
        const x = tx + (((time * 30 + i * r * 0.4) % (r * 2)) + r * 2) % (r * 2);
        line(ctx, x, ty, x, ty + r * 0.52, C.metalDark, 2);
      }
    }
    rect(ctx, cx - r * 0.8, cy - r * 0.5, r * 1.6, r, C.metalDark);
    circle(ctx, cx, cy, r * 0.48, C.metal);
    line(ctx, cx, cy, cx + Math.cos(aim) * r * 1.05, cy + Math.sin(aim) * r * 1.05, C.metalDeep, 6);
    glow(ctx, cx, cy, r * 0.22, color, 0.35 + fill * 0.65);
  },
  bulwark(ctx, cx, cy, r) {
    const color = buildingColor("bulwark");
    rect(ctx, cx - r + SHADOW_OFFSET[0] * 0.6, cy - r + SHADOW_OFFSET[1] * 0.6, r * 2, r * 2, C.shadow);
    rect(ctx, cx - r, cy - r, r * 2, r * 2, C.metalDeep);
    rect(ctx, cx - r * 0.86, cy - r * 0.86, r * 1.72, r * 1.72, C.metalDark);
    const brick = r * 0.86;
    for (let row = 0; row < 2; row += 1) {
      const y = cy - brick + brick * row;
      line(ctx, cx - brick, y + brick, cx + brick, y + brick, C.metalDeep, 2);
      const x = cx + (row === 0 ? brick * 0.5 : -brick * 0.5);
      line(ctx, x, y, x, y + brick, C.metalDeep, 2);
    }
    rect(ctx, cx - r * 0.86, cy - r * 0.86, r * 1.72, r * 0.22, rgba(color, 0.85));
    for (const [sx, sy] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) circle(ctx, cx + sx * r * 0.7, cy + sy * r * 0.7, r * 0.08, C.metal);
  },
};

function clamp(value) {
  return Math.min(Math.max(value, 0), 1);
}

export function hasPainter(kind) {
  return kind in painters;
}

export function paintBuilding(ctx, kind, cx, cy, radius, time, fill = 0.6, aim = -Math.PI / 2, light = 1) {
  const paint = painters[kind];
  if (!paint) return;
  ctx.save();
  paint(ctx, cx, cy, radius, time, fill, aim, light);
  ctx.restore();
}
