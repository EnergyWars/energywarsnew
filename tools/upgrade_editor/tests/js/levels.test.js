import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { game, fresh } from "./data.js";
import { installFakeDom } from "./fakeDom.js";
import { addLevel, duplicateLevel, removeLevel, moveLevel, addRoute, removeRoute, setAutomaticRoutes, uniqueId, validateLevels, validateRoutes, errorsFor, templateLevel } from "../../web/js/levels.js";
import { waveCount, waveTimes, waveTier, hpScale, damageScale, bountyScale, roundWaves, roundSummary, strengthRows, rosterAverage, isNight } from "../../web/js/waves.js";
import { autoPositions, effectiveRoutes, worldTop, toWorld, clampUnit } from "../../web/js/worldLayout.js";
import { mapGeometry, pointerToWorld } from "../../web/js/views/levelMap.js";
import { strengthSeries } from "../../web/js/views/levelWaves.js";
import { levelErrors } from "../../web/js/views/levelsView.js";

installFakeDom();

const kinds = Object.keys(game.enemies);
const read = (code) => JSON.parse(readFileSync(new URL(`../../web/i18n/${code}.json`, import.meta.url), "utf8"));

function doc(count = 4, routes = [[0, 1], [1, 2], [2, 3], [0, 2]]) {
  const copy = fresh();
  copy.levels = copy.levels.slice(0, count);
  copy.routes = routes;
  return copy;
}

test("the shipped levels validate without errors", () => {
  assert.deepEqual(validateLevels(game.levels, kinds), []);
  assert.deepEqual(validateRoutes(game.routes, game.levels.length), []);
  assert.deepEqual(levelErrors(game), []);
});

test("unique ids count upwards from the base without a suffix chain", () => {
  const levels = [{ id: "a" }, { id: "a-2" }, { id: "b" }];
  assert.equal(uniqueId(levels, "a"), "a-3");
  assert.equal(uniqueId(levels, "a-2"), "a-3");
  assert.equal(uniqueId(levels, "b"), "b-2");
});

test("adding a level copies the last one with a new id and automatic world", () => {
  const d = doc();
  const index = addLevel(d);
  assert.equal(index, 4);
  assert.equal(d.levels.length, 5);
  assert.equal(d.levels[4].world, null);
  assert.notEqual(d.levels[4].id, d.levels[3].id);
  assert.deepEqual({ ...d.levels[4], id: "", world: 0 }, { ...d.levels[3], id: "", world: 0 });
  assert.deepEqual(d.routes, [[0, 1], [1, 2], [2, 3], [0, 2]]);
  assert.equal(templateLevel(d.levels).world, null);
  assert.deepEqual(validateLevels(d.levels, kinds), []);
  d.levels[4].terrain.spots.push([[0.5, 0.5], 4, []]);
  assert.notEqual(d.levels[3].terrain.spots.length, d.levels[4].terrain.spots.length);
});

test("duplicating inserts after the source and shifts routes", () => {
  const d = doc();
  const ids = d.levels.map((level) => level.id);
  const index = duplicateLevel(d, 1);
  assert.equal(index, 2);
  assert.equal(d.levels.length, 5);
  assert.equal(d.levels[2].world, null);
  assert.deepEqual(d.levels.map((level) => level.id).filter((id) => ids.includes(id)), ids);
  assert.deepEqual(d.routes, [[0, 1], [1, 3], [3, 4], [0, 3]]);
  assert.deepEqual(validateRoutes(d.routes, 5), []);
  assert.deepEqual(validateLevels(d.levels, kinds), []);
});

test("removing a level drops its routes and reindexes the others", () => {
  const d = doc();
  const index = removeLevel(d, 1);
  assert.equal(d.levels.length, 3);
  assert.equal(index, 1);
  assert.deepEqual(d.routes, [[1, 2], [0, 1]]);
  assert.deepEqual(validateRoutes(d.routes, 3), []);
});

