const FUNCTIONS = {
  min: Math.min, max: Math.max, abs: Math.abs, sqrt: Math.sqrt, exp: Math.exp, ln: Math.log, log10: Math.log10,
  floor: Math.floor, ceil: Math.ceil, round: Math.round, pow: Math.pow, sign: Math.sign,
  log: (value, base = Math.E) => Math.log(value) / Math.log(base),
};
const CONSTANTS = { pi: Math.PI, e: Math.E };
export const FUNCTION_NAMES = Object.keys(FUNCTIONS);
export const CONSTANT_NAMES = Object.keys(CONSTANTS);
const MAX_LENGTH = 400;

export class ExpressionError extends Error {
  constructor(code, detail = "") {
    super(code);
    this.code = code;
    this.detail = detail;
  }
}

function tokenize(source) {
  const tokens = [];
  const pattern = /\s*(?:(\d+\.?\d*(?:e[+-]?\d+)?|\.\d+(?:e[+-]?\d+)?)|([A-Za-z_][A-Za-z_0-9]*)|(\*\*|[-+*/^(),]))/giy;
  let index = 0;
  while (index < source.length) {
    pattern.lastIndex = index;
    const match = pattern.exec(source);
    if (!match) {
      if (/^\s*$/.test(source.slice(index))) break;
      throw new ExpressionError("CHAR", source.slice(index).trim()[0]);
    }
    index = pattern.lastIndex;
    if (match[1] !== undefined) tokens.push({ type: "num", value: Number(match[1]) });
    else if (match[2] !== undefined) tokens.push({ type: "name", value: match[2].toLowerCase() });
    else tokens.push({ type: "op", value: match[3] === "**" ? "^" : match[3] });
  }
  return tokens;
}

export function parse(source) {
  if (typeof source !== "string" || !source.trim()) throw new ExpressionError("EMPTY");
  if (source.length > MAX_LENGTH) throw new ExpressionError("LONG");
  const tokens = tokenize(source);
  let position = 0;
  const peek = () => tokens[position];
  const take = () => tokens[position++];
  const isOp = (value) => peek()?.type === "op" && peek().value === value;
  const expect = (value) => {
    if (!isOp(value)) throw new ExpressionError("EXPECTED", value);
    position += 1;
  };

  function additive() {
    let left = multiplicative();
    while (isOp("+") || isOp("-")) {
      const op = take().value;
      const right = multiplicative();
      left = { type: "bin", op, left, right };
    }
    return left;
  }

  function multiplicative() {
    let left = unary();
    while (isOp("*") || isOp("/")) {
      const op = take().value;
      const right = unary();
      left = { type: "bin", op, left, right };
    }
    return left;
  }

  function unary() {
    if (isOp("-") || isOp("+")) {
      const op = take().value;
      const operand = unary();
      return op === "-" ? { type: "neg", operand } : operand;
    }
    return power();
  }

  function power() {
    const base = primary();
    if (isOp("^")) {
      position += 1;
      return { type: "bin", op: "^", left: base, right: unary() };
    }
    return base;
  }

  function primary() {
    const token = take();
    if (!token) throw new ExpressionError("END");
    if (token.type === "num") return { type: "num", value: token.value };
    if (token.type === "name") {
      if (isOp("(")) {
        if (!Object.hasOwn(FUNCTIONS, token.value)) throw new ExpressionError("FUNCTION", token.value);
        position += 1;
        const args = [];
        if (!isOp(")")) {
          args.push(additive());
          while (isOp(",")) {
            position += 1;
            args.push(additive());
          }
        }
        expect(")");
        return { type: "call", name: token.value, args };
      }
      return { type: "var", name: token.value };
    }
    if (token.value === "(") {
      const inner = additive();
      expect(")");
      return inner;
    }
    throw new ExpressionError("TOKEN", token.value);
  }

  const tree = additive();
  if (position < tokens.length) throw new ExpressionError("TOKEN", String(peek().value));
  return tree;
}

export function variables(tree, found = new Set()) {
  if (tree.type === "var" && !Object.hasOwn(CONSTANTS, tree.name)) found.add(tree.name);
  for (const child of [tree.left, tree.right, tree.operand, ...(tree.args ?? [])]) if (child) variables(child, found);
  return found;
}

export function evaluate(tree, scope = {}) {
  switch (tree.type) {
    case "num": return tree.value;
    case "var":
      if (Object.hasOwn(scope, tree.name)) return scope[tree.name];
      if (Object.hasOwn(CONSTANTS, tree.name)) return CONSTANTS[tree.name];
      throw new ExpressionError("VARIABLE", tree.name);
    case "neg": return -evaluate(tree.operand, scope);
    case "call": return FUNCTIONS[tree.name](...tree.args.map((arg) => evaluate(arg, scope)));
    default: {
      const left = evaluate(tree.left, scope);
      const right = evaluate(tree.right, scope);
      if (tree.op === "+") return left + right;
      if (tree.op === "-") return left - right;
      if (tree.op === "*") return left * right;
      if (tree.op === "/") return left / right;
      return left ** right;
    }
  }
}

export function compute(source, scope) {
  const value = evaluate(parse(source), scope);
  if (!Number.isFinite(value)) throw new ExpressionError("RANGE");
  return value;
}
