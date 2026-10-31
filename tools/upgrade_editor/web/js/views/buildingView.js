import { h } from "../dom.js";
import { t, gameName } from "../i18n.js";
import { number, compact, LENGTH_STATS, cellSize, toCells, fromCells } from "../format.js";
import { effectAt, maxLevel, costs, levelCost, baseValue, gainBase, snapshotLevels, deriveRowsFromBase, startValue } from "../formulas.js";
import { planEditor } from "./planEditor.js";
import { numberField, chart, flipSeries, sectionHeading, isCollapsed, toggleKey, searchSelect } from "./components.js";
import { pruneItem } from "../groups.js";
import { trackGroups } from "./groupsPanel.js";
import { valueTable } from "./valueTable.js";
import { METRICS, CHART_METRICS } from "./metrics.js";
import { buildingIcon } from "./icon.js";
import { variablesCard } from "./variablesPanel.js";
import { layoutView } from "./layoutView.js";
import { moveTrackBy, layoutAddTrack, layoutRemoveTrack } from "../layout.js";

export function trackName(names, track, kind) {
  const specific = `TRACK_${track.toUpperCase()}_${kind.toUpperCase()}`;
  return gameName(names, specific, gameName(names, `TRACK_${track.toUpperCase()}`, track));
}

export function buildingName(names, kind) {
  return gameName(names, `BUILDING_${kind.toUpperCase()}`, kind);
}

export function shortName(names, kind) {
  return gameName(names, `BUILDING_${kind.toUpperCase()}_SHORT`, buildingName(names, kind));
}

export function infoText(names, kind) {
  return gameName(names, `BUILDING_${kind.toUpperCase()}_INFO`, "");
}

export function descriptionText(names, kind) {
  return gameName(names, `BUILDING_${kind.toUpperCase()}_DESC`, "");
}

export function iconFor(entry, size, options) {
  return buildingIcon(entry.id, entry.stats.radius ?? 24, size, options);
}

export function statGroups(stats) {
  const flat = [];
  const nested = [];
  for (const [key, value] of Object.entries(stats)) {
    if (value !== null && typeof value === "object") nested.push([key, Object.entries(value).map(([inner, v]) => [`${key}.${inner}`, v])]);
    else flat.push([key, value]);
  }
  return { flat, nested };
}

function statsCard(ctx, entry) {
  const base = `buildings.${entry.id}`;
  const { flat, nested } = statGroups(entry.stats);
  const originalStats = ctx.original.buildings.find((item) => item.id === entry.id).stats;
  const integerAt = (path) => path.split(".").reduce((node, key) => node?.[key], originalStats);
  const cell = cellSize(ctx.doc);
  const field = (path, value) => {
    const inCells = LENGTH_STATS.has(path);
    return numberField(t(`stat.${path}`), inCells ? toCells(value, cell) : value,
      (v) => ctx.store.set(`${base}.stats.${path}`, inCells ? fromCells(v, cell) : v),
      { min: 0, integer: !inCells && Number.isInteger(integerAt(path)), desc: t(`desc.stat.${path}`) });
  };
  const statsKey = `stats:${entry.id}`;
  if (isCollapsed(ctx, statsKey)) return h("section", { class: "panel-card" }, sectionHeading(ctx, statsKey, t("section.stats")));
  return h("section", { class: "panel-card" },
    sectionHeading(ctx, statsKey, t("section.stats")),
    h("div", { class: "grid" },
      numberField(t("field.cost"), entry.cost, (v) => ctx.store.set(`${base}.cost`, v), { integer: true, min: 0, desc: t("desc.cost") }),
      numberField(t("field.upgradeBase"), entry.upgrade_base, (v) => ctx.store.set(`${base}.upgrade_base`, v), { integer: true, min: 1, hint: t("hint.upgradeBase"), desc: t("desc.upgradeBase") }),
      numberField(t("field.hp"), entry.hp, (v) => ctx.store.set(`${base}.hp`, v), { min: 1, desc: t("desc.hp") }),
      numberField(t("field.armor"), entry.armor ?? 0, (v) => ctx.store.set(`${base}.armor`, v), { min: 0, desc: t("desc.armor") }),
      flat.map(([key, value]) => field(key, value))),
    nested.map(([group, fields]) => h("div", { class: "subgroup" },
      h("h4", {}, t(`section.${group}`)),
      h("div", { class: "grid" }, fields.map(([path, value]) => field(path, value))))));
}

function removeTrack(doc, id, track) {
  const entry = doc.buildings.find((item) => item.id === id);
  entry.tracks = entry.tracks.filter((item) => item !== track);
  layoutRemoveTrack(entry, track);
  if (entry.curves) delete entry.curves[track];
  if (entry.plans) {
    delete entry.plans[track];
    if (Object.keys(entry.plans).length === 0) delete entry.plans;
  }
  pruneItem(doc, `${id}:${track}`);
}

export function toggleSeries(ctx, key, soloKeys = null) {
  flipSeries(ctx.view.hidden, key, soloKeys);
  ctx.render();
}

