import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { trackConfig, planOf, mode, maxLevel, snapshotLevels, buildFormulaLevels, COST_VARIABLES, EFFECT_VARIABLES, MAX_LEVELS } from "../formulas.js";
import { ExpressionError } from "../expr.js";
import { numberField } from "./components.js";

const MODES = ["params", "formula", "table"];
export const HISTORY_LIMIT = 30;
export const FORMULA_KINDS = ["cost", "effect"];

export function formulaHistory(doc, kind) {
  return doc.formula_history?.[kind] ?? [];
}

export function rememberFormula(doc, kind, text) {
  const value = String(text).trim();
  if (!value) return;
  doc.formula_history ??= {};
  const rest = formulaHistory(doc, kind).filter((item) => item !== value);
  doc.formula_history[kind] = [value, ...rest].slice(0, HISTORY_LIMIT);
}

export function forgetFormula(doc, kind, text) {
  if (!doc.formula_history?.[kind]) return;
  doc.formula_history[kind] = doc.formula_history[kind].filter((item) => item !== text);
}

export function matchesFormula(doc, entry, track) {
  const plan = planOf(entry, track);
  try {
    return JSON.stringify(buildFormulaLevels(doc, entry, plan)) === JSON.stringify(plan.levels);
  } catch {
    return false;
  }
}

export function resetToFormula(doc, entry, track) {
  applyFormula(doc, entry, track, {});
}

export function defaultFormulas(doc, entry, track) {
  const config = trackConfig(doc, entry, track);
  const growth = config.growth ?? doc.system.track_growth;
  const cost = `base * ${number(config.price, 6)} * ${number(growth, 6)}^level`;
  const effect = config.gain !== undefined
    ? `1 + ${number(config.gain, 6)} * (${number(config.gain_growth, 6)}^level - 1) / (${number(config.gain_growth, 6)} - 1)`
    : `1 + ${number(config.step, 6)} * level`;
  return { cost, effect };
}

export function describeError(error) {
  if (error instanceof ExpressionError) return t(`expr.${error.code}`, { detail: error.detail });
  if (error.code === "MAX") return t("expr.MAX", { limit: MAX_LEVELS });
  throw error;
}

function memoryKey(entry, track, name) {
  return `${entry.id}:${track}:${name}`;
}

function copy(value) {
  return JSON.parse(JSON.stringify(value));
}

export function switchMode(doc, entry, track, target, memory = {}) {
  const current = mode(entry, track);
  if (current === target) return;
  const levels = snapshotLevels(doc, entry, track);
  const max = maxLevel(doc, entry, track);
  const leaving = planOf(entry, track);
  if (leaving) memory[memoryKey(entry, track, current)] = copy(leaving);
  const saved = memory[memoryKey(entry, track, target)];
  entry.plans = entry.plans ?? {};
  if (target === "params") {
    delete entry.plans[track];
  } else if (saved) {
    entry.plans[track] = copy(saved);
  } else if (target === "table") {
    entry.plans[track] = { mode: "table", levels };
  } else {
    const formulas = defaultFormulas(doc, entry, track);
    entry.plans[track] = { mode: "formula", max, cost: formulas.cost, effect: formulas.effect, levels };
  }
  if (Object.keys(entry.plans).length === 0) delete entry.plans;
}

export function applyFormula(doc, entry, track, patch) {
  const plan = { ...planOf(entry, track), ...patch };
  plan.levels = buildFormulaLevels(doc, entry, plan);
  entry.plans[track] = plan;
  for (const kind of FORMULA_KINDS) if (kind in patch) rememberFormula(doc, kind, patch[kind]);
}

function modeSwitch(ctx, entry, track) {
  const active = mode(entry, track);
  return h("div", { class: "mode-switch", role: "group", "aria-label": t("plan.mode") },
    MODES.map((name) => h("button", {
      class: name === active ? "primary" : "",
      "aria-pressed": String(name === active),
      onclick: () => ctx.store.update((doc) => switchMode(doc, doc.buildings.find((item) => item.id === entry.id), track, name, ctx.view.memory)),
    }, t(`plan.${name}`))));
}

function draftKey(entry, track, key) {
  return `${entry.id}:${track}:${key}`;
}

function draftValue(ctx, entry, track, key) {
  return ctx.view.drafts[draftKey(entry, track, key)] ?? planOf(entry, track)[key];
}

export function pendingPatch(drafts, entry, track) {
  const plan = planOf(entry, track);
  const patch = {};
  for (const key of ["max", "cost", "effect"]) {
    const draft = drafts[draftKey(entry, track, key)];
    if (draft !== undefined && draft !== plan[key]) patch[key] = draft;
  }
  return patch;
}

function clearDrafts(view, entry, track) {
  for (const key of ["max", "cost", "effect"]) {
    delete view.drafts[draftKey(entry, track, key)];
    delete view.drafts[`${draftKey(entry, track, key)}:pick`];
  }
  delete view.planErrors[draftKey(entry, track, "apply")];
}

