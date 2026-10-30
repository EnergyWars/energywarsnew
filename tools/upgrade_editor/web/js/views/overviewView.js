import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number, compact } from "../format.js";
import { maxLevel, effectAt, totalCost, benefitTotal } from "../formulas.js";
import { trackName, buildingName, iconFor } from "./buildingView.js";
import { DIRECT, areas, groupRows, itemCount } from "../groups.js";
import { groupsPanel, areaFilter, selectedArea } from "./groupsPanel.js";
import { openTrack } from "./navigation.js";

const COLUMNS = ["building", "track", "max", "total", "effect", "benefit"];

export function overviewRows(doc, names) {
  const rows = [];
  for (const entry of doc.buildings) {
    for (const track of entry.tracks) {
      const max = maxLevel(doc, entry, track);
      rows.push({
        id: entry.id,
        key: `${entry.id}:${track}`,
        trackId: track,
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

export function overviewBlocks(rows, area, sort) {
  if (!area) return [{ section: DIRECT, name: null, rows: sortRows(rows, sort.key, sort.direction) }];
  return groupRows(rows, area).map((block) => ({ ...block, rows: sortRows(block.rows, sort.key, sort.direction) }));
}

function rowNode(ctx, row) {
  const open = () => { openTrack(ctx.view, row.id, row.trackId); ctx.render(); };
  return h("tr", {},
    h("td", { class: "with-icon" }, iconFor(ctx.doc.buildings.find((entry) => entry.id === row.id), 28), h("button", { type: "button", class: "link", title: t("overview.open"), onclick: open }, row.building)),
    h("td", {}, row.track), h("td", {}, row.max), h("td", {}, compact(row.total)), h("td", {}, `×${number(row.effect, 2)}`), h("td", {}, number(row.benefit, 2)));
}

function blockNodes(ctx, block) {
  const heading = block.name === null ? null : h("tr", { class: "group-row" }, h("th", { colspan: COLUMNS.length, scope: "colgroup" }, block.name, h("small", {}, ` · ${t("groups.count", { count: block.rows.length })}`)));
  const empty = block.name !== null && !block.rows.length ? h("tr", {}, h("td", { colspan: COLUMNS.length, class: "empty" }, t("groups.emptyBlock"))) : null;
  return [heading, ...block.rows.map((row) => rowNode(ctx, row)), empty];
}

export function overviewView(ctx, sort, onSort) {
  const index = selectedArea(ctx);
  const area = index >= 0 ? areas(ctx.doc)[index] : null;
  const blocks = overviewBlocks(overviewRows(ctx.doc, ctx.names), area, sort);
  const head = COLUMNS.map((key) => h("th", {}, h("button", { class: "link", onclick: () => onSort(key) }, t(`table.${key}`), sort.key === key ? (sort.direction === "asc" ? " ▲" : " ▼") : "")));
  const table = h("div", { class: "card scroll" }, h("table", { class: "overview" },
    h("thead", {}, h("tr", {}, head)),
    h("tbody", {}, blocks.map((block) => blockNodes(ctx, block)))));
  return h("section", { class: "detail" },
    h("h2", {}, t("tab.overview")),
    h("div", { class: "split groups-split" },
      groupsPanel(ctx),
      h("div", { class: "groups-main" },
        areaFilter(ctx),
        area && !itemCount(area) ? h("p", { class: "note" }, t("groups.areaEmpty")) : null,
        table)));
}
