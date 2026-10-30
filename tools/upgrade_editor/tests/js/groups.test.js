import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { installFakeDom } from "./fakeDom.js";
import { create } from "../../web/js/store.js";
import {
  DIRECT, NAME_LIMIT, AREA_LIMIT, ITEM_LIMIT, areas, itemKey, parseItem, knownItems, nameProblem, uniqueName,
  addArea, renameArea, removeArea, moveArea, addSection, renameSection, removeSection, moveSection,
  addItem, removeItem, moveItem, pruneItem, membership, targetOptions, targetValue, parseTarget,
  itemCount, blocks, groupRows, validateGroups,
} from "../../web/js/groups.js";
import { computeChanges, indexGroups } from "../../web/js/views/changesView.js";
import { overviewRows } from "../../web/js/views/overviewView.js";

installFakeDom();

const ZAP = "zapper:power";
const LASER = "laser:power";
const SOLAR = "solar:output";

function sample() {
  const doc = fresh();
  doc.groups = [
    { name: "Offensive", items: [ZAP], sections: [{ name: "Schaden", items: [ZAP, LASER] }, { name: "Reichweite", items: ["zapper:range"] }] },
    { name: "Wirtschaft", items: [], sections: [{ name: "Energie", items: [SOLAR, ZAP] }] },
  ];
  return doc;
}

function context(doc = fresh()) {
  const store = create(doc, game);
  const ctx = { original: game, names: game.names, store, view: { tab: "overview", collapsed: new Set(), open: new Set(), drafts: {}, tools: {}, hidden: new Set(), gainModes: {}, planErrors: {} }, renders: 0, render() { this.renders += 1; }, toast() {} };
  Object.defineProperty(ctx, "doc", { get: () => store.state.document });
  return ctx;
}

const byText = (root, text) => root.findAll((node) => node.tagName === "button" && node.text().includes(text));
const combo = (root, label) => root.findAll((node) => node.attributes.role === "combobox" && node.attributes["aria-label"] === label);

function pick(trigger, value) {
  trigger.dispatch("click");
  const root = trigger.parentNode;
  const option = root.findAll((node) => node.attributes.role === "option").find((node) => node.text().includes(value));
  assert.ok(option, `option ${value}`);
  option.dispatch("click");
}

test("item keys combine building and track and parse back", () => {
  assert.equal(itemKey("zapper", "power"), ZAP);
  assert.deepEqual(parseItem(ZAP), { building: "zapper", track: "power" });
  assert.equal(parseItem("nocolon"), null);
  assert.equal(parseItem(":power"), null);
  assert.equal(parseItem("zapper:"), null);
  const known = knownItems(game);
  assert.ok(known.has(ZAP));
  assert.ok(!known.has("solar:power"));
  assert.equal(known.size, game.buildings.reduce((sum, entry) => sum + entry.tracks.length, 0));
});

test("a document without groups has no areas", () => {
  assert.deepEqual(areas(game), []);
  assert.deepEqual(validateGroups(game), []);
  assert.deepEqual(validateGroups({ ...fresh(), groups: null }), []);
});

test("areas get unique names and can be renamed, moved and removed", () => {
  const doc = fresh();
  assert.equal(addArea(doc, "Neu"), 0);
  assert.equal(addArea(doc, "Neu"), 1);
  assert.equal(addArea(doc, "neu"), 2);
  assert.deepEqual(doc.groups.map((area) => area.name), ["Neu", "Neu 2", "neu 3"]);
  assert.equal(renameArea(doc, 0, "  Offensive  "), null);
  assert.equal(doc.groups[0].name, "Offensive");
  assert.equal(renameArea(doc, 1, "OFFENSIVE"), "GROUP_DUPLICATE");
  assert.equal(renameArea(doc, 1, "   "), "GROUP_NAME");
  assert.equal(renameArea(doc, 1, "x".repeat(NAME_LIMIT + 1)), "GROUP_NAME");
  assert.equal(renameArea(doc, 1, "x".repeat(NAME_LIMIT)), null);
  assert.equal(renameArea(doc, 0, "offensive"), null);
  assert.equal(renameArea(doc, 9, "Fehlt"), "GROUPS");
  assert.equal(moveArea(doc, 0, 1), 1);
  assert.equal(doc.groups[1].name, "offensive");
  assert.equal(moveArea(doc, 0, -1), 0);
  assert.equal(moveArea(doc, 2, 1), 2);
  assert.equal(removeArea(doc, 2), 1);
  assert.equal(removeArea(doc, 0), 0);
  assert.equal(removeArea(doc, 0), -1);
  assert.equal(removeArea(doc, 0), -1);
  assert.deepEqual(doc.groups, []);
});

