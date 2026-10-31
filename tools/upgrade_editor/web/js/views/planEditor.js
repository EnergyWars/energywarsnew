import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { trackConfig, planOf, maxLevel, buildFormulaLevels, multiplier, roundTo, writeLevels, COST_VARIABLES, TARGET_VARIABLES, FORMULA_TARGETS, MAX_LEVELS } from "../formulas.js";
import { ExpressionError } from "../expr.js";
import { numberField } from "./components.js";
import { draftKey } from "./valueTable.js";

const TOOLS = ["params", "formula", "table"];
export const SAVED_LIMIT = 50;
export const SAVED_NAME_LIMIT = 60;
export const SAVED_DESCRIPTION_LIMIT = 1000;
export const SAVED_KINDS = ["cost", "metric"];

export function savedFormulas(doc, kind) {
  return doc.saved_formulas?.[kind] ?? [];
}

export function saveFormula(doc, kind, { name, formula, description = "", target = null }) {
  const label = String(name).trim().slice(0, SAVED_NAME_LIMIT);
  const text = String(formula).trim();
  if (!label || !text) return false;
  const entry = { name: label, formula: text, description: String(description).trim().slice(0, SAVED_DESCRIPTION_LIMIT) };
  if (kind === "metric") entry.target = target;
  const list = [...savedFormulas(doc, kind)];
  const index = list.findIndex((item) => item.name.toLowerCase() === label.toLowerCase());
  if (index >= 0) list[index] = entry;
  else if (list.length >= SAVED_LIMIT) return false;
  else list.push(entry);
  doc.saved_formulas ??= {};
  doc.saved_formulas[kind] = list;
  return true;
}

export function deleteSavedFormula(doc, kind, name) {
  if (!doc.saved_formulas?.[kind]) return;
  doc.saved_formulas[kind] = doc.saved_formulas[kind].filter((item) => item.name !== name);
}

export function defaultFormulas(doc, entry, track) {
  const config = trackConfig(doc, entry, track);
  const growth = config.growth ?? doc.system.track_growth;
  const cost = `base * ${number(config.price, 6)} * ${number(growth, 6)}^(level - 1)`;
  const formula = config.gain !== undefined
    ? `start * ${number(config.gain, 6)} * ${number(config.gain_growth, 6)}^(level - 1)`
    : `start * ${number(config.step, 6)}`;
  return { cost, formula, target: FORMULA_TARGETS[0] };
}

export function formulaDefaults(doc, entry, track) {
  const fallback = defaultFormulas(doc, entry, track);
  return { max: maxLevel(doc, entry, track), ...fallback };
}

export function paramDefaults(doc, entry, track) {
  const config = trackConfig(doc, entry, track);
  const params = { max: config.max, price: config.price, growth: config.growth ?? doc.system.track_growth };
  if (config.gain !== undefined) return { ...params, gain: config.gain, gain_growth: config.gain_growth };
  return { ...params, step: config.step };
}

export function paramKeys(params) {
  return "gain" in params ? ["max", "gain", "price", "gain_growth", "growth"] : ["max", "step", "price", "growth"];
}

function paramError() {
  return Object.assign(new Error("PARAM"), { code: "PARAM" });
}

export function paramLevels(doc, entry, params) {
  const positive = (value) => Number.isFinite(value) && value > 0;
  const growing = (value) => Number.isFinite(value) && value > 1;
  if (!Number.isInteger(params.max) || params.max < 1 || params.max > MAX_LEVELS) throw Object.assign(new Error("MAX"), { code: "MAX" });
  const curved = "gain" in params;
  const valid = positive(params.price) && growing(params.growth) && (curved ? positive(params.gain) && growing(params.gain_growth) : positive(params.step));
  if (!valid) throw paramError();
  const config = curved ? { gain: params.gain, gain_growth: params.gain_growth } : { step: params.step };
  return Array.from({ length: params.max }, (_, level) => ({
    cost: Math.max(Math.round(entry.upgrade_base * params.price * params.growth ** level), 1),
    gain: roundTo(multiplier(config, level + 1) - multiplier(config, level)),
  }));
}

