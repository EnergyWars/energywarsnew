import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { trackConfig, planOf, maxLevel, buildFormulaLevels, storedFormula, formulaState, multiplier, roundTo, writeLevels, FORMULA_TARGETS, MAX_LEVELS } from "../formulas.js";
import { ExpressionError } from "../expr.js";
import { numberField } from "./components.js";
import { openModal } from "./modal.js";
import { entryVariables } from "./variablesPanel.js";
import { savedManager, formulaForm, saveFormula } from "./savedFormulas.js";
import { draftKey } from "./valueTable.js";
import { goalTool } from "./goalTool.js";

const TOOLS = ["params", "formula", "table", "goal"];
export { savedFormulas, saveFormula, updateSavedFormula, deleteSavedFormula, SAVED_NAME_LIMIT, SAVED_DESCRIPTION_LIMIT, SAVED_KINDS } from "./savedFormulas.js";

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
  const stored = storedFormula(entry, track);
  if (stored) return { max: stored.max, cost: stored.cost, formula: stored.formula, target: stored.target };
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
  if (typeof error.code === "string" && error.code.startsWith("GOAL_")) return t(`error.${error.code}`);
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
  inputs.max = ctx.view.drafts[inputKey(entry, track, "max")] ?? defaults.max;
  return inputs;
}

export function paramInputs(ctx, entry, track) {
  const defaults = paramDefaults(ctx.doc, entry, track);
  const inputs = {};
  for (const key of Object.keys(defaults)) inputs[key] = ctx.view.drafts[inputKey(entry, track, `p:${key}`)] ?? defaults[key];
  inputs.max = ctx.view.drafts[inputKey(entry, track, "max")] ?? defaults.max;
  return inputs;
}

function report(ctx, entry, track, error) {
  ctx.view.planErrors[inputKey(entry, track, "fill")] = describeError(error);
  ctx.render();
}