test("the number of areas is capped", () => {
  const doc = fresh();
  for (let index = 0; index < AREA_LIMIT; index += 1) assert.equal(addArea(doc, "A"), index);
  assert.equal(addArea(doc, "A"), -1);
  assert.equal(doc.groups.length, AREA_LIMIT);
  assert.equal(uniqueName([{ name: "A" }, { name: "A 2" }], "A"), "A 3");
});

test("subheadings are added, renamed, moved and removed per area", () => {
  const doc = fresh();
  addArea(doc, "Offensive");
  assert.equal(addSection(doc, 0, "Gruppe"), 0);
  assert.equal(addSection(doc, 0, "Gruppe"), 1);
  assert.equal(addSection(doc, 5, "Gruppe"), -1);
  assert.equal(renameSection(doc, 0, 0, "Schaden"), null);
  assert.equal(renameSection(doc, 0, 1, "schaden"), "GROUP_DUPLICATE");
  assert.equal(renameSection(doc, 0, 1, ""), "GROUP_NAME");
  assert.equal(renameSection(doc, 0, 4, "X"), "GROUPS");
  assert.equal(nameProblem(doc.groups[0].sections, "Reichweite"), null);
  assert.equal(moveSection(doc, 0, 0, 1), 1);
  assert.deepEqual(doc.groups[0].sections.map((section) => section.name), ["Gruppe 2", "Schaden"]);
  assert.equal(removeSection(doc, 0, 0), true);
  assert.equal(removeSection(doc, 0, 3), false);
  assert.deepEqual(doc.groups[0].sections.map((section) => section.name), ["Schaden"]);
  addArea(doc, "Wirtschaft");
  assert.equal(addSection(doc, 1, "Schaden"), 0);
});

test("one upgrade can sit in several areas and subheadings at once", () => {
  const doc = fresh();
  addArea(doc, "Offensive");
  addArea(doc, "Wirtschaft");
  addSection(doc, 0, "Schaden");
  assert.equal(addItem(doc, 0, DIRECT, ZAP), true);
  assert.equal(addItem(doc, 0, 0, ZAP), true);
  assert.equal(addItem(doc, 1, DIRECT, ZAP), true);
  assert.equal(addItem(doc, 0, 0, ZAP), false);
  assert.equal(addItem(doc, 0, 0, "solar:power"), false);
  assert.equal(addItem(doc, 0, 7, ZAP), false);
  assert.equal(addItem(doc, 3, DIRECT, ZAP), false);
  assert.deepEqual(membership(doc, ZAP).map((place) => [place.areaName, place.sectionName]), [["Offensive", null], ["Offensive", "Schaden"], ["Wirtschaft", null]]);
  assert.equal(itemCount(doc.groups[0]), 1);
  addItem(doc, 0, 0, LASER);
  assert.equal(itemCount(doc.groups[0]), 2);
  assert.equal(moveItem(doc, 0, 0, 1, -1), 0);
  assert.deepEqual(doc.groups[0].sections[0].items, [LASER, ZAP]);
  assert.equal(removeItem(doc, 0, 0, ZAP), true);
  assert.equal(removeItem(doc, 0, 0, ZAP), false);
  assert.equal(removeItem(doc, 9, 0, ZAP), false);
  assert.equal(moveItem(doc, 9, 0, 0, 1), 0);
  assert.deepEqual(validateGroups(doc), []);
});

