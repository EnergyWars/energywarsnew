import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";

function flatten(value, prefix, out) {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    for (const key of Object.keys(value)) flatten(value[key], prefix ? `${prefix}.${key}` : key, out);
  } else {
    out[prefix] = Array.isArray(value) ? (value.every((item) => typeof item !== "object") ? value.join(", ") : JSON.stringify(value)) : value;
  }
}

function index(doc) {
  const flat = {};
  flatten(doc.system, "system", flat);
  flatten(doc.tracks, "tracks", flat);
  for (const entry of doc.buildings) {
    for (const [key, value] of Object.entries(entry)) if (key !== "id") flatten(value, `buildings.${entry.id}.${key}`, flat);
  }
  (doc.levels ?? []).forEach((level) => flatten(level, `levels.${level.id}`, flat));
  if (doc.levels) flat["levels.order"] = doc.levels.map((level) => level.id).join(", ");
  if (doc.routes !== undefined) flat.routes = Array.isArray(doc.routes) ? doc.routes.map((route) => route.join("-")).join(", ") : "auto";
  indexGroups(doc.groups, flat);
  return flat;
}

export function indexGroups(groups, flat) {
  if (!Array.isArray(groups)) return flat;
  const list = groups.filter((area) => area && typeof area === "object");
  if (!list.length) return flat;
  flat["groups.order"] = list.map((area) => area.name).join(", ");
  for (const area of list) {
    const base = `groups.${area.name}`;
    const sections = (Array.isArray(area.sections) ? area.sections : []).filter((section) => section && typeof section === "object");
    flat[`${base}.items`] = (area.items ?? []).join(", ");
    flat[`${base}.sections`] = sections.map((section) => section.name).join(", ");
    for (const section of sections) flat[`${base}.section.${section.name}`] = (section.items ?? []).join(", ");
  }
  return flat;
}

export function computeChanges(original, edited) {
  const before = index(original);
  const after = index(edited);
  return [...new Set([...Object.keys(before), ...Object.keys(after)])].sort()
    .filter((path) => before[path] !== after[path])
    .map((path) => ({ path, before: before[path], after: after[path] }));
}

export function changesView(ctx) {
  const changes = computeChanges(ctx.original, ctx.doc);
  return h("section", { class: "detail" },
    h("h2", {}, t("tab.changes")),
    changes.length === 0
      ? h("p", { class: "empty" }, t("changes.none"))
      : h("div", { class: "card scroll" }, h("table", { class: "overview" },
        h("thead", {}, h("tr", {}, h("th", {}, t("table.path")), h("th", {}, t("table.before")), h("th", {}, t("table.after")))),
        h("tbody", {}, changes.map((change) => h("tr", {}, h("td", {}, change.path), h("td", { class: "clip" }, number(change.before)), h("td", { class: "clip" }, number(change.after))))))));
}