function textField(ctx, entry, track, key, label, desc) {
  const pickKey = `${draftKey(entry, track, key)}:pick`;
  const input = h("input", { type: "text", value: draftValue(ctx, entry, track, key), spellcheck: false, autocomplete: "off" });
  input.addEventListener("input", () => {
    ctx.view.drafts[draftKey(entry, track, key)] = input.value;
    delete ctx.view.drafts[pickKey];
    refreshApply(ctx, entry, track);
  });
  return h("div", { class: "field wide" },
    h("label", { class: "field" }, h("span", {}, label), input),
    h("small", { class: "field-desc" }, desc),
    historyPicker(ctx, key, pickKey, (text) => {
      ctx.view.drafts[draftKey(entry, track, key)] = text;
      ctx.render();
    }));
}

function refreshApply(ctx, entry, track) {
  const button = document.getElementById(`apply-${entry.id}-${track}`);
  if (button) button.disabled = Object.keys(pendingPatch(ctx.view.drafts, entry, track)).length === 0;
}

function historyPicker(ctx, kind, pickKey, commit) {
  const items = formulaHistory(ctx.doc, kind);
  const picked = items.includes(ctx.view.drafts[pickKey]) ? ctx.view.drafts[pickKey] : "";
  const select = h("select", { "aria-label": t("plan.history") },
    h("option", { value: "" }, t("plan.historyPick", { count: items.length })),
    items.map((item) => h("option", { value: item, selected: item === picked }, item)));
  select.addEventListener("change", () => {
    if (!select.value) {
      delete ctx.view.drafts[pickKey];
      ctx.render();
      return;
    }
    ctx.view.drafts[pickKey] = select.value;
    commit(select.value);
  });
  const remove = h("button", { class: "danger", disabled: !picked, title: t("plan.historyDelete"), onclick: () => {
    delete ctx.view.drafts[pickKey];
    ctx.store.update((doc) => forgetFormula(doc, kind, picked));
  } }, t("plan.historyDelete"));
  return h("div", { class: "history-row" }, select, remove);
}

function formulaEditor(ctx, entry, track) {
  return h("div", { class: "plan" },
    numberField(t("field.max"), draftValue(ctx, entry, track, "max"), (value) => {
      ctx.view.drafts[draftKey(entry, track, "max")] = value;
      ctx.render();
    }, { integer: true, min: 1, desc: t("desc.max") }),
    textField(ctx, entry, track, "cost", t("plan.costFormula"), t("desc.costFormula")),
    textField(ctx, entry, track, "effect", t("plan.effectFormula"), t("desc.effectFormula")),
    applyRow(ctx, entry, track),
    h("p", { class: "note" }, t("plan.variablesCost", { names: COST_VARIABLES.join(", ") })),
    h("p", { class: "note" }, t("plan.variablesEffect", { names: EFFECT_VARIABLES.join(", ") })),
    h("p", { class: "note" }, t("plan.functions")),
    resetRow(ctx, entry, track));
}

export function applyPending(ctx, entry, track) {
  const patch = pendingPatch(ctx.view.drafts, entry, track);
  if (Object.keys(patch).length === 0) return;
  try {
    ctx.store.update((doc) => applyFormula(doc, doc.buildings.find((item) => item.id === entry.id), track, patch));
    clearDrafts(ctx.view, entry, track);
  } catch (error) {
    ctx.view.planErrors[draftKey(entry, track, "apply")] = describeError(error);
    ctx.render();
  }
}

function applyRow(ctx, entry, track) {
  const error = ctx.view.planErrors[draftKey(entry, track, "apply")];
  const pending = Object.keys(pendingPatch(ctx.view.drafts, entry, track)).length > 0;
  return h("div", { class: "reset-row" },
    h("button", { id: `apply-${entry.id}-${track}`, class: "primary", disabled: !pending, onclick: () => applyPending(ctx, entry, track) }, t("plan.apply")),
    h("span", { class: "note" }, t(pending ? "plan.pending" : "plan.applied")),
    error ? h("span", { class: "field-error", role: "alert" }, error) : null);
}

function resetRow(ctx, entry, track) {
  const same = matchesFormula(ctx.doc, entry, track);
  return h("div", { class: "reset-row" },
    h("p", { class: "note" }, t(same ? "plan.matches" : "plan.differs")),
    h("button", { disabled: same, onclick: () => {
      try {
        ctx.store.update((doc) => resetToFormula(doc, doc.buildings.find((item) => item.id === entry.id), track));
      } catch (error) {
        ctx.toast(describeError(error), "error");
      }
    } }, t("plan.resetToFormula")));
}

export function planEditor(ctx, entry, track) {
  const active = mode(entry, track);
  return h("div", { class: "plan-editor" },
    modeSwitch(ctx, entry, track),
    active === "formula" ? formulaEditor(ctx, entry, track) : null,
    active === "table" ? h("p", { class: "note" }, t("plan.tableModeNote")) : null);
}
