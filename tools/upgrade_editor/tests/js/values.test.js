import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { game, fresh, find } from "./data.js";
import { deriveRows, deriveRowsFromBase, baseRow, editLevel, writeLevels, EDITABLE_FIELDS, gainBase, referenceCost, snapshotLevels, planOf } from "../../web/js/formulas.js";
import { pendingLevels, applyLevels, discardLevels, draftKey, gainView, gainModeKey, gainModeValue } from "../../web/js/views/valueTable.js";
import { detailPairs, toggleSeries, chartSeries } from "../../web/js/views/buildingView.js";
import { METRICS, METRIC_KEYS } from "../../web/js/views/metrics.js";
import { COLUMNS, visibleColumns } from "../../web/js/views/valueTable.js";
import { toggleKey, isCollapsed, nearestLevel, highlightState } from "../../web/js/views/components.js";
import { create } from "../../web/js/store.js";

const near = (actual, expected, message) => assert.ok(Math.abs(actual - expected) < 1e-6, `${message ?? ""} ${actual} vs ${expected}`);
const entry = (cost = 10, upgradeBase = 5) => ({ id: "x", cost, upgrade_base: upgradeBase });
const levels = () => [{ cost: 8, gain: 0.4 }, { cost: 16, gain: 0.4 }];

test("derived rows contain every value of a level", () => {
  const [first, second] = deriveRows(entry(), levels());
  assert.equal(first.spent, 18);
  near(first.effect, 1.4);
  near(first.single, 50);
  near(first.total, (1.4 / 1.8) * 100);
  assert.equal(second.spent, 34);
  near(second.effect, 1.8);
  near(second.single, 25);
  near(second.total, (1.8 / 3.4) * 100);
  near(second.benefit, ((0.4 / 1.4) * 100) / 16 * 1000);
});

test("rows fall back to the upgrade base and have no factors without any reference", () => {
  near(referenceCost(entry(0, 10)), 10);
  assert.equal(deriveRows(entry(0, 0), levels())[0].single, null);
  assert.equal(deriveRows(entry(0, 0), levels())[0].total, null);
});

test("editing cost, total cost and effect recalculates dependent values", () => {
  let next = editLevel(entry(), levels(), 0, "cost", 20.4);
  assert.equal(next[0].cost, 20);
  next = editLevel(entry(), levels(), 1, "spent", 40);
  assert.equal(next[1].cost, 22);
  assert.equal(deriveRows(entry(), next)[1].spent, 40);
  next = editLevel(entry(), levels(), 1, "effect", 2);
  near(next[1].gain, 0.6);
  near(deriveRows(entry(), next)[1].effect, 2);
  next = editLevel(entry(), levels(), 0, "gain", 0.25);
  near(deriveRows(entry(), next)[1].effect, 1.65);
  assert.equal(levels()[0].gain, 0.4);
});

test("editing a factor changes the cost and keeps the benefit", () => {
  let next = editLevel(entry(), levels(), 0, "single", 100);
  assert.equal(next[0].cost, 4);
  near(deriveRows(entry(), next)[0].single, 100);
  next = editLevel(entry(), levels(), 1, "total", 60);
  near(deriveRows(entry(), next)[1].total, 60, "total");
  near(next[1].gain, 0.4);
});

test("invalid edits are ignored or clamped", () => {
  assert.deepEqual(editLevel(entry(), levels(), 0, "cost", Number.NaN), levels());
  assert.deepEqual(editLevel(entry(), levels(), 5, "cost", 3), levels());
  assert.equal(editLevel(entry(), levels(), 0, "cost", -5)[0].cost, 1);
  assert.equal(editLevel(entry(), levels(), 1, "spent", 3)[1].cost, 1);
  assert.deepEqual(editLevel(entry(), levels(), 0, "single", 0), levels());
  assert.deepEqual(editLevel(entry(), [{ cost: 4, gain: 0 }], 0, "single", 50), [{ cost: 4, gain: 0 }]);
  assert.deepEqual(editLevel(entry(0, 0), levels(), 0, "total", 50), levels());
  assert.deepEqual(editLevel(entry(), levels(), 0, "unknown", 5), levels());
});

test("writing levels always stores a plain table", () => {
  const doc = fresh();
  const solar = find(doc, "solar");
  writeLevels(solar, "output", [{ cost: 3, gain: 0.1 }]);
  assert.equal(planOf(solar, "output").mode, "table");
  solar.plans.output = { mode: "formula", max: 2, cost: "1", effect: "1", levels: levels() };
  writeLevels(solar, "output", [...levels(), { cost: 1, gain: 0.1 }]);
  assert.deepEqual(solar.plans.output, { mode: "table", levels: [...levels(), { cost: 1, gain: 0.1 }] });
});

