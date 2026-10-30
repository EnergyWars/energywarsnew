import { h } from "../dom.js";
import { t } from "../i18n.js";
import { searchSelect } from "./components.js";
import { buildingName, trackName } from "./buildingView.js";
import {
  DIRECT, areas, sectionsOf, itemsOf, itemCount, parseItem, membership, targetOptions, parseTarget,
  addArea, renameArea, removeArea, moveArea, addSection, renameSection, removeSection, moveSection,
  addItem, removeItem, moveItem, validateGroups, nameProblem, cleanName,
} from "../groups.js";

export const ALL = "all";

export function groupsUi(view) {
  view.groupsUi ??= { area: ALL, notice: "" };
  return view.groupsUi;
}

export function selectedArea(ctx) {
  const ui = groupsUi(ctx.view);
  const index = Number(ui.area);
  if (ui.area === ALL || !Number.isInteger(index) || !areas(ctx.doc)[index]) {
    ui.area = ALL;
    return -1;
  }
  return index;
}

export function itemLabel(names, key) {
  const parsed = parseItem(key);
  if (!parsed) return key;
  return `${buildingName(names, parsed.building)} · ${trackName(names, parsed.track, parsed.building)}`;
}

export function upgradeOptions(doc, names, exclude = []) {
  const skip = new Set(exclude);
  return doc.buildings.flatMap((entry) => entry.tracks.map((track) => `${entry.id}:${track}`))
    .filter((key) => !skip.has(key))
    .map((key) => ({ value: key, label: itemLabel(names, key), hint: key }));
}

export function areaOptions(doc) {
  return [{ value: ALL, label: t("groups.all") }, ...areas(doc).map((area, index) => ({ value: String(index), label: area.name, hint: t("groups.count", { count: itemCount(area) }) }))];
}

function iconButton(symbol, label, onClick, { disabled = false, danger = false } = {}) {
  return h("button", { type: "button", class: danger ? "icon danger" : "icon", title: label, "aria-label": label, disabled, onclick: onClick }, symbol);
}

function renamer(ctx, siblings, skip, rename) {
  return (value) => {
    const ui = groupsUi(ctx.view);
    const problem = nameProblem(siblings, value, skip);
    if (problem) {
      ui.notice = t(`error.${problem}`);
      ctx.render();
      return;
    }
    ui.notice = "";
    if (cleanName(value) === siblings[skip]?.name) return;
    ctx.store.update((doc) => { rename(doc, value); });
  };
}

function textField(label, value, onCommit) {
  const input = h("input", { type: "text", value, maxLength: 60, "aria-label": label });
  input.addEventListener("change", () => onCommit(input.value));
  return h("label", { class: "field" }, h("span", {}, label), input);
}

function itemList(ctx, areaIndex, sectionIndex, items) {
  const { names, store } = ctx;
  return h("ul", { class: "group-items" }, items.map((key, index) => h("li", {},
    h("span", { class: "group-item-name" }, itemLabel(names, key)),
    iconButton("↑", t("action.up"), () => store.update((doc) => { moveItem(doc, areaIndex, sectionIndex, index, -1); }), { disabled: index === 0 }),
    iconButton("↓", t("action.down"), () => store.update((doc) => { moveItem(doc, areaIndex, sectionIndex, index, 1); }), { disabled: index === items.length - 1 }),
    iconButton("✕", t("action.remove"), () => store.update((doc) => { removeItem(doc, areaIndex, sectionIndex, key); }), { danger: true }))));
}

function addPicker(ctx, areaIndex, sectionIndex, items) {
  return searchSelect({
    options: upgradeOptions(ctx.doc, ctx.names, items),
    value: null,
    label: t("groups.itemLabel"),
    prompt: t("groups.addItem"),
    onChange: (key) => ctx.store.update((doc) => { addItem(doc, areaIndex, sectionIndex, key); }),
  });
}

function block(ctx, areaIndex, sectionIndex, holder, count) {
  const { store } = ctx;
  const items = itemsOf(holder);
  const direct = sectionIndex === DIRECT;
  const head = direct
    ? h("h4", {}, t("groups.direct"))
    : h("div", { class: "row-edit group-section-head" },
      textField(t("groups.sectionName"), holder.name, renamer(ctx, sectionsOf(areas(ctx.doc)[areaIndex]), sectionIndex, (doc, value) => renameSection(doc, areaIndex, sectionIndex, value))),
      iconButton("↑", t("action.up"), () => store.update((doc) => { moveSection(doc, areaIndex, sectionIndex, -1); }), { disabled: sectionIndex === 0 }),
      iconButton("↓", t("action.down"), () => store.update((doc) => { moveSection(doc, areaIndex, sectionIndex, 1); }), { disabled: sectionIndex === count - 1 }),
      iconButton("✕", t("groups.deleteSection"), () => { if (confirm(t("groups.confirmDeleteSection", { name: holder.name }))) store.update((doc) => { removeSection(doc, areaIndex, sectionIndex); }); }, { danger: true }));
  return h("div", { class: direct ? "group-block" : "group-block group-section" },
    head,
    items.length ? itemList(ctx, areaIndex, sectionIndex, items) : h("p", { class: "empty" }, t("groups.emptyBlock")),
    addPicker(ctx, areaIndex, sectionIndex, items));
}

