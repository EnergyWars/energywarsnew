import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number, percent } from "../format.js";

export function numberField(label, value, onChange, { step = "any", min, integer = false, hint, desc } = {}) {
  const input = h("input", { type: "number", value: number(value, 4), step: integer ? 1 : step, min });
  input.addEventListener("change", () => {
    const parsed = Number(input.value);
    if (Number.isFinite(parsed)) onChange(integer ? Math.round(parsed) : parsed);
  });
  return h("label", { class: "field", title: hint }, h("span", {}, label), input, desc ? h("small", { class: "field-desc" }, desc) : null);
}

const CHART = { width: 640, height: 240, left: 12, right: 12, top: 14, bottom: 22 };
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

export function nearestLevel(viewX, count) {
  if (count <= 1) return 0;
  const plotWidth = CHART.width - CHART.left - CHART.right;
  const index = Math.round(((viewX - CHART.left) / plotWidth) * (count - 1));
  return Math.min(Math.max(index, 0), count - 1);
}

export function highlightState(focusKey, key) {
  if (!focusKey) return "";
  return focusKey === key ? "focus" : "dim";
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
  [0, count - 1].forEach((level, index) => {
    const text = svgNode("text", { class: "tick", x: x(level), y: CHART.height - 4, "text-anchor": index === 0 ? "start" : "end" });
    text.textContent = String(level);
    svg.append(text);
  });
  svg.append(svgNode("rect", { class: "hit", x: 0, y: 0, width: CHART.width, height: CHART.height, fill: "transparent" }));
  const guide = svgNode("line", { class: "guide", y1: CHART.top, y2: CHART.height - CHART.bottom, x1: 0, x2: 0 });
  guide.style.display = "none";
  svg.append(guide);
  const points = [];
  const marks = [];
  for (const item of visible) {
    const scale = chartScale(item.values.filter(Number.isFinite));
    const y = (value) => CHART.top + (1 - scale.at(value)) * plotHeight;
    const line = item.values.map((value, index) => (Number.isFinite(value) ? `${x(index)},${y(value)}` : null)).filter(Boolean);
    const polyline = svgNode("polyline", { points: line.join(" "), class: "series", style: `stroke:${item.color}`, "vector-effect": "non-scaling-stroke" });
    polyline.dataset.key = item.key;
    marks.push(polyline);
    svg.append(polyline);
    item.values.forEach((value, index) => {
      if (!Number.isFinite(value)) return;
      const point = svgNode("circle", { class: "point", cx: x(index), cy: y(value), r: 4, style: `fill:${item.color}` });
      point.dataset.index = String(index);
      point.dataset.key = item.key;
      marks.push(point);
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
  const show = (event) => {
    const matrix = svg.getScreenCTM();
    if (!matrix) return;
    const cursor = svg.createSVGPoint();
    cursor.x = event.clientX;
    cursor.y = event.clientY;
    const index = nearestLevel(cursor.matrixTransform(matrix.inverse()).x, count);
    const anchor = svg.createSVGPoint();
    anchor.x = x(index);
    anchor.y = CHART.top;
    const screen = anchor.matrixTransform(matrix);
    const box = svg.parentElement.getBoundingClientRect();
    guide.setAttribute("x1", x(index));
    guide.setAttribute("x2", x(index));
    guide.style.display = "";
    points.forEach((point) => point.classList.toggle("active", Number(point.dataset.index) === index));
    tip.replaceChildren(
      h("strong", {}, `${t("level.short")} ${index}`),
      h("dl", {}, detail(index).map(([label, value]) => h("div", {}, h("dt", {}, label), h("dd", {}, value)))));
    tip.style.left = `${screen.x - box.left}px`;
    tip.style.top = `${Math.max(screen.y - box.top, 0)}px`;
    tip.classList.toggle("flip", screen.x - box.left > box.width * 0.55);
    tip.hidden = false;
  };
  svg.addEventListener("pointermove", show);
  svg.addEventListener("pointerdown", show);
  svg.addEventListener("pointerleave", hide);
  const focus = (key) => {
    for (const mark of marks) {
      const state = highlightState(key, mark.dataset.key);
      mark.classList.toggle("focus", state === "focus");
      mark.classList.toggle("dim", state === "dim");
    }
  };
  const legend = h("ul", { class: "legend" }, shown.map((item) => {
    const off = hidden.has(item.key);
    const peak = item.format(Math.max(...item.values.filter(Number.isFinite)));
    return h("li", {}, h("button", { type: "button", class: off ? "legend-item off" : "legend-item", "aria-pressed": String(!off), "data-tip": `${item.desc} (${t(off ? "chart.show" : "chart.hide", { name: item.label })})`, onclick: () => onToggle(item.key), onpointerenter: () => focus(item.key), onpointerleave: () => focus(null), onfocus: () => focus(item.key), onblur: () => focus(null) },
      h("span", { class: "swatch", style: `background:${item.color}` }), `${item.label} · ${t("chart.peak")} ${peak}`));
  }));
  return h("figure", { class: "chart-box" }, svg, tip, legend, h("figcaption", { class: "note" }, t("chart.scaleNote")));
}

export { percent };

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
