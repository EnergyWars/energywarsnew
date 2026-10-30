import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { game, fresh, find } from "./data.js";
import { installFakeDom } from "./fakeDom.js";
import { create } from "../../web/js/store.js";
import { mitigate } from "../../web/js/armor.js";
import { monsterRow } from "../../web/js/monsters.js";
import {
  BALANCE_RULES, CATEGORIES, upgradeWarnings, levelMedians, armedBuildings, towerDps, bestTower, appearances,
  killTime, monsterWarnings, starterWarnings, bossWarnings, checkBalance,
} from "../../web/js/balance.js";
import { balanceView, balanceUi, focusWarning, warningText, sortUpgrades, RULE_FIELDS } from "../../web/js/views/balanceView.js";

installFakeDom();

const read = (code) => JSON.parse(readFileSync(new URL(`../../web/i18n/${code}.json`, import.meta.url), "utf8"));
const dictionary = { de: read("de"), en: read("en") };

function context(doc = fresh()) {
  const store = create(doc, game);
  const ctx = { original: game, names: game.names, store, view: { tab: "balance", collapsed: new Set(), open: new Set() }, renders: 0, render() { this.renders += 1; }, toast() {} };
  Object.defineProperty(ctx, "doc", { get: () => store.state.document });
  return ctx;
}

const freshView = () => ({ tab: "balance", collapsed: new Set(["upgrades:laser", "levels.waves"]), open: new Set() });

test("tower damage per second follows the attack values and the armor", () => {
  const zapper = find(game, "zapper");
  assert.equal(towerDps(zapper, 0, game.armor), zapper.stats.attack.damage / zapper.stats.attack.cooldown);
  assert.equal(towerDps(zapper, 100, game.armor), mitigate(zapper.stats.attack.damage, 100, game.armor) / zapper.stats.attack.cooldown);
  const laser = find(game, "laser");
  assert.equal(laser.stats.attack.cooldown, 0);
  assert.ok(Math.abs(towerDps(laser, 0, game.armor) - laser.stats.attack.damage) < 1e-9);
  assert.ok(Math.abs(towerDps(laser, 500, game.armor) - game.armor.min_damage / BALANCE_RULES.tick) < 1e-9);
  assert.equal(towerDps(find(game, "solar"), 0, game.armor), 0);
  assert.ok(armedBuildings(game).every((entry) => entry.stats.attack.damage > 0));
  assert.ok(armedBuildings(game).some((entry) => entry.id === "zapper"));
  assert.ok(!armedBuildings(game).some((entry) => entry.id === "solar"));
});

test("the best tower has the highest damage against the given armor", () => {
  const best = bestTower(game, 0);
  for (const entry of armedBuildings(game)) assert.ok(best.dps >= towerDps(entry, 0, game.armor), entry.id);
  const doc = fresh();
  find(doc, "plasma").stats.attack.damage = 100000;
  assert.equal(bestTower(doc, 0).id, "plasma");
  assert.equal(bestTower({ ...fresh(), buildings: [find(game, "solar")] }, 0), null);
});

test("level medians are the median level factor of all tracks at the same level", () => {
  const doc = fresh();
  doc.buildings = [find(doc, "zapper"), find(doc, "laser"), find(doc, "tesla")];
  doc.buildings.forEach((entry, index) => {
    entry.tracks = ["power"];
    entry.plans = { power: { mode: "table", levels: [{ cost: entry.cost, gain: 0.1 * (index + 1) }, { cost: entry.cost, gain: 0.2 }] } };
  });
  const medians = levelMedians(doc);
  assert.ok(Math.abs(medians.get(1) - 20) < 1e-9);
  assert.ok(Math.abs(medians.get(2) - 20) < 1e-9);
  doc.buildings.pop();
  assert.ok(Math.abs(levelMedians(doc).get(1) - 15) < 1e-9);
});