test("items per list are capped", () => {
  const doc = fresh();
  addArea(doc, "Alles");
  doc.groups[0].items = Array.from({ length: ITEM_LIMIT }, (_, index) => `x${index}`);
  assert.equal(addItem(doc, 0, DIRECT, ZAP), false);
});

test("pruning removes an upgrade from every area and subheading", () => {
  const doc = sample();
  assert.equal(pruneItem(doc, ZAP), 3);
  assert.deepEqual(membership(doc, ZAP), []);
  assert.equal(pruneItem(doc, ZAP), 0);
  assert.deepEqual(doc.groups[0].sections[0].items, [LASER]);
});

test("target options skip places that already hold the upgrade", () => {
  const doc = sample();
  const values = targetOptions(doc, ZAP).map((option) => option.value);
  assert.deepEqual(values, [targetValue(0, 1), targetValue(1, DIRECT)]);
  assert.equal(targetOptions(doc, SOLAR).find((option) => option.value === "0/0").label, "Offensive › Schaden");
  assert.deepEqual(parseTarget("1/-1"), { area: 1, section: DIRECT });
  assert.equal(parseTarget("x"), null);
});

test("blocks list direct items first and then every subheading", () => {
  const doc = sample();
  assert.deepEqual(blocks(doc.groups[0]).map((block) => [block.section, block.name, block.items.length]), [[DIRECT, null, 1], [0, "Schaden", 2], [1, "Reichweite", 1]]);
  assert.deepEqual(blocks(undefined), []);
  const rows = overviewRows(doc, game.names);
  const grouped = groupRows(rows, doc.groups[1]);
  assert.deepEqual(grouped.map((block) => block.name), ["Energie"]);
  assert.deepEqual(grouped[0].rows.map((row) => row.key), [SOLAR, ZAP]);
  assert.deepEqual(groupRows(rows, doc.groups[0]).map((block) => block.rows.length), [1, 2, 1]);
});

test("overview rows carry the upgrade key", () => {
  const rows = overviewRows(game, game.names);
  assert.ok(rows.every((row) => row.key === `${row.id}:${row.trackId}`));
});

test("the live check mirrors the model error codes", () => {
  const cases = [
    [(doc) => { doc.groups = {}; }, "GROUPS", "groups"],
    [(doc) => { doc.groups = Array.from({ length: AREA_LIMIT + 1 }, (_, index) => ({ name: `A${index}` })); }, "GROUPS", "groups"],
    [(doc) => { doc.groups = [7]; }, "GROUPS", "groups.0"],
    [(doc) => { doc.groups = [{ name: "A", extra: 1 }]; }, "GROUPS", "groups.0"],
    [(doc) => { doc.groups = [{ name: "A", items: "x" }]; }, "GROUPS", "groups.0.items"],
    [(doc) => { doc.groups = [{ name: "A", sections: {} }]; }, "GROUPS", "groups.0.sections"],
    [(doc) => { doc.groups = [{ name: "A", sections: [{ name: "B", bogus: true }] }]; }, "GROUPS", "groups.0.sections.0"],
    [(doc) => { doc.groups = [{ name: " " }]; }, "GROUP_NAME", "groups.0.name"],
    [(doc) => { doc.groups = [{ name: 3 }]; }, "GROUP_NAME", "groups.0.name"],
    [(doc) => { doc.groups = [{ name: "x".repeat(NAME_LIMIT + 1) }]; }, "GROUP_NAME", "groups.0.name"],
    [(doc) => { doc.groups = [{ name: "A", sections: [{ items: [] }] }]; }, "GROUP_NAME", "groups.0.sections.0.name"],
    [(doc) => { doc.groups = [{ name: "A" }, { name: " a " }]; }, "GROUP_DUPLICATE", "groups.1.name"],
    [(doc) => { doc.groups = [{ name: "A", sections: [{ name: "B" }, { name: "b" }] }]; }, "GROUP_DUPLICATE", "groups.0.sections.1.name"],
    [(doc) => { doc.groups = [{ name: "A", items: [ZAP, ZAP] }]; }, "GROUP_DUPLICATE", "groups.0.items.1"],
    [(doc) => { doc.groups = [{ name: "A", items: ["solar:power"] }]; }, "GROUP_ITEM", "groups.0.items.0"],
    [(doc) => { doc.groups = [{ name: "A", items: ["ghost:power"] }]; }, "GROUP_ITEM", "groups.0.items.0"],
    [(doc) => { doc.groups = [{ name: "A", sections: [{ name: "B", items: [5] }] }]; }, "GROUP_ITEM", "groups.0.sections.0.items.0"],
  ];
  for (const [mutate, code, path] of cases) {
    const doc = fresh();
    mutate(doc);
    assert.ok(validateGroups(doc).some((error) => error.code === code && error.path === path), `${code} ${path}`);
  }
  const listed = fresh();
  find(listed, "zapper").tracks = find(listed, "zapper").tracks.filter((track) => track !== "power");
  listed.groups = [{ name: "A", items: [ZAP] }];
  assert.deepEqual(validateGroups(listed).map((error) => error.code), ["GROUP_ITEM"]);
  assert.deepEqual(validateGroups(sample()), []);
  assert.deepEqual(validateGroups({ ...fresh(), groups: [{ name: "Leer" }] }), []);
});