function commitLevels(ctx, entry, track, levels, source = null) {
  delete ctx.view.planErrors[inputKey(entry, track, "fill")];
  delete ctx.view.drafts[draftKey(entry, track)];
  ctx.store.update((doc) => {
    writeLevels(doc.buildings.find((item) => item.id === entry.id), track, levels.map((level) => ({ ...level })), source);
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
  commitLevels(ctx, entry, track, levels, { max: Number(inputs.max), cost: inputs.cost, target: inputs.target, formula: inputs.formula });
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
    error ? h("span", { class: "field-error", role: "alert" }, error) : null);
}

function textField(ctx, entry, track, key, label, kind) {
  const name = `f:${key}`;
  const input = h("input", { type: "text", value: formulaInputs(ctx, entry, track)[key], spellcheck: false, autocomplete: "off" });
  input.addEventListener("input", () => {
    ctx.view.drafts[inputKey(entry, track, name)] = input.value;
  });
  return h("div", { class: "field wide" },
    h("div", { class: "formula-row" },
      h("label", { class: "field grow" }, h("span", {}, label), input),
      savedButtons(ctx, entry, track, kind)),
    savedState(ctx, entry, track, kind) === "naming" ? namingForm(ctx, entry, track, kind) : null);
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

function iconButton(icon, label, onclick, pressed = null) {
  return h("button", { type: "button", class: "icon-button", title: label, "aria-label": label, "aria-pressed": pressed === null ? null : String(pressed), onclick }, icon);
}

function savedButtons(ctx, entry, track, kind) {
  const naming = savedState(ctx, entry, track, kind) === "naming";
  return h("div", { class: "icon-row" },
    iconButton("💾", t("plan.saveFormula"), () => setSavedState(ctx, entry, track, kind, naming ? "" : "naming"), naming),
    iconButton("📂", t("plan.applySaved"), () => openSavedModal(ctx, entry, track, kind)),
    iconButton("⚙", t("saved.manage"), () => openFormulasPage(ctx)));
}

function openSavedModal(ctx, entry, track, kind) {
  return openModal({
    title: t(kind === "metric" ? "plan.savedTitleMetric" : "plan.savedTitleCost"),
    render: ({ close, refresh }) => h("div", {},
      savedManager(ctx, kind, {
        refresh,
        onApply: (item) => {
          close();
          applySaved(ctx, entry, track, kind, item);
        },
      }),
      h("div", { class: "saved-row" }, h("button", { type: "button", class: "link", onclick: () => openFormulasPage(ctx, close) }, t("saved.manage")))),
  });
}

function openFormulasPage(ctx, close = () => {}) {
  close();
  ctx.view.tab = "formulas";
  ctx.render();
}

function namingForm(ctx, entry, track, kind) {
  return formulaForm({
    kind,
    onSubmit: (values) => {
      let done = false;
      ctx.store.update((doc) => {
        done = saveFormula(doc, kind, { ...values, ...currentFormula(ctx, entry, track, kind) });
      });
      if (done) setSavedState(ctx, entry, track, kind, "");
      return done;
    },
    onCancel: () => setSavedState(ctx, entry, track, kind, ""),
  });
}

export const TIP_VARIABLES = ["level", "base", "build", "max", "growth", "start", "cost", "pi", "e"];

export function variableTip(entry = null) {
  const own = entry ? entryVariables(entry).map((item) => `${item.name} = ${item.value} – ${item.description || t("plan.var.custom")}`) : [];
  return [...TIP_VARIABLES.map((name) => `${name} – ${t(`plan.var.${name}`)}`), ...own].join("\n");
}

export function operatorTip() {
  return t("plan.operatorsTip");
}

function variableHelp(entry) {
  return h("div", { class: "help-row" },
    h("span", { class: "variable-help multiline", tabindex: "0", "data-tip": variableTip(entry) }, t("plan.variablesHelp")),
    h("span", { class: "variable-help multiline", tabindex: "0", "data-tip": operatorTip() }, t("plan.operatorsHelp")));
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
    h("label", { class: "field" }, h("span", {}, t("plan.target")), select));
}

function formulaTool(ctx, entry, track) {
  return h("div", { class: "plan" },
    textField(ctx, entry, track, "cost", t("plan.costFormula"), "cost"),
    targetSelect(ctx, entry, track),
    textField(ctx, entry, track, "formula", t("plan.targetFormula"), "metric"),
    variableHelp(entry));
}

export function formulaDraftChanged(ctx, entry, track) {
  const stored = storedFormula(entry, track);
  if (!stored) return false;
  const inputs = formulaInputs(ctx, entry, track);
  return Number(inputs.max) !== stored.max || inputs.cost !== stored.cost || inputs.formula !== stored.formula || inputs.target !== stored.target;
}

function formulaStatus(ctx, entry, track) {
  const state = formulaState(ctx.doc, entry, track);
  if (!state) return null;
  return h("div", { class: `formula-status ${state}`, role: "status" },
    h("span", { class: "note" }, t(`plan.status.${state}`)),
    formulaDraftChanged(ctx, entry, track) ? h("span", { class: "note" }, t("plan.status.draft")) : null);
}

const PARAM_LABELS = { step: "field.step", gain: "field.gain", price: "field.price", growth: "field.growth", gain_growth: "field.gainGrowth" };

function paramTool(ctx, entry, track) {
  const inputs = paramInputs(ctx, entry, track);
  return h("div", { class: "plan" },
    h("div", { class: "grid" }, paramKeys(inputs).filter((key) => key !== "max").map((key) => numberField(t(PARAM_LABELS[key]), inputs[key], (value) => {
      ctx.view.drafts[inputKey(entry, track, `p:${key}`)] = value;
      ctx.render();
    }, { min: key.endsWith("growth") ? 1 : 0 }))));
}

function applyGoal(ctx, entry, track, result) {
  ctx.view.drafts[inputKey(entry, track, "f:cost")] = result.cost;
  ctx.view.drafts[inputKey(entry, track, "f:formula")] = result.formula;
  ctx.view.drafts[inputKey(entry, track, "f:target")] = result.target;
  ctx.view.drafts[inputKey(entry, track, "max")] = result.max;
  ctx.view.tools[inputKey(entry, track, "tool")] = "formula";
  ctx.render();
}

function maxField(ctx, entry, track) {
  const inputs = toolOf(ctx.view, entry, track) === "params" ? paramInputs(ctx, entry, track) : formulaInputs(ctx, entry, track);
  return numberField(t("field.max"), inputs.max, (value) => {
    ctx.view.drafts[inputKey(entry, track, "max")] = value;
    ctx.render();
  }, { integer: true, min: 1 });
}

export function planEditor(ctx, entry, track) {
  const active = toolOf(ctx.view, entry, track);
  const action = active === "params" ? () => fillFromParams(ctx, entry, track) : () => fillFromFormula(ctx, entry, track);
  return h("div", { class: "plan-editor" },
    h("h4", { class: "value-heading" }, t("plan.tools")),
    maxField(ctx, entry, track),
    toolSwitch(ctx, entry, track),
    active === "table" || active === "goal" ? null : fillRow(ctx, entry, track, action),
    active === "formula" ? formulaStatus(ctx, entry, track) : null,
    active === "params" ? paramTool(ctx, entry, track) : null,
    active === "formula" ? formulaTool(ctx, entry, track) : null,
    active === "goal" ? goalTool(ctx, entry, track, {
      key: (name) => inputKey(entry, track, name),
      max: Number(formulaInputs(ctx, entry, track).max),
      describe: describeError,
      apply: (result) => applyGoal(ctx, entry, track, result),
    }) : null);
}
