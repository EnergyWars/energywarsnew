import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { METRICS } from "./metrics.js";
import { sectionHeading, isCollapsed, toggleKey } from "./components.js";
import { snapshotLevels, deriveRowsFromBase, editLevel, writeLevels, gainBase, startValue, referenceCost, MAX_LEVELS } from "../formulas.js";

export const COLUMNS = [{ key: "level" }, ...METRICS];

export const PINNED_COLUMNS = ["level", "cost", "value"];

export const OPTIONAL_COLUMNS = METRICS.map((metric) => metric.key).filter((key) => !PINNED_COLUMNS.includes(key));

export function visibleColumns(hidden) {
  return COLUMNS.filter((column) => PINNED_COLUMNS.includes(column.key) || !hidden.has(column.key));
}

export function draftKey(entry, track) {
  return `${entry.id}:${track}:rows`;
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

function columnToggles(ctx) {
  return h("div", { class: "actions" },
    h("span", { class: "note" }, t("values.columns")),
    OPTIONAL_COLUMNS.map((key) => {
      const input = h("input", { type: "checkbox", checked: !ctx.view.hidden.has(key), "aria-label": t(`values.col.${key}`) });
      input.addEventListener("change", () => {
        toggleKey(ctx.view.hidden, key);
        ctx.render();
      });
      return h("label", { class: "field inline", "data-tip": t(`values.desc.${key}`) }, input, h("span", {}, t(`values.col.${key}`)));
    }));
}

function readonlyCell(column, row, tip) {
  const value = row[column.key];
  if (value === null || value === undefined) return h("td", { "data-tip": tip });
  return h("td", { class: "base", "data-tip": tip }, column.key === "level" ? String(value) : column.format(value));
}

function cell(ctx, entry, track, column, row, index, start) {
  const tip = t(`values.desc.${column.key}`);
  if (row.level === 0) return readonlyCell(column, row, tip);
  if (column.key === "level") return h("td", { "data-tip": tip }, row.level);
  const shown = row[column.key];
  if (shown === null || shown === undefined) return h("td", { "data-tip": tip }, "–");
  const digits = column.digits === 0 ? 0 : 6;
  const input = h("input", { type: "number", step: "any", value: number(shown, digits), "aria-label": `${t(`values.col.${column.key}`)} ${row.level}` });
  input.addEventListener("change", () => {
    const parsed = Number(input.value);
    if (!Number.isFinite(parsed)) return;
    changeDraft(ctx, entry, track, (levels) => editLevel(entry, levels, index, column.key, parsed, start));
  });
  return h("td", { "data-tip": tip }, input);
}

export function valueTable(ctx, entry, track) {
  const current = snapshotLevels(ctx.doc, entry, track);
  const draft = pendingLevels(ctx, entry, track);
  const levels = draft ?? current;
  const start = startValue(ctx.doc, entry, track);
  const rows = deriveRowsFromBase(entry, levels, start);
  const base = gainBase(ctx.doc, entry, track);
  const reference = referenceCost(entry);
  const changed = (index) => index > 0 && (!current[index - 1] || current[index - 1].cost !== levels[index - 1].cost || current[index - 1].gain !== levels[index - 1].gain);
  const columns = visibleColumns(ctx.view.hidden);
  const head = columns.map((column) => h("th", { "data-tip": t(`values.desc.${column.key}`), tabindex: "0" }, t(`values.col.${column.key}`)));
  const body = rows.map((row, index) => h("tr", { class: changed(index) ? "changed" : "" }, columns.map((column) => cell(ctx, entry, track, column, row, index - 1, start))));
  const key = `values:${entry.id}:${track}`;
  if (isCollapsed(ctx, key)) return h("section", { class: "value-table" }, sectionHeading(ctx, key, t("values.title"), "h4", "value-heading"));
  return h("section", { class: "value-table" },
    sectionHeading(ctx, key, t("values.title"), "h4", "value-heading"),
    h("p", { class: "note" }, t("values.hint")),
    h("div", { class: "actions" },
      h("span", { class: "note" }, t("values.referenceCost", { value: number(reference, 2) })),
      base !== null ? h("span", { class: "note" }, t("values.base", { value: number(base, 2) })) : h("span", { class: "note" }, t("values.noBase"))),
    columnToggles(ctx),
    h("div", { class: "table-edit" }, h("table", { class: "levels" }, h("thead", {}, h("tr", {}, head)), h("tbody", {}, body))),
    h("div", { class: "actions" },
      h("button", { class: "primary", disabled: !draft, onclick: () => { applyLevels(ctx, entry, track); } }, t("values.apply")),
      h("button", { disabled: !draft, onclick: () => discardLevels(ctx, entry, track) }, t("values.discard")),
      h("button", { disabled: levels.length >= MAX_LEVELS, onclick: () => changeDraft(ctx, entry, track, (list) => [...list, { ...list[list.length - 1] }]) }, t("values.add")),
      h("button", { disabled: levels.length <= 1, onclick: () => changeDraft(ctx, entry, track, (list) => list.slice(0, -1)) }, t("values.remove")),
      h("span", { class: "note" }, t(draft ? "values.pending" : "values.applied"))));
}