test("group edits show up as changes and an empty list does not", () => {
  const doc = sample();
  const paths = computeChanges(game, doc).map((change) => change.path);
  assert.ok(paths.includes("groups.order"));
  assert.ok(paths.includes("groups.Offensive.items"));
  assert.ok(paths.includes("groups.Offensive.sections"));
  assert.ok(paths.includes("groups.Offensive.section.Schaden"));
  assert.deepEqual(computeChanges(game, { ...fresh(), groups: [] }), []);
  assert.equal(indexGroups(doc.groups, {})["groups.Wirtschaft.section.Energie"], `${SOLAR}, ${ZAP}`);
  assert.deepEqual(indexGroups(undefined, {}), {});
  const moved = sample();
  moved.groups.reverse();
  assert.deepEqual(computeChanges(sample(), moved).map((change) => change.path), ["groups.order"]);
});

test("the overview creates areas, subheadings and items and groups the table", async () => {
  const { overviewView } = await import("../../web/js/views/overviewView.js");
  const { groupsUi } = await import("../../web/js/views/groupsPanel.js");
  const ctx = context();
  const sort = { key: "benefit", direction: "desc" };
  let root = overviewView(ctx, sort, () => {});
  assert.ok(root.text().includes("groups.none"));
  const rowCount = root.findAll((node) => node.tagName === "tr").length;
  assert.equal(rowCount, overviewRows(game, game.names).length + 1);
  byText(root, "groups.add")[0].dispatch("click");
  assert.equal(ctx.doc.groups.length, 1);
  assert.equal(groupsUi(ctx.view).area, "0");
  root = overviewView(ctx, sort, () => {});
  byText(root, "groups.addSection")[0].dispatch("click");
  root = overviewView(ctx, sort, () => {});
  const pickers = combo(root, "groups.itemLabel");
  assert.equal(pickers.length, 2);
  pick(pickers[0], ZAP);
  root = overviewView(ctx, sort, () => {});
  pick(combo(root, "groups.itemLabel")[1], ZAP);
  root = overviewView(ctx, sort, () => {});
  pick(combo(root, "groups.itemLabel")[1], LASER);
  assert.deepEqual(ctx.doc.groups[0].items, [ZAP]);
  assert.deepEqual(ctx.doc.groups[0].sections[0].items, [ZAP, LASER]);
  root = overviewView(ctx, sort, () => {});
  const groupRowsShown = root.findAll((node) => node.tagName === "tr" && node.className === "group-row");
  assert.equal(groupRowsShown.length, 1);
  assert.equal(root.findAll((node) => node.tagName === "tr").length, 1 + 1 + 1 + 2);
  const inputs = root.findAll((node) => node.tagName === "input" && node.type === "text");
  inputs[0].value = "Offensive";
  inputs[0].dispatch("change");
  assert.equal(ctx.doc.groups[0].name, "Offensive");
  root = overviewView(ctx, sort, () => {});
  const section = root.findAll((node) => node.tagName === "input" && node.type === "text")[1];
  section.value = "Schaden";
  section.dispatch("change");
  assert.equal(ctx.doc.groups[0].sections[0].name, "Schaden");
  assert.ok(ctx.store.canUndo());
});