test("absolute gains use the base value of the track", () => {
  const hull = find(game, "bulwark");
  assert.equal(gainBase(game, hull, "hull"), hull.hp);
  const zapper = find(game, "zapper");
  assert.equal(gainBase(game, zapper, "range"), zapper.stats.attack.range / game.system.cell);
  assert.equal(gainBase(game, zapper, "power"), zapper.stats.attack.damage);
  assert.equal(gainBase(game, find(game, "plasma"), "splash"), find(game, "plasma").stats.attack.splash / game.system.cell);
  assert.equal(gainBase(game, find(game, "relay"), "range"), find(game, "relay").stats.range / game.system.cell);
  assert.equal(gainBase(game, find(game, "shield"), "range"), find(game, "shield").stats.shield.radius / game.system.cell);
  assert.equal(gainBase(game, find(game, "healer"), "range"), find(game, "healer").stats.heal.range / game.system.cell);
  assert.equal(gainBase(game, find(game, "exporter"), "rate"), find(game, "exporter").stats.export);
  assert.equal(gainBase(game, find(game, "solar"), "output"), find(game, "solar").stats.output);
  assert.equal(gainBase(game, find(game, "battery"), "capacity"), find(game, "battery").stats.capacity);
  assert.equal(gainBase(game, find(game, "zapper"), "crit"), null);
  assert.equal(gainBase(undefined, { hp: 10, stats: {} }, "hull"), 10);
});

test("gain view converts between factor and absolute values", () => {
  const factor = gainView(10, "factor");
  assert.equal(factor.show(0.4), 0.4);
  assert.equal(factor.parse(0.4), 0.4);
  const absolute = gainView(10, "absolute");
  assert.equal(absolute.show(0.4), 4);
  assert.equal(absolute.parse(4), 0.4);
  assert.equal(gainView(null, "absolute").converted, false);
});

function context(doc) {
  const store = create(doc, doc);
  const ctx = { store, view: { drafts: {}, gainModes: {}, hidden: new Set() }, render() {}, toast() {} };
  Object.defineProperty(ctx, "doc", { get: () => store.state.document });
  return ctx;
}

test("table drafts apply only on request and become a table plan", () => {
  const ctx = context(fresh());
  const solar = find(ctx.doc, "solar");
  const before = JSON.stringify(snapshotLevels(ctx.doc, solar, "output"));
  const draftLevels = snapshotLevels(ctx.doc, solar, "output").map((level) => ({ ...level }));
  draftLevels[0].cost = 999;
  ctx.view.drafts[draftKey(solar, "output")] = { base: before, levels: draftLevels };
  assert.equal(pendingLevels(ctx, solar, "output")[0].cost, 999);
  assert.equal(planOf(solar, "output"), null);
  applyLevels(ctx, solar, "output");
  const applied = find(ctx.doc, "solar");
  assert.equal(planOf(applied, "output").mode, "table");
  assert.equal(planOf(applied, "output").levels[0].cost, 999);
  assert.equal(ctx.view.drafts[draftKey(solar, "output")], undefined);
  applyLevels(ctx, applied, "output");
  assert.equal(ctx.store.state.past.length, 1);
});

test("a draft is dropped when the underlying levels changed meanwhile", () => {
  const ctx = context(fresh());
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts[draftKey(solar, "output")] = { base: "[]", levels: [{ cost: 1, gain: 0.1 }] };
  assert.equal(pendingLevels(ctx, solar, "output"), null);
  assert.equal(ctx.view.drafts[draftKey(solar, "output")], undefined);
  assert.equal(pendingLevels(ctx, solar, "output"), null);
});

test("discard removes the draft", () => {
  const ctx = context(fresh());
  const solar = find(ctx.doc, "solar");
  ctx.view.drafts[draftKey(solar, "output")] = { base: "x", levels: [] };
  discardLevels(ctx, solar, "output");
  assert.deepEqual(ctx.view.drafts, {});
  assert.equal(gainModeKey(solar, "output"), "solar:output");
});

