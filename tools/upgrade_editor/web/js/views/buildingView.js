import { h } from "../dom.js";
import { t, gameName } from "../i18n.js";
import { number, compact, LENGTH_STATS, cellSize, toCells, fromCells } from "../format.js";
import { trackConfig, effectAt, maxLevel, mode, costs, levelCost, totalCost, benefitTotal, snapshotLevels, deriveRows } from "../formulas.js";
import { planEditor } from "./planEditor.js";
import { numberField, chart, percent, sectionHeading, isCollapsed, toggleKey } from "./components.js";
import { valueTable } from "./valueTable.js";
import { buildingIcon } from "./icon.js";

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
      flat.map(([key, value]) => field(key, value))),
    nested.map(([group, fields]) => h("div", { class: "subgroup" },
      h("h4", {}, t(`section.${group}`)),
      h("div", { class: "grid" }, fields.map(([path, value]) => field(path, value))))));
}

function swap(doc, id, from, to) {
  const list = doc.buildings.find((entry) => entry.id === id).tracks;
  [list[from], list[to]] = [list[to], list[from]];
}

function removeTrack(doc, id, track) {
  const entry = doc.buildings.find((item) => item.id === id);
  entry.tracks = entry.tracks.filter((item) => item !== track);
  if (entry.curves) delete entry.curves[track];
  if (entry.plans) {
    delete entry.plans[track];
    if (Object.keys(entry.plans).length === 0) delete entry.plans;
  }
}

export function toggleSeries(ctx, key) {
  if (ctx.view.hidden.has(key)) ctx.view.hidden.delete(key);
  else ctx.view.hidden.add(key);
  ctx.render();
}

export function detailPairs(row) {
  return [
    [t("table.cost"), number(row.cost, 0)],
    [t("table.spent"), number(row.spent, 0)],
    [t("values.col.gain"), `+${number(row.gain, 4)}`],
    [t("table.effect"), `×${number(row.effect, 3)}`],
    [t("table.benefit"), number(row.benefit, 2)],
    [t("table.factorLevel"), percent(row.single)],
    [t("table.factorTotal"), percent(row.total)],
  ];
}

export function chartSeries(rows) {
  const decimals = (digits) => (value) => number(value, digits);
  return [
    { key: "cost", label: t("table.cost"), color: "var(--series-cost)", values: rows.map((row) => row.cost), format: decimals(0) },
    { key: "spent", label: t("table.spent"), color: "var(--series-spent)", values: rows.map((row) => row.spent), format: decimals(0) },
    { key: "effect", label: t("table.effect"), color: "var(--series-effect)", values: rows.map((row) => row.effect), format: (value) => `×${number(value, 2)}` },
    { key: "factorLevel", label: t("table.factorLevel"), color: "var(--series-level)", values: rows.map((row) => row.single ?? NaN), format: percent },
    { key: "factorTotal", label: t("table.factorTotal"), color: "var(--series-total)", values: rows.map((row) => row.total ?? NaN), format: percent },
  ];
}

function trackDetail(ctx, entry, track, index) {
  const { doc, store } = ctx;
  const active = mode(entry, track);
  const max = maxLevel(doc, entry, track);
  const rows = deriveRows(entry, snapshotLevels(doc, entry, track));
  return h("div", { class: "track-detail" },
    chart(chartSeries(rows), { hidden: ctx.view.hidden, onToggle: (key) => toggleSeries(ctx, key), detail: (index) => detailPairs(rows[index]) }),
    h("dl", { class: "stats" },
      h("div", {}, h("dt", {}, t("stat.first")), h("dd", {}, levelCost(doc, entry, track, 0))),
      h("div", {}, h("dt", {}, t("stat.total")), h("dd", {}, compact(totalCost(doc, entry, track)))),
      h("div", {}, h("dt", {}, t("stat.max")), h("dd", {}, `×${number(effectAt(entry, track, max, doc), 2)}`)),
      h("div", {}, h("dt", {}, t("stat.benefit")), h("dd", {}, number(benefitTotal(doc, entry, track), 2)))),
    planEditor(ctx, entry, track),
    active === "params" ? paramFields(ctx, entry, track) : null,
    valueTable(ctx, entry, track),
    h("div", { class: "actions" },
      h("button", { class: "icon", title: t("action.up"), disabled: index === 0, onclick: () => store.update((d) => swap(d, entry.id, index, index - 1)) }, "↑"),
      h("button", { class: "icon", title: t("action.down"), disabled: index === entry.tracks.length - 1, onclick: () => store.update((d) => swap(d, entry.id, index, index + 1)) }, "↓"),
      h("button", { class: "icon danger", title: t("action.remove"), onclick: () => store.update((d) => removeTrack(d, entry.id, track)) }, "✕")));
}

