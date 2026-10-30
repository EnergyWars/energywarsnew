import { h } from "../dom.js";
import { t } from "../i18n.js";
import { numberField } from "./components.js";
import { trackName } from "./buildingView.js";
import { usage } from "../formulas.js";

export function tracksView(ctx) {
  const { doc, names, store } = ctx;
  const rows = Object.entries(doc.tracks).map(([track, config]) => h("tr", {},
    h("th", { scope: "row" }, trackName(names, track, "")),
    ["max", "step", "price", "growth", "energy"].map((key) => h("td", {}, config[key] === undefined ? "–" : numberField("", config[key], (v) => store.set(`tracks.${track}.${key}`, v), { integer: key === "max", min: 0 }))),
    h("td", {}, usage(doc, track).length)));
  return h("section", { class: "detail" },
    h("h2", {}, t("tab.tracks")),
    h("div", { class: "card grid" }, numberField(t("field.trackGrowth"), doc.system.track_growth, (v) => store.set("system.track_growth", v), { min: 1, hint: t("hint.trackGrowth"), desc: t("hint.trackGrowth") })),
    h("p", { class: "note" }, t("desc.tracksTable")),
    h("div", { class: "card scroll" }, h("table", { class: "overview" },
      h("thead", {}, h("tr", {}, h("th", {}, t("table.track")), ["max", "step", "price", "growth", "energy"].map((key) => h("th", { title: t(`desc.track.${key}`) }, t(`field.${key}`))), h("th", {}, t("table.usedBy")))),
      h("tbody", {}, rows))));
}
