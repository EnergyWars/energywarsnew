class FakeNode {
  constructor(tag) {
    this.tagName = tag;
    this.children = [];
    this.parentNode = null;
    this.attributes = {};
    this.listeners = {};
    this.className = "";
    this.hidden = false;
    this.disabled = false;
    this.value = "";
    this.type = "";
    this.id = "";
    this.title = "";
    this.placeholder = "";
    this.textContent = "";
    this.style = {};
    this.dataset = {};
    this.nodeType = 1;
    this.focused = false;
  }

  setAttribute(name, value) {
    this.attributes[name] = String(value);
  }

  getAttribute(name) {
    return this.attributes[name] ?? null;
  }

  removeAttribute(name) {
    delete this.attributes[name];
  }

  append(...nodes) {
    for (const node of nodes) {
      node.parentNode = this;
      this.children.push(node);
    }
  }

  replaceChildren(...nodes) {
    this.children = [];
    this.append(...nodes);
  }

  addEventListener(type, handler) {
    (this.listeners[type] ??= []).push(handler);
  }

  dispatch(type, event = {}) {
    const payload = { type, target: this, preventDefault() { this.prevented = true; }, ...event };
    for (const handler of this.listeners[type] ?? []) handler(payload);
    return payload;
  }

  contains(node) {
    for (let current = node; current; current = current.parentNode) if (current === this) return true;
    return false;
  }

  focus() {
    this.focused = true;
  }

  find(predicate) {
    if (predicate(this)) return this;
    for (const child of this.children) {
      const found = child.find ? child.find(predicate) : null;
      if (found) return found;
    }
    return null;
  }

  findAll(predicate, out = []) {
    if (predicate(this)) out.push(this);
    for (const child of this.children) if (child.findAll) child.findAll(predicate, out);
    return out;
  }

  text() {
    return this.textContent + this.children.map((child) => (child.text ? child.text() : child.data ?? "")).join("");
  }
}

export function installFakeDom() {
  globalThis.document = {
    createElement: (tag) => new FakeNode(tag),
    createTextNode: (data) => ({ nodeType: 3, data: String(data), text: () => String(data) }),
    createElementNS: (_, tag) => new FakeNode(tag),
  };
}