test("upgrade warnings only report levels far below the typical value of the same level", () => {
  const warnings = upgradeWarnings(game);
  const medians = levelMedians(game);
  assert.ok(warnings.length > 0);
  assert.ok(warnings.length < 20);
  for (const warning of warnings) {
    assert.ok(warning.worst < (medians.get(warning.worstLevel) * BALANCE_RULES.minLevelShare) / 100);
    assert.equal(warning.typical, medians.get(warning.worstLevel));
    assert.ok(warning.first >= 1 && warning.first <= warning.worstLevel && warning.count <= warning.levels);
  }
  assert.deepEqual(upgradeWarnings(game, { ...BALANCE_RULES, minLevelShare: 0 }), []);
  assert.ok(upgradeWarnings(game, { ...BALANCE_RULES, minLevelShare: 50 }).length > warnings.length);
  const doc = fresh();
  doc.buildings = [find(doc, "zapper"), find(doc, "laser"), find(doc, "tesla")];
  doc.buildings.forEach((entry) => {
    entry.tracks = ["power"];
    entry.plans = { power: { mode: "table", levels: [{ cost: entry.cost, gain: 0.5 }, { cost: entry.cost, gain: 0.5 }] } };
  });
  assert.deepEqual(upgradeWarnings(doc), []);
  doc.buildings[0].plans.power.levels[1] = { cost: 10 * doc.buildings[0].cost, gain: 0.1 };
  assert.deepEqual(upgradeWarnings(doc).map((warning) => [warning.building, warning.first, warning.count, warning.levels, warning.worstLevel]), [["zapper", 2, 1, 2, 2]]);
  assert.ok(Math.abs(upgradeWarnings(doc)[0].worst - 1) < 1e-9);
});

test("monsters appear through rosters, extra monsters and air raids", () => {
  assert.ok(appearances(game, "crawler").some((place) => place.level === 0 && !place.night));
  assert.ok(appearances(game, "stalker").every((place) => place.night));
  assert.ok(appearances(game, "wasp").length > 0);
  assert.deepEqual(appearances(game, "dreadwing"), []);
  assert.deepEqual(appearances(game, "ghost"), []);
  const doc = fresh();
  doc.levels[0].extra_waves = [{ day: 2, night: true, kind: "dreadwing", count: 1 }];
  assert.deepEqual(appearances(doc, "dreadwing"), [{ level: 0, night: true }]);
});

test("kill times use the buffed monster at the given level and time of day", () => {
  const item = killTime(game, "behemoth", 2, true);
  const row = monsterRow(game.enemies.behemoth, game.armor, 2, true);
  assert.equal(item.hp, row.hp);
  assert.equal(item.effectiveHp, row.effectiveHp);
  assert.equal(item.seconds, row.hp / bestTower(game, row.armor).dps);
  assert.ok(killTime(game, "behemoth", 7, true).seconds > killTime(game, "behemoth", 0, false).seconds);
  assert.equal(killTime({ ...fresh(), buildings: [] }, "crawler", 0, false).seconds, Infinity);
});

test("monster warnings flag only monsters above the time limit", () => {
  const warnings = monsterWarnings(game);
  for (const warning of warnings) {
    const limit = game.enemies[warning.monster].boss ? BALANCE_RULES.bossKillSeconds : BALANCE_RULES.killSeconds;
    assert.equal(warning.limit, limit);
    assert.ok(warning.seconds > limit);
  }
  assert.ok(warnings.every((warning, index) => index === 0 || warning.seconds / warning.limit <= warnings[index - 1].seconds / warnings[index - 1].limit));
  const doc = fresh();
  doc.enemies.crawler.hp = 1e6;
  const tough = monsterWarnings(doc).find((warning) => warning.monster === "crawler");
  assert.equal(tough.boss, false);
  assert.equal(tough.appears, true);
  assert.deepEqual(monsterWarnings(doc, { ...BALANCE_RULES, killSeconds: 1e9, bossKillSeconds: 1e9 }), []);
  doc.enemies.dreadwing.hp = 1e7;
  const unused = monsterWarnings(doc).find((warning) => warning.monster === "dreadwing");
  assert.equal(unused.appears, false);
  assert.equal(unused.level, doc.levels.length - 1);
});

