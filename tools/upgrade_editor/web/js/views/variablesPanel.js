import { h } from "../dom.js";
import { t } from "../i18n.js";
import { FUNCTION_NAMES, CONSTANT_NAMES } from "../expr.js";
import { COST_VARIABLES, TARGET_VARIABLES } from "../formulas.js";
import { numberField, sectionHeading, isCollapsed } from "./components.js";

export const VARIABLE_LIMIT = 50;
export const VARIABLE_NAME_LIMIT = 40;
export const VARIABLE_DESCRIPTION_LIMIT = 200;
const NAME_PATTERN = /^[a-z_][a-z0-9_]*$/;
const MAX_NUMBER = 1e15;
const RESERVED = new Set([...COST_VARIABLES, ...TARGET_VARIABLES, ...FUNCTION_NAMES, ...CONSTANT_NAMES]);

export function entryVariables(entry) {
  return Array.isArray(entry.variables) ? entry.variables : [];
}

export function validVariableName(name, existing = []) {
  return name.length <= VARIABLE_NAME_LIMIT && NAME_PATTERN.test(name) && !RESERVED.has(name) && !existing.includes(name);
}

function target(doc, id) {
  return doc.buildings.find((entry) => entry.id === id);
}

function toNumber(value) {
  if (typeof value === "string" && value.trim() === "") return NaN;
  return Number(value);
}

export function addVariable(doc, id, { name, value, description = "" }) {
  const entry = target(doc, id);
  const label = String(name ?? "").trim().toLowerCase();
  const amount = toNumber(value);
  const list = entryVariables(entry);
  const valid = entry && list.length < VARIABLE_LIMIT && validVariableName(label, list.map((item) => item.name)) && Number.isFinite(amount) && Math.abs(amount) <= MAX_NUMBER;
  if (!valid) return false;
  entry.variables = [...list, { name: label, value: amount, description: String(description ?? "").trim().slice(0, VARIABLE_DESCRIPTION_LIMIT) }];
  return true;
}

export function updateVariable(doc, id, name, changes) {
  const entry = target(doc, id);
  const item = entry ? entryVariables(entry).find((candidate) => candidate.name === name) : null;
  if (!item) return false;
  if ("value" in changes) {
    const amount = toNumber(changes.value);
    if (!Number.isFinite(amount) || Math.abs(amount) > MAX_NUMBER) return false;
    item.value = amount;
  }
  if ("description" in changes) item.description = String(changes.description ?? "").trim().slice(0, VARIABLE_DESCRIPTION_LIMIT);
  return true;
}

export function deleteVariable(doc, id, name) {
  const entry = target(doc, id);
  if (!entry || !entry.variables) return;
  entry.variables = entry.variables.filter((item) => item.name !== name);
  if (entry.variables.length === 0) delete entry.variables;
}

function addForm(ctx, entry) {
  const name = h("input", { type: "text", maxlength: VARIABLE_NAME_LIMIT, placeholder: t("variables.name"), "aria-label": t("variables.name"), spellcheck: false, autocomplete: "off" });
  const value = h("input", { type: "number", step: "any", placeholder: t("variables.value"), "aria-label": t("variables.value") });
  const description = h("input", { type: "text", maxlength: VARIABLE_DESCRIPTION_LIMIT, placeholder: t("variables.description"), "aria-label": t("variables.description"), autocomplete: "off" });
  const error = h("span", { class: "field-error", role: "alert" });
  const add = () => {
    let done = false;
    ctx.store.update((doc) => { done = addVariable(doc, entry.id, { name: name.value, value: value.value, description: description.value }); });
    if (!done) error.textContent = t("variables.invalid");
  };
  return h("div", { class: "variable-add" },
    h("div", { class: "variable-fields" }, name, value, description),
    h("div", { class: "saved-row" }, h("button", { type: "button", class: "primary", onclick: add }, t("variables.add")), error));
}

function row(ctx, entry, item) {
  const description = h("input", { type: "text", value: item.description, maxlength: VARIABLE_DESCRIPTION_LIMIT, placeholder: t("variables.description"), "aria-label": t("variables.description"), autocomplete: "off" });
  description.addEventListener("change", () => ctx.store.update((doc) => { updateVariable(doc, entry.id, item.name, { description: description.value }); }));
  return h("li", { class: "variable-row" },
    h("code", {}, item.name),
    numberField(t("variables.value"), item.value, (value) => ctx.store.update((doc) => { updateVariable(doc, entry.id, item.name, { value }); })),
    description,
    h("button", { type: "button", class: "danger", onclick: () => ctx.store.update((doc) => deleteVariable(doc, entry.id, item.name)) }, t("variables.delete")));
}

export function variablesCard(ctx, entry) {
  const key = `variables:${entry.id}`;
  const list = entryVariables(entry);
  return h("section", { class: "panel-card" },
    sectionHeading(ctx, key, t("variables.title")),
    isCollapsed(ctx, key) ? null : [
      h("p", { class: "note" }, t("variables.hint")),
      list.length ? h("ul", { class: "variable-list" }, list.map((item) => row(ctx, entry, item))) : h("p", { class: "note" }, t("variables.none")),
      addForm(ctx, entry),
    ]);
}