export function describeError(error) {
  if (error instanceof ExpressionError) return t(`expr.${error.code}`, { detail: error.detail });
  if (error.code === "MAX") return t("expr.MAX", { limit: MAX_LEVELS });
  if (error.code === "PARAM") return t("error.PARAM");
  if (error.code === "TARGET") return t("error.TARGET");
  throw error;
}

function inputKey(entry, track, name) {
  return `${entry.id}:${track}:${name}`;
}

export function toolOf(view, entry, track) {
  return view.tools[inputKey(entry, track, "tool")] ?? "params";
}

export function formulaInputs(ctx, entry, track) {
  const defaults = formulaDefaults(ctx.doc, entry, track);
  const inputs = {};
  for (const key of Object.keys(defaults)) inputs[key] = ctx.view.drafts[inputKey(entry, track, `f:${key}`)] ?? defaults[key];
  return inputs;
}

export function paramInputs(ctx, entry, track) {
  const defaults = paramDefaults(ctx.doc, entry, track);
  const inputs = {};
  for (const key of Object.keys(defaults)) inputs[key] = ctx.view.drafts[inputKey(entry, track, `p:${key}`)] ?? defaults[key];
  return inputs;
}

function report(ctx, entry, track, error) {
  ctx.view.planErrors[inputKey(entry, track, "fill")] = describeError(error);
  ctx.render();
}

function commitLevels(ctx, entry, track, levels, change = () => {}) {
  delete ctx.view.planErrors[inputKey(entry, track, "fill")];
  delete ctx.view.drafts[draftKey(entry, track)];
  ctx.store.update((doc) => {
    writeLevels(doc.buildings.find((item) => item.id === entry.id), track, levels.map((level) => ({ ...level })));
    change(doc);
  });
}

export function fillFromParams(ctx, entry, track) {
  let levels;
  try {
    levels = paramLevels(ctx.doc, entry, paramInputs(ctx, entry, track));
  } catch (error) {
    report(ctx, entry, track, error);
    return;
  }
  commitLevels(ctx, entry, track, levels);
}

export function fillFromFormula(ctx, entry, track) {
  const inputs = formulaInputs(ctx, entry, track);
  let levels;
  try {
    levels = buildFormulaLevels(ctx.doc, entry, inputs, track);
  } catch (error) {
    report(ctx, entry, track, error);
    return;
  }
  commitLevels(ctx, entry, track, levels);
}

function toolSwitch(ctx, entry, track) {
  const active = toolOf(ctx.view, entry, track);
  return h("div", { class: "mode-switch", role: "group", "aria-label": t("plan.tool") },
    TOOLS.map((name) => h("button", {
      class: name === active ? "primary" : "",
      "aria-pressed": String(name === active),
      onclick: () => {
        ctx.view.tools[inputKey(entry, track, "tool")] = name;
        ctx.render();
      },
    }, t(`plan.${name}`))));
}

function fillRow(ctx, entry, track, action) {
  const error = ctx.view.planErrors[inputKey(entry, track, "fill")];
  return h("div", { class: "reset-row" },
    h("button", { class: "primary", onclick: action }, t("plan.fill")),
    h("span", { class: "note" }, t("plan.fillHint")),
    error ? h("span", { class: "field-error", role: "alert" }, error) : null);
}

function textField(ctx, entry, track, key, label, desc, kind) {
  const name = `f:${key}`;
  const input = h("input", { type: "text", value: formulaInputs(ctx, entry, track)[key], spellcheck: false, autocomplete: "off" });
  input.addEventListener("input", () => {
    ctx.view.drafts[inputKey(entry, track, name)] = input.value;
  });
  return h("div", { class: "field wide" },
    h("label", { class: "field" }, h("span", {}, label), input),
    h("small", { class: "field-desc" }, desc),
    savedControls(ctx, entry, track, kind));
}

