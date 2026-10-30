import { h } from "../dom.js";
import { t, gameName, current } from "../i18n.js";
import { cellSize, toCells, fromCells } from "../format.js";
import { sectionHeading, isCollapsed } from "./components.js";
import { numberInput, selectInput, checkInput } from "./levelFields.js";
import { enemyIcon } from "./enemyIcon.js";
import { LOOKS } from "../enemyPainter.js";
import { CLASSES, FACTIONS, FLAGS, BUFF_STATS, SCOPES, setBase, setBuff, setFlag, buffValue } from "../monsters.js";
import { strengthSection } from "./monsterStrength.js";

const clone = (value) => JSON.parse(JSON.stringify(value));

export function monsterName(names, kind) {
  return gameName(names, `ENEMY_${kind.toUpperCase()}`, kind);
}

export function monsterDescription(names, kind) {
  return gameName(names, `ENEMY_${kind.toUpperCase()}_DESC`, "");
}

export function badges(enemy) {
  const list = [{ key: `class.${enemy.class}`, tone: enemy.class }, { key: `faction.${enemy.faction}`, tone: "faction" }];
  if (enemy.boss) list.push({ key: "boss", tone: "boss" });
  if (enemy.nocturnal) list.push({ key: "nocturnal", tone: "night" });
  if (enemy.sabotage) list.push({ key: "sabotage", tone: "sabotage" });
  return list;
}

export function badgeRow(enemy) {
  return h("span", { class: "badges" }, badges(enemy).map((badge) => h("span", { class: `pill ${badge.tone}`, "data-tip": t(`monsters.badgeDesc.${badge.key}`) }, t(`monsters.badge.${badge.key}`))));
}

function editor(ctx, kind) {
  return (mutator) => {
    const next = clone(ctx.doc.enemies[kind]);
    if (mutator(next) === false) {
      ctx.render();
      return;
    }
    ctx.store.update((doc) => {
      doc.enemies[kind] = next;
    });
  };
}

function baseFields(ctx, kind, enemy, edit) {
  const cell = cellSize(ctx.doc);
  const base = (key, label, options = {}) => numberInput(t(`monsters.f.${key}`), options.show ? options.show(enemy[key]) : enemy[key], (value) => edit((next) => setBase(next, key, options.store ? options.store(value) : value)), t(`monsters.d.${key}`), { min: options.min ?? 0, integer: options.integer });
  return h("div", { class: "grid" },
    base("hp", "hp", { min: 0.01 }),
    base("speed", "speed", { min: 0.01 }),
    base("damage", "damage"),
    base("cooldown", "cooldown", { min: 0.01 }),
    base("reach", "reach", { show: (v) => toCells(v, cell), store: (v) => fromCells(v, cell) }),
    base("radius", "radius", { min: 0.01 }),
    base("bounty", "bounty", { integer: true }),
    base("armor", "armor"),
    selectInput(t("monsters.f.class"), enemy.class, CLASSES.map((value) => ({ value, label: t(`monsters.badge.class.${value}`) })), (value) => edit((next) => { next.class = value; }), t("monsters.d.class")),
    selectInput(t("monsters.f.faction"), enemy.faction, FACTIONS.map((value) => ({ value, label: t(`monsters.badge.faction.${value}`) })), (value) => edit((next) => { next.faction = value; }), t("monsters.d.faction")),
    selectInput(t("monsters.f.look"), enemy.look, Object.keys(LOOKS).map((value) => ({ value, label: value })), (value) => edit((next) => { next.look = value; }), t("monsters.d.look")),
    FLAGS.map((flag) => checkInput(t(`monsters.f.${flag}`), Boolean(enemy[flag]), (on) => edit((next) => setFlag(next, flag, on)), t(`monsters.d.${flag}`))));
}

function buffFields(enemy, edit) {
  return h("div", { class: "buff-grid" }, SCOPES.map((scope) => h("div", { class: "subgroup" },
    h("h4", {}, t(`monsters.buff.${scope}`)),
    h("p", { class: "note" }, t(`monsters.buff.${scope}Desc`)),
    h("div", { class: "grid" }, BUFF_STATS.map((stat) => numberInput(
      `${t(`monsters.col.${stat}`)} (%)`,
      Math.round(buffValue(enemy, scope, stat) * 100000) / 1000,
      (value) => edit((next) => setBuff(next, scope, stat, value / 100)),
      t(`monsters.buff.${scope}${stat === "armor" ? "Armor" : "Stat"}`, { stat: t(`monsters.col.${stat}`) }),
      { min: -99 }))))));
}

export function monsterDetail(ctx, kind) {
  const enemy = ctx.doc.enemies[kind];
  const edit = editor(ctx, kind);
  const statsKey = `monsters.stats:${kind}`;
  const buffsKey = `monsters.buffs:${kind}`;
  return h("section", { class: "building-panel monster-detail" },
    h("header", { class: "panel-head" },
      enemyIcon(ctx.doc.enemies, kind, 96),
      h("div", {}, h("h2", {}, monsterName(ctx.names, kind)), badgeRow(enemy), h("p", { class: "caption building-desc" }, monsterDescription(ctx.names, kind) || t("monsters.noDesc", { lang: current() })))),
    h("section", { class: "panel-card" },
      sectionHeading(ctx, statsKey, t("monsters.statsTitle")),
      isCollapsed(ctx, statsKey) ? null : [h("p", { class: "note" }, t("monsters.statsHint")), baseFields(ctx, kind, enemy, edit)]),
    h("section", { class: "panel-card" },
      sectionHeading(ctx, buffsKey, t("monsters.buffsTitle")),
      isCollapsed(ctx, buffsKey) ? null : [h("p", { class: "note" }, t("monsters.buffsHint")), buffFields(enemy, edit)]),
    strengthSection(ctx, kind));
}