test("tooltip lists every value of a level and series can be toggled", () => {
  const rows = deriveRows(entry(), levels());
  const pairs = detailPairs(rows[1]);
  assert.equal(pairs.length, METRICS.length);
  assert.ok(pairs.every(([label, value]) => label && value));
  const ctx = context(fresh());
  toggleSeries(ctx, "cost");
  assert.ok(ctx.view.hidden.has("cost"));
  toggleSeries(ctx, "cost");
  assert.ok(!ctx.view.hidden.has("cost"));
  const series = chartSeries(rows);
  assert.deepEqual(series.map((item) => item.key), METRIC_KEYS);
  assert.ok(series.every((item) => item.values.length === 2));
});

test("sections and tracks can be collapsed and expanded again", () => {
  const set = new Set();
  assert.equal(toggleKey(set, "a"), true);
  assert.equal(toggleKey(set, "a"), false);
  assert.equal(set.size, 0);
  const ctx = { view: { collapsed: new Set(["stats:solar"]) } };
  assert.equal(isCollapsed(ctx, "stats:solar"), true);
  assert.equal(isCollapsed(ctx, "upgrades:solar"), false);
});

test("the hovered level is the nearest one along the plot width", () => {
  assert.equal(nearestLevel(-50, 10), 0);
  assert.equal(nearestLevel(5000, 10), 9);
  assert.equal(nearestLevel(12, 10), 0);
  assert.equal(nearestLevel(640 - 12, 10), 9);
  assert.equal(nearestLevel(320, 11), 5);
  assert.equal(nearestLevel(320, 1), 0);
  assert.equal(nearestLevel(12 + (616 / 9) * 3.4, 10), 3);
  assert.equal(nearestLevel(12 + (616 / 9) * 3.6, 10), 4);
});

test("the gain mode defaults to factor and respects a missing base", () => {
  const view = { gainModes: {} };
  const solar = { id: "solar" };
  assert.equal(gainModeValue(view, solar, "output", 10), "factor");
  view.gainModes["solar:output"] = "absolute";
  assert.equal(gainModeValue(view, solar, "output", 10), "absolute");
  assert.equal(gainModeValue(view, solar, "output", null), "factor");
});

test("total cost includes the original purchase price", () => {
  const rows = deriveRows(entry(10), [{ cost: 8, gain: 0.4 }, { cost: 16, gain: 0.4 }]);
  assert.deepEqual(rows.map((row) => row.spent), [18, 34]);
  assert.deepEqual(deriveRows(entry(0, 5), [{ cost: 8, gain: 0.4 }]).map((row) => row.spent), [8]);
  assert.deepEqual(deriveRows({ id: "x", upgrade_base: 5 }, [{ cost: 8, gain: 0.4 }]).map((row) => row.spent), [8]);
  near(rows[1].total, (1.8 / 3.4) * 100);
});

const SAMPLE = [{ cost: 20, gain: 0.5 }, { cost: 35, gain: 0.4 }, { cost: 60, gain: 0.3 }, { cost: 100, gain: 0.2 }];
const OWNER = { id: "x", cost: 50, upgrade_base: 8 };

test("table columns, chart series and tooltip show exactly the same values", () => {
  const tableKeys = COLUMNS.map((column) => column.key).filter((key) => key !== "level");
  assert.deepEqual(tableKeys, METRIC_KEYS);
  const rows = deriveRows(OWNER, SAMPLE);
  const series = chartSeries(rows);
  assert.deepEqual(series.map((item) => item.key), METRIC_KEYS);
  assert.equal(detailPairs(rows[0]).length, METRIC_KEYS.length);
  for (const key of METRIC_KEYS) assert.ok(key in rows[0], key);
  for (const item of series) {
    assert.deepEqual(item.values, rows.map((row) => row[item.key]), item.key);
    assert.ok(item.color && typeof item.format === "function", item.key);
  }
  assert.equal(new Set(series.map((item) => item.color)).size, series.length);
});

test("every table value can be edited", () => {
  assert.deepEqual([...EDITABLE_FIELDS].sort(), [...METRIC_KEYS].sort());
});

const COST_DRIVEN = ["cost", "costFactor", "spent", "spentFactor", "single", "total", "benefit"];
const GAIN_DRIVEN = ["gain", "effect"];

function expectRowsEqual(actual, expected, message) {
  assert.equal(actual.length, expected.length, message);
  actual.forEach((row, index) => {
    for (const key of METRIC_KEYS) {
      if (expected[index][key] === null) assert.equal(row[key], null, `${message} ${index}.${key}`);
      else near(row[key], expected[index][key], `${message} ${index}.${key}`);
    }
  });
}

