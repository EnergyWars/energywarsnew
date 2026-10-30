import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number, percent } from "../format.js";
import { chart, flipSeries, sectionHeading, isCollapsed } from "./components.js";
import { numberInput } from "./levelFields.js";
import { curveRows, example, armorEntries, setArmor, CURVE_MAX, CURVE_STEP, reduction } from "../armor.js";
import { monsterUi } from "./monsterState.js";
import { buildingName } from "./buildingView.js";
import { monsterName } from "./monsterDetail.js";

export const ARMOR_COLUMNS = [
  { key: "reduction", color: "var(--series-effect)", format: percent },
  { key: "taken", color: "var(--series-cost-factor)", format: percent },
  { key: "durability", color: "var(--series-level)", format: (value) => `×${number(value, 2)}` },
];

export function armorSeries(rows) {
  return ARMOR_COLUMNS.map((column) => ({
    key: column.key,
    color: column.color,
    format: column.format,
    label: t(`armor.col.${column.key}`),
    desc: t(`armor.desc.${column.key}`),
    values: rows.map((row) => row[column.key]),
  }));
}

export function armorDetail(rows, index) {
  return [[t("armor.col.armor"), number(rows[index].armor, 0)], ...ARMOR_COLUMNS.map((column) => [t(`armor.col.${column.key}`), column.format(rows[index][column.key])])];
}

function configFields(ctx) {
  const armor = ctx.doc.armor;
  const set = (key, value) => ctx.store.set(`armor.${key}`, value);
  return h("div", { class: "grid" },
    numberInput(t("armor.f.constant"), armor.constant, (value) => (value > 0 ? set("constant", value) : ctx.render()), t("armor.d.constant", { half: number(armor.constant, 0) }), { min: 0.01 }),
    numberInput(t("armor.f.maxReduction"), Math.round(armor.max_reduction * 100000) / 1000, (value) => (value >= 0 && value < 100 ? set("max_reduction", value / 100) : ctx.render()), t("armor.d.maxReduction"), { min: 0 }),
    numberInput(t("armor.f.minDamage"), armor.min_damage, (value) => (value >= 0 ? set("min_damage", value) : ctx.render()), t("armor.d.minDamage"), { min: 0 }));
}

function exampleBlock(ctx) {
  const ui = monsterUi(ctx.view);
  const result = example(ctx.doc.armor, ui.example.armor, ui.example.damage);
  return h("div", { class: "armor-example" },
    h("h4", {}, t("armor.exampleTitle")),
    h("div", { class: "grid" },
      numberInput(t("armor.f.exampleArmor"), ui.example.armor, (value) => { ui.example.armor = Math.max(value, 0); ctx.render(); }, t("armor.d.exampleArmor"), { min: 0 }),
      numberInput(t("armor.f.exampleDamage"), ui.example.damage, (value) => { ui.example.damage = Math.max(value, 0); ctx.render(); }, t("armor.d.exampleDamage"), { min: 0 })),
    h("p", { class: "example-line", role: "status" }, t("armor.exampleResult", { armor: number(ui.example.armor, 1), damage: number(ui.example.damage, 1), share: number(result.reduction, 1), result: number(result.result, 2) }), result.floored ? ` ${t("armor.exampleFloor", { min: number(ctx.doc.armor.min_damage, 2) })}` : ""));
}

function curveTable(rows, hidden) {
  const columns = ARMOR_COLUMNS.filter((column) => !hidden.has(column.key));
  return h("div", { class: "scroll" }, h("table", { class: "overview armor-curve" },
    h("thead", {}, h("tr", {}, h("th", { "data-tip": t("armor.desc.armor") }, t("armor.col.armor")), columns.map((column) => h("th", { "data-tip": t(`armor.desc.${column.key}`) }, t(`armor.col.${column.key}`))))),
    h("tbody", {}, rows.map((row) => h("tr", {}, h("td", {}, number(row.armor, 0)), columns.map((column) => h("td", {}, column.format(row[column.key]))))))));
}

export function curveSection(ctx) {
  const ui = monsterUi(ctx.view);
  const rows = curveRows(ctx.doc.armor, CURVE_MAX, CURVE_STEP);
  const toggle = (key, solo) => {
    flipSeries(ui.armorHidden, key, solo);
    ctx.render();
  };
  return [
    chart(armorSeries(rows), { hidden: ui.armorHidden, onToggle: toggle, detail: (index) => armorDetail(rows, index), title: (index) => `${t("armor.col.armor")} ${rows[index].armor}`, tick: (index) => String(rows[index].armor) }),
    curveTable(rows, ui.armorHidden),
  ];
}

export function entryName(ctx, entry) {
  return entry.type === "building" ? buildingName(ctx.names, entry.id) : monsterName(ctx.names, entry.id);
}

export function filterEntries(entries, query, nameOf) {
  const needle = query.trim().toLowerCase();
  if (!needle) return entries;
  return entries.filter((entry) => `${entry.id} ${nameOf(entry)}`.toLowerCase().includes(needle));
}

export function armorTable(ctx) {
  const ui = monsterUi(ctx.view);
  const entries = filterEntries(armorEntries(ctx.doc), ui.armorQuery, (entry) => entryName(ctx, entry));
  const search = h("input", { type: "search", value: ui.armorQuery, placeholder: t("armor.search"), "aria-label": t("armor.search") });
  search.addEventListener("change", () => { ui.armorQuery = search.value; ctx.render(); });
  const rows = entries.map((entry) => {
    const input = h("input", { type: "number", step: "any", min: 0, value: number(entry.armor, 4), "aria-label": `${t("armor.col.armor")} ${entryName(ctx, entry)}` });
    input.addEventListener("change", () => {
      const value = Number(input.value);
      if (Number.isFinite(value) && value >= 0) ctx.store.update((doc) => setArmor(doc, entry.type, entry.id, value));
      else ctx.render();
    });
    return h("tr", {}, h("td", {}, entryName(ctx, entry)), h("td", {}, t(`armor.type.${entry.type}`)), h("td", { "data-tip": t("armor.d.entry") }, input), h("td", {}, percent(reduction(entry.armor, ctx.doc.armor) * 100)));
  });
  return [
    h("div", { class: "actions" }, h("label", { class: "field inline" }, h("span", {}, t("armor.search")), search)),
    h("div", { class: "scroll table-edit" }, h("table", { class: "overview armor-all" },
      h("thead", {}, h("tr", {}, ["name", "type", "armor", "reduction"].map((key) => h("th", { "data-tip": t(`armor.desc.all.${key}`) }, t(`armor.all.${key}`))))),
      h("tbody", {}, rows))),
  ];
}

export function armorView(ctx) {
  const sections = [
    ["config", t("armor.configTitle"), t("armor.configHint"), () => [configFields(ctx), exampleBlock(ctx)]],
    ["curve", t("armor.curveTitle"), t("armor.curveHint"), () => curveSection(ctx)],
    ["all", t("armor.allTitle"), t("armor.allHint"), () => armorTable(ctx)],
  ];
  return h("div", { class: "armor-view" }, sections.map(([key, title, hint, body]) => h("section", { class: "panel-card" },
    sectionHeading(ctx, `armor.${key}`, title),
    isCollapsed(ctx, `armor.${key}`) ? null : [h("p", { class: "note" }, hint), body()])));
}
