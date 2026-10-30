import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { chart, flipSeries, sectionHeading, isCollapsed } from "./components.js";
import { MONSTER_METRICS, visibleMonsterColumns, metricFormat, rowName, cellTip } from "./monsterMetrics.js";
import { monsterRows, editMonster, columnView } from "../monsters.js";
import { monsterUi, levelCount } from "./monsterState.js";

const clone = (value) => JSON.parse(JSON.stringify(value));

export function pendingEnemy(ctx, kind) {
  const ui = monsterUi(ctx.view);
  const draft = ui.drafts[kind];
  if (!draft) return null;
  if (draft.base !== JSON.stringify(ctx.doc.enemies[kind])) {
    delete ui.drafts[kind];
    return null;
  }
  return draft.enemy;
}

export function setDraftEnemy(ctx, kind, enemy) {
  monsterUi(ctx.view).drafts[kind] = { base: JSON.stringify(ctx.doc.enemies[kind]), enemy: clone(enemy) };
}

export function editDraft(ctx, kind, row, key, value) {
  const ui = monsterUi(ctx.view);
  const shown = pendingEnemy(ctx, kind) ?? ctx.doc.enemies[kind];
  const next = editMonster(shown, ctx.doc.armor, row, key, value);
  if (next) {
    setDraftEnemy(ctx, kind, next);
    ui.notice = "";
  } else {
    ui.notice = t("monsters.rejected");
  }
  ctx.render();
  return Boolean(next);
}

export function applyDraft(ctx, kind) {
  const draft = pendingEnemy(ctx, kind);
  if (!draft) return false;
  ctx.store.update((doc) => {
    doc.enemies[kind] = clone(draft);
  });
  delete monsterUi(ctx.view).drafts[kind];
  return true;
}

export function discardDraft(ctx, kind) {
  delete monsterUi(ctx.view).drafts[kind];
  ctx.render();
}

export function displayValue(row, key, view) {
  const value = row[key];
  return view ? view.show(value) : value;
}

export function strengthViews(enemy, config, mode) {
  return Object.fromEntries(MONSTER_METRICS.map((metric) => [metric.key, columnView(metric.key, enemy, config, mode)]));
}

export function strengthSeries(rows, views, mode) {
  return MONSTER_METRICS.map((metric) => ({
    key: metric.key,
    color: metric.color,
    label: t(`monsters.col.${metric.key}`),
    desc: t(`monsters.desc.${metric.key}`),
    format: metricFormat(metric, mode),
    values: rows.map((row) => displayValue(row, metric.key, views[metric.key])),
  }));
}

export function strengthDetail(rows, views, mode, index) {
  return MONSTER_METRICS.map((metric) => [t(`monsters.col.${metric.key}`), metricFormat(metric, mode)(displayValue(rows[index], metric.key, views[metric.key]))]);
}

function tick(rows, index) {
  const row = rows[index];
  return `${row.level + 1}${row.night ? "☾" : "☀"}`;
}

function cell(ctx, kind, column, row, views, mode, changed) {
  const tip = cellTip(column.key, row);
  if (column.key === "row") return h("td", { "data-tip": t("monsters.desc.row") }, rowName(row));
  const view = views[column.key];
  if (view.blocked) return h("td", { "data-tip": `${tip} ${t("monsters.noBase")}`, class: "base" }, "–");
  const shown = displayValue(row, column.key, view);
  const digits = column.digits === 0 ? 0 : 6;
  const input = h("input", { type: "number", step: "any", value: number(shown, digits), "aria-label": `${t(`monsters.col.${column.key}`)} ${rowName(row)}` });
  input.addEventListener("change", () => {
    const parsed = Number(input.value);
    if (!Number.isFinite(parsed)) {
      ctx.render();
      return;
    }
    editDraft(ctx, kind, row, column.key, view.parse(parsed));
  });
  return h("td", { "data-tip": tip, class: changed ? "changed-cell" : "" }, input);
}

export function strengthTable(ctx, kind, rows, saved, views, mode) {
  const columns = visibleMonsterColumns(monsterUi(ctx.view).hidden);
  const head = columns.map((column) => h("th", { tabindex: "0", "data-tip": t(`monsters.desc.${column.key}`) }, t(`monsters.col.${column.key}`)));
  const body = rows.map((row, index) => {
    const changedRow = JSON.stringify(row) !== JSON.stringify(saved[index]);
    return h("tr", { class: changedRow ? "changed" : "" }, columns.map((column) => cell(ctx, kind, column, row, views, mode, changedRow)));
  });
  return h("div", { class: "table-edit scroll" }, h("table", { class: "levels monster-table" }, h("thead", {}, h("tr", {}, head)), h("tbody", {}, body)));
}

export function strengthSection(ctx, kind) {
  const ui = monsterUi(ctx.view);
  const key = `monsters.strength:${kind}`;
  const heading = sectionHeading(ctx, key, t("monsters.strengthTitle"));
  if (isCollapsed(ctx, key)) return h("section", { class: "panel-card" }, heading);
  const draft = pendingEnemy(ctx, kind);
  const enemy = draft ?? ctx.doc.enemies[kind];
  const count = levelCount(ctx.doc);
  const rows = monsterRows(enemy, ctx.doc.armor, count);
  const saved = monsterRows(ctx.doc.enemies[kind], ctx.doc.armor, count);
  const views = strengthViews(enemy, ctx.doc.armor, ui.mode);
  const toggle = (metric, solo) => {
    flipSeries(ui.hidden, metric, solo);
    ctx.render();
  };
  const select = h("select", { "aria-label": t("monsters.mode") },
    h("option", { value: "absolute", selected: ui.mode === "absolute" }, t("monsters.modeAbsolute")),
    h("option", { value: "factor", selected: ui.mode === "factor" }, t("monsters.modeFactor")));
  select.addEventListener("change", () => {
    ui.mode = select.value;
    ctx.render();
  });
  return h("section", { class: "panel-card monster-strength" },
    heading,
    h("p", { class: "note" }, t("monsters.strengthHint", { levels: count })),
    h("p", { class: "note" }, t("monsters.strengthRules")),
    chart(strengthSeries(rows, views, ui.mode), {
      hidden: ui.hidden,
      onToggle: toggle,
      detail: (index) => strengthDetail(rows, views, ui.mode, index),
      title: (index) => rowName(rows[index]),
      tick: (index) => tick(rows, index),
    }),
    h("div", { class: "actions" },
      h("label", { class: "field inline", "data-tip": t("monsters.modeTip") }, h("span", {}, t("monsters.mode")), select),
      ui.notice ? h("span", { class: "field-error", role: "alert" }, ui.notice) : null),
    strengthTable(ctx, kind, rows, saved, views, ui.mode),
    h("div", { class: "actions" },
      h("button", { class: "primary", disabled: !draft, onclick: () => applyDraft(ctx, kind) }, t("values.apply")),
      h("button", { disabled: !draft, onclick: () => discardDraft(ctx, kind) }, t("values.discard")),
      h("span", { class: "note" }, t(draft ? "monsters.pending" : "monsters.applied"))));
}
