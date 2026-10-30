import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { overviewRows, sortRows } from "../../web/js/views/overviewView.js";
import { computeChanges } from "../../web/js/views/changesView.js";
import { number, compact, LENGTH_STATS, cellSize, toCells, fromCells, DEFAULT_CELL } from "../../web/js/format.js";

test("overview lists every track of every building", () => {
  const rows = overviewRows(game, game.names);
  const expected = game.buildings.reduce((sum, entry) => sum + entry.tracks.length, 0);
  assert.equal(rows.length, expected);
  assert.ok(rows.every((row) => row.total > 0 && row.benefit > 0));
});

test("rows sort by text and numbers in both directions", () => {
  const rows = [{ building: "b", total: 2 }, { building: "a", total: 5 }];
  assert.equal(sortRows(rows, "building", "asc")[0].building, "a");
  assert.equal(sortRows(rows, "total", "desc")[0].total, 5);
  assert.equal(sortRows(rows, "total", "asc")[0].total, 2);
});

test("changes are empty for identical documents and list edits", () => {
  assert.deepEqual(computeChanges(game, fresh()), []);
  const doc = fresh();
  doc.tracks.rate.price = 0.5;
  find(doc, "solar").tracks = ["output"];
  const paths = computeChanges(game, doc).map((change) => change.path);
  assert.ok(paths.includes("tracks.rate.price"));
  assert.ok(paths.includes("buildings.solar.tracks"));
});

test("number formatting", () => {
  assert.equal(number(1.5), "1.5");
  assert.equal(number(3), "3");
  assert.equal(number(undefined), "–");
  assert.equal(number("x"), "x");
  assert.equal(compact(12500), "12.5k");
  assert.equal(compact(950), "950");
});

test("lengths convert between pixels and tile widths", () => {
  assert.equal(toCells(56, 56), 1);
  assert.equal(toCells(84, 56), 1.5);
  assert.equal(fromCells(1.5, 56), 84);
  assert.equal(toCells(220, 56), 3.9286);
  assert.equal(fromCells(4, 56), 224);
  assert.equal(fromCells(3.3, 56), 184.8);
});

test("tile size comes from the document with a fallback", () => {
  assert.equal(cellSize(game), game.system.cell);
  assert.equal(cellSize({ system: {} }), DEFAULT_CELL);
  assert.equal(cellSize(undefined), DEFAULT_CELL);
});

test("every length stat exists in the game data", () => {
  const paths = new Set();
  for (const entry of game.buildings) {
    for (const [key, value] of Object.entries(entry.stats)) {
      if (value !== null && typeof value === "object") Object.keys(value).forEach((inner) => paths.add(`${key}.${inner}`));
      else paths.add(key);
    }
  }
  for (const path of LENGTH_STATS) assert.ok(paths.has(path), path);
});

test("chart scale maps values onto the unit range including zero", async () => {
  const { chartScale } = await import("../../web/js/views/components.js");
  const scale = chartScale([10, 20, 30]);
  assert.equal(scale.at(0), 0);
  assert.equal(scale.at(30), 1);
  assert.equal(scale.at(15), 0.5);
  assert.equal(chartScale([-10, 10]).at(0), 0.5);
  assert.ok(Number.isFinite(chartScale([0, 0]).at(0)));
});
