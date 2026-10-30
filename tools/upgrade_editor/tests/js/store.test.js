import test from "node:test";
import assert from "node:assert/strict";
import { create, setPath } from "../../web/js/store.js";
import { game, fresh } from "./data.js";

test("set, undo and redo", () => {
  const store = create(fresh(), game);
  store.set("tracks.rate.price", 0.9);
  assert.equal(store.state.document.tracks.rate.price, 0.9);
  assert.ok(store.dirty());
  store.undo();
  assert.equal(store.state.document.tracks.rate.price, 0.22);
  assert.ok(!store.dirty());
  store.redo();
  assert.equal(store.state.document.tracks.rate.price, 0.9);
});

test("undo and redo on empty history do nothing", () => {
  const store = create(fresh(), game);
  store.undo();
  store.redo();
  assert.ok(!store.canUndo() && !store.canRedo());
});

test("a new edit clears the redo stack", () => {
  const store = create(fresh(), game);
  store.set("tracks.rate.price", 0.9);
  store.undo();
  store.set("tracks.rate.price", 0.8);
  assert.ok(!store.canRedo());
});

test("update mutates in one history step and unset removes keys", () => {
  const store = create(fresh(), game);
  store.update((doc) => { doc.tracks.rate.max = 3; doc.tracks.rate.step = 1; });
  assert.equal(store.state.past.length, 1);
  store.unset("tracks.links.growth");
  assert.equal(store.state.document.tracks.links.growth, undefined);
});

test("history is limited", () => {
  const store = create(fresh(), game);
  for (let i = 0; i < 250; i += 1) store.set("tracks.rate.max", i + 1);
  assert.equal(store.state.past.length, 200);
});

test("listeners are notified and markSaved resets dirty", () => {
  const store = create(fresh(), game);
  let calls = 0;
  store.subscribe(() => { calls += 1; });
  store.set("tracks.rate.max", 3);
  store.markSaved();
  assert.equal(calls, 2);
  assert.ok(!store.dirty());
});

test("replace resets history", () => {
  const store = create(fresh(), game);
  store.set("tracks.rate.max", 3);
  store.replace(fresh());
  assert.ok(!store.canUndo() && !store.dirty());
});

test("setPath walks nested keys", () => {
  const doc = { a: { b: { c: 1 } } };
  setPath(doc, "a.b.c", 2);
  assert.equal(doc.a.b.c, 2);
});
