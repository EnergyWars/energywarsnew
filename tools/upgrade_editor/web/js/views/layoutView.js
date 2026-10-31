import { h } from "../dom.js";
import { t, gameName } from "../i18n.js";
import { layoutOf, moveTrack, moveGroup, addGroup, renameGroup, deleteGroup, resetLayout, LAYOUT_LIMIT, LAYOUT_TITLE_LIMIT } from "../layout.js";

function startDrag(ctx, event, drag) {
  ctx.view.drag = drag;
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData?.("text/plain", drag.type);
  }
}

function accepts(ctx, ...types) {
  return types.includes(ctx.view.drag?.type);
}

function allow(ctx, event, ...types) {
  if (!accepts(ctx, ...types)) return false;
  event.preventDefault();
  return true;
}

function dropTrack(ctx, entry, groupIndex, position) {
  const { track } = ctx.view.drag;
  ctx.view.drag = null;
  ctx.store.update((doc) => { moveTrack(doc, entry.id, track, groupIndex, position); });
}

function groupHead(ctx, entry, group, index, count) {
  const label = group.title ? gameName(ctx.names, group.title, group.title) : "";
  const input = h("input", { type: "text", value: label, maxlength: LAYOUT_TITLE_LIMIT, placeholder: t("layout.untitled"), "aria-label": t("layout.groupTitle"), autocomplete: "off" });
  input.addEventListener("change", () => {
    if (input.value !== label) ctx.store.update((doc) => { renameGroup(doc, entry.id, index, input.value); });
  });
  const handle = h("span", { class: "drag-handle", draggable: true, title: t("layout.handle"), "aria-label": t("layout.handle") }, "⠿");
  handle.addEventListener("dragstart", (event) => startDrag(ctx, event, { type: "group", index }));
  handle.addEventListener("dragend", () => { ctx.view.drag = null; });
  const head = h("div", { class: "group-head" },
    handle,
    input,
    h("button", { type: "button", class: "icon danger", title: t("layout.deleteGroup"), "aria-label": t("layout.deleteGroup"), disabled: count < 2, onclick: () => ctx.store.update((doc) => { deleteGroup(doc, entry.id, index); }) }, "✕"));
  head.addEventListener("dragover", (event) => allow(ctx, event, "group", "track"));
  head.addEventListener("drop", (event) => {
    if (!allow(ctx, event, "group", "track")) return;
    event.stopPropagation();
    if (ctx.view.drag.type === "group") {
      const from = ctx.view.drag.index;
      ctx.view.drag = null;
      ctx.store.update((doc) => { moveGroup(doc, entry.id, from, index); });
    } else dropTrack(ctx, entry, index, 0);
  });
  return head;
}

function trackSlot(ctx, entry, track, groupIndex, position, content) {
  const handle = h("span", { class: "drag-handle", draggable: true, title: t("layout.handle"), "aria-label": t("layout.handle") }, "⠿");
  handle.addEventListener("dragstart", (event) => startDrag(ctx, event, { type: "track", track }));
  handle.addEventListener("dragend", () => { ctx.view.drag = null; });
  const slot = h("div", { class: "layout-row" }, handle, content);
  slot.addEventListener("dragover", (event) => allow(ctx, event, "track"));
  slot.addEventListener("drop", (event) => {
    if (!allow(ctx, event, "track")) return;
    event.stopPropagation();
    dropTrack(ctx, entry, groupIndex, position);
  });
  return slot;
}

export function layoutView(ctx, entry, renderRow) {
  const groups = layoutOf(entry);
  const order = groups.flatMap((group) => group.tracks);
  const blocks = groups.map((group, groupIndex) => {
    const rows = group.tracks.map((track, position) => trackSlot(ctx, entry, track, groupIndex, position, renderRow(track, order.indexOf(track), order.length)));
    const body = h("div", { class: "group-body" }, rows);
    body.addEventListener("dragover", (event) => allow(ctx, event, "track"));
    body.addEventListener("drop", (event) => {
      if (allow(ctx, event, "track")) dropTrack(ctx, entry, groupIndex, null);
    });
    return h("section", { class: "layout-group" }, groupHead(ctx, entry, group, groupIndex, groups.length), body);
  });
  return h("div", { class: "layout" },
    blocks,
    h("div", { class: "saved-row" },
      h("button", { type: "button", disabled: groups.length >= LAYOUT_LIMIT, onclick: () => ctx.store.update((doc) => { addGroup(doc, entry.id, t("layout.newGroup")); }) }, t("layout.add")),
      h("button", { type: "button", disabled: !Array.isArray(entry.default_layout), onclick: () => ctx.store.update((doc) => { resetLayout(doc, entry.id); }) }, t("layout.reset"))));
}
