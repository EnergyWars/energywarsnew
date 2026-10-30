import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { game, fresh } from "./data.js";
import { installFakeDom } from "./fakeDom.js";
import { LOOKS, SHAPES, lookKey, lookOf, paintEnemy, paintMonster } from "../../web/js/enemyPainter.js";
import { reduction, mitigate, armorForReduction, curveRows, example, armorEntries, setArmor } from "../../web/js/armor.js";
import { buffFactor, statAt, monsterRows, monsterRow, editMonster, columnView, setBase, setBuff, setFlag, filterMonsters, editTarget } from "../../web/js/monsters.js";
import { MONSTER_METRICS, MONSTER_KEYS, visibleMonsterColumns, cellTip, editStatOf, metricFormat } from "../../web/js/views/monsterMetrics.js";
import { strengthSeries, strengthDetail, strengthViews, pendingEnemy, applyDraft, discardDraft } from "../../web/js/views/monsterStrength.js";
import { armorSeries, armorDetail, ARMOR_COLUMNS, filterEntries } from "../../web/js/views/armorView.js";
import { extraWavesAt, waveComposition, dayComposition, roundSummary, addExtra, removeExtra, spawnerCounts, waveMix, fallbackKind, roundWaves, extraShare } from "../../web/js/waves.js";
import { validateLevels } from "../../web/js/levels.js";
import { create } from "../../web/js/store.js";

installFakeDom();

const read = (code) => JSON.parse(readFileSync(new URL(`../../web/i18n/${code}.json`, import.meta.url), "utf8"));
const near = (actual, expected, message = "") => assert.ok(Math.abs(actual - expected) <= 1e-6 + Math.abs(expected) * 1e-4, `${message} ${actual} vs ${expected}`);
const kinds = Object.keys(game.enemies);
const config = game.armor;

function recorder() {
  const log = [];
  const ctx = new Proxy({}, {
    get: (_, name) => (name === "log" ? log : (...args) => { log.push([name, ...args.map((arg) => (typeof arg === "number" ? Math.round(arg * 1000) / 1000 : arg))]); }),
    set: (_, name, value) => { log.push([`set:${name}`, value]); return true; },
  });
  return ctx;
}

function signature(look, flags = {}, night = 0) {
  const ctx = recorder();
  paintEnemy(ctx, look, flags, 0, 0, 20, 0.3, 1.25, night);
  return JSON.stringify(ctx.log);
}

test("every look paints on a fake canvas and all looks are different", () => {
  const seen = new Map();
  for (const [key, look] of Object.entries(LOOKS)) {
    assert.ok(SHAPES.includes(look.shape), key);
    const sig = signature(look);
    assert.ok(sig.length > 100, key);
    assert.ok(!seen.has(sig), `${key} equals ${seen.get(sig)}`);
    seen.set(sig, key);
  }
  assert.equal(seen.size, Object.keys(LOOKS).length);
});

test("all enemies of the data set have a look", () => {
  assert.equal(kinds.length, 30);
  for (const kind of kinds) {
    assert.ok(LOOKS[game.enemies[kind].look], kind);
    assert.equal(lookKey(game.enemies, kind), game.enemies[kind].look);
    const ctx = recorder();
    paintMonster(ctx, game.enemies, kind, 0, 0, game.enemies[kind].radius, 0, 0.5, 0);
    assert.ok(ctx.log.length > 5, kind);
  }
});

test("unknown looks fall back to the crawler and boss ring, night glow and air shadow change the drawing", () => {
  assert.equal(lookKey({ x: { look: "nope" } }, "x"), "crawler");
  assert.equal(lookOf({}, "unknown"), LOOKS.crawler);
  const look = LOOKS.crawler;
  assert.notEqual(signature(look), signature(look, { boss: true }));
  assert.notEqual(signature(look), signature(look, { air: true }));
  assert.notEqual(signature(look, {}, 0), signature(look, {}, 1));
  assert.notEqual(signature(look, {}, 0), signature(look, {}, 0.1) === signature(look, {}, 0) ? "" : "x");
});

test("animation changes the drawing over time", () => {
  for (const key of ["crawler", "wasp", "nightwing", "drone"]) {
    const a = recorder();
    const b = recorder();
    paintEnemy(a, LOOKS[key], {}, 0, 0, 20, 0, 0, 0);
    paintEnemy(b, LOOKS[key], {}, 0, 0, 20, 0, 0.37, 0);
    assert.notEqual(JSON.stringify(a.log), JSON.stringify(b.log), key);
  }
});

