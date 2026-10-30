import { h } from "../dom.js";
import { t, gameName } from "../i18n.js";
import { number } from "../format.js";
import { sectionHeading, isCollapsed, searchSelect } from "./components.js";
import { numberInput, selectInput, enemyOptions, removeButton, addButton, describe } from "./levelFields.js";
import { waveSettings, strengthPanel } from "./levelWaves.js";
import { monsterUi } from "./monsterState.js";
import { waveComposition, dayComposition, waveTimes, spawnerCounts, addExtra, removeExtra, extraEntries, MAX_EXTRA_COUNT } from "../waves.js";

const kindName = (ctx, kind) => gameName(ctx.names, `ENEMY_${kind.toUpperCase()}`, kind);

export function levelOptions(levels) {
  return levels.map((level, index) => ({ value: String(index), label: `${index + 1}. ${level.id}`, hint: `${level.cells[0]}×${level.cells[1]}` }));
}

export function compositionText(ctx, groups) {
  return groups.map((group) => `${t(`waves.faction.${group.faction}`)} ×${group.spawners}: ${group.items.map((item) => `${kindName(ctx, item.kind)} ≈${number(item.expected, 1)}${item.fallback ? "*" : ""}`).join(", ") || "–"}`);
}

export function overviewRows(ctx, level, rounds) {
  return Array.from({ length: rounds }, (_, index) => {
    const day = index + 1;
    const entries = dayComposition(level, ctx.doc.enemies, day);
    return { day, entries: entries.map((entry) => ({ ...entry, name: kindName(ctx, entry.kind) })) };
  });
}

function entryText(ctx, entry) {
  const parts = [];
  if (entry.expected > 0) parts.push(`${entry.name} ≈${number(entry.expected, 1)} ${t("waves.perSpawner")}${entry.spawners > 1 ? ` (×${entry.spawners})` : ""}`);
  if (entry.extra > 0) parts.push(`${entry.name} +${entry.extra} ${t("waves.extraShort")}`);
  return parts.join(", ");
}

function overviewTable(ctx, level, ui) {
  const rows = overviewRows(ctx, level, ui.rounds);
  return h("div", { class: "scroll" }, h("table", { class: "overview wave-days" },
    h("thead", {}, h("tr", {}, h("th", { "data-tip": t("waves.desc.day") }, t("waves.col.day")), h("th", { "data-tip": t("waves.desc.monsters") }, t("waves.col.monsters")))),
    h("tbody", {}, rows.map((row) => h("tr", { class: row.day === ui.day ? "changed" : "" },
      h("td", {}, h("button", { type: "button", class: "link", onclick: () => { ui.day = row.day; ctx.render(); } }, row.day)),
      h("td", {}, row.entries.length ? row.entries.map((entry) => h("div", {}, entry.faction === "extra" ? "★ " : "", entryText(ctx, entry))) : "–"))))));
}

function dayTable(ctx, level, ui) {
  const waves = waveComposition(level, ctx.doc.enemies, ui.day);
  return h("div", { class: "scroll" }, h("table", { class: "overview wave-detail" },
    h("thead", {}, h("tr", {}, ["no", "time", "phase", "units", "monsters", "extras"].map((key) => h("th", { "data-tip": t(`waves.desc.${key}`) }, t(`waves.col.${key}`))))),
    h("tbody", {}, waves.map((wave) => h("tr", {},
      h("td", {}, wave.index + 1),
      h("td", {}, `${number(wave.time, 1)} s`),
      h("td", {}, t(wave.night ? "waves.night" : "waves.dayPhase")),
      h("td", {}, number(wave.units, 0)),
      h("td", {}, compositionText(ctx, wave.groups).map((line) => h("div", {}, line))),
      h("td", {}, wave.extras.length ? wave.extras.map((entry) => h("div", {}, `★ ${kindName(ctx, entry.kind)} ×${entry.count}`)) : "–"))))));
}