test("renaming to a taken or empty name shows a notice and keeps the document", async () => {
  const { overviewView } = await import("../../web/js/views/overviewView.js");
  const { groupsUi } = await import("../../web/js/views/groupsPanel.js");
  const ctx = context(sample());
  groupsUi(ctx.view).area = "1";
  let root = overviewView(ctx, { key: "benefit", direction: "desc" }, () => {});
  const input = root.findAll((node) => node.tagName === "input" && node.type === "text")[0];
  input.value = "offensive";
  input.dispatch("change");
  assert.equal(ctx.doc.groups[1].name, "Wirtschaft");
  assert.equal(groupsUi(ctx.view).notice, "error.GROUP_DUPLICATE");
  assert.ok(!ctx.store.canUndo());
  input.value = "";
  input.dispatch("change");
  assert.equal(groupsUi(ctx.view).notice, "error.GROUP_NAME");
  input.value = "Wirtschaft";
  input.dispatch("change");
  assert.equal(groupsUi(ctx.view).notice, "");
  assert.ok(!ctx.store.canUndo());
  root = overviewView(ctx, { key: "benefit", direction: "desc" }, () => {});
  assert.ok(root.findAll((node) => node.className === "field-error").length === 0);
});

test("areas and subheadings can be sorted and deleted after confirmation", async () => {
  const { overviewView } = await import("../../web/js/views/overviewView.js");
  const { groupsUi, areaOptions } = await import("../../web/js/views/groupsPanel.js");
  const ctx = context(sample());
  const sort = { key: "benefit", direction: "desc" };
  groupsUi(ctx.view).area = "0";
  let root = overviewView(ctx, sort, () => {});
  root.findAll((node) => node.tagName === "button" && node.attributes["aria-label"] === "action.down")[0].dispatch("click");
  assert.deepEqual(ctx.doc.groups.map((area) => area.name), ["Wirtschaft", "Offensive"]);
  assert.equal(groupsUi(ctx.view).area, "1");
  root = overviewView(ctx, sort, () => {});
  const head = root.findAll((node) => node.className === "row-edit group-section-head")[0];
  head.findAll((node) => node.tagName === "button" && node.attributes["aria-label"] === "action.down")[0].dispatch("click");
  assert.deepEqual(ctx.doc.groups[1].sections.map((section) => section.name), ["Reichweite", "Schaden"]);
  globalThis.confirm = () => false;
  root = overviewView(ctx, sort, () => {});
  root.findAll((node) => node.attributes["aria-label"] === "groups.deleteSection")[0].dispatch("click");
  assert.equal(ctx.doc.groups[1].sections.length, 2);
  globalThis.confirm = () => true;
  root.findAll((node) => node.attributes["aria-label"] === "groups.deleteSection")[0].dispatch("click");
  assert.deepEqual(ctx.doc.groups[1].sections.map((section) => section.name), ["Schaden"]);
  root = overviewView(ctx, sort, () => {});
  root.findAll((node) => node.attributes["aria-label"] === "groups.delete")[1].dispatch("click");
  assert.deepEqual(ctx.doc.groups.map((area) => area.name), ["Wirtschaft"]);
  assert.equal(groupsUi(ctx.view).area, "0");
  root = overviewView(ctx, sort, () => {});
  root.findAll((node) => node.attributes["aria-label"] === "groups.delete")[0].dispatch("click");
  assert.deepEqual(ctx.doc.groups, []);
  assert.equal(groupsUi(ctx.view).area, "all");
  delete globalThis.confirm;
  assert.equal(areaOptions(sample())[0].value, "all");
  assert.equal(areaOptions(sample()).length, 3);
});

