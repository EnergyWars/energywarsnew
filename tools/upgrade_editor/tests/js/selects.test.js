import test from "node:test";
import assert from "node:assert/strict";
import { game, fresh, find } from "./data.js";
import { installFakeDom } from "./fakeDom.js";
import { create } from "../../web/js/store.js";
import { searchSelect, choiceSelect, choiceField, usesSearch, NATIVE_SELECT_LIMIT } from "../../web/js/views/components.js";
import { saveFormula, savedFormulas, planEditor } from "../../web/js/views/planEditor.js";

installFakeDom();

const options = (count) => Array.from({ length: count }, (_, index) => ({ value: `v${index}`, label: `Label ${index}` }));
const combos = (root) => root.findAll((node) => node.attributes.role === "combobox");

function context(doc = fresh()) {
  const store = create(doc, game);
  const ctx = { original: game, names: game.names, store, view: { collapsed: new Set(), open: new Set(), drafts: {}, tools: {}, hidden: new Set(), gainModes: {}, planErrors: {} }, renders: 0, render() { this.renders += 1; }, toast() {} };
  Object.defineProperty(ctx, "doc", { get: () => store.state.document });
  return ctx;
}

function choose(trigger, text) {
  trigger.dispatch("click");
  trigger.parentNode.findAll((node) => node.attributes.role === "option").find((node) => node.text().includes(text)).dispatch("click");
}

test("small fixed choices stay a native select, longer lists get a search", () => {
  assert.equal(usesSearch(options(NATIVE_SELECT_LIMIT)), false);
  assert.equal(usesSearch(options(NATIVE_SELECT_LIMIT + 1)), true);
  const changes = [];
  const native = choiceSelect({ options: options(3), value: "v1", onChange: (value) => changes.push(value), label: "Klein" });
  assert.equal(native.tagName, "select");
  assert.equal(native.value, "v1");
  assert.equal(native.children.length, 3);
  native.value = "v2";
  native.dispatch("change");
  const search = choiceSelect({ options: options(8), value: "v5", onChange: (value) => changes.push(value), label: "Groß" });
  assert.equal(search.className, "search-select");
  choose(combos(search)[0], "Label 7");
  assert.deepEqual(changes, ["v2", "v7"]);
});

test("a searchable field is no label so picking an option does not reopen it", () => {
  assert.equal(choiceField("Feld", "v0", options(3), () => {}, "Beschreibung").tagName, "label");
  const field = choiceField("Feld", "v0", options(9), () => {}, "Beschreibung");
  assert.equal(field.tagName, "div");
  assert.equal(field.attributes["data-tip"], "Beschreibung");
  assert.ok(field.text().includes("Beschreibung"));
  assert.equal(choiceField("Feld", "v0", options(2), () => {}).findAll((node) => node.className === "field-desc").length, 0);
});

test("a prompt is shown until something is picked", () => {
  const empty = searchSelect({ options: options(3), value: null, onChange: () => {}, label: "Wahl", prompt: "Bitte wählen …" });
  assert.ok(combos(empty)[0].text().includes("Bitte wählen …"));
  assert.ok(combos(empty)[0].className.includes("prompt"));
  const chosen = searchSelect({ options: options(3), value: "v2", onChange: () => {}, label: "Wahl", prompt: "Bitte wählen …" });
  assert.ok(combos(chosen)[0].text().includes("Label 2"));
  assert.ok(!combos(chosen)[0].className.includes("prompt"));
  const plain = searchSelect({ options: options(3), value: "v9", onChange: () => {}, label: "Wahl" });
  assert.ok(combos(plain)[0].text().includes("v9"));
});