test("changing any cost based value recalculates every dependent value", () => {
  for (const field of COST_DRIVEN) {
    for (let index = 0; index < SAMPLE.length; index += 1) {
      const target = SAMPLE.map((level) => ({ ...level }));
      target[index].cost = 77;
      const expected = deriveRows(OWNER, target);
      const edited = editLevel(OWNER, SAMPLE, index, field, expected[index][field]);
      const label = `${field}@${index}`;
      assert.equal(edited[index].cost, 77, label);
      assert.deepEqual(edited.map((level) => level.gain), SAMPLE.map((level) => level.gain), label);
      expectRowsEqual(deriveRows(OWNER, edited), expected, label);
    }
  }
});

test("changing any benefit based value recalculates every dependent value", () => {
  for (const field of GAIN_DRIVEN) {
    for (let index = 0; index < SAMPLE.length; index += 1) {
      const target = SAMPLE.map((level) => ({ ...level }));
      target[index].gain = 0.75;
      const expected = deriveRows(OWNER, target);
      const edited = editLevel(OWNER, SAMPLE, index, field, expected[index][field]);
      const label = `${field}@${index}`;
      near(edited[index].gain, 0.75, label);
      assert.deepEqual(edited.map((level) => level.cost), SAMPLE.map((level) => level.cost), label);
      expectRowsEqual(deriveRows(OWNER, edited), expected, label);
    }
  }
});

test("an edit only moves the following levels, earlier levels stay untouched", () => {
  const before = deriveRows(OWNER, SAMPLE);
  for (const field of EDITABLE_FIELDS) {
    const index = 2;
    const probe = deriveRows(OWNER, SAMPLE)[index][field] * 1.5;
    const after = deriveRows(OWNER, editLevel(OWNER, SAMPLE, index, field, probe));
    for (const key of METRIC_KEYS) {
      for (let earlier = 0; earlier < index; earlier += 1) near(after[earlier][key], before[earlier][key], `${field}->${key}@${earlier}`);
    }
    assert.notDeepEqual(after[index], before[index], field);
  }
});

test("cumulative values of later levels shift when an earlier level changes", () => {
  const before = deriveRows(OWNER, SAMPLE);
  const costly = deriveRows(OWNER, editLevel(OWNER, SAMPLE, 0, "cost", 120));
  assert.equal(costly[3].spent - before[3].spent, 100);
  assert.ok(costly[3].total < before[3].total);
  near(costly[3].effect, before[3].effect);
  const stronger = deriveRows(OWNER, editLevel(OWNER, SAMPLE, 0, "effect", 2));
  near(stronger[3].effect - before[3].effect, 0.5);
  assert.equal(stronger[3].spent, before[3].spent);
  assert.ok(stronger[3].total > before[3].total);
});

test("every edit keeps the table consistent with itself", () => {
  for (const field of EDITABLE_FIELDS) {
    for (let index = 0; index < SAMPLE.length; index += 1) {
      const edited = editLevel(OWNER, SAMPLE, index, field, deriveRows(OWNER, SAMPLE)[index][field] * 1.2);
      const rows = deriveRows(OWNER, edited);
      let spent = OWNER.cost;
      let effect = 1;
      rows.forEach((row, position) => {
        spent += edited[position].cost;
        effect += edited[position].gain;
        assert.equal(row.cost, edited[position].cost);
        near(row.spent, spent, `${field}@${index} spent ${position}`);
        near(row.effect, effect, `${field}@${index} effect ${position}`);
        near(row.costFactor, row.cost / OWNER.cost);
        near(row.spentFactor, row.spent / OWNER.cost);
        assert.ok(edited[position].cost >= 1 && Number.isInteger(edited[position].cost));
      });
    }
  }
});

test("factors without a reference cost cannot be edited and leave the levels unchanged", () => {
  const owner = { id: "x", cost: 0, upgrade_base: 0 };
  for (const field of ["costFactor", "spentFactor", "single", "total"]) {
    assert.deepEqual(editLevel(owner, SAMPLE, 1, field, 2), SAMPLE, field);
  }
  assert.equal(deriveRows(owner, SAMPLE)[0].costFactor, null);
  assert.equal(deriveRows(owner, SAMPLE)[0].spentFactor, null);
});

test("the benefit value needs a positive gain and value", () => {
  assert.deepEqual(editLevel(OWNER, SAMPLE, 0, "benefit", 0), SAMPLE);
  assert.deepEqual(editLevel(OWNER, [{ cost: 5, gain: 0 }], 0, "benefit", 10), [{ cost: 5, gain: 0 }]);
});