test("removing the last level keeps the selection in range and at least one level stays", () => {
  const d = doc(2, [[0, 1]]);
  assert.equal(removeLevel(d, 1), 0);
  assert.deepEqual(d.routes, []);
  assert.equal(removeLevel(d, 0), 0);
  assert.equal(d.levels.length, 1);
});

test("automatic routes stay automatic through every operation", () => {
  const d = doc(3, null);
  duplicateLevel(d, 0);
  moveLevel(d, 1, 1);
  removeLevel(d, 2);
  addLevel(d);
  assert.equal(d.routes, null);
});

test("moving a level swaps the route endpoints", () => {
  const d = doc();
  const id = d.levels[1].id;
  assert.equal(moveLevel(d, 1, 1), 2);
  assert.equal(d.levels[2].id, id);
  assert.deepEqual(d.routes, [[0, 2], [2, 1], [1, 3], [0, 1]]);
  assert.equal(moveLevel(d, 0, -1), 0);
  assert.equal(moveLevel(d, 3, 1), 3);
  assert.deepEqual(validateRoutes(d.routes, 4), []);
});

test("moving up then down restores the document", () => {
  const d = doc();
  const before = JSON.stringify(d);
  moveLevel(d, 2, -1);
  moveLevel(d, 1, 1);
  assert.equal(JSON.stringify(d), before);
});

test("route editing starts from the effective routes and rejects duplicates", () => {
  const d = doc(4, null);
  const effective = effectiveRoutes(d.routes, 4);
  assert.equal(addRoute(d, 3, 0, effective), true);
  assert.deepEqual(d.routes, [[0, 1], [1, 2], [2, 3], [0, 3]]);
  assert.equal(addRoute(d, 1, 0, effective), false);
  assert.equal(addRoute(d, 2, 2, effective), false);
  removeRoute(d, 2, 1, effective);
  assert.deepEqual(d.routes, [[0, 1], [2, 3], [0, 3]]);
  setAutomaticRoutes(d);
  assert.equal(d.routes, null);
});

test("level validation mirrors the model error codes", () => {
  const level = () => JSON.parse(JSON.stringify(game.levels[0]));
  const codes = (mutate) => {
    const levels = [level()];
    mutate(levels[0]);
    return validateLevels(levels, kinds).map((e) => `${e.code}@${e.path}`);
  };
  assert.deepEqual(codes((l) => { l.id = " "; }), ["LEVEL_ID@levels.0.id"]);
  assert.deepEqual(codes((l) => { l.cells = [19, 64]; }), ["LEVEL_CELLS@levels.0.cells"]);
  assert.deepEqual(codes((l) => { l.cells = [52, 401]; }), ["LEVEL_CELLS@levels.0.cells"]);
  assert.deepEqual(codes((l) => { l.cells = [52.5, 64]; }), ["LEVEL_CELLS@levels.0.cells"]);
  assert.deepEqual(codes((l) => { l.money = -1; }), ["LEVEL_MONEY@levels.0.money"]);
  assert.deepEqual(codes((l) => { l.day = 0; }), ["LEVEL_TIME@levels.0.day"]);
  assert.deepEqual(codes((l) => { l.night = -5; }), ["LEVEL_TIME@levels.0.night"]);
  assert.deepEqual(codes((l) => { l.seed = 1.5; }), ["LEVEL_SEED@levels.0.seed"]);
  assert.deepEqual(codes((l) => { l.drop = [1.2, 0.5]; }), ["LEVEL_POSITION@levels.0.drop"]);
  assert.deepEqual(codes((l) => { l.world = [0.5, -0.1]; }), ["LEVEL_POSITION@levels.0.world"]);
  assert.deepEqual(codes((l) => { l.world = null; }), []);
  assert.deepEqual(codes((l) => { l.structures[0][0] = "tower"; }), ["LEVEL_STRUCTURE@levels.0.structures.0"]);
  assert.deepEqual(codes((l) => { l.structures[0][1] = [2, 0]; }), ["LEVEL_STRUCTURE@levels.0.structures.0"]);
  assert.deepEqual(codes((l) => { l.terrain.rocks = -1; }), ["LEVEL_TERRAIN@levels.0.terrain.rocks"]);
  assert.deepEqual(codes((l) => { l.terrain.spots[0][1] = 0; }), ["LEVEL_TERRAIN@levels.0.terrain.spots.0"]);
  assert.deepEqual(codes((l) => { l.terrain.spots[0][2] = [[1.5, 0]]; }), ["LEVEL_TERRAIN@levels.0.terrain.spots.0"]);
  assert.deepEqual(codes((l) => { l.challenges[0][0] = "x"; }), ["CHALLENGE@levels.0.challenges.0"]);
  assert.deepEqual(codes((l) => { l.challenges[0][1] = -1; }), ["CHALLENGE@levels.0.challenges.0"]);
  assert.deepEqual(codes((l) => { l.waves.interval = 0; }), ["WAVES@levels.0.waves.interval"]);
  assert.deepEqual(codes((l) => { l.waves.growth = -1; }), ["WAVES@levels.0.waves.growth"]);
  assert.deepEqual(codes((l) => { l.waves.roster = []; }), ["WAVE_ROSTER@levels.0.waves.roster"]);
  assert.deepEqual(codes((l) => { l.waves.night_roster = []; }), []);
  assert.deepEqual(codes((l) => { l.waves.roster[0][0] = "ghost"; }), ["WAVE_ROSTER@levels.0.waves.roster.0"]);
  assert.deepEqual(codes((l) => { l.waves.roster[0][2] = 0; }), ["WAVE_ROSTER@levels.0.waves.roster.0"]);
  assert.deepEqual(codes((l) => { l.waves.night_roster[0][1] = -1; }), ["WAVE_ROSTER@levels.0.waves.night_roster.0"]);
});

