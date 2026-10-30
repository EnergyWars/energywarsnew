import { paintBuilding, hasPainter } from "../painter.js";

const live = new Set();
let running = false;

function frame(now) {
  const time = now / 1000;
  for (const entry of live) {
    if (!entry.canvas.isConnected) {
      live.delete(entry);
      continue;
    }
    draw(entry, time);
  }
  if (live.size > 0) requestAnimationFrame(frame);
  else running = false;
}

function draw({ canvas, kind, radius, size, fill, scale }, time) {
  const ratio = window.devicePixelRatio || 1;
  const ctx = canvas.getContext("2d");
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
  ctx.clearRect(0, 0, size, size);
  const factor = (size * 0.36 / radius) * scale;
  ctx.translate(size / 2, size / 2);
  ctx.scale(factor, factor);
  paintBuilding(ctx, kind, 0, 0, radius, time, fill);
}

export function buildingIcon(kind, radius, size = 64, { fill, scale = 1 } = {}) {
  const ratio = window.devicePixelRatio || 1;
  const canvas = document.createElement("canvas");
  canvas.width = size * ratio;
  canvas.height = size * ratio;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  canvas.className = "icon-canvas";
  canvas.setAttribute("aria-hidden", "true");
  if (!hasPainter(kind)) return canvas;
  const entry = { canvas, kind, radius, size, fill: fill ?? defaultFill(kind), scale };
  draw(entry, 0);
  live.add(entry);
  if (!running) {
    running = true;
    requestAnimationFrame(frame);
  }
  return canvas;
}

function defaultFill(kind) {
  return kind === "fire" || kind === "lamp" ? 1 : 0.65;
}
