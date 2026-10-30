import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number, compact } from "../format.js";
import { maxLevel, effectAt, totalCost, benefitTotal } from "../formulas.js";
import { trackName, buildingName, iconFor } from "./buildingView.js";

const COLUMNS = ["building", "track", "max", "total", "effect", "benefit"];

export function overviewRows(doc, names) {
  const rows = [];
  for (const entry of doc.buildings) {
    for (const track of entry.tracks) {
      const max = maxLevel(doc, entry, track);
      rows.push({
        id: entry.id,
        building: buildingName(names, entry.id),
        track: trackName(names, track, entry.id),
        max,
        total: totalCost(doc, entry, track),
        effect: effectAt(entry, track, max, doc),
        benefit: benefitTotal(doc, entry, track),
      });
    }
  }
  return rows;
}

export function sortRows(rows, key, direction) {
  const factor = direction === "asc" ? 1 : -1;
  return [...rows].sort((a, b) => (typeof a[key] === "string" ? a[key].localeCompare(b[key]) : a[key] - b[key]) * factor);
}

export function overviewView(ctx, sort, onSort) {
  const rows = sortRows(overviewRows(ctx.doc, ctx.names), sort.key, sort.direction);
  const head = COLUMNS.map((key) => h("th", {}, h("button", { class: "link", onclick: () => onSort(key) }, t(`table.${key}`), sort.key === key ? (sort.direction === "asc" ? " ▲" : " ▼") : "")));
  return h("section", { class: "detail" },
    h("h2", {}, t("tab.overview")),
    h("div", { class: "card scroll" }, h("table", { class: "overview" },
      h("thead", {}, h("tr", {}, head)),
      h("tbody", {}, rows.map((row) => h("tr", {}, h("td", { class: "with-icon" }, iconFor(ctx.doc.buildings.find((entry) => entry.id === row.id), 28), row.building), h("td", {}, row.track), h("td", {}, row.max), h("td", {}, compact(row.total)), h("td", {}, `×${number(row.effect, 2)}`), h("td", {}, number(row.benefit, 2))))))));
}
