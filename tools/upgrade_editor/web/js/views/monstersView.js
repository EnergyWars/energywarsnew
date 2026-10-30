import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { CLASSES, FACTIONS, filterMonsters } from "../monsters.js";
import { enemyIcon } from "./enemyIcon.js";
import { monsterUi } from "./monsterState.js";
import { monsterName, monsterDescription, monsterDetail, badgeRow } from "./monsterDetail.js";
import { armorView } from "./armorView.js";
import { choiceField } from "./components.js";
import { wavesView } from "./monsterWaves.js";

export const SECTIONS = ["monsters", "armor", "waves"];
export const FLAVORS = ["all", "normal", "boss", "day", "night"];

function choice(label, value, options, onChange, desc) {
  return choiceField(label, value, options, onChange, desc);
}

export function visibleKinds(ctx) {
  const ui = monsterUi(ctx.view);
  return filterMonsters(ctx.doc.enemies, ctx.names, { query: ui.query, klass: ui.klass, faction: ui.faction, kind: ui.flavor }, (kind) => monsterName(ctx.names, kind));
}

function filters(ctx) {
  const ui = monsterUi(ctx.view);
  const set = (key) => (value) => { ui[key] = value; ctx.render(); };
  const search = h("input", { type: "search", value: ui.query, placeholder: t("monsters.search"), "aria-label": t("monsters.search") });
  search.addEventListener("input", () => { ui.query = search.value; });
  search.addEventListener("change", () => ctx.render());
  return h("div", { class: "monster-filters" },
    h("label", { class: "field", "data-tip": t("monsters.d.search") }, h("span", {}, t("monsters.search")), search, h("small", { class: "field-desc" }, t("monsters.d.search"))),
    choice(t("monsters.filter.class"), ui.klass, [{ value: "all", label: t("monsters.filter.all") }, ...CLASSES.map((value) => ({ value, label: t(`monsters.badge.class.${value}`) }))], set("klass"), t("monsters.d.filterClass")),
    choice(t("monsters.filter.faction"), ui.faction, [{ value: "all", label: t("monsters.filter.all") }, ...FACTIONS.map((value) => ({ value, label: t(`monsters.badge.faction.${value}`) }))], set("faction"), t("monsters.d.filterFaction")),
    choice(t("monsters.filter.flavor"), ui.flavor, FLAVORS.map((value) => ({ value, label: t(`monsters.flavor.${value}`) })), set("flavor"), t("monsters.d.filterFlavor")));
}

function card(ctx, kind, selected) {
  const ui = monsterUi(ctx.view);
  const enemy = ctx.doc.enemies[kind];
  return h("li", {}, h("button", { type: "button", class: selected ? "monster-card selected" : "monster-card", "aria-pressed": String(selected), onclick: () => { ui.kind = kind; ctx.render(); } },
    enemyIcon(ctx.doc.enemies, kind, 64),
    h("strong", {}, monsterName(ctx.names, kind)),
    badgeRow(enemy),
    h("small", { class: "monster-desc" }, monsterDescription(ctx.names, kind)),
    h("small", { class: "monster-numbers" }, `${t("monsters.col.hp")} ${number(enemy.hp, 0)} · ${t("monsters.col.damage")} ${number(enemy.damage, 0)} · ${t("monsters.col.armor")} ${number(enemy.armor, 0)}`)));
}

function catalog(ctx) {
  const ui = monsterUi(ctx.view);
  const kinds = visibleKinds(ctx);
  if (!ui.kind || !ctx.doc.enemies[ui.kind]) ui.kind = kinds[0] ?? Object.keys(ctx.doc.enemies)[0];
  return h("aside", { class: "card monster-catalog" },
    h("p", { class: "note" }, t("monsters.catalogHint", { shown: kinds.length, total: Object.keys(ctx.doc.enemies).length })),
    filters(ctx),
    kinds.length ? h("ul", { class: "monster-grid" }, kinds.map((kind) => card(ctx, kind, kind === ui.kind))) : h("p", { class: "empty" }, t("monsters.noMatch")));
}

function subNav(ctx) {
  const ui = monsterUi(ctx.view);
  return h("div", { class: "mode-switch", role: "tablist" }, SECTIONS.map((section) => h("button", { type: "button", role: "tab", "aria-selected": String(ui.section === section), class: ui.section === section ? "active" : "", "data-tip": t(`monsters.sectionDesc.${section}`), onclick: () => { ui.section = section; ctx.render(); } }, t(`monsters.section.${section}`))));
}

export function monstersView(ctx) {
  const ui = monsterUi(ctx.view);
  const body = ui.section === "armor" ? armorView(ctx)
    : ui.section === "waves" ? wavesView(ctx)
      : (() => {
        const list = catalog(ctx);
        return h("div", { class: "split monsters-split" }, list, monsterDetail(ctx, ui.kind));
      })();
  return h("section", { class: "detail monsters-tab" }, h("h2", {}, t("tab.monsters")), subNav(ctx), body);
}
