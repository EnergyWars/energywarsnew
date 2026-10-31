import { h } from "../dom.js";
import { t } from "../i18n.js";
import { number } from "../format.js";
import { ratePerSecond, cooldownFor } from "../formulas.js";

export const RATE_STATS = new Set(["attack.cooldown", "heal.cooldown"]);

export function rateField(path, cooldown, onChange) {
  const rate = ratePerSecond(cooldown);
  const shown = (value) => (value === null ? "–" : `${t("rate.cooldown")}: ${number(value, 4)} ${t("rate.seconds")}`);
  const hint = h("small", { class: "field-desc rate-cooldown" }, shown(cooldown > 0 ? cooldown : null));
  const input = h("input", { type: "number", value: rate === null ? 0 : number(rate, 4), step: "any", min: 0 });
  input.addEventListener("input", () => {
    hint.textContent = shown(cooldownFor(Number(input.value)));
  });
  input.addEventListener("change", () => {
    const parsed = Number(input.value);
    if (!Number.isFinite(parsed) || parsed < 0) return;
    onChange(parsed === 0 ? 0 : cooldownFor(parsed));
  });
  return h("label", { class: "field" }, hint, h("span", {}, t(`rate.${path.split(".")[0]}`)), input, h("small", { class: "field-desc" }, t(`rate.desc.${path.split(".")[0]}`)));
}