test("level set and duplicate id validation", () => {
  assert.deepEqual(validateLevels([], kinds).map((e) => e.code), ["LEVEL_SET"]);
  const levels = [game.levels[0], game.levels[0]];
  assert.deepEqual(validateLevels(levels, kinds).map((e) => `${e.code}@${e.path}`), ["LEVEL_ID_DUPLICATE@levels.1.id"]);
  assert.equal(errorsFor(validateLevels(levels, kinds), "levels.1").length, 1);
  assert.equal(errorsFor(validateLevels(levels, kinds), "levels.0").length, 0);
});

test("route validation mirrors the model", () => {
  assert.deepEqual(validateRoutes(null, 3), []);
  assert.deepEqual(validateRoutes([[0, 1], [1, 2]], 3), []);
  assert.deepEqual(validateRoutes([[0, 3]], 3).map((e) => e.path), ["routes.0"]);
  assert.deepEqual(validateRoutes([[1, 1]], 3).map((e) => e.path), ["routes.0"]);
  assert.deepEqual(validateRoutes([[0, 1], [1, 0]], 3).map((e) => e.path), ["routes.1"]);
  assert.deepEqual(validateRoutes([[0, 1.5]], 3).map((e) => e.path), ["routes.0"]);
  assert.equal(validateRoutes("x", 3)[0].code, "ROUTES");
});

test("wave formulas match hand-computed values of formulas.gd", () => {
  const waves = { base: 1.3, ramp: 1.5, night: 1.2, growth: 0.4 };
  assert.ok(Math.abs(waveCount(waves, 1, 0, false) - 1.3) < 1e-9);
  assert.ok(Math.abs(waveCount(waves, 1, 1, false) - 3.25) < 1e-9);
  assert.ok(Math.abs(waveCount(waves, 1, 2, false) - 3.25) < 1e-9);
  assert.ok(Math.abs(waveCount(waves, 1, 1, true) - 3.9) < 1e-9);
  assert.ok(Math.abs(waveCount(waves, 3, 0.5, false) - 4.095) < 1e-9);
  assert.ok(Math.abs(waveCount(waves, 0, 0, false) - 1.3) < 1e-9);
  assert.equal(waveTier(1), 0);
  assert.equal(waveTier(5), 4);
  assert.equal(waveTier(0), 0);
  assert.equal(hpScale(1), 1);
  assert.ok(Math.abs(hpScale(3) - 1.4884) < 1e-9);
  assert.equal(damageScale(1), 1);
  assert.ok(Math.abs(damageScale(3) - 1.16) < 1e-9);
  assert.ok(Math.abs(bountyScale(6) - 1.6) < 1e-9);
  assert.equal(bountyScale(0), 1);
});

