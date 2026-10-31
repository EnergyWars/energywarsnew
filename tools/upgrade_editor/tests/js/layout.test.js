import test from "node:test";
import assert from "node:assert/strict";
import { layoutOf, moveTrack, moveTrackBy, addGroup, renameGroup, moveGroup, deleteGroup, resetLayout, layoutAddTrack, layoutRemoveTrack, LAYOUT_LIMIT, LAYOUT_TITLE_LIMIT } from "../../web/js/layout.js";

const make = () => ({
  buildings: [{
    id: "a",
    tracks: ["x", "y", "z"],
    layout: [{ title: "ONE", tracks: ["x", "y"] }, { title: "TWO", tracks: ["z"] }],
    default_layout: [{ title: "ONE", tracks: ["x", "y"] }, { title: "TWO", tracks: ["z"] }],
  }],
});
const layout = (doc) => doc.buildings[0].layout;

test("layoutOf repairs missing, unknown and duplicate tracks", () => {
  assert.deepEqual(layoutOf({ tracks: ["x", "y"] }), [{ title: "", tracks: ["x", "y"] }]);
  const entry = { tracks: ["x", "y", "z"], layout: [{ title: "A", tracks: ["x", "x", "q"] }, { title: 5, tracks: ["y"] }] };
  assert.deepEqual(layoutOf(entry), [{ title: "A", tracks: ["x"] }, { title: "", tracks: ["y", "z"] }]);
});

test("moveTrack moves within and between groups", () => {
  const doc = make();
  assert.ok(moveTrack(doc, "a", "x", 0, 2));
  assert.deepEqual(layout(doc)[0].tracks, ["y", "x"]);
  assert.ok(moveTrack(doc, "a", "x", 1, 0));
  assert.deepEqual(layout(doc).map((g) => g.tracks), [["y"], ["x", "z"]]);
  assert.ok(moveTrack(doc, "a", "y", 1));
  assert.deepEqual(layout(doc).map((g) => g.tracks), [[], ["x", "z", "y"]]);
  assert.equal(moveTrack(doc, "a", "nope", 0), false);
  assert.equal(moveTrack(doc, "a", "x", 9), false);
  assert.equal(moveTrack(doc, "missing", "x", 0), false);
});

test("moveTrackBy steps through groups", () => {
  const doc = make();
  assert.ok(moveTrackBy(doc, "a", "y", 1));
  assert.deepEqual(layout(doc).map((g) => g.tracks), [["x"], ["y", "z"]]);
  assert.ok(moveTrackBy(doc, "a", "y", 1));
  assert.deepEqual(layout(doc)[1].tracks, ["z", "y"]);
  assert.equal(moveTrackBy(doc, "a", "y", 1), false);
  assert.ok(moveTrackBy(doc, "a", "y", -1));
  assert.deepEqual(layout(doc)[1].tracks, ["y", "z"]);
  assert.ok(moveTrackBy(doc, "a", "y", -1));
  assert.deepEqual(layout(doc).map((g) => g.tracks), [["x", "y"], ["z"]]);
  assert.equal(moveTrackBy(doc, "a", "x", -1), false);
  assert.equal(moveTrackBy(doc, "a", "x", 2), false);
});

test("groups can be added, renamed, moved and deleted", () => {
  const doc = make();
  assert.ok(addGroup(doc, "a", "  New  "));
  assert.equal(layout(doc)[2].title, "New");
  assert.ok(renameGroup(doc, "a", 2, "x".repeat(100)));
  assert.equal(layout(doc)[2].title.length, LAYOUT_TITLE_LIMIT);
  assert.equal(renameGroup(doc, "a", 7, "n"), false);
  assert.ok(moveGroup(doc, "a", 2, 0));
  assert.deepEqual(layout(doc).map((g) => g.title), ["x".repeat(LAYOUT_TITLE_LIMIT), "ONE", "TWO"]);
  assert.equal(moveGroup(doc, "a", 1, 1), false);
  assert.ok(deleteGroup(doc, "a", 2));
  assert.deepEqual(layout(doc)[1].tracks, ["x", "y", "z"]);
  assert.ok(deleteGroup(doc, "a", 0));
  assert.equal(deleteGroup(doc, "a", 0), false);
});

test("group count is limited", () => {
  const doc = make();
  while (addGroup(doc, "a", "g"));
  assert.equal(layout(doc).length, LAYOUT_LIMIT);
});

test("resetLayout restores the default and add/remove keep the layout in sync", () => {
  const doc = make();
  moveTrack(doc, "a", "x", 1);
  assert.ok(resetLayout(doc, "a"));
  assert.deepEqual(layout(doc), doc.buildings[0].default_layout);
  assert.notEqual(layout(doc), doc.buildings[0].default_layout);
  const entry = doc.buildings[0];
  entry.tracks.push("w");
  layoutAddTrack(entry, "w");
  assert.deepEqual(entry.layout[1].tracks, ["z", "w"]);
  layoutAddTrack(entry, "w");
  assert.equal(entry.layout[1].tracks.length, 2);
  layoutRemoveTrack(entry, "x");
  assert.deepEqual(entry.layout[0].tracks, ["y"]);
  assert.equal(resetLayout({ buildings: [{ id: "b", tracks: [] }] }, "b"), false);
});