test("the look table matches the GDScript painter", () => {
  const path = new URL("../../../../src/ui/enemy_painter.gd", import.meta.url);
  if (!existsSync(path)) return;
  const text = readFileSync(path, "utf8");
  const entries = [...text.matchAll(/^\t"(\w+)": \{"shape": SHAPE_(\w+)/gm)].map((match) => [match[1], match[2].toLowerCase()]);
  assert.equal(entries.length, Object.keys(LOOKS).length);
  for (const [key, shape] of entries) assert.equal(LOOKS[key]?.shape, shape, key);
  const gdKeys = new Map([...text.matchAll(/^\t"(\w+)": \{(.*)\}/gm)].map((match) => [match[1], match[2]]));
  for (const [key, look] of Object.entries(LOOKS)) {
    const line = gdKeys.get(key);
    for (const field of ["legs", "plates", "spikes", "horns", "rotors", "barrels", "wings", "stripes"]) {
      const match = line.match(new RegExp(`"${field}": (\\d+)`));
      assert.equal(look[field], match ? Number(match[1]) : undefined, `${key}.${field}`);
    }
    assert.equal(Boolean(look.fangs), line.includes('"fangs": true'), key);
    const scale = line.match(/"scale": ([\d.]+)/);
    assert.equal(look.scale, scale ? Number(scale[1]) : undefined, `${key}.scale`);
  }
});

test("armor reduction follows the game formula", () => {
  const cfg = { constant: 100, max_reduction: 0.9, min_damage: 1 };
  assert.equal(reduction(0, cfg), 0);
  assert.equal(reduction(-5, cfg), 0);
  near(reduction(100, cfg), 0.5);
  near(reduction(300, cfg), 0.75);
  near(reduction(10000, cfg), 0.9);
  near(mitigate(20, 100, cfg), 10);
  near(mitigate(1.5, 5000, cfg), 1);
  near(mitigate(0.5, 5000, cfg), 0.5);
  assert.equal(mitigate(0, 100, cfg), 0);
  assert.equal(mitigate(10, 0, cfg), 10);
});

test("armor for a wanted reduction inverts the formula", () => {
  const cfg = { constant: 100, max_reduction: 0.9, min_damage: 1 };
  near(armorForReduction(0.5, cfg), 100);
  near(reduction(armorForReduction(0.6, cfg), cfg), 0.6);
  assert.equal(armorForReduction(0.9, cfg), null);
  assert.equal(armorForReduction(-0.1, cfg), null);
  assert.equal(armorForReduction(0, cfg), 0);
});

test("the armor curve covers 0 to 300 and chart equals table values", () => {
  const rows = curveRows(config);
  assert.equal(rows[0].armor, 0);
  assert.equal(rows[rows.length - 1].armor, 300);
  const series = armorSeries(rows);
  assert.deepEqual(series.map((item) => item.key), ARMOR_COLUMNS.map((column) => column.key));
  rows.forEach((row, index) => {
    for (const item of series) assert.equal(item.values[index], row[item.key]);
    const detail = armorDetail(rows, index);
    assert.equal(detail.length, 1 + ARMOR_COLUMNS.length);
    near(row.reduction + row.taken, 100);
    near(row.durability, 1 / (1 - row.reduction / 100));
  });
  const capped = curveRows({ constant: 10, max_reduction: 0.5, min_damage: 0 });
  assert.ok(capped.some((row) => row.capped));
  assert.ok(capped.every((row) => row.reduction <= 50 + 1e-9));
});

test("armor example reports the minimum damage floor", () => {
  const cfg = { constant: 100, max_reduction: 0.9, min_damage: 1 };
  const plain = example(cfg, 100, 20);
  near(plain.result, 10);
  assert.equal(plain.floored, false);
  const floored = example(cfg, 5000, 1.5);
  near(floored.result, 1);
  assert.equal(floored.floored, true);
});

test("armor entries list buildings and monsters and can be edited", () => {
  const doc = fresh();
  const entries = armorEntries(doc);
  assert.equal(entries.length, doc.buildings.length + kinds.length);
  assert.ok(entries.some((entry) => entry.type === "building" && entry.id === "core"));
  assert.ok(setArmor(doc, "building", "core", 33));
  assert.equal(doc.buildings.find((entry) => entry.id === "core").armor, 33);
  assert.ok(setArmor(doc, "monster", "crawler", 12));
  assert.equal(doc.enemies.crawler.armor, 12);
  assert.equal(setArmor(doc, "monster", "crawler", -1), false);
  assert.equal(setArmor(doc, "monster", "crawler", Number.NaN), false);
  assert.equal(setArmor(doc, "monster", "ghost", 1), false);
  assert.equal(setArmor(doc, "building", "ghost", 1), false);
  assert.equal(filterEntries(entries, "core", (entry) => entry.id).length, 1);
  assert.equal(filterEntries(entries, "  ", (entry) => entry.id).length, entries.length);
});

test("buffs combine night and level like Formulas.enemy_buff", () => {
  const enemy = { hp: 100, damage: 10, speed: 50, armor: 20, cooldown: 2, bounty: 7, buffs: { night: { hp: 0.5, damage: 0, speed: 0, armor: 1 }, level: { hp: 0.1, damage: 0, speed: 0, armor: -0.2 } } };
  near(buffFactor(enemy, "hp", false, 0), 1);
  near(buffFactor(enemy, "hp", true, 0), 1.5);
  near(buffFactor(enemy, "hp", false, 3), 1.3);
  near(buffFactor(enemy, "hp", true, 3), 1.5 * 1.3);
  near(buffFactor(enemy, "armor", false, 10), 0);
  near(statAt(enemy, "armor", true, 2), 20 * 2 * 0.6);
  assert.equal(buffFactor({ hp: 1 }, "hp", true, 4), 1);
  near(buffFactor(enemy, "hp", false, -3), 1);
});

test("monster rows hold every value of a level and time of day", () => {
  const enemy = { hp: 100, damage: 10, speed: 50, armor: 100, cooldown: 2, bounty: 7, buffs: { night: { hp: 0.5, damage: 0.2, speed: 0, armor: 0 }, level: { hp: 0.1, damage: 0, speed: 0, armor: 0 } } };
  const rows = monsterRows(enemy, config, 3);
  assert.equal(rows.length, 6);
  assert.deepEqual(rows.map((row) => row.index), [0, 1, 2, 3, 4, 5]);
  const row = rows[3];
  assert.equal(row.level, 1);
  assert.equal(row.night, true);
  near(row.hp, 100 * 1.5 * 1.1);
  near(row.damage, 12);
  near(row.reduction, 50);
  near(row.effectiveHp, 165 * 2);
  near(row.dps, 6);
  assert.equal(row.bounty, 7);
  assert.deepEqual(monsterRows(enemy, config, 0).length, 2);
  near(monsterRow(enemy, config, 0, false).hp, 100);
});

test("every cell of every monster can be edited and the edited value is reached", () => {
  const keys = ["hp", "damage", "speed", "armor", "reduction", "effectiveHp", "dps", "bounty"];
  for (const kind of kinds) {
    const enemy = game.enemies[kind];
    const snapshot = JSON.stringify(enemy);
    const rows = monsterRows(enemy, config, 4);
    for (const row of rows) {
      for (const key of keys) {
        let wanted = row[key] * 1.37 + (key === "bounty" ? 1 : 0.5);
        if (key === "reduction") wanted = Math.min(row.reduction * 1.2 + 1, 80);
        if (key === "bounty") wanted = Math.round(wanted);
        const next = editMonster(enemy, config, row, key, wanted);
        const needsArmor = ["armor", "reduction"].includes(key);
        if (needsArmor && !(enemy.armor > 0) && (row.night || row.level > 0)) {
          assert.equal(next, null, `${kind} ${key} ${row.index}`);
          continue;
        }
        assert.ok(next, `${kind} ${key} ${row.index}`);
        const after = monsterRows(next, config, 4)[row.index];
        near(after[key], wanted, `${kind} ${key} row ${row.index}`);
      }
    }
    assert.equal(JSON.stringify(enemy), snapshot);
  }
});

test("a cell edit changes exactly the documented parameter", () => {
  const enemy = JSON.parse(JSON.stringify(game.enemies.crawler));
  const rows = monsterRows(enemy, config, 5);
  const base = editMonster(enemy, config, rows[0], "hp", 100);
  assert.equal(base.hp, 100);
  assert.deepEqual(base.buffs, enemy.buffs);
  const level = editMonster(enemy, config, rows[6], "hp", enemy.hp * 1.5);
  assert.equal(level.hp, enemy.hp);
  assert.deepEqual(level.buffs.night, enemy.buffs.night);
  near(level.buffs.level.hp, 0.5 / 3);
  const night = editMonster(enemy, config, rows[7], "hp", enemy.hp * 2);
  assert.equal(night.hp, enemy.hp);
  assert.deepEqual(night.buffs.level, enemy.buffs.level);
  near(night.buffs.night.hp, 2 / (1 + enemy.buffs.level.hp * 3) - 1);
  assert.deepEqual([editTarget(rows[0]), editTarget(rows[1]), editTarget(rows[2]), editTarget(rows[3])], ["base", "night", "level", "night"]);
});

test("derived columns edit their source parameter", () => {
  const enemy = { hp: 100, damage: 10, speed: 50, armor: 100, cooldown: 2, bounty: 7, buffs: { night: { hp: 0, damage: 0, speed: 0, armor: 0 }, level: { hp: 0, damage: 0, speed: 0, armor: 0 } } };
  const row = monsterRows(enemy, config, 1)[0];
  assert.equal(editMonster(enemy, config, row, "dps", 20).damage, 40);
  near(editMonster(enemy, config, row, "reduction", 75).armor, 300);
  near(editMonster(enemy, config, row, "effectiveHp", 400).hp, 200);
  assert.equal(editMonster(enemy, config, row, "bounty", 9.6).bounty, 10);
  assert.equal(editStatOf("reduction"), "armor");
  assert.equal(editStatOf("effectiveHp"), "hp");
  assert.equal(editStatOf("dps"), "damage");
  assert.equal(editStatOf("speed"), "speed");
});

test("invalid cell edits are rejected", () => {
  const enemy = JSON.parse(JSON.stringify(game.enemies.beetle));
  const rows = monsterRows(enemy, config, 3);
  const bad = [[0, "hp", 0], [0, "hp", -3], [0, "speed", 0], [2, "hp", 0], [1, "hp", 0], [0, "hp", Number.NaN], [0, "reduction", 90], [0, "reduction", -1], [0, "effectiveHp", 0], [0, "dps", -1], [0, "bounty", -2], [0, "level", 3], [0, "unknown", 3]];
  for (const [index, key, value] of bad) assert.equal(editMonster(enemy, config, rows[index], key, value), null, `${key} ${value}`);
  assert.ok(editMonster(enemy, config, rows[0], "damage", 0));
  assert.ok(editMonster(enemy, config, rows[0], "armor", 0));
  assert.equal(editMonster({ ...enemy, armor: 0 }, config, rows[2], "armor", 5), null);
});

test("factor columns convert between values and multiples of the base", () => {
  const enemy = JSON.parse(JSON.stringify(game.enemies.beetle));
  const view = columnView("hp", enemy, config, "factor");
  near(view.show(enemy.hp * 2), 2);
  near(view.parse(2), enemy.hp * 2);
  assert.equal(columnView("hp", enemy, config, "absolute").converted, false);
  assert.equal(columnView("bounty", enemy, config, "factor").converted, false);
  assert.equal(columnView("reduction", enemy, config, "factor").converted, false);
  const none = columnView("armor", { ...enemy, armor: 0 }, config, "factor");
  assert.equal(none.blocked, true);
  assert.equal(columnView("armor", { ...enemy, armor: 0 }, config, "absolute").blocked, false);
});

test("base value setters validate and flags are optional keys", () => {
  const enemy = JSON.parse(JSON.stringify(game.enemies.crawler));
  assert.ok(setBase(enemy, "hp", 50));
  assert.equal(setBase(enemy, "hp", 0), false);
  assert.equal(setBase(enemy, "cooldown", -1), false);
  assert.equal(setBase(enemy, "damage", -1), false);
  assert.equal(setBase(enemy, "armor", Number.NaN), false);
  assert.ok(setBase(enemy, "bounty", 3.6));
  assert.equal(enemy.bounty, 4);
  assert.ok(setBuff(enemy, "night", "hp", 0.25));
  assert.equal(enemy.buffs.night.hp, 0.25);
  assert.equal(setBuff(enemy, "night", "hp", -1), false);
  setFlag(enemy, "boss", true);
  assert.equal(enemy.boss, true);
  setFlag(enemy, "boss", false);
  assert.equal("boss" in enemy, false);
  const blank = {};
  assert.ok(setBuff(blank, "level", "speed", 0.1));
  assert.equal(blank.buffs.level.speed, 0.1);
});

test("filters combine class, faction, kind and search", () => {
  const all = filterMonsters(game.enemies, game.names, {});
  assert.equal(all.length, 30);
  const air = filterMonsters(game.enemies, game.names, { klass: "air" });
  assert.ok(air.length > 0 && air.every((kind) => game.enemies[kind].class === "air"));
  const bosses = filterMonsters(game.enemies, game.names, { flavor: "boss", kind: "boss" });
  assert.ok(bosses.length >= 10 && bosses.every((kind) => game.enemies[kind].boss));
  assert.equal(filterMonsters(game.enemies, game.names, { kind: "normal" }).length, 30 - bosses.length);
  const nest = filterMonsters(game.enemies, game.names, { faction: "nest" });
  assert.ok(nest.every((kind) => game.enemies[kind].faction === "nest"));
  assert.ok(filterMonsters(game.enemies, game.names, { kind: "night" }).every((kind) => game.enemies[kind].nocturnal));
  assert.ok(filterMonsters(game.enemies, game.names, { kind: "day" }).every((kind) => !game.enemies[kind].nocturnal));
  assert.deepEqual(filterMonsters(game.enemies, game.names, { query: "WASP" }), ["wasp"]);
  assert.deepEqual(filterMonsters(game.enemies, game.names, { query: "zzz" }), []);
  assert.deepEqual(filterMonsters(game.enemies, game.names, { query: "stach" }, (kind) => (kind === "wasp" ? "Stachler" : kind)), ["wasp"]);
});

function context(doc = fresh()) {
  const store = create(doc, game);
  const ctx = { original: game, names: game.names, store, view: { collapsed: new Set() }, renders: 0, render() { this.renders += 1; }, toast() {} };
  Object.defineProperty(ctx, "doc", { get: () => store.state.document });
  return ctx;
}

test("chart series, tooltip and table show the same values", async () => {
  const { strengthSection } = await import("../../web/js/views/monsterStrength.js");
  for (const mode of ["absolute", "factor"]) {
    const ctx = context();
    ctx.view.monsterUi = undefined;
    const { monsterUi } = await import("../../web/js/views/monsterState.js");
    monsterUi(ctx.view).mode = mode;
    const kind = "beetle";
    const root = strengthSection(ctx, kind);
    const enemy = ctx.doc.enemies[kind];
    const rows = monsterRows(enemy, ctx.doc.armor, ctx.doc.levels.length);
    const views = strengthViews(enemy, ctx.doc.armor, mode);
    const series = strengthSeries(rows, views, mode);
    assert.deepEqual(series.map((item) => item.key), MONSTER_KEYS);
    const body = root.find((node) => node.tagName === "tbody");
    assert.equal(body.children.length, rows.length);
    rows.forEach((row, index) => {
      const inputs = body.children[index].findAll((node) => node.tagName === "input");
      assert.equal(inputs.length, MONSTER_KEYS.length);
      const detail = strengthDetail(rows, views, mode, index);
      assert.equal(detail.length, MONSTER_KEYS.length);
      MONSTER_KEYS.forEach((key, position) => {
        near(Number(inputs[position].value), series[position].values[index], `${mode} ${key} ${index}`);
        const metric = MONSTER_METRICS[position];
        assert.equal(detail[position][1], metricFormat(metric, mode)(series[position].values[index]));
        assert.equal(detail[position][0], `monsters.col.${key}`);
      });
    });
    const legend = root.find((node) => node.className === "legend");
    assert.equal(legend.children.length, MONSTER_KEYS.length);
    assert.equal(root.findAll((node) => node.tagName === "polyline").length, MONSTER_KEYS.length);
  }
});

test("hiding a series removes its line and its column", async () => {
  const { strengthSection } = await import("../../web/js/views/monsterStrength.js");
  const { monsterUi } = await import("../../web/js/views/monsterState.js");
  const ctx = context();
  monsterUi(ctx.view).hidden.add("speed");
  const root = strengthSection(ctx, "beetle");
  assert.equal(root.findAll((node) => node.tagName === "polyline").length, MONSTER_KEYS.length - 1);
  assert.equal(root.findAll((node) => node.tagName === "th").length, MONSTER_KEYS.length);
  assert.deepEqual(visibleMonsterColumns(new Set(["hp"])).map((column) => column.key).slice(0, 2), ["row", "damage"]);
});

test("cell edits create a draft that only applies on request and recalculates dependents", async () => {
  const { strengthSection } = await import("../../web/js/views/monsterStrength.js");
  const ctx = context();
  const kind = "beetle";
  const before = JSON.stringify(ctx.doc.enemies[kind]);
  let root = strengthSection(ctx, kind);
  const cellInput = (name, row) => root.find((node) => node.tagName === "input" && node.attributes["aria-label"] === `monsters.col.${name} monsters.level ${row}`);
  const target = root.findAll((node) => node.tagName === "input" && node.attributes["aria-label"]?.startsWith("monsters.col.hp"))[5];
  assert.ok(target);
  target.value = "500";
  target.dispatch("change");
  assert.equal(JSON.stringify(ctx.doc.enemies[kind]), before);
  const draft = pendingEnemy(ctx, kind);
  assert.ok(draft);
  const index = 5;
  near(monsterRows(draft, ctx.doc.armor, ctx.doc.levels.length)[index].hp, 500);
  root = strengthSection(ctx, kind);
  const rows = monsterRows(draft, ctx.doc.armor, ctx.doc.levels.length);
  const hpInputs = root.findAll((node) => node.tagName === "input" && node.attributes["aria-label"]?.startsWith("monsters.col.hp"));
  near(Number(hpInputs[index].value), 500);
  const effective = root.findAll((node) => node.tagName === "input" && node.attributes["aria-label"]?.startsWith("monsters.col.effectiveHp"));
  near(Number(effective[index].value), rows[index].effectiveHp);
  assert.ok(root.findAll((node) => node.tagName === "tr" && node.className === "changed").length > 0);
  const apply = root.find((node) => node.tagName === "button" && node.text() === "values.apply");
  assert.equal(apply.disabled, false);
  apply.dispatch("click");
  assert.equal(pendingEnemy(ctx, kind), null);
  assert.notEqual(JSON.stringify(ctx.doc.enemies[kind]), before);
  near(monsterRows(ctx.doc.enemies[kind], ctx.doc.armor, ctx.doc.levels.length)[index].hp, 500);
  assert.ok(ctx.store.canUndo());
  assert.equal(cellInput("zzz", 1), null);
});

test("discard drops the draft and invalid input is reported", async () => {
  const { strengthSection } = await import("../../web/js/views/monsterStrength.js");
  const { monsterUi } = await import("../../web/js/views/monsterState.js");
  const ctx = context();
  const root = strengthSection(ctx, "beetle");
  const hp = root.findAll((node) => node.tagName === "input" && node.attributes["aria-label"]?.startsWith("monsters.col.hp"))[0];
  hp.value = "250";
  hp.dispatch("change");
  assert.ok(pendingEnemy(ctx, "beetle"));
  discardDraft(ctx, "beetle");
  assert.equal(pendingEnemy(ctx, "beetle"), null);
  hp.value = "0";
  hp.dispatch("change");
  assert.equal(pendingEnemy(ctx, "beetle"), null);
  assert.equal(monsterUi(ctx.view).notice, "monsters.rejected");
  hp.value = "abc";
  hp.dispatch("change");
  assert.equal(applyDraft(ctx, "beetle"), false);
});

test("a stale draft is dropped when the base values change", async () => {
  const { setDraftEnemy } = await import("../../web/js/views/monsterStrength.js");
  const ctx = context();
  setDraftEnemy(ctx, "beetle", ctx.doc.enemies.beetle);
  assert.ok(pendingEnemy(ctx, "beetle"));
  ctx.store.update((doc) => { doc.enemies.beetle.hp += 1; });
  assert.equal(pendingEnemy(ctx, "beetle"), null);
});

test("every cell tip explains what the cell changes", () => {
  const rows = monsterRows(game.enemies.beetle, config, 3);
  for (const row of rows) {
    for (const key of MONSTER_KEYS) {
      const tip = cellTip(key, row);
      assert.ok(tip.includes(`monsters.desc.${key}`));
      if (key !== "bounty") assert.ok(tip.includes(row.night ? "monsters.edit.night" : row.level === 0 ? "monsters.edit.base" : "monsters.edit.level"));
    }
  }
  assert.ok(cellTip("dps", rows[0]).includes("monsters.edit.via.dps"));
  assert.ok(cellTip("bounty", rows[0]).includes("monsters.edit.bounty"));
});

test("the monster tab renders catalog, details and the other sections", async () => {
  const { monstersView, visibleKinds } = await import("../../web/js/views/monstersView.js");
  const { monsterUi } = await import("../../web/js/views/monsterState.js");
  const ctx = context();
  let root = monstersView(ctx);
  assert.equal(root.findAll((node) => node.className === "monster-card" || node.className === "monster-card selected").length, 30);
  assert.equal(root.findAll((node) => node.tagName === "canvas").length >= 31, true);
  const ui = monsterUi(ctx.view);
  assert.equal(ui.kind, kinds[0]);
  const card = root.findAll((node) => node.className === "monster-card")[3];
  card.dispatch("click");
  assert.equal(ui.kind, kinds[4]);
  ui.klass = "air";
  assert.ok(visibleKinds(ctx).every((kind) => ctx.doc.enemies[kind].class === "air"));
  root = monstersView(ctx);
  assert.equal(root.findAll((node) => /^monster-card/.test(node.className)).length, visibleKinds(ctx).length);
  ui.klass = "all";
  ui.query = "nomatch";
  root = monstersView(ctx);
  assert.ok(root.find((node) => node.className === "empty"));
  ui.query = "";
  const hp = ctx.doc.enemies[ui.kind].hp;
  root = monstersView(ctx);
  const field = root.findAll((node) => node.tagName === "input" && node.type === "number" && Number(node.value) === hp)[0];
  field.value = String(hp + 5);
  field.dispatch("change");
  assert.equal(ctx.doc.enemies[ui.kind].hp, hp + 5);
  const reachField = monstersView(ctx);
  const reach = ctx.doc.enemies[ui.kind].reach;
  const reachInput = reachField.findAll((node) => node.tagName === "input" && node.type === "number" && Number(node.value) === Math.round((reach / 56) * 10000) / 10000)[0];
  assert.ok(reachInput);
  reachInput.value = "2";
  reachInput.dispatch("change");
  assert.equal(ctx.doc.enemies[ui.kind].reach, 112);
  for (const section of ["armor", "waves"]) {
    ui.section = section;
    assert.ok(monstersView(ctx).findAll((node) => node.tagName === "section").length > 2, section);
  }
});

test("buff and flag fields edit the monster", async () => {
  const { monstersView } = await import("../../web/js/views/monstersView.js");
  const { monsterUi } = await import("../../web/js/views/monsterState.js");
  const ctx = context();
  const ui = monsterUi(ctx.view);
  ui.kind = "crawler";
  let root = monstersView(ctx);
  const checks = root.findAll((node) => node.tagName === "input" && node.type === "checkbox");
  assert.equal(checks.length, 3);
  checks[0].checked = true;
  checks[0].dispatch("change");
  assert.equal(ctx.doc.enemies.crawler.boss, true);
  root = monstersView(ctx);
  const buff = root.findAll((node) => node.tagName === "input" && node.type === "number" && node.parentNode.text().startsWith("monsters.col.hp (%)"))[0];
  near(Number(buff.value), ctx.doc.enemies.crawler.buffs.night.hp * 100);
  buff.value = "30";
  buff.dispatch("change");
  near(ctx.doc.enemies.crawler.buffs.night.hp, 0.3);
  const selects = monstersView(ctx).findAll((node) => node.tagName === "select");
  assert.ok(selects.length >= 3);
});

test("the armor view edits the constants and the armor of buildings and monsters", async () => {
  const { armorView } = await import("../../web/js/views/armorView.js");
  const ctx = context();
  const root = armorView(ctx);
  const inputs = root.findAll((node) => node.tagName === "input" && node.type === "number");
  const constant = inputs.find((node) => Number(node.value) === ctx.doc.armor.constant);
  constant.value = "150";
  constant.dispatch("change");
  assert.equal(ctx.doc.armor.constant, 150);
  const refreshed = armorView(ctx);
  const cap = refreshed.findAll((node) => node.tagName === "input" && node.type === "number").find((node) => Number(node.value) === 90);
  cap.value = "80";
  cap.dispatch("change");
  near(ctx.doc.armor.max_reduction, 0.8);
  cap.value = "100";
  cap.dispatch("change");
  near(ctx.doc.armor.max_reduction, 0.8);
  const table = armorView(ctx).find((node) => node.tagName === "table" && node.className === "overview armor-all");
  assert.equal(table.find((node) => node.tagName === "tbody").children.length, ctx.doc.buildings.length + 30);
  const first = table.find((node) => node.tagName === "tbody").children[0].find((node) => node.tagName === "input");
  first.value = "77";
  first.dispatch("change");
  assert.equal(ctx.doc.buildings[0].armor, 77);
  const curve = armorView(ctx).find((node) => node.className === "overview armor-curve");
  assert.equal(curve.find((node) => node.tagName === "tbody").children.length, 31);
});

const dayLevel = () => ({ day: 40, night: 30, structures: [["nest", [0.5, 0.1]], ["nest", [0.2, 0.1]], ["camp", [0.8, 0.1]], ["turret", [0.5, 0.5]]], waves: { interval: 9, base: 1.3, ramp: 1.5, night: 1.2, growth: 0.4, roster: [["crawler", 0, 1], ["spitter", 1, 0.3], ["soldier", 0, 1]], night_roster: [["stalker", 0, 1]] } });

test("extra waves fire with the first wave of the matching section like Formulas.extra_waves", () => {
  const level = { ...dayLevel(), extra_waves: [{ day: 2, night: false, kind: "wasp", count: 3 }, { day: 3, night: true, kind: "nightwing", count: 2 }] };
  const nightIndex = roundWaves(level, 1).find((wave) => wave.night).index;
  assert.ok(nightIndex > 0);
  assert.equal(extraWavesAt(level, 2, 0).length, 1);
  assert.equal(extraWavesAt(level, 2, 1).length, 0);
  assert.equal(extraWavesAt(level, 1, 0).length, 0);
  assert.equal(extraWavesAt(level, 2, nightIndex).length, 0);
  assert.equal(extraWavesAt(level, 3, nightIndex).length, 1);
  assert.equal(extraWavesAt(level, 3, nightIndex + 1).length, 0);
  assert.equal(extraWavesAt(level, 3, 0).length, 0);
  assert.deepEqual(extraWavesAt({ ...level, extra_waves: undefined }, 2, 0), []);
});

test("extra entries can be added and removed", () => {
  const level = dayLevel();
  addExtra(level, { kind: "wasp", day: 4 });
  addExtra(level, { kind: "gnat" });
  assert.deepEqual(level.extra_waves[0], { day: 4, night: false, kind: "wasp", count: 1 });
  assert.equal(level.extra_waves.length, 2);
  removeExtra(level, 0);
  assert.equal(level.extra_waves[0].kind, "gnat");
  removeExtra(level, 0);
  assert.equal("extra_waves" in level, false);
});

test("the composition splits waves by spawner faction and roster weights", () => {
  const level = dayLevel();
  assert.deepEqual(spawnerCounts(level), { nest: 2, camp: 1 });
  const waves = waveComposition(level, game.enemies, 2);
  assert.ok(waves.length > 3);
  for (const wave of waves) {
    assert.equal(wave.groups.length, 2);
    for (const group of wave.groups) near(group.items.reduce((sum, item) => sum + item.expected, 0), wave.units);
  }
  const day = waves.find((wave) => !wave.night);
  const nest = day.groups.find((group) => group.faction === "nest");
  assert.deepEqual(nest.items.map((item) => item.kind), ["crawler", "spitter"]);
  near(nest.items[1].share, 0.3 / 1.3);
  assert.deepEqual(day.groups.find((group) => group.faction === "camp").items.map((item) => item.kind), ["soldier"]);
  const firstRound = waveComposition(level, game.enemies, 1)[0].groups.find((group) => group.faction === "nest");
  assert.deepEqual(firstRound.items.map((item) => item.kind), ["crawler"]);
  const night = waves.find((wave) => wave.night).groups.find((group) => group.faction === "camp");
  assert.equal(night.items[0].fallback, true);
  assert.equal(game.enemies[night.items[0].kind].faction, "camp");
  assert.equal(game.enemies[night.items[0].kind].nocturnal, true);
});

test("fallback and mix helpers behave like the spawn director", () => {
  assert.equal(game.enemies[fallbackKind(game.enemies, "nest", false)].nocturnal ?? false, false);
  assert.equal(game.enemies[fallbackKind(game.enemies, "nest", true)].nocturnal, true);
  assert.equal(fallbackKind({}, "nest", true), null);
  assert.deepEqual(waveMix([], {}, 1, "nest", false), []);
  assert.deepEqual(waveMix([["crawler", 5, 1]], game.enemies, 1, "nest", false).map((item) => item.fallback), [true]);
});

test("the day composition adds extras and the strength summary counts them", () => {
  const level = { ...dayLevel(), extra_waves: [{ day: 2, night: false, kind: "behemoth", count: 4 }] };
  const day = dayComposition(level, game.enemies, 2);
  const extra = day.find((entry) => entry.faction === "extra");
  assert.deepEqual([extra.kind, extra.extra], ["behemoth", 4]);
  assert.equal(dayComposition(level, game.enemies, 1).some((entry) => entry.faction === "extra"), false);
  const plain = roundSummary({ ...level, extra_waves: [] }, 2, game.enemies);
  const withExtra = roundSummary(level, 2, game.enemies);
  const perNest = 4 / spawnerCounts(level).nest;
  assert.equal(withExtra.units, plain.units + perNest);
  near(withExtra.totalHp - plain.totalHp, perNest * game.enemies.behemoth.hp * plain.hpScale);
  near(withExtra.totalBounty - plain.totalBounty, perNest * game.enemies.behemoth.bounty * plain.bountyScale);
  assert.equal(roundSummary(level, 1, game.enemies).units, roundSummary({ ...level, extra_waves: [] }, 1, game.enemies).units);
});

test("the strength summary counts extras only when their section has a wave and splits them per spawner", () => {
  const noNight = { ...dayLevel(), day: 40, night: 0.5, extra_waves: [{ day: 1, night: true, kind: "stalker", count: 6 }] };
  assert.equal(roundWaves(noNight, 1).some((wave) => wave.night), false);
  assert.equal(roundSummary(noNight, 1, game.enemies).units, roundSummary({ ...noNight, extra_waves: [] }, 1, game.enemies).units);
  const camp = { ...dayLevel(), extra_waves: [] };
  assert.equal(extraShare(camp, game.enemies, { kind: "soldier", count: 6 }), 6);
  assert.equal(extraShare(camp, game.enemies, { kind: "crawler", count: 6 }), 3);
  assert.equal(extraShare({ ...camp, structures: [["camp", [0.5, 0.1]], ["camp", [0.3, 0.1]]] }, game.enemies, { kind: "crawler", count: 6 }), 3);
  assert.equal(extraShare({ ...camp, structures: [] }, game.enemies, { kind: "crawler", count: 6 }), 0);
});

test("extra waves validate like the backend", () => {
  const good = fresh().levels;
  good[0].extra_waves = [{ day: 2, night: true, kind: "wasp", count: 3 }];
  assert.deepEqual(validateLevels(good, kinds), []);
  const bad = [{ day: 0, night: true, kind: "wasp", count: 3 }, { day: 1, night: 1, kind: "wasp", count: 3 }, { day: 1, night: true, kind: "ghost", count: 3 }, { day: 1, night: true, kind: "wasp", count: 0 }, { day: 1, night: true, kind: "wasp", count: 201 }, { day: 1, night: true, kind: "wasp" }, { day: 1, night: true, kind: "wasp", count: 1, x: 1 }, 5];
  for (const entry of bad) {
    good[0].extra_waves = [entry];
    assert.deepEqual(validateLevels(good, kinds).map((error) => error.code), ["EXTRA_WAVE"], JSON.stringify(entry));
  }
  good[0].extra_waves = "x";
  assert.equal(validateLevels(good, kinds)[0].path, "levels.0.extra_waves");
});

test("the waves section edits level, durations and extra monsters", async () => {
  const { monstersView } = await import("../../web/js/views/monstersView.js");
  const { monsterUi } = await import("../../web/js/views/monsterState.js");
  const ctx = context();
  const ui = monsterUi(ctx.view);
  ui.section = "waves";
  let root = monstersView(ctx);
  const level = ctx.doc.levels[0];
  const day = root.findAll((node) => node.tagName === "input" && node.type === "number").find((node) => Number(node.value) === level.day);
  day.value = "123";
  day.dispatch("change");
  assert.equal(ctx.doc.levels[0].day, 123);
  root = monstersView(ctx);
  const add = root.findAll((node) => node.tagName === "button").find((node) => node.text().includes("waves.extraAdd"));
  add.dispatch("click");
  assert.equal(ctx.doc.levels[0].extra_waves.length, 1);
  root = monstersView(ctx);
  const extraCount = root.findAll((node) => node.tagName === "input" && node.type === "number" && node.attributes["step"] === "1").find((node) => Number(node.value) === 1 && node.parentNode.text().includes("waves.f.extraCount"));
  extraCount.value = "5";
  extraCount.dispatch("change");
  assert.equal(ctx.doc.levels[0].extra_waves[0].count, 5);
  root = monstersView(ctx);
  assert.ok(root.findAll((node) => node.tagName === "table" && node.className === "overview wave-days").length === 1);
  assert.ok(root.findAll((node) => node.tagName === "table" && node.className === "overview wave-detail").length === 1);
  assert.ok(root.findAll((node) => node.tagName === "figure").length === 1);
  const remove = root.findAll((node) => node.tagName === "button" && node.attributes["aria-label"] === "action.remove").pop();
  remove.dispatch("click");
  assert.equal("extra_waves" in ctx.doc.levels[0], false);
  ui.level = 3;
  assert.ok(monstersView(ctx));
});

function usedKeys() {
  const keys = new Set();
  const directory = new URL("../../web/js/views/", import.meta.url);
  for (const file of readdirSync(directory).filter((name) => /^monster|^armorView/.test(name))) {
    const text = readFileSync(new URL(file, directory), "utf8");
    for (const match of text.matchAll(/\bt\(\s*"([A-Za-z0-9_.]+)"/g)) if (match[1].includes(".")) keys.add(match[1]);
  }
  return keys;
}

test("every text of the monster tab exists in german and english", () => {
  const dictionary = { de: read("de"), en: read("en") };
  const keys = [...usedKeys()];
  assert.ok(keys.length > 60);
  for (const key of ["hp", "damage", "speed", "armor", "reduction", "effectiveHp", "dps", "bounty"]) keys.push(`monsters.col.${key}`, `monsters.desc.${key}`);
  keys.push("monsters.col.row", "monsters.desc.row");
  for (const key of ["melee", "ranged", "air"]) keys.push(`monsters.badge.class.${key}`, `monsters.badgeDesc.class.${key}`);
  for (const key of ["nest", "camp"]) keys.push(`monsters.badge.faction.${key}`, `monsters.badgeDesc.faction.${key}`, `waves.faction.${key}`);
  for (const key of ["boss", "nocturnal", "sabotage"]) keys.push(`monsters.badge.${key}`, `monsters.badgeDesc.${key}`, `monsters.f.${key}`, `monsters.d.${key}`);
  for (const key of ["hp", "speed", "damage", "cooldown", "reach", "radius", "bounty", "armor", "class", "faction", "look"]) keys.push(`monsters.f.${key}`, `monsters.d.${key}`);
  for (const key of ["all", "normal", "boss", "day", "night"]) keys.push(`monsters.flavor.${key}`);
  for (const key of ["monsters", "armor", "waves"]) keys.push(`monsters.section.${key}`, `monsters.sectionDesc.${key}`);
  for (const scope of ["night", "level"]) keys.push(`monsters.buff.${scope}`, `monsters.buff.${scope}Desc`, `monsters.buff.${scope}Stat`, `monsters.buff.${scope}Armor`);
  for (const key of ["base", "level", "night", "bounty", "via.reduction", "via.effectiveHp", "via.dps"]) keys.push(`monsters.edit.${key}`);
  for (const key of ["armor", "reduction", "taken", "durability"]) keys.push(`armor.col.${key}`, `armor.desc.${key}`);
  for (const key of ["name", "type", "armor", "reduction"]) keys.push(`armor.all.${key}`, `armor.desc.all.${key}`);
  for (const key of ["building", "monster"]) keys.push(`armor.type.${key}`);
  for (const key of ["day", "monsters", "no", "time", "phase", "units", "extras"]) keys.push(`waves.col.${key}`, `waves.desc.${key}`);
  for (const key of ["level", "day", "night", "dayPick", "rounds", "extraDay", "extraPhase", "extraMonster", "extraCount"]) keys.push(`waves.f.${key}`, `waves.d.${key}`);
  keys.push("tab.monsters", "error.EXTRA_WAVE");
  for (const key of keys) {
    assert.ok(dictionary.de[key], `de ${key}`);
    assert.ok(dictionary.en[key], `en ${key}`);
  }
});

test("every monster has a name and a description in both languages", () => {
  for (const kind of kinds) {
    for (const key of [`ENEMY_${kind.toUpperCase()}`, `ENEMY_${kind.toUpperCase()}_DESC`]) {
      assert.ok(game.names[key]?.de, `de ${key}`);
      assert.ok(game.names[key]?.en, `en ${key}`);
    }
  }
});