test("wave times follow day and night duration", () => {
  const level = { day: 80, night: 60, waves: { interval: 9 } };
  assert.equal(waveTimes(level), 16);
  assert.equal(waveTimes({ day: 5, night: 10, waves: { interval: 9 } }), 2);
  assert.equal(waveTimes({ day: 2, night: 1, waves: { interval: 9 } }), 0);
  const longer = { ...level, day: 120 };
  assert.ok(waveTimes(longer) > waveTimes(level));
  assert.equal(isNight(79.9, level), false);
  assert.equal(isNight(80, level), true);
  assert.equal(isNight(140, level), false);
});

test("a round simulates carry, minimum of one and the queue cap", () => {
  const level = { day: 20, night: 10, waves: { interval: 9, base: 0.1, ramp: 0, night: 1, growth: 0, roster: [], night_roster: [] } };
  const waves = roundWaves(level, 1);
  assert.equal(waves.length, 3);
  assert.deepEqual(waves.map((wave) => wave.units), [1, 1, 1]);
  assert.deepEqual(waves.map((wave) => wave.night), [false, false, true]);
  const big = { ...level, waves: { ...level.waves, base: 100 } };
  assert.ok(roundWaves(big, 1).every((wave) => wave.units === 30));
});

test("round summary uses the weighted roster of eligible monsters", () => {
  const enemies = { a: { hp: 10, bounty: 2 }, b: { hp: 40, bounty: 8 } };
  assert.equal(rosterAverage([["a", 0, 1], ["b", 0, 3]], 1, enemies, "hp"), 32.5);
  assert.equal(rosterAverage([["a", 0, 1], ["b", 2, 3]], 1, enemies, "hp"), 10);
  assert.equal(rosterAverage([["a", 0, 1], ["b", 2, 3]], 3, enemies, "hp"), 32.5);
  assert.equal(rosterAverage([["b", 5, 1]], 1, enemies, "hp"), 0);
  const level = { day: 20, night: 10, waves: { interval: 9, base: 4, ramp: 0, night: 1, growth: 0, roster: [["a", 0, 1]], night_roster: [["b", 0, 1]] } };
  const first = roundSummary(level, 1, enemies);
  assert.equal(first.waves, 3);
  assert.equal(first.hpScale, 1);
  const units = roundWaves(level, 1);
  assert.equal(first.units, units.reduce((sum, wave) => sum + wave.units, 0));
  assert.equal(first.totalHp, units.reduce((sum, wave) => sum + wave.units * (wave.night ? 40 : 10), 0));
  const second = roundSummary(level, 2, enemies);
  assert.ok(Math.abs(second.hpScale - 1.22) < 1e-12);
  assert.ok(Math.abs(second.totalBounty - roundWaves(level, 2).reduce((sum, wave) => sum + wave.units * (wave.night ? 8 : 2), 0) * 1.12) < 1e-9);
});

test("strength rows grow monotonically for the shipped first level", () => {
  const rows = strengthRows(game.levels[0], game.enemies, 10);
  assert.equal(rows.length, 10);
  for (let i = 1; i < rows.length; i += 1) {
    assert.ok(rows[i].units >= rows[i - 1].units);
    assert.ok(rows[i].hpScale > rows[i - 1].hpScale);
  }
  const series = strengthSeries(rows);
  assert.equal(series.length, 8);
  assert.ok(series.every((item) => item.values.length === 10 && item.label && item.desc));
});

