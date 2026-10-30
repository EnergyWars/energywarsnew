import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { trackConfig, planOf, maxLevel, buildFormulaLevels, multiplier, roundTo, COST_VARIABLES, EFFECT_VARIABLES, MAX_LEVELS } from "../formulas.js";
import { ExpressionError } from "../expr.js";
import { numberField } from "./components.js";
import { setDraftLevels } from "./valueTable.js";

const TOOLS = ["params", "formula", "table"];
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

export function defaultFormulas(doc, entry, track) {
  const config = trackConfig(doc, entry, track);
  const growth = config.growth ?? doc.system.track_growth;
  const cost = `base * ${number(config.price, 6)} * ${number(growth, 6)}^level`;
  const effect = config.gain !== undefined
    ? `1 + ${number(config.gain, 6)} * (${number(config.gain_growth, 6)}^level - 1) / (${number(config.gain_growth, 6)} - 1)`
    : `1 + ${number(config.step, 6)} * level`;
  return { cost, effect };
}

export function formulaDefaults(doc, entry, track) {
  const plan = planOf(entry, track);
  const fallback = defaultFormulas(doc, entry, track);
  return { max: maxLevel(doc, entry, track), cost: plan?.cost ?? fallback.cost, effect: plan?.effect ?? fallback.effect };
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

export function fillFromParams(ctx, entry, track) {
  try {
    setDraftLevels(ctx, entry, track, paramLevels(ctx.doc, entry, paramInputs(ctx, entry, track)));
  } catch (error) {
    report(ctx, entry, track, error);
    return;
  }
  delete ctx.view.planErrors[inputKey(entry, track, "fill")];
  ctx.render();
}

export function fillFromFormula(ctx, entry, track) {
  const inputs = formulaInputs(ctx, entry, track);
  try {
    setDraftLevels(ctx, entry, track, buildFormulaLevels(ctx.doc, entry, inputs));
  } catch (error) {
    report(ctx, entry, track, error);
    return;
  }
  delete ctx.view.planErrors[inputKey(entry, track, "fill")];
  ctx.store.update((doc) => {
    rememberFormula(doc, "cost", inputs.cost);
    rememberFormula(doc, "effect", inputs.effect);
  });
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

function textField(ctx, entry, track, key, label, desc) {
  const name = `f:${key}`;
  const pickKey = `${inputKey(entry, track, name)}:pick`;
  const input = h("input", { type: "text", value: formulaInputs(ctx, entry, track)[key], spellcheck: false, autocomplete: "off" });
  input.addEventListener("input", () => {
    ctx.view.drafts[inputKey(entry, track, name)] = input.value;
    delete ctx.view.drafts[pickKey];
  });
  return h("div", { class: "field wide" },
    h("label", { class: "field" }, h("span", {}, label), input),
    h("small", { class: "field-desc" }, desc),
    historyPicker(ctx, key, pickKey, (text) => {
      ctx.view.drafts[inputKey(entry, track, name)] = text;
      ctx.render();
    }));
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

function formulaTool(ctx, entry, track) {
  return h("div", { class: "plan" },
    numberField(t("field.max"), formulaInputs(ctx, entry, track).max, (value) => {
      ctx.view.drafts[inputKey(entry, track, "f:max")] = value;
      ctx.render();
    }, { integer: true, min: 1, desc: t("desc.max") }),
    textField(ctx, entry, track, "cost", t("plan.costFormula"), t("desc.costFormula")),
    textField(ctx, entry, track, "effect", t("plan.effectFormula"), t("desc.effectFormula")),
    fillRow(ctx, entry, track, () => fillFromFormula(ctx, entry, track)),
    h("p", { class: "note" }, t("plan.variablesCost", { names: COST_VARIABLES.join(", ") })),
    h("p", { class: "note" }, t("plan.variablesEffect", { names: EFFECT_VARIABLES.join(", ") })),
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
