import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { deriveRows, baseValue, startValue, snapshotLevels, purchasePrice } from "../formulas.js";
import { numberField } from "./components.js";
import { COST_TYPES, VALUE_TYPES, GOAL_MODES, generateGoal, withinTolerance } from "../targetFit.js";

const DECIMALS = 2;

export function goalDefaults(doc, entry, track) {
  const rows = deriveRows(entry, snapshotLevels(doc, entry, track), startValue(doc, entry, track), baseValue(doc, entry, track));
  const last = rows[rows.length - 1];
  return {
    costMode: GOAL_MODES[0],
    cost: Math.round(last?.spent ?? purchasePrice(entry)),
    valueMode: GOAL_MODES[0],
    value: Number((last?.totalValue ?? baseValue(doc, entry, track)).toFixed(DECIMALS)),
    costType: COST_TYPES[0],
    valueType: VALUE_TYPES[0],
  };
}

export function goalInputs(ctx, entry, track, key, max) {
  const defaults = goalDefaults(ctx.doc, entry, track);
  const inputs = { max };
  for (const name of Object.keys(defaults)) inputs[name] = ctx.view.drafts[key(`g:${name}`)] ?? defaults[name];
  return inputs;
}

function choice(ctx, key, name, current, values, labelKey, ariaLabel) {
  const select = h("select", { "aria-label": ariaLabel }, values.map((value) => h("option", { value, selected: value === current }, t(`${labelKey}.${value}`))));
  select.addEventListener("change", () => {
    ctx.view.drafts[key(`g:${name}`)] = select.value;
    ctx.render();
  });
  return select;
}

function amountRow(ctx, key, inputs, label, modeName, amountName, typeName, typeValues, typeLabelKey, typeLabel) {
  return h("div", { class: "goal-row" },
    numberField(label, inputs[amountName], (value) => {
      ctx.view.drafts[key(`g:${amountName}`)] = value;
      ctx.render();
    }, { min: 0 }),
    h("label", { class: "field" }, h("span", {}, t("goal.mode")), choice(ctx, key, modeName, inputs[modeName], GOAL_MODES, "goal.mode", t("goal.mode"))),
    h("label", { class: "field grow" }, h("span", {}, typeLabel), choice(ctx, key, typeName, inputs[typeName], typeValues, typeLabelKey, typeLabel)));
}

function percent(deviation) {
  return `${deviation >= 0 ? "+" : ""}${number(deviation * 100, DECIMALS)} %`;
}

export function goalTool(ctx, entry, track, { key, max, describe, apply }) {
  const inputs = goalInputs(ctx, entry, track, key, max);
  let result = null;
  let error = null;
  try {
    result = generateGoal(ctx.doc, entry, track, inputs);
  } catch (caught) {
    error = describe(caught);
  }
  return h("div", { class: "plan goal" },
    amountRow(ctx, key, inputs, t("goal.cost"), "costMode", "cost", "costType", COST_TYPES, "goal.costType", t("goal.costTypeLabel")),
    amountRow(ctx, key, inputs, t("goal.value"), "valueMode", "value", "valueType", VALUE_TYPES, "goal.valueType", t("goal.valueTypeLabel")),
    error ? h("span", { class: "field-error", role: "alert" }, error) : h("div", { class: "goal-result" },
      h("div", { class: "note" }, t("goal.result", { cost: number(result.spent, 0), costDev: percent(result.costDeviation), value: number(result.totalValue, DECIMALS), valueDev: percent(result.valueDeviation) })),
      withinTolerance(result) ? null : h("div", { class: "field-error", role: "alert" }, t("goal.outside")),
      h("code", {}, result.cost),
      h("code", {}, result.formula)),
    h("div", { class: "reset-row" }, h("button", { class: "primary", disabled: error !== null, onclick: () => apply(result) }, t("goal.generate"))));
}
