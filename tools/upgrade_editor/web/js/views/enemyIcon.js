import { paintMonster } from "../enemyPainter.js";

const live = new Set();
let running = false;

function draw({ canvas, enemies, kind, radius, size, night }, time) {
  const ratio = globalThis.devicePixelRatio || 1;
  const ctx = canvas.getContext("2d");
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
  ctx.clearRect(0, 0, size, size);
  const factor = size / (radius * 5);
  ctx.translate(size / 2, size / 2);
  ctx.scale(factor, factor);
  paintMonster(ctx, enemies, kind, 0, 0, radius, Math.sin(time * 0.6) * 0.5 - 0.3, time, night);
}

function frame(now) {
  for (const entry of live) {
    if (!entry.canvas.isConnected) {
      live.delete(entry);
      continue;
    }
    draw(entry, now / 1000);
  }
  if (live.size > 0) requestAnimationFrame(frame);
  else running = false;
}

export function enemyIcon(enemies, kind, size = 72, { night = 0 } = {}) {
  const ratio = globalThis.devicePixelRatio || 1;
  const canvas = document.createElement("canvas");
  canvas.width = size * ratio;
  canvas.height = size * ratio;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  canvas.className = "icon-canvas";
  canvas.setAttribute("aria-hidden", "true");
  const entry = { canvas, enemies, kind, radius: 16, size, night };
  if (!canvas.getContext) return canvas;
  draw(entry, 0);
  live.add(entry);
  if (!running) {
    running = true;
    requestAnimationFrame(frame);
  }
  return canvas;
}
