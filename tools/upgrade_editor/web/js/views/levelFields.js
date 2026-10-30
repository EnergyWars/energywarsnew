import { h } from "../dom.js";
import { t } from "../i18n.js";
import { numberField, searchSelect, choiceField } from "./components.js";

export function describe(node, text) {
  if (text) node.setAttribute("data-tip", text);
  return node;
}

export function numberInput(label, value, onChange, desc, options = {}) {
  return describe(numberField(label, value, onChange, { ...options, desc }), desc);
}

export function textInput(label, value, onChange, desc) {
  const input = h("input", { type: "text", value });
  input.addEventListener("change", () => onChange(input.value.trim()));
  return describe(h("label", { class: "field" }, h("span", {}, label), input, desc ? h("small", { class: "field-desc" }, desc) : null), desc);
}

export function selectInput(label, value, choices, onChange, desc) {
  return choiceField(label, value, choices, onChange, desc);
}

export function checkInput(label, checked, onChange, desc) {
  const input = h("input", { type: "checkbox", checked });
  input.addEventListener("change", () => onChange(input.checked));
  return describe(h("label", { class: "field check" }, h("span", {}, label), input, desc ? h("small", { class: "field-desc" }, desc) : null), desc);
}

export function enemyOptions(enemies, names, name) {
  return Object.keys(enemies).map((kind) => ({ value: kind, label: name(names, `ENEMY_${kind.toUpperCase()}`, kind), hint: kind }));
}

export function monsterSelect(options, value, onChange, label) {
  return searchSelect({ options, value, onChange, label });
}

export function removeButton(onClick, label) {
  return h("button", { type: "button", class: "icon danger", title: label, "aria-label": label, onclick: onClick }, "✕");
}

export function addButton(label, onClick) {
  return h("button", { type: "button", onclick: onClick }, `+ ${label}`);
}

export function errorNote(errors) {
  if (!errors.length) return null;
  return h("ul", { class: "errors", role: "alert" }, errors.map((error) => h("li", {}, `${t(`error.${error.code}`)} – ${error.path}`)));
}
