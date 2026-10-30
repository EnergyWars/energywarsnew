import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { game } from "./data.js";
import { WAVE_RULES, waveCount, waveTimes, waveTime, roundWaves, extraWavesAt } from "../../web/js/waves.js";
import { AUTO, autoPositions, connectAll } from "../../web/js/worldLayout.js";
import { reduction, mitigate } from "../../web/js/armor.js";
import { buffFactor } from "../../web/js/monsters.js";
import { LOOKS } from "../../web/js/enemyPainter.js";
import * as levels from "../../web/js/levels.js";

const root = new URL("../../../../", import.meta.url);
const source = (path) => readFileSync(new URL(path, root), "utf8");
const constant = (text, name) => {
  const match = text.match(new RegExp(`^const ${name}(?:: \\w+)? := ([^\\n]+)$`, "m"));
  assert.ok(match, name);
  return match[1].trim();
};
const number = (text, name) => Number(constant(text, name));
const pythonList = (text, name) => {
  const match = text.match(new RegExp(`^${name} = \\(([^)]*)\\)`, "m"));
  assert.ok(match, name);
  return [...match[1].matchAll(/"([^"]+)"/g)].map((item) => item[1]);
};
const pythonNumber = (text, name) => Number(text.match(new RegExp(`^${name} = (\\d+)`, "m"))[1]);
const near = (actual, expected, epsilon = 1e-9) => assert.ok(Math.abs(actual - expected) < epsilon, `${actual} != ${expected}`);
const ARMOR = { constant: 100, max_reduction: 0.9, min_damage: 1 };

test("wave constants mirror game_config.gd", () => {
  const config = source("src/core/game_config.gd");
  assert.equal(WAVE_RULES.hpGrowth, number(config, "ROUND_HP_GROWTH"));
  assert.equal(WAVE_RULES.damageGrowth, number(config, "ROUND_DAMAGE_GROWTH"));
  assert.equal(WAVE_RULES.bountyGrowth, number(config, "ROUND_BOUNTY_GROWTH"));
  assert.equal(WAVE_RULES.first, number(config, "WAVE_FIRST"));
  assert.equal(WAVE_RULES.groundBonus, number(config, "GROUND_WAVE_BONUS"));
  assert.equal(WAVE_RULES.maxQueue, number(config, "WAVE_MAX"));
});

test("armor defaults mirror game_config.gd", () => {
  const literal = constant(source("src/core/game_config.gd"), "ARMOR");
  for (const [key, value] of Object.entries(ARMOR)) assert.equal(Number(literal.match(new RegExp(`"${key}": ([\\d.]+)`))[1]), value, key);
  assert.deepEqual(game.defaults.armor, ARMOR);
});

test("world layout constants mirror campaign.gd", () => {
  const campaign = source("src/core/campaign.gd");
  assert.equal(AUTO.left, number(campaign, "AUTO_LEFT"));
  assert.equal(AUTO.right, number(campaign, "AUTO_RIGHT"));
  assert.equal(AUTO.start, number(campaign, "AUTO_START"));
  assert.equal(AUTO.step, number(campaign, "AUTO_STEP"));
  assert.equal(AUTO.pad, number(campaign, "AUTO_PAD"));
});

test("level limits mirror content_model.py and ContentOverrides", () => {
  const model = source("tools/upgrade_editor/upgrade_editor/content_model.py");
  const overrides = source("src/core/content_overrides.gd");
  for (const name of ["MIN_CELLS", "MAX_CELLS", "MAX_LEVELS", "MAX_EXTRA_COUNT"]) assert.equal(levels[name], pythonNumber(model, name), name);
  for (const name of ["MIN_CELLS", "MAX_CELLS", "MAX_EXTRA_COUNT"]) assert.equal(levels[name], number(overrides, name), name);
  for (const name of ["STRUCTURE_KINDS", "CHALLENGE_KINDS", "TERRAIN_COUNTS", "WAVE_NUMBERS", "LEVEL_REQUIRED", "LEVEL_OPTIONAL"]) assert.deepEqual(levels[name], pythonList(model, name), name);
});

test("armor reference values match test_parity.gd", () => {
  near(reduction(100, ARMOR), 0.5);
  near(reduction(300, ARMOR), 0.75);
  near(reduction(1e6, ARMOR), 0.9);
  near(mitigate(40, 100, ARMOR), 20);
  near(mitigate(1, 60, ARMOR), 1);
  near(mitigate(1, 60, ARMOR, 1 / 30), 0.625);
  near(mitigate(0.5, 1e6, ARMOR), 0.5);
  near(mitigate(0.01, 1e6, ARMOR, 1 / 30), 0.01);
  near(mitigate(3, 0, ARMOR), 3);
});

