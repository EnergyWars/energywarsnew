import { h } from "../dom.js";
import { t } from "../i18n.js";
import { savedManager, SAVED_KINDS } from "./savedFormulas.js";

export function formulasView(ctx) {
  return h("div", { class: "formulas-page" },
    h("p", { class: "note" }, t("formulas.intro")),
    SAVED_KINDS.map((kind) => h("section", { class: "panel-card" },
      h("h3", { class: "section-title" }, t(`formulas.${kind}`)),
      savedManager(ctx, kind, { refresh: () => ctx.render(), allowCreate: true, manage: true }))));
}