export function detailPairs(row, hidden = new Set()) {
  return METRICS.filter((metric) => !hidden.has(metric.key)).map((metric) => [t(`values.col.${metric.key}`), row[metric.key] === null || row[metric.key] === undefined ? "–" : metric.format(row[metric.key])]);
}

export function chartSeries(rows) {
  return CHART_METRICS.map((metric) => ({
    key: metric.key,
    label: t(`values.col.${metric.key}`),
    desc: t(`values.desc.${metric.key}`),
    color: metric.color,
    values: rows.map((row) => row[metric.key] ?? NaN),
    format: metric.format,
  }));
}

function trackDetail(ctx, entry, track, index, count) {
  const { doc, store } = ctx;
  const max = maxLevel(doc, entry, track);
  const start = startValue(doc, entry, track);
  const rows = deriveRowsFromBase(entry, snapshotLevels(doc, entry, track), start, baseValue(doc, entry, track));
  const totals = rows[rows.length - 1];
  const hasBase = gainBase(doc, entry, track) !== null;
  return h("div", { class: "track-detail" },
    chart(chartSeries(rows), { hidden: ctx.view.hidden, onToggle: (key, solo) => toggleSeries(ctx, key, solo), detail: (index) => detailPairs(rows[index], ctx.view.hidden) }),
    h("dl", { class: "stats" },
      h("div", { "data-tip": t("stat.totalCostDesc") }, h("dt", {}, t("stat.totalCost")), h("dd", {}, compact(totals.spent))),
      h("div", { "data-tip": t("stat.totalValueDesc") }, h("dt", {}, t("stat.totalValue")), h("dd", {}, hasBase ? number(totals.totalValue, 2) : `×${number(totals.effect, 2)}`))),
    trackGroups(ctx, entry, track),
    planEditor(ctx, entry, track),
    valueTable(ctx, entry, track),
    h("div", { class: "actions" },
      h("button", { class: "icon", title: t("action.up"), disabled: index === 0, onclick: () => store.update((d) => { moveTrackBy(d, entry.id, track, -1); }) }, "↑"),
      h("button", { class: "icon", title: t("action.down"), disabled: index === count - 1, onclick: () => store.update((d) => { moveTrackBy(d, entry.id, track, 1); }) }, "↓"),
      h("button", { class: "icon danger", title: t("action.remove"), onclick: () => store.update((d) => removeTrack(d, entry.id, track)) }, "✕")));
}

function trackRow(ctx, entry, track, index, count) {
  const { doc, names, view } = ctx;
  const max = maxLevel(doc, entry, track);
  const key = `${entry.id}:${track}`;
  const open = view.open.has(key);
  const toggle = () => {
    toggleKey(view.open, key);
    ctx.render();
  };
  return h("div", { class: open ? "track-row open" : "track-row" },
    h("div", { class: "track-head" },
      h("div", { class: "track-text", onclick: toggle },
        h("div", { class: "body" }, trackName(names, track, entry.id)),
        h("div", { class: "caption" }, `${t("level.short")} 0/${max}  ×1 → ×${number(effectAt(entry, track, 1, doc), 2)}`)),
      h("button", { class: "icon", "aria-expanded": String(open), title: t(open ? "action.collapse" : "action.expand"), onclick: toggle }, open ? "▴" : "▾"),
      h("span", { class: "gold-button" }, `▲ ${levelCost(doc, entry, track, 0)}`)),
    open ? trackDetail(ctx, entry, track, index, count) : null);
}

export function buildingPanel(ctx, entry) {
  const { doc, names, store } = ctx;
  const available = Object.keys(doc.tracks).filter((track) => !entry.tracks.includes(track));
  const select = searchSelect({
    options: available.map((track) => ({ value: track, label: trackName(names, track, entry.id), hint: track })),
    value: null,
    label: t("action.addTrack"),
    prompt: t("action.addTrack"),
    disabled: available.length === 0,
    onChange: (track) => store.update((d) => {
      const target = d.buildings.find((item) => item.id === entry.id);
      target.tracks.push(track);
      layoutAddTrack(target, track);
    }),
  });
  return h("section", { class: "building-panel" },
    h("header", { class: "panel-head" },
      iconFor(entry, 88, { scale: 1 }),
      h("div", {}, h("h2", {}, buildingName(names, entry.id)), h("p", { class: "caption" }, infoText(names, entry.id)),
        descriptionText(names, entry.id) ? h("p", { class: "caption building-desc" }, descriptionText(names, entry.id)) : null)),
    statsCard(ctx, entry),
    variablesCard(ctx, entry),
    h("section", { class: "panel-card" },
      sectionHeading(ctx, `upgrades:${entry.id}`, t("section.upgrades")),
      isCollapsed(ctx, `upgrades:${entry.id}`) ? null : [
        layoutView(ctx, entry, (track, index, count) => trackRow(ctx, entry, track, index, count)),
        h("div", { class: "add" }, select)]));
}
