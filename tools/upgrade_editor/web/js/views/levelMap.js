import { h } from "../dom.js";
import { t } from "../i18n.js";
import { autoPositions, effectiveRoutes, worldTop, toWorld } from "../worldLayout.js";
import { routeKey, addRoute, removeRoute, setAutomaticRoutes } from "../levels.js";
import { sectionHeading, isCollapsed } from "./components.js";
import { selectInput, addButton, removeButton } from "./levelFields.js";

const SVG = "http://www.w3.org/2000/svg";
const MAP = { width: 480, height: 520, radius: 18, pad: 30 };

function node(tag, attributes = {}, ...children) {
  const element = document.createElementNS(SVG, tag);
  for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value);
  children.forEach((child) => element.append(child));
  return element;
}

export function mapGeometry(positions) {
  const top = worldTop(positions);
  const span = 1 - top;
  const height = Math.round(MAP.height * span);
  const px = (x) => MAP.pad + x * (MAP.width - 2 * MAP.pad);
  const py = (y) => MAP.pad + ((y - top) / span) * (height - 2 * MAP.pad);
  return { top, height, px, py, width: MAP.width };
}

export function pointerToWorld(geometry, viewX, viewY) {
  const fx = (viewX - MAP.pad) / (MAP.width - 2 * MAP.pad);
  const fy = (viewY - MAP.pad) / (geometry.height - 2 * MAP.pad);
  return toWorld([fx, fy], geometry.top);
}

function routeEditor(ctx, levels, routes) {
  const ui = ctx.view.levelUi;
  const choices = levels.map((level, index) => ({ value: String(index), label: `${index + 1}. ${level.id}` }));
  const from = Math.min(ui.routeFrom ?? 0, levels.length - 1);
  const to = Math.min(ui.routeTo ?? Math.min(1, levels.length - 1), levels.length - 1);
  const automatic = !Array.isArray(ctx.doc.routes);
  return h("div", { class: "route-editor" },
    h("p", { class: "note" }, t(automatic ? "levels.routesAuto" : "levels.routesCustom")),
    h("ul", { class: "route-list" }, routes.map((route) => h("li", {},
      `${route[0] + 1}. ${levels[route[0]].id} ↔ ${route[1] + 1}. ${levels[route[1]].id}`,
      removeButton(() => ctx.store.update((doc) => removeRoute(doc, route[0], route[1], routes)), t("levels.removeRoute"))))),
    h("div", { class: "row-edit" },
      selectInput(t("levels.f.routeFrom"), String(from), choices, (value) => { ui.routeFrom = Number(value); ctx.render(); }, t("levels.d.routeFrom")),
      selectInput(t("levels.f.routeTo"), String(to), choices, (value) => { ui.routeTo = Number(value); ctx.render(); }, t("levels.d.routeTo")),
      addButton(t("levels.addRoute"), () => ctx.store.update((doc) => { addRoute(doc, from, to, routes); }))),
    h("button", { type: "button", disabled: automatic, onclick: () => ctx.store.update((doc) => setAutomaticRoutes(doc)) }, t("levels.routesReset")));
}

export function levelMap(ctx, selected, onSelect) {
  const levels = ctx.doc.levels;
  const positions = autoPositions(levels);
  const routes = effectiveRoutes(ctx.doc.routes, levels.length);
  const geometry = mapGeometry(positions);
  const svg = node("svg", { viewBox: `0 0 ${geometry.width} ${geometry.height}`, class: "world-map", role: "img", "aria-label": t("levels.mapLabel") });
  const lines = new Map();
  const circles = new Map();
  const labels = new Map();
  const place = (index, x, y) => {
    circles.get(index).setAttribute("cx", x);
    circles.get(index).setAttribute("cy", y);
    labels.get(index).setAttribute("x", x);
    labels.get(index).setAttribute("y", y + 5);
    for (const [key, entry] of lines) {
      if (entry.route[0] === index) {
        entry.line.setAttribute("x1", x);
        entry.line.setAttribute("y1", y);
      }
      if (entry.route[1] === index) {
        entry.line.setAttribute("x2", x);
        entry.line.setAttribute("y2", y);
      }
    }
  };
  for (const route of routes) {
    const [a, b] = [positions[route[0]], positions[route[1]]];
    const line = node("line", { class: "route", x1: geometry.px(a[0]), y1: geometry.py(a[1]), x2: geometry.px(b[0]), y2: geometry.py(b[1]) });
    lines.set(routeKey(route), { line, route });
    svg.append(line);
  }
  levels.forEach((level, index) => {
    const x = geometry.px(positions[index][0]);
    const y = geometry.py(positions[index][1]);
    const circle = node("circle", { class: index === selected ? "stop selected" : level.world ? "stop" : "stop auto", cx: x, cy: y, r: MAP.radius, tabindex: 0, role: "button", "aria-label": `${index + 1}. ${level.id}` });
    const label = node("text", { class: "stop-label", x, y: y + 5, "text-anchor": "middle" });
    label.textContent = String(index + 1);
    const caption = node("title");
    caption.textContent = `${index + 1}. ${level.id}`;
    circle.append(caption);
    circles.set(index, circle);
    labels.set(index, label);
    circle.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        onSelect(index);
      }
    });
    circle.addEventListener("pointerdown", (event) => {
      event.preventDefault();
      onSelect(index, false);
      const matrix = svg.getScreenCTM();
      if (!matrix) return;
      let target = null;
      const toView = (move) => {
        const cursor = svg.createSVGPoint();
        cursor.x = move.clientX;
        cursor.y = move.clientY;
        return cursor.matrixTransform(matrix.inverse());
      };
      const move = (moveEvent) => {
        const point = toView(moveEvent);
        target = pointerToWorld(geometry, point.x, point.y);
        place(index, geometry.px(target[0]), geometry.py(target[1]));
      };
      const finish = () => {
        window.removeEventListener("pointermove", move);
        window.removeEventListener("pointerup", finish);
        if (target) ctx.store.update((doc) => { doc.levels[index].world = target; });
        else ctx.render();
      };
      window.addEventListener("pointermove", move);
      window.addEventListener("pointerup", finish);
    });
    svg.append(circle, label);
  });
  const closed = isCollapsed(ctx, "levels.map");
  return h("section", { class: "card level-map" },
    sectionHeading(ctx, "levels.map", t("levels.mapTitle")),
    closed ? null : [
      h("p", { class: "note" }, t("levels.d.map")),
      h("div", { class: "map-layout" }, svg, routeEditor(ctx, levels, routes))]);
}