test("changing the day length changes the wave count immediately", () => {
  const d = fresh();
  const before = roundSummary(d.levels[0], 1, d.enemies).waves;
  d.levels[0].day += 40;
  assert.ok(roundSummary(d.levels[0], 1, d.enemies).waves > before);
});

test("auto layout mirrors Campaign.positions", () => {
  const manual = autoPositions([{ world: [0.5, 0.9] }, { world: [0.2, 0.7] }]);
  assert.deepEqual(manual, [[0.5, 0.9], [0.2, 0.7]]);
  const auto = autoPositions([{ world: null }, { world: null }, { world: null }, { world: null }]);
  assert.deepEqual(auto[0], [0.28, 0.9]);
  assert.equal(auto[1][0], 0.72);
  assert.equal(auto[2][0], 0.28);
  assert.ok(Math.abs(auto[1][1] - 0.71) < 1e-9);
  assert.ok(Math.abs(auto[3][1] - 0.33) < 1e-9);
  const mixed = autoPositions([{ world: [0.8, 0.9] }, { world: null }]);
  assert.deepEqual(mixed[1][0], 0.28);
  assert.ok(Math.abs(mixed[1][1] - 0.71) < 1e-9);
  const firstOdd = autoPositions([{ world: null }]);
  assert.deepEqual(firstOdd, [[0.28, 0.9]]);
});

test("world top extends upwards for long automatic chains", () => {
  assert.equal(worldTop(autoPositions(game.levels)), 0);
  const long = autoPositions(Array.from({ length: 10 }, () => ({ world: null })));
  assert.ok(worldTop(long) < 0);
});

test("effective routes link unlinked levels to their predecessor", () => {
  assert.deepEqual(effectiveRoutes(null, 3), [[0, 1], [1, 2]]);
  assert.deepEqual(effectiveRoutes([[0, 2]], 4), [[0, 2], [0, 1], [2, 3]]);
  assert.deepEqual(effectiveRoutes([], 1), []);
  assert.deepEqual(effectiveRoutes(game.routes, game.levels.length), game.routes);
});

test("dragging converts view coordinates to clamped world coordinates", () => {
  const geometry = mapGeometry(autoPositions(game.levels));
  const [x, y] = [geometry.px(0.25), geometry.py(0.75)];
  const world = pointerToWorld(geometry, x, y);
  assert.ok(Math.abs(world[0] - 0.25) < 0.002);
  assert.ok(Math.abs(world[1] - 0.75) < 0.002);
  assert.deepEqual(pointerToWorld(geometry, -500, 99999), [0, 1]);
  assert.equal(clampUnit(1.5), 1);
  assert.equal(clampUnit(-1), 0);
  assert.deepEqual(toWorld([0.5, 0.5], -1), [0.5, 0]);
});

test("the levels tab is registered", () => {
  const main = readFileSync(new URL("../../web/js/main.js", import.meta.url), "utf8");
  assert.ok(main.includes('"levels"') && main.includes("levelsView"));
});