test("levels without a tier 0 monster in a roster are reported", () => {
  assert.deepEqual(starterWarnings(game), []);
  const doc = fresh();
  doc.levels[1].waves.roster = doc.levels[1].waves.roster.map((entry) => [entry[0], Math.max(entry[1], 2), entry[2]]);
  doc.levels[2].waves.night_roster = [];
  const warnings = starterWarnings(doc);
  assert.deepEqual(warnings.map((warning) => [warning.level, warning.night, warning.lowest]), [[1, false, 2], [2, true, null]]);
  assert.equal(warnings[0].levelId, doc.levels[1].id);
});

test("bosses before the first allowed day are reported from rosters and extra monsters", () => {
  assert.deepEqual(bossWarnings(game), []);
  const doc = fresh();
  doc.levels[0].waves.night_roster.push(["behemoth", 0, 0.1], ["behemoth", 2, 0.1]);
  doc.levels[1].extra_waves = [{ day: 2, night: false, kind: "tank", count: 1 }, { day: 3, night: true, kind: "tank", count: 1 }, { day: 1, night: false, kind: "crawler", count: 5 }];
  const warnings = bossWarnings(doc);
  assert.deepEqual(warnings.map((warning) => [warning.source, warning.level, warning.monster, warning.day, warning.night]), [["roster", 0, "behemoth", 1, true], ["extra", 1, "tank", 2, false]]);
  assert.equal(bossWarnings(doc, { ...BALANCE_RULES, bossFirstDay: 1 }).length, 0);
});

test("the check sums every category", () => {
  const result = checkBalance(game);
  assert.deepEqual(Object.keys(result).filter((key) => key !== "total"), CATEGORIES);
  assert.equal(result.total, CATEGORIES.reduce((sum, key) => sum + result[key].length, 0));
});

test("every warning jumps to the matching place", () => {
  let view = focusWarning(freshView(), { type: "upgrade", building: "laser", track: "power" });
  assert.equal(view.tab, "buildings");
  assert.equal(view.building, "laser");
  assert.ok(view.open.has("laser:power"));
  assert.ok(!view.collapsed.has("upgrades:laser"));
  view = freshView();
  view.monsterUi = { section: "armor", kind: "crawler", query: "x", klass: "air", faction: "camp", flavor: "boss", rounds: 10, day: 1, level: 0 };
  focusWarning(view, { type: "monster", monster: "behemoth" });
  assert.equal(view.tab, "monsters");
  assert.deepEqual([view.monsterUi.section, view.monsterUi.kind, view.monsterUi.query, view.monsterUi.klass, view.monsterUi.faction, view.monsterUi.flavor], ["monsters", "behemoth", "", "all", "all", "all"]);
  view = focusWarning(freshView(), { type: "starter", level: 3 });
  assert.equal(view.tab, "levels");
  assert.equal(view.levelUi.index, 3);
  assert.ok(!view.collapsed.has("levels.waves"));
  view = focusWarning(freshView(), { type: "boss", source: "roster", level: 2 });
  assert.equal(view.levelUi.index, 2);
  view = focusWarning(freshView(), { type: "boss", source: "extra", level: 4, day: 14 });
  assert.equal(view.tab, "monsters");
  assert.deepEqual([view.monsterUi.section, view.monsterUi.level, view.monsterUi.day, view.monsterUi.rounds], ["waves", 4, 14, 14]);
});

test("upgrade warnings are sorted by the first weak level and then by severity", () => {
  const sorted = sortUpgrades([{ first: 3, worst: 1 }, { first: 1, worst: 20 }, { first: 1, worst: 5 }]);
  assert.deepEqual(sorted.map((item) => [item.first, item.worst]), [[1, 5], [1, 20], [3, 1]]);
});

test("every warning type has a text", () => {
  const doc = fresh();
  doc.levels[0].waves.night_roster.push(["behemoth", 0, 0.1]);
  doc.levels[1].extra_waves = [{ day: 1, night: false, kind: "tank", count: 1 }];
  doc.levels[2].waves.roster = [["crawler", 1, 1]];
  doc.levels[3].waves.night_roster = [];
  doc.enemies.dreadwing.hp = 1e7;
  const result = checkBalance(doc);
  const all = CATEGORIES.flatMap((key) => result[key]);
  for (const type of ["upgrade", "monster", "starter", "boss"]) assert.ok(all.some((warning) => warning.type === type), type);
  const keys = new Set(all.map((warning) => warningText(doc.names, warning)));
  for (const key of ["balance.upgradeText", "balance.monsterText", "balance.monsterTextUnused", "balance.starterText", "balance.starterEmpty", "balance.bossRoster", "balance.bossExtra"]) assert.ok(keys.has(key), key);
});

