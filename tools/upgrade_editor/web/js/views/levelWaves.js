import { h } from "../dom.js";
import { t, gameName } from "../i18n.js";
import { number, compact } from "../format.js";
import { chart, flipSeries, sectionHeading, isCollapsed } from "./components.js";
import { numberInput, enemyOptions, monsterSelect, removeButton, addButton, describe } from "./levelFields.js";
import { strengthRows, roundWaves, waveTimes } from "../waves.js";

const STRENGTH_COLUMNS = [
  { key: "first", color: "var(--series-gain)", format: (value) => number(value, 0) },
  { key: "last", color: "var(--series-level)", format: (value) => number(value, 0) },
  { key: "units", color: "var(--series-effect)", format: (value) => number(value, 0) },
  { key: "totalHp", color: "var(--series-spent)", format: (value) => compact(value) },
  { key: "hpScale", color: "var(--series-cost-factor)", format: (value) => `×${number(value, 2)}` },
  { key: "damageScale", color: "var(--series-spent-factor)", format: (value) => `×${number(value, 2)}` },
  { key: "bountyScale", color: "var(--series-cost)", format: (value) => `×${number(value, 2)}` },
  { key: "totalBounty", color: "var(--series-total)", format: (value) => compact(value) },
];

export function strengthSeries(rows) {
  return STRENGTH_COLUMNS.map((column) => ({
    key: column.key,
    color: column.color,
    format: column.format,
    label: t(`levels.strength.${column.key}`),
    desc: t(`levels.strengthDesc.${column.key}`),
    values: rows.map((row) => row[column.key]),
  }));
}

function rosterRows(roster, field, level, ctx, edit) {
  const options = enemyOptions(ctx.doc.enemies, ctx.names, gameName);
  return roster.map((entry, index) => h("div", { class: "row-edit roster-row" },
    describe(h("div", { class: "field" }, h("span", {}, t("levels.f.monster")), monsterSelect(options, entry[0], (value) => edit((l) => { l.waves[field][index][0] = value; }), t("levels.f.monster")), h("small", { class: "field-desc" }, t("levels.d.monster"))), t("levels.d.monster")),
    numberInput(t("levels.f.tier"), entry[1], (value) => edit((l) => { l.waves[field][index][1] = value; }), t("levels.d.tier", { day: entry[1] + 1 }), { integer: true, min: 0 }),
    numberInput(t("levels.f.weight"), entry[2], (value) => edit((l) => { l.waves[field][index][2] = value; }), t("levels.d.weight"), { min: 0.01 }),
    removeButton(() => edit((l) => { l.waves[field].splice(index, 1); }), t("action.remove"))));
}

function rosterBlock(ctx, level, field, edit) {
  const first = Object.keys(ctx.doc.enemies)[0];
  const used = new Set(level.waves[field].map((entry) => entry[0]));
  const fresh = Object.keys(ctx.doc.enemies).find((kind) => !used.has(kind)) ?? first;
  return h("div", { class: "roster" },
    h("h4", {}, t(`levels.${field}`)),
    h("p", { class: "note" }, t(`levels.d.${field}`)),
    rosterRows(level.waves[field], field, level, ctx, edit),
    addButton(t("levels.addMonster"), () => edit((l) => { l.waves[field].push([fresh, 0, 1]); })));
}

export function waveSettings(ctx, level, edit) {
  const waves = level.waves;
  const day = roundWaves(level, 1).filter((wave) => !wave.night).length;
  const total = waveTimes(level);
  return h("div", { class: "wave-settings" },
    h("div", { class: "grid" },
      numberInput(t("levels.f.interval"), waves.interval, (value) => edit((l) => { l.waves.interval = value; }), t("levels.d.interval"), { min: 1 }),
      numberInput(t("levels.f.base"), waves.base, (value) => edit((l) => { l.waves.base = value; }), t("levels.d.base"), { min: 0 }),
      numberInput(t("levels.f.ramp"), waves.ramp, (value) => edit((l) => { l.waves.ramp = value; }), t("levels.d.ramp"), { min: 0 }),
      numberInput(t("levels.f.nightFactor"), waves.night, (value) => edit((l) => { l.waves.night = value; }), t("levels.d.nightFactor"), { min: 0 }),
      numberInput(t("levels.f.growth"), waves.growth, (value) => edit((l) => { l.waves.growth = value; }), t("levels.d.growth"), { min: 0 })),
    h("p", { class: "note" }, t("levels.waveTimes", { total, day, night: total - day, length: number(Number(level.day) + Number(level.night), 0) })),
    rosterBlock(ctx, level, "roster", edit),
    rosterBlock(ctx, level, "night_roster", edit));
}

function strengthTable(rows, hidden) {
  const columns = STRENGTH_COLUMNS.filter((column) => !hidden.has(column.key));
  return h("div", { class: "scroll" }, h("table", { class: "overview strength" },
    h("thead", {}, h("tr", {},
      h("th", {}, t("levels.strength.round")),
      columns.map((column) => h("th", { "data-tip": t(`levels.strengthDesc.${column.key}`) }, t(`levels.strength.${column.key}`)))),),
    h("tbody", {}, rows.map((row) => h("tr", {},
      h("td", {}, row.round),
      columns.map((column) => h("td", {}, column.format(row[column.key]))))))));
}

export function strengthPanel(ctx, level, ui) {
  const hidden = ctx.view.waveHidden ??= new Set();
  const rows = strengthRows(level, ctx.doc.enemies, ui.rounds);
  const series = strengthSeries(rows);
  const toggle = (key, solo) => {
    flipSeries(hidden, key, solo);
    ctx.render();
  };
  const detail = (index) => STRENGTH_COLUMNS.filter((column) => !hidden.has(column.key)).map((column) => [t(`levels.strength.${column.key}`), column.format(rows[index][column.key])]);
  const closed = isCollapsed(ctx, "levels.strength");
  return h("section", { class: "level-section" },
    sectionHeading(ctx, "levels.strength", t("levels.strengthTitle")),
    closed ? null : [
      h("p", { class: "note" }, t("levels.d.strength")),
      h("div", { class: "grid" }, numberInput(t("levels.f.rounds"), ui.rounds, (value) => { ui.rounds = Math.min(Math.max(value, 1), 60); ctx.render(); }, t("levels.d.rounds"), { integer: true, min: 1 })),
      chart(series, { hidden, onToggle: toggle, detail, title: (index) => `${t("levels.day")} ${index + 1}`, tick: (index) => String(index + 1) }),
      strengthTable(rows, hidden)]);
}

export function wavesSection(ctx, level, edit) {
  const closed = isCollapsed(ctx, "levels.waves");
  return h("section", { class: "level-section" },
    sectionHeading(ctx, "levels.waves", t("levels.wavesTitle")),
    closed ? null : waveSettings(ctx, level, edit));
}
