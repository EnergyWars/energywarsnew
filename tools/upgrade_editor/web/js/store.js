const HISTORY_LIMIT = 200;

export function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

export function setPath(document, path, value) {
  const keys = path.split(".");
  let node = document;
  for (const key of keys.slice(0, -1)) node = node[key];
  node[keys[keys.length - 1]] = value;
}

export function create(document, original) {
  const state = { document: clone(document), original, past: [], future: [], listeners: [], saved: JSON.stringify(document) };
  const notify = () => state.listeners.forEach((listener) => listener());
  const push = () => {
    state.past.push(clone(state.document));
    if (state.past.length > HISTORY_LIMIT) state.past.shift();
    state.future = [];
  };
  return {
    state,
    subscribe: (listener) => state.listeners.push(listener),
    set(path, value) {
      push();
      setPath(state.document, path, value);
      notify();
    },
    update(mutator) {
      push();
      try {
        mutator(state.document);
      } catch (error) {
        state.document = state.past.pop();
        throw error;
      }
      notify();
    },
    unset(path) {
      push();
      const keys = path.split(".");
      let node = state.document;
      for (const key of keys.slice(0, -1)) node = node[key];
      delete node[keys[keys.length - 1]];
      notify();
    },
    undo() {
      if (!state.past.length) return;
      state.future.push(clone(state.document));
      state.document = state.past.pop();
      notify();
    },
    redo() {
      if (!state.future.length) return;
      state.past.push(clone(state.document));
      state.document = state.future.pop();
      notify();
    },
    canUndo: () => state.past.length > 0,
    canRedo: () => state.future.length > 0,
    dirty: () => JSON.stringify(state.document) !== state.saved,
    markSaved() {
      state.saved = JSON.stringify(state.document);
      notify();
    },
    replace(document) {
      state.document = clone(document);
      state.past = [];
      state.future = [];
      state.saved = JSON.stringify(document);
      notify();
    },
  };
}