function savedState(ctx, entry, track, kind) {
  return ctx.view.drafts[inputKey(entry, track, `s:${kind}`)] ?? "";
}

function setSavedState(ctx, entry, track, kind, state) {
  const key = inputKey(entry, track, `s:${kind}`);
  if (state) ctx.view.drafts[key] = state;
  else delete ctx.view.drafts[key];
  ctx.render();
}

function currentFormula(ctx, entry, track, kind) {
  const inputs = formulaInputs(ctx, entry, track);
  return kind === "metric" ? { formula: inputs.formula, target: inputs.target } : { formula: inputs.cost };
}

function applySaved(ctx, entry, track, kind, item) {
  const drafts = ctx.view.drafts;
  if (kind === "metric") {
    drafts[inputKey(entry, track, "f:formula")] = item.formula;
    drafts[inputKey(entry, track, "f:target")] = item.target;
  } else {
    drafts[inputKey(entry, track, "f:cost")] = item.formula;
  }
  setSavedState(ctx, entry, track, kind, "");
}

function savedControls(ctx, entry, track, kind) {
  const state = savedState(ctx, entry, track, kind);
  const saved = savedFormulas(ctx.doc, kind);
  const buttons = h("div", { class: "saved-row" },
    h("button", { type: "button", "aria-pressed": String(state === "naming"), onclick: () => setSavedState(ctx, entry, track, kind, state === "naming" ? "" : "naming") }, t("plan.saveFormula")),
    h("button", { type: "button", "aria-pressed": String(state === "listing"), onclick: () => setSavedState(ctx, entry, track, kind, state === "listing" ? "" : "listing") }, t("plan.applySaved")));
  if (state === "naming") return h("div", { class: "saved" }, buttons, namingForm(ctx, entry, track, kind));
  if (state === "listing") return h("div", { class: "saved" }, buttons, savedList(ctx, entry, track, kind, saved));
  return h("div", { class: "saved" }, buttons);
}

function namingForm(ctx, entry, track, kind) {
  const name = h("input", { type: "text", maxlength: SAVED_NAME_LIMIT, placeholder: t("plan.saveName"), "aria-label": t("plan.saveName"), autocomplete: "off" });
  const description = h("textarea", { rows: 4, maxlength: SAVED_DESCRIPTION_LIMIT, placeholder: t("plan.saveDescription"), "aria-label": t("plan.saveDescription") });
  const error = h("span", { class: "field-error", role: "alert" });
  const save = () => {
    let done = false;
    ctx.store.update((doc) => {
      done = saveFormula(doc, kind, { name: name.value, description: description.value, ...currentFormula(ctx, entry, track, kind) });
    });
    if (done) setSavedState(ctx, entry, track, kind, "");
    else error.textContent = t("plan.saveFailed");
  };
  name.addEventListener("keydown", (event) => {
    if (event.key === "Enter") save();
  });
  return h("div", { class: "saved-form" },
    h("label", { class: "field" }, h("span", {}, t("plan.saveName")), name),
    h("label", { class: "field" }, h("span", {}, t("plan.saveDescription")), description),
    h("small", { class: "field-desc" }, t(kind === "metric" ? "plan.saveHintMetric" : "plan.saveHintCost")),
    h("div", { class: "saved-row" },
      h("button", { type: "button", class: "primary", onclick: save }, t("plan.saveConfirm")),
      h("button", { type: "button", onclick: () => setSavedState(ctx, entry, track, kind, "") }, t("plan.saveCancel")),
      error));
}

function savedList(ctx, entry, track, kind, saved) {
  if (saved.length === 0) return h("p", { class: "note" }, t("plan.savedNone"));
  return h("ul", { class: "saved-list" }, saved.map((item) => h("li", {},
    h("div", { class: "saved-head" },
      h("strong", {}, item.name),
      kind === "metric" ? h("span", { class: "note" }, t(`values.col.${item.target}`)) : null),
    h("code", {}, item.formula),
    item.description ? h("p", { class: "saved-description" }, item.description) : null,
    h("div", { class: "saved-row" },
      h("button", { type: "button", class: "primary", onclick: () => applySaved(ctx, entry, track, kind, item) }, t("plan.savedApply")),
      h("button", { type: "button", class: "danger", onclick: () => ctx.store.update((doc) => deleteSavedFormula(doc, kind, item.name)) }, t("plan.savedDelete"))))));
}

