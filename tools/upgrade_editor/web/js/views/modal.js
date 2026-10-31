import { h } from "../dom.js";
import { t } from "../i18n.js";

export function openModal({ title, render }) {
  const body = h("div", { class: "modal-body" });
  const previous = document.activeElement;
  const close = () => {
    document.removeEventListener("keydown", onKey);
    backdrop.remove();
    if (previous?.focus) previous.focus();
  };
  const onKey = (event) => {
    if (event.key === "Escape") close();
  };
  const refresh = () => body.replaceChildren(render({ close, refresh }));
  const closeButton = h("button", { type: "button", class: "modal-close", "aria-label": t("modal.close"), onclick: close }, t("modal.close"));
  const dialog = h("div", { class: "modal", role: "dialog", "aria-modal": "true", "aria-label": title },
    h("div", { class: "modal-head" }, h("h3", {}, title), closeButton),
    body);
  const backdrop = h("div", { class: "modal-backdrop", onclick: (event) => {
    if (event.target === backdrop) close();
  } }, dialog);
  document.addEventListener("keydown", onKey);
  document.body.append(backdrop);
  refresh();
  closeButton.focus();
  return { close, refresh, backdrop };
}
