import { h } from "../dom.js";
import { t, gameName } from "../i18n.js";
import { number, percent } from "../format.js";
import { BALANCE_RULES, CATEGORIES, checkBalance } from "../balance.js";
import { numberField, sectionHeading, isCollapsed } from "./components.js";
import { buildingName, trackName, iconFor } from "./buildingView.js";
import { enemyIcon } from "./enemyIcon.js";
import { openTrack, openMonster, openLevel, openWaves } from "./navigation.js";

export const RULE_FIELDS = [
  { key: "minLevelShare", min: 0 },
  { key: "killSeconds", min: 1 },
  { key: "bossKillSeconds", min: 1 },
  { key: "bossFirstDay", min: 1, integer: true },
];

export function balanceUi(view) {
  view.balanceUi ??= { rules: { ...BALANCE_RULES } };
  return view.balanceUi;
}

const monsterName = (names, kind) => gameName(names, `ENEMY_${kind.toUpperCase()}`, kind);
const phase = (night) => t(night ? "balance.night" : "balance.day");

export function sortUpgrades(warnings) {
  return [...warnings].sort((a, b) => a.first - b.first || a.worst - b.worst);
}

export function warningText(names, warning) {
  if (warning.type === "upgrade") {
    return t("balance.upgradeText", { building: buildingName(names, warning.building), track: trackName(names, warning.track, warning.building), first: warning.first, count: warning.count, levels: warning.levels, worst: percent(warning.worst), at: warning.worstLevel, typical: percent(warning.typical) });
  }
  if (warning.type === "monster") {
    return t(warning.appears ? "balance.monsterText" : "balance.monsterTextUnused", { monster: monsterName(names, warning.monster), seconds: number(warning.seconds, 1), limit: number(warning.limit, 0), hp: number(warning.effectiveHp, 0), level: warning.level + 1, phase: phase(warning.night), tower: buildingName(names, warning.tower ?? ""), dps: number(warning.towerDps, 1) });
  }
  if (warning.type === "starter") {
    return t(warning.lowest === null ? "balance.starterEmpty" : "balance.starterText", { level: warning.level + 1, id: warning.levelId, phase: phase(warning.night), lowest: warning.lowest });
  }
  return t(warning.source === "extra" ? "balance.bossExtra" : "balance.bossRoster", { level: warning.level + 1, id: warning.levelId, monster: monsterName(names, warning.monster), day: warning.day, phase: phase(warning.night) });
}

export function focusWarning(view, warning) {
  if (warning.type === "upgrade") return openTrack(view, warning.building, warning.track);
  if (warning.type === "monster") return openMonster(view, warning.monster);
  if (warning.type === "boss" && warning.source === "extra") return openWaves(view, warning.level, warning.day);
  return openLevel(view, warning.level);
}

function icon(ctx, warning) {
  if (warning.type === "upgrade") return iconFor(ctx.doc.buildings.find((entry) => entry.id === warning.building), 32);
  if (warning.monster && ctx.doc.enemies[warning.monster]) return enemyIcon(ctx.doc.enemies, warning.monster, 32);
  return h("span", { class: "warning-mark", "aria-hidden": "true" }, "⚠");
}

function item(ctx, warning) {
  return h("li", {}, h("button", { type: "button", class: "warning-item", title: t("balance.jump"), onclick: () => { focusWarning(ctx.view, warning); ctx.render(); globalThis.scrollTo?.(0, 0); } },
    icon(ctx, warning),
    h("span", { class: "warning-text" }, warningText(ctx.names, warning)),
    h("span", { class: "chevron", "aria-hidden": "true" }, "→")));
}

function category(ctx, key, warnings) {
  const sectionKey = `balance:${key}`;
  const title = `${t(`balance.cat.${key}`)} (${warnings.length})`;
  const closed = isCollapsed(ctx, sectionKey);
  return h("section", { class: "panel-card balance-category" },
    sectionHeading(ctx, sectionKey, title),
    closed ? null : [
      h("p", { class: "note" }, t(`balance.rule.${key}`, balanceUi(ctx.view).rules)),
      warnings.length ? h("ul", { class: "warning-list" }, warnings.map((warning) => item(ctx, warning))) : h("p", { class: "empty ok-note" }, t("balance.clean"))]);
}

function ruleCard(ctx) {
  const ui = balanceUi(ctx.view);
  return h("div", { class: "card grid balance-rules" },
    RULE_FIELDS.map((field) => numberField(t(`balance.f.${field.key}`), ui.rules[field.key], (value) => {
      if (value < field.min) return;
      ui.rules[field.key] = value;
      ctx.render();
    }, { min: field.min, integer: Boolean(field.integer), desc: t(`balance.d.${field.key}`) })),
    h("div", { class: "actions" }, h("button", { type: "button", onclick: () => { ui.rules = { ...BALANCE_RULES }; ctx.render(); } }, t("balance.resetRules"))));
}

export function balanceView(ctx) {
  const ui = balanceUi(ctx.view);
  const result = checkBalance(ctx.doc, { ...BALANCE_RULES, ...ui.rules });
  const lists = { ...result, upgrades: sortUpgrades(result.upgrades) };
  return h("section", { class: "detail balance-tab" },
    h("h2", {}, t("tab.balance")),
    h("p", { class: "note" }, t("balance.hint")),
    ruleCard(ctx),
    h("p", { class: result.total ? "badge warn" : "badge" }, t("balance.total", { count: result.total })),
    CATEGORIES.map((key) => category(ctx, key, lists[key])));
}