export const TIP_VARIABLES = ["level", "base", "build", "max", "growth", "start", "cost", "pi", "e"];

export function variableTip() {
  return TIP_VARIABLES.map((name) => `${name} – ${t(`plan.var.${name}`)}`).join("\n");
}

function variableHelp() {
  return h("span", { class: "variable-help multiline", tabindex: "0", "data-tip": variableTip() }, t("plan.variablesHelp"));
}

function targetSelect(ctx, entry, track) {
  const name = inputKey(entry, track, "f:target");
  const current = formulaInputs(ctx, entry, track).target;
  const select = h("select", { "aria-label": t("plan.target") },
    FORMULA_TARGETS.map((key) => h("option", { value: key, selected: key === current }, t(`values.col.${key}`))));
  select.addEventListener("change", () => {
    ctx.view.drafts[name] = select.value;
    ctx.render();
  });
  return h("div", { class: "field wide" },
    h("label", { class: "field" }, h("span", {}, t("plan.target")), select),
    h("small", { class: "field-desc" }, t(`desc.target.${current}`)));
}

function formulaTool(ctx, entry, track) {
  return h("div", { class: "plan" },
    variableHelp(),
    numberField(t("field.max"), formulaInputs(ctx, entry, track).max, (value) => {
      ctx.view.drafts[inputKey(entry, track, "f:max")] = value;
      ctx.render();
    }, { integer: true, min: 1, desc: t("desc.max") }),
    textField(ctx, entry, track, "cost", t("plan.costFormula"), t("desc.costFormula"), "cost"),
    targetSelect(ctx, entry, track),
    textField(ctx, entry, track, "formula", t("plan.targetFormula"), t("desc.targetFormula"), "metric"),
    fillRow(ctx, entry, track, () => fillFromFormula(ctx, entry, track)),
    h("p", { class: "note" }, t("plan.variablesCost", { names: COST_VARIABLES.join(", ") })),
    h("p", { class: "note" }, t("plan.variablesEffect", { names: TARGET_VARIABLES.join(", ") })),
    h("p", { class: "note" }, t("plan.functions")));
}

const PARAM_LABELS = { max: "field.max", step: "field.step", gain: "field.gain", price: "field.price", growth: "field.growth", gain_growth: "field.gainGrowth" };
const PARAM_DESCS = { max: "desc.max", step: "desc.step", gain: "desc.gain", price: "desc.price", growth: "desc.growth", gain_growth: "desc.gainGrowth" };

function paramTool(ctx, entry, track) {
  const inputs = paramInputs(ctx, entry, track);
  return h("div", { class: "plan" },
    h("div", { class: "grid" }, paramKeys(inputs).map((key) => numberField(t(PARAM_LABELS[key]), inputs[key], (value) => {
      ctx.view.drafts[inputKey(entry, track, `p:${key}`)] = value;
      ctx.render();
    }, { integer: key === "max", min: key.endsWith("growth") ? 1 : 0, desc: t(PARAM_DESCS[key]) }))),
    fillRow(ctx, entry, track, () => fillFromParams(ctx, entry, track)));
}

export function planEditor(ctx, entry, track) {
  const active = toolOf(ctx.view, entry, track);
  return h("div", { class: "plan-editor" },
    h("h4", { class: "value-heading" }, t("plan.tools")),
    h("p", { class: "note" }, t("plan.toolsHint")),
    toolSwitch(ctx, entry, track),
    active === "params" ? paramTool(ctx, entry, track) : null,
    active === "formula" ? formulaTool(ctx, entry, track) : null,
    active === "table" ? h("p", { class: "note" }, t("plan.tableModeNote")) : null);
}