function areaEditor(ctx, index) {
  const area = areas(ctx.doc)[index];
  const sections = sectionsOf(area);
  return h("div", { class: "group-editor" },
    textField(t("groups.name"), area.name, renamer(ctx, areas(ctx.doc), index, (doc, value) => renameArea(doc, index, value))),
    h("small", { class: "field-desc" }, t("groups.d.name")),
    block(ctx, index, DIRECT, area, sections.length),
    sections.map((section, sectionIndex) => block(ctx, index, sectionIndex, section, sections.length)),
    h("button", { type: "button", onclick: () => ctx.store.update((doc) => { addSection(doc, index, t("groups.newSection")); }) }, `+ ${t("groups.addSection")}`));
}

function areaList(ctx, selected) {
  const ui = groupsUi(ctx.view);
  const list = areas(ctx.doc);
  if (!list.length) return h("p", { class: "empty" }, t("groups.none"));
  return h("ol", { class: "group-list" }, list.map((area, index) => h("li", { class: index === selected ? "level-item selected" : "level-item" },
    h("button", { type: "button", class: "level-pick", "aria-current": String(index === selected), onclick: () => { ui.area = String(index); ui.notice = ""; ctx.render(); } },
      area.name, h("small", {}, ` · ${t("groups.count", { count: itemCount(area) })}`)),
    iconButton("▲", t("action.up"), () => { ui.area = String(index - 1); ctx.store.update((doc) => { moveArea(doc, index, -1); }); }, { disabled: index === 0 }),
    iconButton("▼", t("action.down"), () => { ui.area = String(index + 1); ctx.store.update((doc) => { moveArea(doc, index, 1); }); }, { disabled: index === list.length - 1 }),
    iconButton("✕", t("groups.delete"), () => {
      if (!confirm(t("groups.confirmDelete", { name: area.name }))) return;
      ctx.store.update((doc) => { const next = removeArea(doc, index); ui.area = next < 0 ? ALL : String(next); });
    }, { danger: true }))));
}

export function groupsPanel(ctx) {
  const ui = groupsUi(ctx.view);
  const selected = selectedArea(ctx);
  const errors = validateGroups(ctx.doc);
  return h("aside", { class: "card groups-panel" },
    h("h3", { class: "section-title" }, t("groups.title")),
    h("p", { class: "note" }, t("groups.hint")),
    errors.length ? h("ul", { class: "errors", role: "alert" }, errors.map((error) => h("li", {}, `${t(`error.${error.code}`)} – ${error.path}`))) : null,
    ui.notice ? h("p", { class: "field-error", role: "alert" }, ui.notice) : null,
    areaList(ctx, selected),
    h("button", { type: "button", class: "primary", onclick: () => ctx.store.update((doc) => { const index = addArea(doc, t("groups.newArea")); if (index >= 0) ui.area = String(index); }) }, `+ ${t("groups.add")}`),
    selected >= 0 ? areaEditor(ctx, selected) : (areas(ctx.doc).length ? h("p", { class: "note" }, t("groups.pick")) : null));
}

export function areaFilter(ctx) {
  const ui = groupsUi(ctx.view);
  selectedArea(ctx);
  return h("div", { class: "field groups-filter", "data-tip": t("groups.d.filter") },
    h("span", {}, t("groups.filter")),
    searchSelect({ options: areaOptions(ctx.doc), value: ui.area, label: t("groups.filter"), onChange: (value) => { ui.area = value; ui.notice = ""; ctx.render(); } }),
    h("small", { class: "field-desc" }, t("groups.d.filter")));
}

export function trackGroups(ctx, entry, track) {
  const key = `${entry.id}:${track}`;
  if (!areas(ctx.doc).length) return null;
  const places = membership(ctx.doc, key);
  const options = targetOptions(ctx.doc, key);
  return h("div", { class: "track-groups" },
    h("span", { class: "note" }, t("groups.member")),
    places.length ? h("span", { class: "badges" }, places.map((place) => {
      const name = place.sectionName ? `${place.areaName} › ${place.sectionName}` : place.areaName;
      return h("span", { class: "pill group-pill" }, name,
        h("button", { type: "button", class: "pill-remove", title: t("groups.removeFrom", { name }), "aria-label": t("groups.removeFrom", { name }), onclick: () => ctx.store.update((doc) => { removeItem(doc, place.area, place.section, key); }) }, "✕"));
    })) : h("span", { class: "note" }, t("groups.notInAny")),
    options.length ? searchSelect({
      options,
      value: null,
      label: t("groups.addTo"),
      prompt: t("groups.addTo"),
      onChange: (value) => {
        const target = parseTarget(value);
        if (target) ctx.store.update((doc) => { addItem(doc, target.area, target.section, key); });
      },
    }) : null);
}
