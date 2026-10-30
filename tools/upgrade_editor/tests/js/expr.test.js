import test from "node:test";
import assert from "node:assert/strict";
import { parse, evaluate, compute, variables, ExpressionError } from "../../web/js/expr.js";

const calc = (source, scope = {}) => compute(source, scope);
const fails = (source, code) => assert.throws(() => calc(source, { level: 1 }), (error) => error instanceof ExpressionError && error.code === code, source);

test("arithmetic and precedence", () => {
  assert.equal(calc("1 + 2 * 3"), 7);
  assert.equal(calc("(1 + 2) * 3"), 9);
  assert.equal(calc("10 / 4 - 1"), 1.5);
  assert.equal(calc("2 * -3"), -6);
  assert.equal(calc("--3"), 3);
  assert.equal(calc("+4"), 4);
});

test("power is right associative and binds tighter than unary minus", () => {
  assert.equal(calc("2 ^ 3 ^ 2"), 512);
  assert.equal(calc("-2 ^ 2"), -4);
  assert.equal(calc("2 ** 3"), 8);
  assert.equal(calc("2 ^ -1"), 0.5);
});

test("numbers", () => {
  assert.equal(calc(".5 + 1."), 1.5);
  assert.equal(calc("1e3"), 1000);
  assert.equal(calc("2.5e-1"), 0.25);
});

test("variables are case insensitive and constants exist", () => {
  assert.equal(calc("Level * 2", { level: 4 }), 8);
  assert.ok(Math.abs(calc("pi") - Math.PI) < 1e-12);
  assert.ok(Math.abs(calc("e") - Math.E) < 1e-12);
});

test("functions", () => {
  assert.equal(calc("min(3, 1, 2)"), 1);
  assert.equal(calc("max(1, 5)"), 5);
  assert.equal(calc("sqrt(16) + abs(-2)"), 6);
  assert.equal(calc("floor(2.7) + ceil(2.1) + round(2.5)"), 8);
  assert.equal(calc("pow(2, 10)"), 1024);
  assert.equal(calc("log(8, 2)"), 3);
  assert.ok(Math.abs(calc("ln(e)") - 1) < 1e-12);
  assert.equal(calc("log10(1000)"), 3);
  assert.equal(calc("sign(-9)"), -1);
  assert.equal(calc("exp(0)"), 1);
});

test("typical balance formula", () => {
  assert.equal(calc("base * 0.25 * 1.18 ^ level", { base: 40, level: 0 }), 10);
});

test("syntax errors carry codes", () => {
  fails("", "EMPTY");
  fails("   ", "EMPTY");
  fails("1 +", "END");
  fails("(1 + 2", "EXPECTED");
  fails("1 2", "TOKEN");
  fails("1 + * 2", "TOKEN");
  fails("foo(1)", "FUNCTION");
  fails("3 $ 4", "CHAR");
  fails("x + 1", "VARIABLE");
  fails("1 / 0", "RANGE");
  fails("sqrt(-1)", "RANGE");
  fails("x".repeat(401), "LONG");
  fails(")", "TOKEN");
});

test("non string input is empty", () => {
  assert.throws(() => parse(null), ExpressionError);
});

test("no access to the global scope or prototypes", () => {
  fails("constructor", "VARIABLE");
  fails("toString(1)", "FUNCTION");
  fails("__proto__", "VARIABLE");
});

test("variables lists names without constants", () => {
  assert.deepEqual([...variables(parse("base * pi + max(level, 2)"))].sort(), ["base", "level"]);
});

test("evaluate reuses a parsed tree", () => {
  const tree = parse("level * 2");
  assert.equal(evaluate(tree, { level: 2 }), 4);
  assert.equal(evaluate(tree, { level: 5 }), 10);
});