const KEY_PATTERN = /\bt\(\s*"([A-Za-z0-9_.]+)"/g;

function usedKeys() {
  const keys = new Set();
  const directory = new URL("../../web/js/views/", import.meta.url);
  for (const file of readdirSync(directory).filter((name) => name.startsWith("level"))) {
    const text = readFileSync(new URL(file, directory), "utf8");
    for (const match of text.matchAll(KEY_PATTERN)) if (match[1].includes(".")) keys.add(match[1]);
  }
  return keys;
}

test("every level text key exists in german and english", () => {
  const dictionary = { de: read("de"), en: read("en") };
  const keys = [...usedKeys()];
  assert.ok(keys.length > 50);
  const dynamic = [];
  for (const kind of ["nest", "camp", "turret"]) dynamic.push(`levels.structure.${kind}`);
  for (const kind of ["core", "lost", "days", "combo", "survive"]) dynamic.push(`levels.challenge.${kind}`, `levels.challengeDesc.${kind}`);
  for (const kind of ["plateaus", "chasms", "ponds", "groves", "forests", "rocks"]) dynamic.push(`levels.terrain.${kind}`, `levels.terrainDesc.${kind}`);
  for (const kind of ["first", "last", "units", "totalHp", "hpScale", "damageScale", "bountyScale", "totalBounty"]) dynamic.push(`levels.strength.${kind}`, `levels.strengthDesc.${kind}`);
  for (const field of ["roster", "night_roster"]) dynamic.push(`levels.${field}`, `levels.d.${field}`);
  for (const code of ["LEVEL_SET", "LEVEL_ID", "LEVEL_ID_DUPLICATE", "LEVEL_CELLS", "LEVEL_MONEY", "LEVEL_TIME", "LEVEL_SEED", "LEVEL_POSITION", "LEVEL_STRUCTURE", "LEVEL_TERRAIN", "CHALLENGE", "ROUTES", "WAVES", "WAVE_ROSTER"]) dynamic.push(`error.${code}`);
  dynamic.push("tab.levels", "select.search", "select.empty", "levels.routesAuto", "levels.routesCustom");
  for (const key of [...keys, ...dynamic]) {
    if (key.includes("${")) continue;
    assert.ok(dictionary.de[key], `de ${key}`);
    assert.ok(dictionary.en[key], `en ${key}`);
  }
});

test("every model error code of the content model has a translation", () => {
  const model = readFileSync(new URL("../../upgrade_editor/content_model.py", import.meta.url), "utf8");
  const codes = new Set([...model.matchAll(/_error\("([A-Z_]+)"/g)].map((match) => match[1]).filter((code) => /^(LEVEL|CHALLENGE|ROUTES|WAVE)/.test(code)));
  const dictionary = read("de");
  for (const code of codes) assert.ok(dictionary[`error.${code}`], code);
});

test("the level tab renders with every control and reacts to edits", async () => {
  const { levelsView } = await import("../../web/js/views/levelsView.js");
  const { create } = await import("../../web/js/store.js");
  const store = create(fresh(), game);
  let renders = 0;
  const ctx = { doc: store.state.document, original: game, names: game.names, store, view: { collapsed: new Set() }, render: () => { renders += 1; }, toast: () => {} };
  const root = levelsView(ctx);
  assert.equal(root.tagName, "section");
  assert.equal(root.findAll((node) => node.tagName === "circle" && (node.attributes.class ?? "").startsWith("stop")).length, game.levels.length);
  assert.equal(root.findAll((node) => node.tagName === "line" && node.attributes.class === "route").length, game.routes.length);
  const combos = (label) => root.findAll((node) => node.attributes.role === "combobox" && node.attributes["aria-label"] === label);
  assert.equal(combos("levels.f.monster").length, game.levels[0].waves.roster.length + game.levels[0].waves.night_roster.length);
  assert.equal(combos("levels.f.routeFrom").length, 1);
  assert.equal(combos("levels.f.routeTo").length, 1);
  assert.equal(combos("levels.f.challengeKind").length, game.levels[0].challenges.length);
  assert.equal(root.findAll((node) => node.tagName === "select" && node.attributes["aria-label"] === "levels.f.structureKind").length, game.levels[0].structures.length);
  assert.ok(root.findAll((node) => node.tagName === "figure").length === 1);
  const numberInputs = root.findAll((node) => node.tagName === "input" && node.type === "number");
  assert.ok(numberInputs.length > 20);
  const money = numberInputs.find((node) => Number(node.value) === game.levels[0].money);
  money.value = "999";
  money.dispatch("change");
  assert.equal(store.state.document.levels[0].money, 999);
  const add = root.findAll((node) => node.tagName === "button" && node.text().includes("levels.add") && node.className === "primary")[0];
  add.dispatch("click");
  assert.equal(store.state.document.levels.length, game.levels.length + 1);
  assert.ok(store.canUndo());
});