function extraRow(ctx, level, index, edit) {
  const entry = extraEntries(level)[index];
  const options = enemyOptions(ctx.doc.enemies, ctx.names, gameName);
  const change = (patch) => edit((l) => { l.extra_waves[index] = { ...l.extra_waves[index], ...patch }; });
  return h("div", { class: "row-edit roster-row" },
    numberInput(t("waves.f.extraDay"), entry.day, (value) => change({ day: Math.max(value, 1) }), t("waves.d.extraDay"), { integer: true, min: 1 }),
    selectInput(t("waves.f.extraPhase"), entry.night ? "night" : "day", [{ value: "day", label: t("waves.dayPhase") }, { value: "night", label: t("waves.night") }], (value) => change({ night: value === "night" }), t("waves.d.extraPhase")),
    describe(h("div", { class: "field" }, h("span", {}, t("waves.f.extraMonster")), searchSelect({ options, value: entry.kind, onChange: (value) => change({ kind: value }), label: t("waves.f.extraMonster") }), h("small", { class: "field-desc" }, t("waves.d.extraMonster"))), t("waves.d.extraMonster")),
    numberInput(t("waves.f.extraCount"), entry.count, (value) => change({ count: Math.min(Math.max(value, 1), MAX_EXTRA_COUNT) }), t("waves.d.extraCount", { max: MAX_EXTRA_COUNT }), { integer: true, min: 1 }),
    removeButton(() => edit((l) => removeExtra(l, index)), t("action.remove")));
}

export function extraBlock(ctx, level, edit) {
  const first = Object.keys(ctx.doc.enemies)[0];
  const entries = extraEntries(level);
  return h("div", { class: "roster extra-waves" },
    h("p", { class: "note" }, t("waves.extraHint")),
    entries.map((_, index) => extraRow(ctx, level, index, edit)),
    addButton(t("waves.extraAdd"), () => edit((l) => addExtra(l, { kind: first }))));
}

function section(ctx, key, title, hint, body) {
  const closed = isCollapsed(ctx, key);
  return h("section", { class: "panel-card" }, sectionHeading(ctx, key, title), closed ? null : [h("p", { class: "note" }, hint), body()]);
}

export function wavesView(ctx) {
  const ui = monsterUi(ctx.view);
  ui.level = Math.min(Math.max(ui.level, 0), ctx.doc.levels.length - 1);
  const level = ctx.doc.levels[ui.level];
  const edit = (mutator) => ctx.store.update((doc) => mutator(doc.levels[ui.level]));
  const counts = spawnerCounts(level);
  const picker = h("div", { class: "field" }, h("span", {}, t("waves.f.level")),
    searchSelect({ options: levelOptions(ctx.doc.levels), value: String(ui.level), onChange: (value) => { ui.level = Number(value); ctx.render(); }, label: t("waves.f.level") }),
    h("small", { class: "field-desc" }, t("waves.d.level")));
  return h("div", { class: "waves-view" },
    section(ctx, "waves.level", t("waves.levelTitle"), t("waves.levelHint"), () => [
      h("div", { class: "grid" }, picker,
        numberInput(t("waves.f.day"), level.day, (value) => (value > 0 ? edit((l) => { l.day = value; }) : ctx.render()), t("waves.d.day"), { min: 1 }),
        numberInput(t("waves.f.night"), level.night, (value) => (value > 0 ? edit((l) => { l.night = value; }) : ctx.render()), t("waves.d.night"), { min: 1 })),
      h("p", { class: "note" }, t("waves.spawners", { nest: counts.nest, camp: counts.camp, waves: waveTimes(level) })),
      waveSettings(ctx, level, edit)]),
    section(ctx, "waves.extra", t("waves.extraTitle"), t("waves.extraIntro"), () => extraBlock(ctx, level, edit)),
    section(ctx, "waves.days", t("waves.daysTitle"), t("waves.daysHint"), () => [
      h("div", { class: "grid" }, numberInput(t("waves.f.rounds"), ui.rounds, (value) => { ui.rounds = Math.min(Math.max(value, 1), 60); ctx.render(); }, t("waves.d.rounds"), { integer: true, min: 1 })),
      overviewTable(ctx, level, ui),
      h("h4", {}, t("waves.dayDetail", { day: ui.day })),
      h("div", { class: "grid" }, numberInput(t("waves.f.dayPick"), ui.day, (value) => { ui.day = Math.min(Math.max(value, 1), 60); ctx.render(); }, t("waves.d.dayPick"), { integer: true, min: 1 })),
      dayTable(ctx, level, ui),
      h("p", { class: "note" }, t("waves.fallbackNote"))]),
    strengthPanel(ctx, level, ui));
}
