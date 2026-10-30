import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { sectionHeading, isCollapsed } from "./components.js";
import { snapshotLevels, deriveRows, editLevel, writeLevels, gainBase, roundTo, MAX_LEVELS } from "../formulas.js";

const COLUMNS = [
  { key: "level" },
  { key: "cost", edit: true, digits: 0 },
  { key: "spent", edit: true, digits: 0 },
  { key: "gain", edit: true, digits: 4 },
  { key: "effect", edit: true, digits: 4 },
  { key: "single", edit: true, digits: 2 },
  { key: "total", edit: true, digits: 2 },
  { key: "benefit", digits: 2 },
];

export function draftKey(entry, track) {
  return `${entry.id}:${track}:rows`;
}

export function gainModeKey(entry, track) {
  return `${entry.id}:${track}`;
}

export function pendingLevels(ctx, entry, track) {
  const key = draftKey(entry, track);
  const draft = ctx.view.drafts[key];
  if (!draft) return null;
  if (draft.base !== JSON.stringify(snapshotLevels(ctx.doc, entry, track))) {
    delete ctx.view.drafts[key];
    return null;
  }
  return draft.levels;
}

function changeDraft(ctx, entry, track, change) {
  const current = snapshotLevels(ctx.doc, entry, track);
  const levels = pendingLevels(ctx, entry, track) ?? current;
  ctx.view.drafts[draftKey(entry, track)] = { base: JSON.stringify(current), levels: change(levels) };
  ctx.render();
}

export function applyLevels(ctx, entry, track) {
  const levels = pendingLevels(ctx, entry, track);
  if (!levels) return;
  ctx.store.update((doc) => writeLevels(doc.buildings.find((item) => item.id === entry.id), track, levels.map((level) => ({ ...level }))));
  delete ctx.view.drafts[draftKey(entry, track)];
}

export function discardLevels(ctx, entry, track) {
  delete ctx.view.drafts[draftKey(entry, track)];
  ctx.render();
}

export function gainView(base, mode) {
  const absolute = mode === "absolute" && base !== null;
  return {
    absolute,
    show: (gain) => (absolute ? roundTo(gain * base, 4) : gain),
    parse: (value) => (absolute ? value / base : value),
  };
}

function gainSelect(ctx, entry, track, base, mode) {
  const select = h("select", { "aria-label": t("values.gainMode") },
    h("option", { value: "factor", selected: mode === "factor" }, t("values.gainFactor")),
    h("option", { value: "absolute", selected: mode === "absolute", disabled: base === null }, t("values.gainAbsolute")));
  select.addEventListener("change", () => {
    ctx.view.gainModes[gainModeKey(entry, track)] = select.value;
    ctx.render();
  });
  return h("label", { class: "field inline" }, h("span", {}, t("values.gainMode")), select);
}

function cell(ctx, entry, track, column, row, index, view) {
  if (!column.edit) return h("td", {}, column.key === "level" ? row.level : number(row[column.key], column.digits));
  const shown = column.key === "gain" ? view.show(row.gain) : row[column.key];
  if (shown === null) return h("td", {}, "–");
  const input = h("input", { type: "number", step: "any", value: number(shown, column.digits === 0 ? 0 : 6), "aria-label": `${t(`values.col.${column.key}`)} ${row.level}` });
  input.addEventListener("change", () => {
    const parsed = Number(input.value);
    if (!Number.isFinite(parsed)) return;
    changeDraft(ctx, entry, track, (levels) => editLevel(entry, levels, index, column.key, column.key === "gain" ? view.parse(parsed) : parsed));
  });
  return h("td", {}, input);
}

export function valueTable(ctx, entry, track) {
  const current = snapshotLevels(ctx.doc, entry, track);
  const draft = pendingLevels(ctx, entry, track);
  const levels = draft ?? current;
  const rows = deriveRows(entry, levels);
  const base = gainBase(ctx.doc, entry, track);
  const mode = base === null ? "factor" : ctx.view.gainModes[gainModeKey(entry, track)] ?? "factor";
  const view = gainView(base, mode);
  const changed = (index) => !current[index] || current[index].cost !== levels[index].cost || current[index].gain !== levels[index].gain;
  const head = COLUMNS.map((column) => h("th", { title: t(`values.desc.${column.key}`) }, column.key === "gain" && view.absolute ? t("values.col.gainAbsolute") : t(`values.col.${column.key}`)));
  const body = rows.map((row, index) => h("tr", { class: changed(index) ? "changed" : "" }, COLUMNS.map((column) => cell(ctx, entry, track, column, row, index, view))));
  const key = `values:${entry.id}:${track}`;
  if (isCollapsed(ctx, key)) return h("section", { class: "value-table" }, sectionHeading(ctx, key, t("values.title"), "h4", "value-heading"));
  return h("section", { class: "value-table" },
    sectionHeading(ctx, key, t("values.title"), "h4", "value-heading"),
    h("p", { class: "note" }, t("values.hint")),
    h("div", { class: "actions" },
      gainSelect(ctx, entry, track, base, mode),
      base !== null ? h("span", { class: "note" }, t("values.base", { value: number(base, 2) })) : h("span", { class: "note" }, t("values.noBase"))),
    h("div", { class: "table-edit" }, h("table", { class: "levels" }, h("thead", {}, h("tr", {}, head)), h("tbody", {}, body))),
    h("div", { class: "actions" },
      h("button", { class: "primary", disabled: !draft, onclick: () => { applyLevels(ctx, entry, track); } }, t("values.apply")),
      h("button", { disabled: !draft, onclick: () => discardLevels(ctx, entry, track) }, t("values.discard")),
      h("button", { disabled: levels.length >= MAX_LEVELS, onclick: () => changeDraft(ctx, entry, track, (list) => [...list, { ...list[list.length - 1] }]) }, t("values.add")),
      h("button", { disabled: levels.length <= 1, onclick: () => changeDraft(ctx, entry, track, (list) => list.slice(0, -1)) }, t("values.remove")),
      h("span", { class: "note" }, t(draft ? "values.pending" : "values.applied"))));
}
