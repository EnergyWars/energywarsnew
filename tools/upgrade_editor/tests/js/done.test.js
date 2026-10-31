import test from "node:test";
import assert from "node:assert/strict";
import { isDone, setDone, pruneDone, doneKey } from "../../web/js/done.js";

const entry = { id: "solar" };

test("done marks are set, cleared and pruned", () => {
  const doc = {};
  assert.equal(isDone(doc, entry, "hull"), false);
  setDone(doc, entry, "hull", true);
  setDone(doc, entry, "hull", true);
  setDone(doc, entry, "armor", true);
  assert.deepEqual(doc.done, ["solar:armor", "solar:hull"]);
  assert.equal(isDone(doc, entry, "hull"), true);
  assert.equal(doneKey(entry, "hull"), "solar:hull");
  setDone(doc, entry, "hull", false);
  assert.equal(isDone(doc, entry, "hull"), false);
  pruneDone(doc, "solar", "armor");
  assert.deepEqual(doc.done, []);
  pruneDone({}, "solar", "armor");
});