test("wave reference values match test_parity.gd", () => {
  const waves = { interval: 9, base: 1.3, ramp: 1.5, night: 1.2, growth: 0.4, roster: [], night_roster: [] };
  near(waveCount(waves, 3, 0.5, true), 4.914);
  assert.equal(waveTimes({ day: 80, night: 60, waves }), 16);
  assert.equal(waveTime({ waves }, 5), 48);
  const level = { day: 20, night: 10, waves };
  assert.deepEqual(roundWaves(level, 2).map((wave) => wave.units), [2, 4, 6]);
  assert.deepEqual(roundWaves(level, 2).map((wave) => wave.night), [false, false, true]);
  const extras = { day: 40, night: 30, waves, extra_waves: [{ day: 2, night: false, kind: "wasp", count: 2 }, { day: 3, night: true, kind: "stalker", count: 1 }] };
  assert.deepEqual(extraWavesAt(extras, 2, 0).map((entry) => entry.kind), ["wasp"]);
  assert.deepEqual(extraWavesAt(extras, 2, 1), []);
  assert.deepEqual(extraWavesAt(extras, 3, 5).map((entry) => entry.kind), ["stalker"]);
  assert.deepEqual(extraWavesAt(extras, 3, 6), []);
});

test("buff reference values match test_parity.gd", () => {
  near(buffFactor(game.enemies.colossus, "hp", true, 7), 2.125);
  near(buffFactor(game.enemies.colossus, "armor", true, 7), 1.633);
  near(buffFactor(game.enemies.colossus, "speed", false, 7), 1);
  near(buffFactor(game.enemies.crawler, "hp", false, 0), 1);
  near(buffFactor({ buffs: { night: { hp: -2 } } }, "hp", true, 0), 0);
});

test("route and layout reference values match test_parity.gd", () => {
  assert.deepEqual(connectAll([[0, 2]], 4), [[0, 2], [0, 1], [2, 3]]);
  assert.deepEqual(connectAll([[1, 2]], 4), [[1, 2], [0, 1], [2, 3]]);
  assert.deepEqual(connectAll([[0, 1], [2, 3]], 4), [[0, 1], [2, 3], [1, 2]]);
  assert.deepEqual(connectAll([[0, 9], [1, 1]], 2), [[0, 1]]);
  const layout = autoPositions([{ world: [0.5, 0.9] }, { world: null }, { world: null }, { world: null }]);
  const expected = [[0.5, 0.9], [0.72, 0.71], [0.28, 0.52], [0.72, 0.33]];
  layout.forEach((point, index) => {
    near(point[0], expected[index][0]);
    near(point[1], expected[index][1]);
  });
});

test("enemy look colours and sizes mirror enemy_painter.gd", () => {
  const theme = Object.fromEntries([...source("src/ui/app_theme.gd").matchAll(/^const (\w+) := Color\("(#[0-9a-fA-F]{6})"\)/gm)].map((match) => [match[1], match[2].toLowerCase()]));
  const painter = source("src/ui/enemy_painter.gd");
  const lines = new Map([...painter.matchAll(/^\t"(\w+)": \{(.*)\},?$/gm)].map((match) => [match[1], match[2]]));
  assert.equal(lines.size, Object.keys(LOOKS).length);
  const colour = (text) => {
    const literal = text.match(/^Color\("(#[0-9a-fA-F]{6})"\)$/);
    if (literal) return literal[1].toLowerCase();
    const named = text.match(/^AppTheme\.(\w+)$/);
    assert.ok(named && theme[named[1]], text);
    return theme[named[1]];
  };
  for (const [key, look] of Object.entries(LOOKS)) {
    const line = lines.get(key);
    assert.ok(line, key);
    for (const field of ["body", "shell", "spit", "mark", "core"]) {
      const match = line.match(new RegExp(`"${field}": (AppTheme\\.\\w+|Color\\("#[0-9a-fA-F]{6}"\\))`));
      assert.equal(look[field]?.toLowerCase(), match ? colour(match[1]) : undefined, `${key}.${field}`);
    }
    for (const field of ["gun", "barrel"]) {
      const match = line.match(new RegExp(`"${field}": ([\\d.]+)`));
      assert.equal(look[field], match ? Number(match[1]) : undefined, `${key}.${field}`);
    }
  }
});

test("enemy painter constants mirror enemy_painter.gd and painter.gd", () => {
  const js = source("tools/upgrade_editor/web/js/enemyPainter.js");
  const gd = source("src/ui/enemy_painter.gd");
  const jsConst = (name) => js.match(new RegExp(`^const ${name} = ([^;]+);`, "m"))[1].replace(/"/g, "").trim();
  for (const name of ["BONE", "GUN", "GLOW"]) assert.equal(jsConst(name).toLowerCase(), constant(gd, name).match(/#[0-9a-fA-F]{6}/)[0].toLowerCase(), name);
  for (const name of ["BOSS_RING", "BOSS_ARCS"]) assert.equal(Number(jsConst(name)), number(gd, name), name);
  assert.equal(jsConst("FALLBACK_LOOK"), constant(gd, "FALLBACK_LOOK").replace(/"/g, ""));
  const offset = constant(source("src/ui/painter.gd"), "SHADOW_OFFSET").match(/Vector2\((\d+), (\d+)\)/);
  assert.equal(jsConst("SHADOW_OFFSET"), `[${offset[1]}, ${offset[2]}]`);
});
