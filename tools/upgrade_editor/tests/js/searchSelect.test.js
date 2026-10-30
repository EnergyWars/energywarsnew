import test from "node:test";
import assert from "node:assert/strict";
import { installFakeDom } from "./fakeDom.js";
import { filterOptions, stepActive, searchSelect } from "../../web/js/views/components.js";

installFakeDom();

const OPTIONS = [
  { value: "crawler", label: "Krabbler", hint: "crawler" },
  { value: "wasp", label: "Stachler" },
  { value: "tank", label: "Panzer" },
];

function build(extra = {}) {
  const changes = [];
  const root = searchSelect({ options: OPTIONS, value: "wasp", onChange: (value) => changes.push(value), label: "Monster", ...extra });
  const trigger = root.find((node) => node.attributes.role === "combobox");
  const input = root.find((node) => node.attributes.role === "searchbox");
  const list = root.find((node) => node.attributes.role === "listbox");
  const panel = root.children[1];
  return { root, trigger, input, list, panel, changes };
}

const options = (list) => list.findAll((node) => node.attributes.role === "option");

test("filter matches label and value case-insensitively", () => {
  assert.equal(filterOptions(OPTIONS, "").length, 3);
  assert.deepEqual(filterOptions(OPTIONS, "KRAB").map((o) => o.value), ["crawler"]);
  assert.deepEqual(filterOptions(OPTIONS, "ank").map((o) => o.value), ["tank"]);
  assert.deepEqual(filterOptions(OPTIONS, "zzz"), []);
});

test("active index steps and clamps", () => {
  assert.equal(stepActive(-1, "ArrowDown", 3), 0);
  assert.equal(stepActive(2, "ArrowDown", 3), 2);
  assert.equal(stepActive(0, "ArrowUp", 3), 0);
  assert.equal(stepActive(-1, "ArrowUp", 3), 2);
  assert.equal(stepActive(1, "Home", 3), 0);
  assert.equal(stepActive(1, "End", 3), 2);
  assert.equal(stepActive(1, "ArrowDown", 0), -1);
});

test("closed select shows the current label with aria state", () => {
  const { trigger, panel } = build();
  assert.equal(trigger.text().includes("Stachler"), true);
  assert.equal(trigger.attributes["aria-expanded"], "false");
  assert.equal(panel.hidden, true);
  assert.equal(trigger.attributes["aria-haspopup"], "listbox");
});

test("clicking opens the list with the current option active", () => {
  const { trigger, panel, input, list } = build();
  trigger.dispatch("click");
  assert.equal(panel.hidden, false);
  assert.equal(trigger.attributes["aria-expanded"], "true");
  assert.equal(input.focused, true);
  const rows = options(list);
  assert.equal(rows.length, 3);
  assert.equal(rows[1].attributes["aria-selected"], "true");
  assert.ok(rows[1].className.includes("active"));
  assert.equal(input.attributes["aria-activedescendant"], rows[1].id);
});

test("typing filters and enter selects the first match", () => {
  const { trigger, input, list, panel, changes } = build();
  trigger.dispatch("click");
  input.value = "pan";
  input.dispatch("input");
  assert.equal(options(list).length, 1);
  input.dispatch("keydown", { key: "Enter" });
  assert.deepEqual(changes, ["tank"]);
  assert.equal(panel.hidden, true);
});

test("arrow keys move the active option and enter selects it", () => {
  const { trigger, input, changes } = build();
  trigger.dispatch("click");
  const down = input.dispatch("keydown", { key: "ArrowDown" });
  assert.equal(down.prevented, true);
  input.dispatch("keydown", { key: "Enter" });
  assert.deepEqual(changes, ["tank"]);
});

test("selecting the current value does not fire a change", () => {
  const { trigger, input, changes } = build();
  trigger.dispatch("click");
  input.dispatch("keydown", { key: "Enter" });
  assert.deepEqual(changes, []);
});

test("escape closes without selecting", () => {
  const { trigger, input, panel, changes } = build();
  trigger.dispatch("click");
  input.dispatch("keydown", { key: "Escape" });
  assert.equal(panel.hidden, true);
  assert.equal(trigger.focused, true);
  assert.deepEqual(changes, []);
});

test("clicking an option selects it", () => {
  const { trigger, list, changes } = build();
  trigger.dispatch("click");
  const row = options(list)[0];
  const down = row.dispatch("pointerdown");
  assert.equal(down.prevented, true);
  row.dispatch("click");
  assert.deepEqual(changes, ["crawler"]);
});

test("losing focus outside closes the list, focus inside keeps it", () => {
  const { root, trigger, input, panel } = build();
  trigger.dispatch("click");
  root.dispatch("focusout", { relatedTarget: input });
  assert.equal(panel.hidden, false);
  root.dispatch("focusout", { relatedTarget: null });
  assert.equal(panel.hidden, true);
});

test("empty result shows a placeholder row and arrow down on the trigger opens", () => {
  const { trigger, input, list, panel } = build({ empty: "Nothing" });
  trigger.dispatch("keydown", { key: "ArrowDown" });
  assert.equal(panel.hidden, false);
  input.value = "qqq";
  input.dispatch("input");
  assert.equal(options(list).length, 0);
  assert.ok(list.text().includes("Nothing"));
  assert.equal(input.attributes["aria-activedescendant"], undefined);
});

test("disabled select does not open", () => {
  const { trigger, panel } = build({ disabled: true });
  trigger.dispatch("click");
  assert.equal(panel.hidden, true);
});
