import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";

export function numberField(label, value, onChange, { step = "any", min, integer = false, hint, desc } = {}) {
  const input = h("input", { type: "number", value: number(value, 4), step: integer ? 1 : step, min });
  input.addEventListener("change", () => {
    const parsed = Number(input.value);
    if (Number.isFinite(parsed)) onChange(integer ? Math.round(parsed) : parsed);
  });
  return h("label", { class: "field", title: hint }, h("span", {}, label), input, desc ? h("small", { class: "field-desc" }, desc) : null);
}

const CHART = { width: 480, height: 150, left: 8, right: 8, top: 10, bottom: 18 };
const SVG = "http://www.w3.org/2000/svg";

function svgNode(tag, attributes = {}, ...children) {
  const node = document.createElementNS(SVG, tag);
  for (const [key, value] of Object.entries(attributes)) node.setAttribute(key, value);
  children.forEach((child) => node.append(child));
  return node;
}

export function chartScale(values) {
  const low = Math.min(0, ...values);
  const high = Math.max(...values, low + 1e-9);
  return { low, high, at: (value) => (value - low) / (high - low) };
}

export function chart(series, { hidden = new Set(), onToggle = () => {}, detail = () => [] } = {}) {
  const shown = series.filter((item) => item.values.some((value) => Number.isFinite(value)));
  const visible = shown.filter((item) => !hidden.has(item.key));
  const count = Math.max(...shown.map((item) => item.values.length), 1);
  const plotWidth = CHART.width - CHART.left - CHART.right;
  const plotHeight = CHART.height - CHART.top - CHART.bottom;
  const x = (index) => CHART.left + (count === 1 ? plotWidth / 2 : (index / (count - 1)) * plotWidth);
  const svg = svgNode("svg", { viewBox: `0 0 ${CHART.width} ${CHART.height}`, class: "chart", role: "img", "aria-label": t("chart.label") });
  svg.append(svgNode("line", { class: "axis", x1: CHART.left, x2: CHART.width - CHART.right, y1: CHART.height - CHART.bottom, y2: CHART.height - CHART.bottom }));
  [1, count].forEach((level, index) => {
    const text = svgNode("text", { class: "tick", x: x(level - 1), y: CHART.height - 4, "text-anchor": index === 0 ? "start" : "end" });
    text.textContent = String(level);
    svg.append(text);
  });
  const guide = svgNode("line", { class: "guide", y1: CHART.top, y2: CHART.height - CHART.bottom, x1: 0, x2: 0 });
  guide.style.display = "none";
  svg.append(guide);
  const points = [];
  for (const item of visible) {
    const scale = chartScale(item.values.filter(Number.isFinite));
    const y = (value) => CHART.top + (1 - scale.at(value)) * plotHeight;
    const line = item.values.map((value, index) => (Number.isFinite(value) ? `${x(index)},${y(value)}` : null)).filter(Boolean);
    svg.append(svgNode("polyline", { points: line.join(" "), class: "series", style: `stroke:${item.color}`, "vector-effect": "non-scaling-stroke" }));
    item.values.forEach((value, index) => {
      if (!Number.isFinite(value)) return;
      const point = svgNode("circle", { class: "point", cx: x(index), cy: y(value), r: 3.5, style: `fill:${item.color}` });
      point.dataset.index = String(index);
      points.push(point);
      svg.append(point);
    });
  }
  const tip = h("div", { class: "chart-tip", role: "status" });
  tip.hidden = true;
  const hide = () => {
    tip.hidden = true;
    guide.style.display = "none";
    points.forEach((point) => point.classList.remove("active"));
  };
  svg.addEventListener("pointermove", (event) => {
    const rect = svg.getBoundingClientRect();
    if (rect.width <= 0) return;
    const fraction = Math.min(Math.max((event.clientX - rect.left) / rect.width, 0), 1);
    const raw = count === 1 ? 0 : Math.round(((fraction * CHART.width - CHART.left) / plotWidth) * (count - 1));
    const index = Math.min(Math.max(raw, 0), count - 1);
    guide.setAttribute("x1", x(index));
    guide.setAttribute("x2", x(index));
    guide.style.display = "";
    points.forEach((point) => point.classList.toggle("active", Number(point.dataset.index) === index));
    tip.replaceChildren(
      h("strong", {}, `${t("level.short")} ${index + 1}`),
      h("dl", {}, detail(index).map(([label, value]) => h("div", {}, h("dt", {}, label), h("dd", {}, value)))));
    tip.style.left = `${(x(index) / CHART.width) * rect.width}px`;
    tip.classList.toggle("flip", fraction > 0.55);
    tip.hidden = false;
  });
  svg.addEventListener("pointerleave", hide);
  const legend = h("ul", { class: "legend" }, shown.map((item) => {
    const off = hidden.has(item.key);
    const peak = item.format(Math.max(...item.values.filter(Number.isFinite)));
    return h("li", {}, h("button", { type: "button", class: off ? "legend-item off" : "legend-item", "aria-pressed": String(!off), title: t(off ? "chart.show" : "chart.hide", { name: item.label }), onclick: () => onToggle(item.key) },
      h("span", { class: "swatch", style: `background:${item.color}` }), `${item.label} · ${t("chart.peak")} ${peak}`));
  }));
  return h("figure", { class: "chart-box" }, svg, tip, legend, h("figcaption", { class: "note" }, t("chart.scaleNote")));
}

export function percent(value) {
  return value === null || value === undefined ? "–" : `${number(value, 0)} %`;
}

export function toggleKey(set, key) {
  if (set.has(key)) set.delete(key);
  else set.add(key);
  return set.has(key);
}

export function isCollapsed(ctx, key) {
  return ctx.view.collapsed.has(key);
}

export function sectionHeading(ctx, key, title, tag = "h3", className = "section-title") {
  const closed = isCollapsed(ctx, key);
  return h(tag, { class: className },
    h("button", { type: "button", class: "section-toggle", "aria-expanded": String(!closed), title: t(closed ? "action.expand" : "action.collapse"), onclick: () => { toggleKey(ctx.view.collapsed, key); ctx.render(); } },
      h("span", { class: "chevron", "aria-hidden": "true" }, closed ? "▸" : "▾"), title));
}