test("saved formulas use buttons instead of dropdowns: apply, save with a description and delete", () => {
  const doc = fresh();
  saveFormula(doc, "cost", { name: "Zwei", formula: "base * 2", description: "doppelt so teuer" });
  saveFormula(doc, "metric", { name: "Eff", formula: "1.2", description: "", target: "efficiency" });
  const ctx = context(doc);
  const entry = find(ctx.doc, "zapper");
  ctx.view.tools["zapper:power:tool"] = "formula";
  const press = (root, label, index = 0) => root.findAll((node) => node.tagName === "button" && node.text() === label)[index].dispatch("click");
  let root = planEditor(ctx, entry, "power");
  assert.equal(combos(root).length, 0);
  assert.equal(root.findAll((node) => node.tagName === "button" && node.text() === "plan.applySaved").length, 2);
  assert.equal(root.findAll((node) => node.tagName === "button" && node.text() === "plan.saveFormula").length, 2);
  press(root, "plan.applySaved", 0);
  root = planEditor(ctx, entry, "power");
  assert.ok(root.text().includes("doppelt so teuer"));
  press(root, "plan.savedApply");
  assert.equal(ctx.view.drafts["zapper:power:f:cost"], "base * 2");
  root = planEditor(ctx, entry, "power");
  assert.ok(!root.text().includes("doppelt so teuer"));
  press(root, "plan.applySaved", 1);
  root = planEditor(ctx, entry, "power");
  press(root, "plan.savedApply");
  assert.equal(ctx.view.drafts["zapper:power:f:formula"], "1.2");
  assert.equal(ctx.view.drafts["zapper:power:f:target"], "efficiency");
  press(root, "plan.saveFormula", 1);
  root = planEditor(ctx, entry, "power");
  const name = root.find((node) => node.attributes["aria-label"] === "plan.saveName");
  const description = root.find((node) => node.attributes["aria-label"] === "plan.saveDescription");
  name.value = "Meine Effizienz";
  description.value = "Ausführlich";
  press(root, "plan.saveConfirm");
  assert.deepEqual(savedFormulas(ctx.doc, "metric").map((item) => [item.name, item.formula, item.description, item.target]), [["Eff", "1.2", "", "efficiency"], ["Meine Effizienz", "1.2", "Ausführlich", "efficiency"]]);
  root = planEditor(ctx, entry, "power");
  press(root, "plan.saveFormula", 0);
  root = planEditor(ctx, entry, "power");
  root.find((node) => node.attributes["aria-label"] === "plan.saveName").value = "   ";
  press(root, "plan.saveConfirm");
  assert.equal(savedFormulas(ctx.doc, "cost").length, 1);
  root = planEditor(ctx, entry, "power");
  assert.ok(root.findAll((node) => node.className === "field-error").some((node) => node.textContent === "plan.saveFailed"));
  press(root, "plan.saveCancel");
  root = planEditor(ctx, entry, "power");
  press(root, "plan.applySaved", 0);
  root = planEditor(ctx, entry, "power");
  press(root, "plan.savedDelete");
  assert.deepEqual(savedFormulas(ctx.doc, "cost"), []);
  root = planEditor(ctx, entry, "power");
  press(root, "plan.applySaved", 0);
  root = planEditor(ctx, entry, "power");
  assert.ok(root.text().includes("plan.savedNone"));
});

test("the monster look uses a search while small choices stay native", async () => {
  const { monsterDetail } = await import("../../web/js/views/monsterDetail.js");
  const { monsterUi } = await import("../../web/js/views/monsterState.js");
  const ctx = context();
  monsterUi(ctx.view).kind = "crawler";
  const root = monsterDetail(ctx, "crawler");
  const look = combos(root).filter((node) => node.attributes["aria-label"] === "monsters.f.look");
  assert.equal(look.length, 1);
  choose(look[0], "beetle");
  assert.equal(ctx.doc.enemies.crawler.look, "beetle");
  assert.ok(root.findAll((node) => node.tagName === "select").length >= 2);
});

test("the monster kind filter narrows the catalog", async () => {
  const { visibleKinds } = await import("../../web/js/views/monstersView.js");
  const { monsterUi } = await import("../../web/js/views/monsterState.js");
  const ctx = context();
  const ui = monsterUi(ctx.view);
  ui.kind = "crawler";
  const all = visibleKinds(ctx);
  assert.equal(all.length, Object.keys(game.enemies).length);
  ui.flavor = "boss";
  const bosses = visibleKinds(ctx);
  assert.ok(bosses.length > 0 && bosses.length < all.length);
  assert.ok(bosses.every((kind) => game.enemies[kind].boss));
  ui.flavor = "night";
  assert.ok(visibleKinds(ctx).every((kind) => game.enemies[kind].nocturnal));
  ui.flavor = "all";
  ui.klass = "air";
  assert.ok(visibleKinds(ctx).every((kind) => game.enemies[kind].class === "air"));
});
