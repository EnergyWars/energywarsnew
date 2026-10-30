import { h } from "../dom.js";
import { t, gameName } from "../i18n.js";
import { shortName, iconFor } from "./buildingView.js";

export function menuGroups(doc) {
  const known = new Set();
  const groups = [];
  for (const category of doc.categories) {
    const kinds = category.kinds.filter((kind) => doc.buildings.some((entry) => entry.id === kind));
    kinds.forEach((kind) => known.add(kind));
    if (kinds.length) groups.push({ key: category.key, kinds });
  }
  const rest = doc.buildings.map((entry) => entry.id).filter((kind) => !known.has(kind));
  if (rest.length) groups.push({ key: "other", kinds: rest });
  const everything = new Set(groups.flatMap((group) => group.kinds));
  return [{ key: "all", kinds: doc.buildings.map((entry) => entry.id).filter((kind) => everything.has(kind)) }, ...groups];
}

export function groupLabel(names, key) {
  return gameName(names, `BUILD_CATEGORY_${key.toUpperCase()}`, t(`menu.${key}`));
}

export function buildMenu(ctx, selected) {
  const { doc, names, view } = ctx;
  const groups = menuGroups(doc);
  const active = groups.find((group) => group.key === view.category) ?? groups[0];
  const tabs = h("div", { class: "menu-tabs" }, groups.map((group) => h("button", {
    class: group.key === active.key ? "primary" : "",
    onclick: () => { view.category = group.key; ctx.render(); },
  }, groupLabel(names, group.key))));
  const cards = active.kinds.map((kind) => {
    const entry = doc.buildings.find((item) => item.id === kind);
    return h("button", { class: `build-card${kind === selected ? " selected" : ""}`, "aria-pressed": String(kind === selected), onclick: () => { view.building = kind; ctx.render(); } },
      iconFor(entry, 62),
      h("span", { class: "tiny" }, shortName(names, kind)),
      h("span", { class: "tiny gold" }, String(entry.cost)));
  });
  return h("nav", { class: "build-menu", "aria-label": t("menu.build") }, tabs, h("div", { class: "build-grid" }, cards));
}
