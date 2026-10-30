import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { installFakeDom } from "./fakeDom.js";
import { fresh } from "./data.js";
import { api } from "../../web/js/api.js";
import { create, setPath, unsetPath } from "../../web/js/store.js";
import { compute, parse } from "../../web/js/expr.js";
import { validateLevels, validateRoutes, MAX_ITEMS, isIdentifier } from "../../web/js/levels.js";

const WEB = fileURLToPath(new URL("../../web/js/", import.meta.url));

function sources(dir = WEB) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? sources(path) : name.endsWith(".js") ? [[path, readFileSync(path, "utf8")]] : [];
  });
}

test("api requests send no cookies, set the guard header on changes and report errors", async () => {
  const seen = [];
  globalThis.fetch = async (path, options) => {
    seen.push({ path, options });
    return { ok: false, status: 403, json: async () => ({ error: "GUARD" }) };
  };
  await assert.rejects(api.document(), (error) => error.message === "GUARD" && error.status === 403);
  await assert.rejects(api.save({}), (error) => error.message === "GUARD");
  assert.equal(seen[0].options.headers, undefined);
  assert.equal(seen[0].options.credentials, "omit");
  assert.equal(seen[1].options.headers["X-Upgrade-Editor"], "1");
  assert.equal(seen[1].options.headers["Content-Type"], "application/json");
  globalThis.fetch = async () => ({ ok: false, status: 500, json: async () => { throw new SyntaxError("html"); } });
  await assert.rejects(api.document(), (error) => error.message === "ERROR");
  delete globalThis.fetch;
});

test("store paths cannot reach prototypes or create missing parents", () => {
  const doc = fresh();
  for (const path of ["__proto__.polluted", "tracks.__proto__.polluted", "constructor.prototype.polluted", "tracks.rate.constructor", "missing.deep.value", "tracks..price", ""]) {
    assert.throws(() => setPath(doc, path, 1), /PATH/, path);
    assert.throws(() => unsetPath(doc, path), /PATH/, path);
  }
  assert.equal({}.polluted, undefined);
  assert.equal(Object.prototype.polluted, undefined);
  setPath(doc, "tracks.rate.price", 0.5);
  assert.equal(doc.tracks.rate.price, 0.5);
  const store = create(doc, doc);
  store.unset("tracks.rate.growth");
  assert.equal("growth" in store.state.document.tracks.rate, false);
  assert.throws(() => store.unset("__proto__.toString"), /PATH/);
  assert.equal(typeof {}.toString, "function");
});

test("documents with a __proto__ key stay plain data", () => {
  const doc = JSON.parse('{"tracks": {"__proto__": {"polluted": 1}}}');
  const store = create(doc, doc);
  assert.equal({}.polluted, undefined);
  assert.equal(store.state.document.tracks.polluted, undefined);
});

test("formulas cannot reach object internals and stay fast on hostile input", () => {
  for (const source of ["constructor(1)", "__proto__(1)", "toString(1)", "valueOf(1)", "hasOwnProperty(1)"]) {
    assert.throws(() => compute(source, { level: 1 }), (error) => error.code === "FUNCTION", source);
  }
  for (const source of ["constructor", "__proto__", "prototype", "toString"]) {
    assert.throws(() => compute(source, {}), (error) => error.code === "VARIABLE", source);
  }
  assert.throws(() => compute("level", Object.create({ level: 5 })), (error) => error.code === "VARIABLE");
  const started = performance.now();
  for (const source of ["1".repeat(400), "(".repeat(399), "-".repeat(399) + "1", "1e".repeat(200), "a".repeat(400), "1+".repeat(199) + "1"]) {
    try {
      parse(source);
    } catch (error) {
      assert.ok(error.code, source.slice(0, 10));
    }
  }
  assert.throws(() => parse("1".repeat(401)), (error) => error.code === "LONG");
  assert.ok(performance.now() - started < 500);
});

test("level ids and lists are limited like the server validation", () => {
  const doc = fresh();
  const kinds = Object.keys(doc.enemies);
  for (const id of ['a"b', "a b", "x\ny", "<script>", "", "a".repeat(49), "ü"]) {
    const levels = fresh().levels;
    levels[0].id = id;
    assert.ok(validateLevels(levels, kinds).some((error) => error.code === "LEVEL_ID"), JSON.stringify(id));
    assert.equal(isIdentifier(id), false);
  }
  assert.ok(isIdentifier("dawn-2_b"));
  const crowded = fresh().levels;
  crowded[0].structures = Array.from({ length: MAX_ITEMS + 1 }, () => ["nest", [0.5, 0.5]]);
  crowded[0].terrain.ponds = 1e6;
  crowded[0].money = 1e300;
  const errors = validateLevels(crowded, kinds);
  assert.ok(errors.some((error) => error.code === "LIMIT" && error.path === "levels.0.structures"));
  assert.ok(errors.some((error) => error.code === "LEVEL_TERRAIN" && error.path === "levels.0.terrain.ponds"));
  assert.ok(errors.some((error) => error.code === "LEVEL_MONEY"));
  assert.deepEqual(validateRoutes(Array.from({ length: 2001 }, () => [0, 1]), 2), [{ code: "LIMIT", path: "routes" }]);
});

test("the web app never renders markup from strings or evaluates code", () => {
  const forbidden = /\.innerHTML|\.outerHTML|insertAdjacentHTML|document\.write|\beval\s*\(|new Function|setTimeout\(\s*["'`]|setInterval\(\s*["'`]|createContextualFragment|srcdoc/;
  for (const [path, text] of sources()) assert.doesNotMatch(text, forbidden, path);
});

test("svg styles go through the CSS object model, not inline style attributes", async () => {
  installFakeDom();
  const { svgNode } = await import("../../web/js/views/components.js");
  const node = svgNode("polyline", { class: "series", style: "stroke:#123456", points: "0,0" });
  assert.equal(node.style.cssText, "stroke:#123456");
  assert.equal(node.getAttribute("style"), null);
  assert.equal(node.getAttribute("class"), "series");
  for (const [path, text] of sources()) assert.doesNotMatch(text, /setAttribute\(\s*["']style["']/, path);
});

test("text from the document is rendered as text nodes", async () => {
  installFakeDom();
  const { h } = await import("../../web/js/dom.js");
  const node = h("div", { title: '"><img src=x onerror=alert(1)>' }, "<b>bold</b>", 5);
  assert.equal(node.children[0].nodeType, 3);
  assert.equal(node.children[0].data, "<b>bold</b>");
  assert.equal(node.title, '"><img src=x onerror=alert(1)>');
  assert.equal(node.listeners.error, undefined);
});

test("every validation error code is translated", () => {
  const read = (path) => readFileSync(new URL(path, import.meta.url), "utf8");
  const dictionaries = ["de", "en"].map((code) => JSON.parse(read(`../../web/i18n/${code}.json`)));
  const codes = new Set(["../../upgrade_editor/model.py", "../../upgrade_editor/content_model.py"].flatMap((path) => [...read(path).matchAll(/_error\("([A-Z_]+)"/g)].map((match) => match[1])));
  assert.ok(codes.has("LIMIT") && codes.has("READONLY"));
  for (const dictionary of dictionaries) {
    for (const code of codes) assert.ok(dictionary[`error.${code}`], code);
  }
});