test("the area filter switches the table and falls back when an area vanishes", async () => {
  const { overviewView } = await import("../../web/js/views/overviewView.js");
  const { groupsUi, selectedArea } = await import("../../web/js/views/groupsPanel.js");
  const ctx = context(sample());
  const sort = { key: "benefit", direction: "desc" };
  let root = overviewView(ctx, sort, () => {});
  pick(combo(root, "groups.filter")[0], "Wirtschaft");
  assert.equal(groupsUi(ctx.view).area, "1");
  root = overviewView(ctx, sort, () => {});
  assert.equal(root.findAll((node) => node.tagName === "tr" && node.className === "group-row").length, 1);
  groupsUi(ctx.view).area = "9";
  assert.equal(selectedArea(ctx), -1);
  assert.equal(groupsUi(ctx.view).area, "all");
  ctx.store.update((doc) => { doc.groups[0].items = []; doc.groups[0].sections = []; });
  groupsUi(ctx.view).area = "0";
  root = overviewView(ctx, sort, () => {});
  assert.ok(root.text().includes("groups.areaEmpty"));
});

test("an overview row opens the building with its track expanded", async () => {
  const { overviewView } = await import("../../web/js/views/overviewView.js");
  const ctx = context();
  ctx.view.collapsed.add("upgrades:laser");
  const root = overviewView(ctx, { key: "benefit", direction: "desc" }, () => {});
  const row = overviewRows(game, game.names).find((item) => item.key === LASER);
  const line = root.findAll((node) => node.tagName === "tr" && node.children[1]?.text() === row.track && node.children[0].text().includes(row.building))[0];
  line.find((node) => node.tagName === "button" && node.title === "overview.open").dispatch("click");
  assert.equal(ctx.view.tab, "buildings");
  assert.equal(ctx.view.building, "laser");
  assert.ok(ctx.view.open.has(LASER));
  assert.ok(!ctx.view.collapsed.has("upgrades:laser"));
});

test("the building panel shows and edits the areas of a track", async () => {
  const { buildingPanel } = await import("../../web/js/views/buildingView.js");
  const ctx = context(sample());
  ctx.view.open.add(ZAP);
  let root = buildingPanel(ctx, find(ctx.doc, "zapper"));
  const pills = root.findAll((node) => node.className === "pill group-pill");
  assert.deepEqual(pills.map((node) => node.text().replace("✕", "")), ["Offensive", "Offensive › Schaden", "Wirtschaft › Energie"]);
  pick(combo(root, "groups.addTo")[0], "Wirtschaft");
  assert.ok(ctx.doc.groups[1].items.includes(ZAP));
  root = buildingPanel(ctx, find(ctx.doc, "zapper"));
  root.findAll((node) => node.className === "pill-remove")[0].dispatch("click");
  assert.ok(!ctx.doc.groups[0].items.includes(ZAP));
  const empty = context();
  empty.view.open.add(ZAP);
  assert.equal(buildingPanel(empty, find(empty.doc, "zapper")).findAll((node) => node.className === "track-groups").length, 0);
});

test("removing a track also removes it from every area", async () => {
  const { buildingPanel } = await import("../../web/js/views/buildingView.js");
  const ctx = context(sample());
  ctx.view.open.add(ZAP);
  const root = buildingPanel(ctx, find(ctx.doc, "zapper"));
  root.findAll((node) => node.tagName === "button" && node.className === "icon danger" && node.title === "action.remove")[0].dispatch("click");
  assert.ok(!find(ctx.doc, "zapper").tracks.includes("power"));
  assert.deepEqual(membership(ctx.doc, ZAP), []);
  assert.deepEqual(validateGroups(ctx.doc), []);
});

test("adding a track uses a searchable dropdown", async () => {
  const { buildingPanel } = await import("../../web/js/views/buildingView.js");
  const ctx = context();
  const root = buildingPanel(ctx, find(ctx.doc, "solar"));
  assert.equal(root.findAll((node) => node.tagName === "select").length, 0);
  const trigger = combo(root, "action.addTrack")[0];
  assert.ok(trigger.text().includes("action.addTrack"));
  assert.ok(trigger.className.includes("prompt"));
  pick(trigger, "chain");
  assert.equal(find(ctx.doc, "solar").tracks.at(-1), "chain");
});
