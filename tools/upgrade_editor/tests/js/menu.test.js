import test from "node:test";
import assert from "node:assert/strict";
import { game } from "./data.js";
import { menuGroups } from "../../web/js/views/buildMenu.js";
import { statGroups } from "../../web/js/views/buildingView.js";
import { hasPainter, paintBuilding } from "../../web/js/painter.js";
import { rgba, lighten, darken, mix, buildingColor } from "../../web/js/theme.js";
import { readFileSync } from "node:fs";

const strings = JSON.parse(readFileSync(new URL("../../web/i18n/de.json", import.meta.url), "utf8"));

test("menu has an all tab plus the game categories and covers every building", () => {
  const groups = menuGroups(game);
  assert.equal(groups[0].key, "all");
  assert.deepEqual(groups.slice(1, 5).map((group) => group.key), ["energy", "towers", "defense", "utility"]);
  assert.deepEqual(new Set(groups[0].kinds), new Set(game.buildings.map((entry) => entry.id)));
  assert.ok(groups.some((group) => group.key === "other" && group.kinds.includes("core")));
});

test("every building has a painter", () => {
  for (const entry of game.buildings) assert.ok(hasPainter(entry.id), entry.id);
  assert.ok(!hasPainter("nest"));
});

test("every painter draws without throwing on a recording context", () => {
  const calls = [];
  const target = new Proxy({}, { get: (_, name) => (name === "canvas" ? {} : (...args) => { calls.push(name); return args; }), set: () => true });
  for (const entry of game.buildings) {
    for (const fill of [0, 0.5, 1]) paintBuilding(target, entry.id, 0, 0, entry.stats.radius, 1.3, fill);
  }
  paintBuilding(target, "unknown", 0, 0, 10, 0);
  assert.ok(calls.length > 100);
});

test("every base stat has a german label", () => {
  for (const entry of game.buildings) {
    const { flat, nested } = statGroups(entry.stats);
    for (const [key] of flat) assert.ok(strings[`stat.${key}`], key);
    for (const [group, fields] of nested) {
      assert.ok(strings[`section.${group}`], group);
      for (const [path] of fields) assert.ok(strings[`stat.${path}`], path);
    }
  }
});

test("colour helpers", () => {
  assert.equal(rgba("#ff0000", 0.5), "rgba(255,0,0,0.5)");
  assert.equal(lighten("#000000", 0.5), "#808080");
  assert.equal(darken("#ffffff", 0.5), "#808080");
  assert.equal(mix("#000000", "#ffffff", 0.5), "#808080");
  assert.equal(buildingColor("solar"), "#ffc83d");
  assert.equal(buildingColor("unknown"), "#3ee8ff");
});
