import { h } from "../dom.js";
import { t } from "../i18n.js";
import { addLevel, duplicateLevel, removeLevel, moveLevel, validateLevels, validateRoutes, errorsFor } from "../levels.js";
import { levelForm } from "./levelForm.js";
import { levelMap } from "./levelMap.js";
import { wavesSection, strengthPanel } from "./levelWaves.js";
import { errorNote } from "./levelFields.js";

export function levelUi(view) {
  view.levelUi ??= { index: 0, rounds: 10 };
  return view.levelUi;
}

export function levelErrors(doc) {
  return [...validateLevels(doc.levels, Object.keys(doc.enemies)), ...validateRoutes(doc.routes, doc.levels.length)];
}

function listEntry(ctx, ui, level, index, count) {
  const selected = index === ui.index;
  return h("li", { class: selected ? "level-item selected" : "level-item" },
    h("button", { type: "button", class: "level-pick", "aria-current": String(selected), onclick: () => { ui.index = index; ctx.render(); } },
      h("strong", {}, `${index + 1}.`), ` ${level.id}`, h("small", {}, ` ${level.cells[0]}×${level.cells[1]}`)),
    h("button", { type: "button", class: "icon", title: t("action.up"), "aria-label": t("action.up"), disabled: index === 0, onclick: () => { ui.index = index - 1; ctx.store.update((doc) => moveLevel(doc, index, -1)); } }, "▲"),
    h("button", { type: "button", class: "icon", title: t("action.down"), "aria-label": t("action.down"), disabled: index === count - 1, onclick: () => { ui.index = index + 1; ctx.store.update((doc) => moveLevel(doc, index, 1)); } }, "▼"),
    h("button", { type: "button", class: "icon", title: t("levels.duplicate"), "aria-label": t("levels.duplicate"), onclick: () => ctx.store.update((doc) => { ui.index = duplicateLevel(doc, index); }) }, "⧉"),
    h("button", { type: "button", class: "icon danger", title: t("levels.delete"), "aria-label": t("levels.delete"), disabled: count <= 1, onclick: () => { if (confirm(t("levels.confirmDelete", { id: level.id }))) ctx.store.update((doc) => { ui.index = removeLevel(doc, index); }); } }, "✕"));
}

function listCard(ctx, ui) {
  const levels = ctx.doc.levels;
  return h("aside", { class: "card level-list" },
    h("h3", { class: "section-title" }, t("levels.list")),
    h("p", { class: "note" }, t("levels.d.list")),
    h("ol", {}, levels.map((level, index) => listEntry(ctx, ui, level, index, levels.length))),
    h("button", { type: "button", class: "primary", onclick: () => ctx.store.update((doc) => { ui.index = addLevel(doc); }) }, `+ ${t("levels.add")}`));
}

export function levelsView(ctx) {
  const ui = levelUi(ctx.view);
  ui.index = Math.min(Math.max(ui.index, 0), ctx.doc.levels.length - 1);
  const level = ctx.doc.levels[ui.index];
  const edit = (mutator) => ctx.store.update((doc) => mutator(doc.levels[ui.index]));
  const errors = errorsFor(levelErrors(ctx.doc), `levels.${ui.index}`);
  const global = levelErrors(ctx.doc).filter((error) => !error.path.startsWith("levels.") || error.path === "levels");
  return h("section", { class: "detail level-tab" },
    h("h2", {}, t("tab.levels")),
    levelMap(ctx, ui.index, (index, render = true) => { ui.index = index; if (render) ctx.render(); }),
    h("div", { class: "split levels-split" },
      listCard(ctx, ui),
      h("div", { class: "panel-card level-panel" },
        h("h3", { class: "section-title" }, t("levels.editing", { id: level.id })),
        errorNote([...global, ...errors]),
        levelForm(ctx, level, edit),
        wavesSection(ctx, level, edit),
        strengthPanel(ctx, level, ui))));
}