test("balance texts exist in both languages with the same placeholders", () => {
  const placeholders = (text) => [...text.matchAll(/\{(\w+)\}/g)].map((match) => match[1]).sort();
  const keys = Object.keys(dictionary.en).filter((key) => key.startsWith("balance.") || key.startsWith("groups.") || key === "tab.balance" || key === "overview.open" || key.startsWith("error.GROUP"));
  assert.ok(keys.length > 60);
  for (const key of keys) {
    assert.ok(dictionary.de[key], key);
    assert.deepEqual(placeholders(dictionary.de[key]), placeholders(dictionary.en[key]), key);
  }
  for (const category of CATEGORIES) {
    for (const prefix of ["balance.cat.", "balance.rule."]) assert.ok(dictionary.de[`${prefix}${category}`], `${prefix}${category}`);
  }
  for (const field of RULE_FIELDS) {
    assert.ok(dictionary.de[`balance.f.${field.key}`] && dictionary.de[`balance.d.${field.key}`], field.key);
    assert.ok(field.key in BALANCE_RULES);
  }
  for (const code of ["GROUPS", "GROUP_NAME", "GROUP_DUPLICATE", "GROUP_ITEM"]) assert.ok(dictionary.de[`error.${code}`] && dictionary.en[`error.${code}`], code);
});

test("the balance tab lists every category, jumps on click and keeps the document untouched", () => {
  const doc = fresh();
  doc.levels[0].waves.night_roster.push(["behemoth", 0, 0.1]);
  const ctx = context(doc);
  const before = JSON.stringify(ctx.doc);
  let root = balanceView(ctx);
  assert.equal(root.findAll((node) => node.tagName === "section" && node.className === "panel-card balance-category").length, CATEGORIES.length);
  assert.equal(root.findAll((node) => node.className === "warning-item").length, checkBalance(doc).total);
  assert.equal(root.findAll((node) => node.className === "empty ok-note").length, 1);
  const boss = root.findAll((node) => node.className === "warning-item").find((node) => node.text().includes("balance.bossRoster"));
  boss.dispatch("click");
  assert.equal(ctx.view.tab, "levels");
  assert.equal(ctx.view.levelUi.index, 0);
  assert.equal(ctx.renders, 1);
  assert.equal(JSON.stringify(ctx.doc), before);
  assert.ok(!ctx.store.canUndo());
});

test("thresholds in the balance tab change the result without touching the document", () => {
  const ctx = context();
  const ui = balanceUi(ctx.view);
  let root = balanceView(ctx);
  const total = root.findAll((node) => node.className === "warning-item").length;
  const field = root.findAll((node) => node.tagName === "input" && node.type === "number" && Number(node.value) === BALANCE_RULES.minLevelShare)[0];
  field.value = "0";
  field.dispatch("change");
  assert.equal(ui.rules.minLevelShare, 0);
  root = balanceView(ctx);
  assert.equal(root.findAll((node) => node.className === "warning-item").length, total - upgradeWarnings(game).length);
  const days = root.findAll((node) => node.tagName === "input" && node.type === "number" && Number(node.value) === BALANCE_RULES.bossFirstDay)[0];
  days.value = "0";
  days.dispatch("change");
  assert.equal(ui.rules.bossFirstDay, BALANCE_RULES.bossFirstDay);
  root.findAll((node) => node.tagName === "button" && node.text() === "balance.resetRules")[0].dispatch("click");
  assert.deepEqual(ui.rules, BALANCE_RULES);
  assert.ok(!ctx.store.canUndo());
  ctx.view.collapsed.add("balance:upgrades");
  root = balanceView(ctx);
  assert.equal(root.findAll((node) => node.className === "warning-item").length, total - upgradeWarnings(game).length);
});
