import { h } from "../dom.js";
import { t } from "../i18n.js";
import { parse } from "../expr.js";
import { FORMULA_TARGETS } from "../formulas.js";
import { choiceSelect } from "./components.js";

export const SAVED_NAME_LIMIT = 60;
export const SAVED_DESCRIPTION_LIMIT = 1000;
export const SAVED_FORMULA_LIMIT = 500;
export const SAVED_KINDS = ["cost", "metric"];
export const NEW_FORMULA = "\u0000new";

export function savedFormulas(doc, kind) {
  return doc.saved_formulas?.[kind] ?? [];
}

function isValidFormula(text) {
  if (!text || text.length > SAVED_FORMULA_LIMIT) return false;
  try {
    parse(text);
    return true;
  } catch {
    return false;
  }
}

function normalize(kind, { name, formula, description = "", target = null }) {
  const label = String(name ?? "").trim().slice(0, SAVED_NAME_LIMIT);
  const text = String(formula ?? "").trim();
  if (!label || !isValidFormula(text)) return null;
  if (kind === "metric" && !FORMULA_TARGETS.includes(target)) return null;
  const entry = { name: label, formula: text, description: String(description ?? "").trim().slice(0, SAVED_DESCRIPTION_LIMIT) };
  if (kind === "metric") entry.target = target;
  return entry;
}

const sameName = (a, b) => a.toLowerCase() === b.toLowerCase();

function store(doc, kind, list) {
  doc.saved_formulas ??= {};
  doc.saved_formulas[kind] = list;
}

export function saveFormula(doc, kind, input) {
  const entry = normalize(kind, input);
  if (!entry) return false;
  const list = [...savedFormulas(doc, kind)];
  const index = list.findIndex((item) => sameName(item.name, entry.name));
  if (index >= 0) list[index] = entry;
  else list.push(entry);
  store(doc, kind, list);
  return true;
}

export function updateSavedFormula(doc, kind, oldName, input) {
  const entry = normalize(kind, input);
  const list = [...savedFormulas(doc, kind)];
  const index = list.findIndex((item) => item.name === oldName);
  if (!entry || index < 0) return false;
  if (list.some((item, other) => other !== index && sameName(item.name, entry.name))) return false;
  list[index] = entry;
  store(doc, kind, list);
  return true;
}

export function deleteSavedFormula(doc, kind, name) {
  if (!doc.saved_formulas?.[kind]) return;
  doc.saved_formulas[kind] = doc.saved_formulas[kind].filter((item) => item.name !== name);
}

export function formulaForm({ kind, initial = {}, showFormula = false, onSubmit, onCancel }) {
  const name = h("input", { type: "text", value: initial.name ?? "", maxlength: SAVED_NAME_LIMIT, placeholder: t("plan.saveName"), "aria-label": t("plan.saveName"), autocomplete: "off" });
  const formula = showFormula ? h("input", { type: "text", value: initial.formula ?? "", maxlength: SAVED_FORMULA_LIMIT, "aria-label": t("saved.formula"), spellcheck: false, autocomplete: "off" }) : null;
  let target = initial.target ?? FORMULA_TARGETS[0];
  const targetSelect = showFormula && kind === "metric"
    ? choiceSelect({ options: FORMULA_TARGETS.map((key) => ({ value: key, label: t(`values.col.${key}`) })), value: target, label: t("saved.target"), onChange: (value) => { target = value; } })
    : null;
  const description = h("textarea", { rows: 4, value: initial.description ?? "", maxlength: SAVED_DESCRIPTION_LIMIT, placeholder: t("plan.saveDescription"), "aria-label": t("plan.saveDescription") });
  const error = h("span", { class: "field-error", role: "alert" });
  const submit = () => {
    const values = { name: name.value, description: description.value };
    if (showFormula) values.formula = formula.value;
    if (targetSelect) values.target = target;
    if (!onSubmit(values)) error.textContent = t("plan.saveFailed");
  };
  name.addEventListener("keydown", (event) => {
    if (event.key === "Enter") submit();
  });
  return h("div", { class: "saved-form" },
    h("label", { class: "field" }, h("span", {}, t("plan.saveName")), name),
    formula ? h("label", { class: "field" }, h("span", {}, t("saved.formula")), formula) : null,
    targetSelect ? h("label", { class: "field" }, h("span", {}, t("saved.target")), targetSelect) : null,
    h("label", { class: "field" }, h("span", {}, t("plan.saveDescription")), description),
    h("div", { class: "saved-row" },
      h("button", { type: "button", class: "primary", onclick: submit }, t("plan.saveConfirm")),
      h("button", { type: "button", onclick: onCancel }, t("plan.saveCancel")),
      error));
}

const editKey = (kind) => `saved:${kind}:edit`;

export function savedManager(ctx, kind, { refresh, onApply = null, allowCreate = false, manage = false }) {
  const editing = manage ? ctx.view.drafts[editKey(kind)] ?? "" : "";
  const setEditing = (value) => {
    if (value) ctx.view.drafts[editKey(kind)] = value;
    else delete ctx.view.drafts[editKey(kind)];
    refresh();
  };
  const saved = savedFormulas(ctx.doc, kind);
  const create = allowCreate
    ? editing === NEW_FORMULA
      ? formulaForm({
        kind,
        showFormula: true,
        onSubmit: (values) => {
          let done = false;
          ctx.store.update((doc) => { done = saveFormula(doc, kind, values); });
          if (done) setEditing("");
          return done;
        },
        onCancel: () => setEditing(""),
      })
      : h("div", { class: "saved-row" }, h("button", { type: "button", onclick: () => setEditing(NEW_FORMULA) }, t("saved.new")))
    : null;
  const items = saved.length === 0 && editing !== NEW_FORMULA
    ? h("p", { class: "note" }, t("plan.savedNone"))
    : h("ul", { class: "saved-list" }, saved.map((item) => h("li", {}, editing === item.name
      ? formulaForm({
        kind,
        initial: item,
        showFormula: true,
        onSubmit: (values) => {
          let done = false;
          ctx.store.update((doc) => { done = updateSavedFormula(doc, kind, item.name, values); });
          if (done) setEditing("");
          return done;
        },
        onCancel: () => setEditing(""),
      })
      : [
        h("div", { class: "saved-head" },
          h("strong", {}, item.name),
          kind === "metric" ? h("span", { class: "note" }, t(`values.col.${item.target}`)) : null),
        h("code", {}, item.formula),
        item.description ? h("p", { class: "saved-description" }, item.description) : null,
        h("div", { class: "saved-row" },
          onApply ? h("button", { type: "button", class: "primary", onclick: () => onApply(item) }, t("plan.savedApply")) : null,
          manage ? h("button", { type: "button", onclick: () => setEditing(item.name) }, t("saved.edit")) : null,
          manage ? h("button", { type: "button", class: "danger", onclick: () => {
            ctx.store.update((doc) => deleteSavedFormula(doc, kind, item.name));
            refresh();
          } }, t("plan.savedDelete")) : null),
      ])));
  return h("div", { class: "saved-manager" }, items, create);
}