test("hidden series disappear from the table columns and the tooltip", () => {
  const hidden = new Set(["costFactor", "benefit"]);
  const columns = visibleColumns(hidden).map((column) => column.key);
  assert.equal(columns[0], "level");
  assert.ok(!columns.includes("costFactor") && !columns.includes("benefit"));
  assert.deepEqual(columns.slice(1), METRIC_KEYS.filter((key) => !hidden.has(key)));
  const rows = deriveRows(OWNER, SAMPLE);
  assert.equal(detailPairs(rows[0], hidden).length, METRIC_KEYS.length - 2);
  assert.equal(detailPairs(rows[0]).length, METRIC_KEYS.length);
  assert.deepEqual(visibleColumns(new Set()).map((column) => column.key), COLUMNS.map((column) => column.key));
  assert.deepEqual(visibleColumns(new Set(METRIC_KEYS)).map((column) => column.key), ["level"]);
});

test("table, tooltip and chart legend follow the same hidden set", () => {
  const hidden = new Set(["spent"]);
  const table = visibleColumns(hidden).map((column) => column.key).filter((key) => key !== "level");
  const tooltip = METRIC_KEYS.filter((key) => detailPairs(deriveRows(OWNER, SAMPLE)[0], hidden).some(([label]) => label === chartSeries(deriveRows(OWNER, SAMPLE)).find((item) => item.key === key).label));
  assert.deepEqual(table, tooltip);
});

test("hovering a legend entry focuses its line and dims all others", () => {
  assert.equal(highlightState(null, "cost"), "");
  assert.equal(highlightState("cost", "cost"), "focus");
  assert.equal(highlightState("cost", "gain"), "dim");
});

test("every value has a distinct explanation in both languages for legend, header and cells", () => {
  const series = chartSeries(deriveRows(OWNER, SAMPLE));
  for (const item of series) assert.equal(item.desc, `values.desc.${item.key}`);
  for (const code of ["de", "en"]) {
    const dictionary = JSON.parse(readFileSync(new URL(`../../web/i18n/${code}.json`, import.meta.url), "utf8"));
    const texts = METRIC_KEYS.map((key) => dictionary[`values.desc.${key}`]);
    assert.ok(texts.every((text) => typeof text === "string" && text.length > 20), code);
    assert.equal(new Set(texts).size, texts.length, code);
    assert.ok(dictionary["values.desc.level"], code);
    assert.ok(METRIC_KEYS.every((key) => dictionary[`values.col.${key}`]), code);
  }
});

test("level zero is the purchased building with only meaningful values", () => {
  const base = baseRow(OWNER);
  assert.equal(base.level, 0);
  assert.equal(base.spent, 50);
  assert.equal(base.spentFactor, 1);
  assert.equal(base.effect, 1);
  assert.equal(base.total, 100);
  for (const key of ["cost", "costFactor", "gain", "single", "benefit"]) assert.equal(base[key], null, key);
  assert.equal(baseRow({ id: "x", cost: 0, upgrade_base: 8 }).total, 100);
  assert.equal(baseRow({ id: "x", cost: 0, upgrade_base: 0 }).spentFactor, null);
  assert.equal(baseRow({ id: "x", cost: 0, upgrade_base: 0 }).total, null);
});

test("rows with the base level start at zero and keep the following levels", () => {
  const rows = deriveRowsFromBase(OWNER, SAMPLE);
  assert.equal(rows.length, SAMPLE.length + 1);
  assert.deepEqual(rows.map((row) => row.level), [0, 1, 2, 3, 4]);
  assert.deepEqual(rows.slice(1), deriveRows(OWNER, SAMPLE));
  assert.equal(rows[1].spent - rows[0].spent, SAMPLE[0].cost);
});

test("chart series and tooltip include level zero and skip values that do not exist", () => {
  const rows = deriveRowsFromBase(OWNER, SAMPLE);
  const series = chartSeries(rows);
  assert.ok(series.every((item) => item.values.length === rows.length));
  assert.ok(Number.isNaN(series.find((item) => item.key === "cost").values[0]));
  assert.equal(series.find((item) => item.key === "spent").values[0], 50);
  const pairs = detailPairs(rows[0]);
  const labels = Object.fromEntries(pairs);
  assert.equal(labels[chartSeries(rows).find((item) => item.key === "cost").label], "–");
  assert.equal(pairs.length, METRIC_KEYS.length);
});
