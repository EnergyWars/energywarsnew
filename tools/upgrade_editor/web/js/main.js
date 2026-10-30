import { h, toast } from "./dom.js";
import { api } from "./api.js";
import { load, t, setLanguage, current } from "./i18n.js";
import { create } from "./store.js";
import { buildingPanel } from "./views/buildingView.js";
import { buildMenu } from "./views/buildMenu.js";
import { tracksView } from "./views/tracksView.js";
import { overviewView } from "./views/overviewView.js";
import { changesView, computeChanges } from "./views/changesView.js";
import { levelsView } from "./views/levelsView.js";
import { monstersView } from "./views/monstersView.js";
import { balanceView } from "./views/balanceView.js";

const TABS = ["buildings", "overview", "tracks", "levels", "monsters", "balance", "changes"];
const view = { tab: "buildings", building: null, category: "all", open: new Set(), drafts: {}, tools: {}, hidden: new Set(), collapsed: new Set(), gainModes: {}, planErrors: {}, sort: { key: "benefit", direction: "desc" }, errors: [] };
let store;
let names = {};

function readPreference(key) {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function writePreference(key, value) {
  try {
    localStorage.setItem(key, value);
  } catch {
    return;
  }
}

function context() {
  const doc = store.state.document;
  return { doc, original: store.state.original, names, store, view, render, toast };
}

async function save() {
  try {
    const result = await api.save(store.state.document);
    store.replace(result.document);
    toast(t("toast.saved"), "ok");
  } catch (error) {
    view.errors = error.errors || [];
    render();
    toast(t("toast.invalid"), "error");
  }
}

async function reset() {
  if (!confirm(t("confirm.reset"))) return;
  await api.reset();
  const loaded = await api.document();
  store.state.original = loaded.original;
  view.tools = {};
  view.drafts = {};
  view.planErrors = {};
  store.replace(loaded.document);
  toast(t("toast.reset"), "ok");
}

function toolbar() {
  const changed = computeChanges(store.state.original, store.state.document).length;
  return h("header", { class: "bar" },
    h("h1", {}, t("app.title")),
    h("span", { class: "badge" }, t("status.changes", { count: changed })),
    h("div", { class: "spacer" }),
    h("button", { disabled: !store.canUndo(), onclick: () => store.undo() }, t("action.undo")),
    h("button", { disabled: !store.canRedo(), onclick: () => store.redo() }, t("action.redo")),
    h("button", { class: "primary", disabled: !store.dirty(), onclick: save }, t("action.save")),
    h("button", { onclick: reset }, t("action.reset")),
    h("button", { onclick: () => { setLanguage(current() === "de" ? "en" : "de"); writePreference("lang", current()); render(); } }, current().toUpperCase()));
}

function errorList() {
  if (!view.errors.length) return null;
  return h("ul", { class: "errors", role: "alert" }, view.errors.map((error) => h("li", {}, `${t(`error.${error.code}`)} – ${error.path}`)));
}

function body() {
  const ctx = context();
  if (view.tab === "overview") return overviewView(ctx, view.sort, (key) => { view.sort = { key, direction: view.sort.key === key && view.sort.direction === "desc" ? "asc" : "desc" }; render(); });
  if (view.tab === "tracks") return tracksView(ctx);
  if (view.tab === "levels") return levelsView(ctx);
  if (view.tab === "monsters") return monstersView(ctx);
  if (view.tab === "balance") return balanceView(ctx);
  if (view.tab === "changes") return changesView(ctx);
  const entry = ctx.doc.buildings.find((item) => item.id === view.building) ?? ctx.doc.buildings[0];
  view.building = entry.id;
  return h("div", { class: "split" }, buildMenu(ctx, entry.id), buildingPanel(ctx, entry));
}

function render() {
  const app = document.getElementById("app");
  document.documentElement.lang = current();
  document.title = t("app.title");
  const tabs = h("div", { class: "tabs", role: "tablist" }, TABS.map((tab) => h("button", { role: "tab", "aria-selected": String(view.tab === tab), class: view.tab === tab ? "active" : "", onclick: () => { view.tab = tab; render(); } }, t(`tab.${tab}`))));
  app.replaceChildren(...[toolbar(), tabs, errorList(), body()].filter(Boolean));
}

async function start() {
  await load(readPreference("lang"));
  const loaded = await api.document();
  names = loaded.original.names;
  store = create(loaded.document, loaded.original);
  store.subscribe(() => { view.errors = []; render(); });
  render();
  window.addEventListener("beforeunload", (event) => { if (store.dirty()) event.preventDefault(); });
}

start().catch(() => toast("Error", "error"));