function paramFields(ctx, entry, track) {
  const { doc, store } = ctx;
  const config = trackConfig(doc, entry, track);
  const own = Boolean(entry.curves?.[track]);
  const base = own ? `buildings.${entry.id}.curves.${track}` : `tracks.${track}`;
  const growthKey = own && config.gain !== undefined ? "gain_growth" : "growth";
  const shared = !own && ctx.usage(track).length > 1;
  return h("div", {},
    shared ? h("p", { class: "note" }, t("note.shared", { count: ctx.usage(track).length })) : null,
    h("div", { class: "grid" },
      numberField(t("field.max"), config.max, (v) => store.set(`${base}.max`, v), { integer: true, min: 1, desc: t("desc.max") }),
      config.gain !== undefined
        ? numberField(t("field.gain"), config.gain, (v) => store.set(`${base}.gain`, v), { min: 0, desc: t("desc.gain") })
        : numberField(t("field.step"), config.step, (v) => store.set(`${base}.step`, v), { min: 0, desc: t("desc.step") }),
      numberField(t("field.price"), config.price, (v) => store.set(`${base}.price`, v), { min: 0, desc: t("desc.price") }),
      numberField(t(config.gain !== undefined ? "field.gainGrowth" : "field.growth"), config[growthKey] ?? doc.system.track_growth, (v) => store.set(`${base}.${growthKey}`, v), { min: 1, desc: t(config.gain !== undefined ? "desc.gainGrowth" : "desc.growth") })));
}

function trackRow(ctx, entry, track, index) {
  const { doc, names, view } = ctx;
  const max = maxLevel(doc, entry, track);
  const key = `${entry.id}:${track}`;
  const open = view.open.has(key);
  const toggle = () => {
    toggleKey(view.open, key);
    ctx.render();
  };
  return h("div", { class: "track-row" },
    h("div", { class: "track-head" },
      h("div", { class: "track-text", onclick: toggle },
        h("div", { class: "body" }, trackName(names, track, entry.id)),
        h("div", { class: "caption" }, `${t("level.short")} 0/${max}  ×1 → ×${number(effectAt(entry, track, 1, doc), 2)}  ·  ${t(`plan.${mode(entry, track)}`)}`)),
      h("button", { class: "icon", "aria-expanded": String(open), title: t(open ? "action.collapse" : "action.expand"), onclick: toggle }, open ? "▴" : "▾"),
      h("span", { class: "gold-button" }, `▲ ${levelCost(doc, entry, track, 0)}`)),
    open ? trackDetail(ctx, entry, track, index) : null);
}

export function buildingPanel(ctx, entry) {
  const { doc, names, store } = ctx;
  const available = Object.keys(doc.tracks).filter((track) => !entry.tracks.includes(track));
  const select = h("select", {}, h("option", { value: "" }, t("action.addTrack")), available.map((track) => h("option", { value: track }, trackName(names, track, entry.id))));
  select.addEventListener("change", () => {
    if (select.value) store.update((d) => d.buildings.find((item) => item.id === entry.id).tracks.push(select.value));
  });
  return h("section", { class: "building-panel" },
    h("header", { class: "panel-head" },
      iconFor(entry, 88, { scale: 1 }),
      h("div", {}, h("h2", {}, buildingName(names, entry.id)), h("p", { class: "caption" }, infoText(names, entry.id)))),
    statsCard(ctx, entry),
    h("section", { class: "panel-card" },
      sectionHeading(ctx, `upgrades:${entry.id}`, t("section.upgrades")),
      isCollapsed(ctx, `upgrades:${entry.id}`) ? null : [
        entry.tracks.map((track, index) => trackRow(ctx, entry, track, index)),
        h("div", { class: "add" }, select)]));
}
