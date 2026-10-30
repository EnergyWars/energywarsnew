export const MIN_CELLS = 20;
export const MAX_CELLS = 400;
export const MAX_LEVELS = 200;
export const STRUCTURE_KINDS = ["nest", "camp", "turret"];
export const CHALLENGE_KINDS = ["core", "lost", "days", "combo", "survive"];
export const TERRAIN_COUNTS = ["plateaus", "chasms", "ponds", "groves", "forests", "rocks"];
export const WAVE_NUMBERS = ["interval", "base", "ramp", "night", "growth"];
export const MAX_NUMBER = 1e9;
export const MAX_ITEMS = 64;
export const MAX_ROUTES = 2000;
export const MAX_TERRAIN = 100;
export const MAX_SECONDS = 3600;
export const MAX_WAVE_FACTOR = 1000;
export const MAX_DAY = 10000;
export const IDENTIFIER = /^[A-Za-z0-9_-]{1,48}$/;
export const LEVEL_REQUIRED = ["id", "cells", "money", "day", "night", "seed", "drop", "structures", "terrain", "waves", "world", "challenges"];
export const LEVEL_OPTIONAL = ["extra_waves"];
const WAVE_KEYS = [...WAVE_NUMBERS, "roster", "night_roster"];
const TERRAIN_KEYS = [...TERRAIN_COUNTS, "spots"];

const clone = (value) => JSON.parse(JSON.stringify(value));
const isNumber = (value) => typeof value === "number" && Number.isFinite(value) && Math.abs(value) <= MAX_NUMBER;
const isInteger = (value) => isNumber(value) && Number.isInteger(value);
const isUnit = (value) => isNumber(value) && value >= 0 && value <= 1;
const isPair = (value, check) => Array.isArray(value) && value.length === 2 && value.every(check);
const isText = (value) => typeof value === "string" && value.trim() !== "";
const isOffset = (value) => isInteger(value) && Math.abs(value) <= MAX_CELLS;
export const isIdentifier = (value) => typeof value === "string" && IDENTIFIER.test(value);

function within(items, limit, path, errors) {
  if (items.length <= limit) return true;
  errors.push(error("LIMIT", path));
  return false;
}
const isObject = (value) => Boolean(value) && typeof value === "object" && !Array.isArray(value);
const sameKeys = (value, keys) => Object.keys(value).length === keys.length && keys.every((key) => Object.hasOwn(value, key));

export function uniqueId(levels, base = "level") {
  const used = new Set(levels.map((level) => level.id));
  const stem = base.replace(/-\d+$/, "") || "level";
  let counter = 2;
  while (used.has(`${stem}-${counter}`)) counter += 1;
  return `${stem}-${counter}`;
}

export function templateLevel(levels) {
  const level = clone(levels[levels.length - 1]);
  level.id = uniqueId(levels, level.id);
  level.world = null;
  return level;
}

export function remapRoutes(routes, mapping) {
  if (!Array.isArray(routes)) return routes;
  const result = [];
  for (const [a, b] of routes) {
    const from = mapping(a);
    const to = mapping(b);
    if (from === null || to === null) continue;
    result.push([from, to]);
  }
  return result;
}

export function addLevel(doc) {
  if (doc.levels.length >= MAX_LEVELS) return doc.levels.length - 1;
  doc.levels.push(templateLevel(doc.levels));
  return doc.levels.length - 1;
}

export function duplicateLevel(doc, index) {
  if (doc.levels.length >= MAX_LEVELS) return index;
  const copy = clone(doc.levels[index]);
  copy.id = uniqueId(doc.levels, copy.id);
  copy.world = null;
  const position = index + 1;
  doc.levels.splice(position, 0, copy);
  doc.routes = remapRoutes(doc.routes, (value) => (value >= position ? value + 1 : value));
  return position;
}

export function removeLevel(doc, index) {
  if (doc.levels.length <= 1) return Math.min(index, doc.levels.length - 1);
  doc.levels.splice(index, 1);
  doc.routes = remapRoutes(doc.routes, (value) => (value === index ? null : value > index ? value - 1 : value));
  return Math.min(index, doc.levels.length - 1);
}

export function moveLevel(doc, index, direction) {
  const target = index + direction;
  if (target < 0 || target >= doc.levels.length) return index;
  const [level] = doc.levels.splice(index, 1);
  doc.levels.splice(target, 0, level);
  doc.routes = remapRoutes(doc.routes, (value) => (value === index ? target : value === target ? index : value));
  return target;
}

export function routeKey(route) {
  return route[0] < route[1] ? `${route[0]}-${route[1]}` : `${route[1]}-${route[0]}`;
}

export function addRoute(doc, from, to, effective) {
  if (from === to) return false;
  const base = Array.isArray(doc.routes) ? doc.routes : effective.map((route) => [...route]);
  if (base.some((route) => routeKey(route) === routeKey([from, to]))) return false;
  doc.routes = [...base, [Math.min(from, to), Math.max(from, to)]];
  return true;
}

export function removeRoute(doc, from, to, effective) {
  const base = Array.isArray(doc.routes) ? doc.routes : effective.map((route) => [...route]);
  const key = routeKey([from, to]);
  doc.routes = base.filter((route) => routeKey(route) !== key);
}

export function setAutomaticRoutes(doc) {
  doc.routes = null;
}

function error(code, path) {
  return { code, path };
}

function checkRoster(roster, kinds, path, errors) {
  if (!Array.isArray(roster)) {
    errors.push(error("WAVE_ROSTER", path));
    return;
  }
  if (!within(roster, MAX_ITEMS, path, errors)) return;
  roster.forEach((entry, index) => {
    const valid = Array.isArray(entry) && entry.length === 3 && typeof entry[0] === "string" && kinds.has(entry[0]) && isInteger(entry[1]) && entry[1] >= 0 && entry[1] <= MAX_ITEMS && isNumber(entry[2]) && entry[2] > 0 && entry[2] <= MAX_WAVE_FACTOR;
    if (!valid) errors.push(error("WAVE_ROSTER", `${path}.${index}`));
  });
}

function checkWaves(waves, kinds, path, errors) {
  if (!isObject(waves) || !sameKeys(waves, WAVE_KEYS)) {
    errors.push(error("WAVES", path));
    return;
  }
  if (!isNumber(waves.interval) || waves.interval <= 0 || waves.interval > MAX_SECONDS) errors.push(error("WAVES", `${path}.interval`));
  for (const key of WAVE_NUMBERS.slice(1)) if (!isNumber(waves[key]) || waves[key] < 0 || waves[key] > MAX_WAVE_FACTOR) errors.push(error("WAVES", `${path}.${key}`));
  checkRoster(waves.roster, kinds, `${path}.roster`, errors);
  checkRoster(waves.night_roster, kinds, `${path}.night_roster`, errors);
  if (Array.isArray(waves.roster) && waves.roster.length === 0) errors.push(error("WAVE_ROSTER", `${path}.roster`));
}

export const MAX_EXTRA_COUNT = 200;

function checkExtraWaves(entries, kinds, path, errors) {
  if (!Array.isArray(entries)) {
    errors.push(error("EXTRA_WAVE", path));
    return;
  }
  if (!within(entries, MAX_ITEMS, path, errors)) return;
  entries.forEach((entry, index) => {
    const valid = entry && typeof entry === "object" && Object.keys(entry).sort().join() === "count,day,kind,night" && isInteger(entry.day) && entry.day >= 1 && entry.day <= MAX_DAY && typeof entry.night === "boolean" && typeof entry.kind === "string" && kinds.has(entry.kind) && isInteger(entry.count) && entry.count >= 1 && entry.count <= MAX_EXTRA_COUNT;
    if (!valid) errors.push(error("EXTRA_WAVE", `${path}.${index}`));
  });
}

function checkTerrain(terrain, path, errors) {
  if (!isObject(terrain) || !sameKeys(terrain, TERRAIN_KEYS)) {
    errors.push(error("LEVEL_TERRAIN", path));
    return;
  }
  for (const key of TERRAIN_COUNTS) if (!isInteger(terrain[key]) || terrain[key] < 0 || terrain[key] > MAX_TERRAIN) errors.push(error("LEVEL_TERRAIN", `${path}.${key}`));
  if (!Array.isArray(terrain.spots)) {
    errors.push(error("LEVEL_TERRAIN", `${path}.spots`));
    return;
  }
  if (!within(terrain.spots, MAX_ITEMS, `${path}.spots`, errors)) return;
  terrain.spots.forEach((spot, index) => {
    const valid = Array.isArray(spot) && spot.length === 3 && isPair(spot[0], isUnit) && isInteger(spot[1]) && spot[1] > 0 && spot[1] <= MAX_CELLS && Array.isArray(spot[2]) && spot[2].length <= MAX_ITEMS && spot[2].every((offset) => isPair(offset, isOffset));
    if (!valid) errors.push(error("LEVEL_TERRAIN", `${path}.spots.${index}`));
  });
}

export function validateLevel(level, kinds, path = "levels.0") {
  const errors = [];
  if (!isObject(level)) return [error("TYPE", path)];
  for (const key of Object.keys(level)) if (!LEVEL_REQUIRED.includes(key) && !LEVEL_OPTIONAL.includes(key)) errors.push(error("UNKNOWN_KEY", `${path}.${key}`));
  const missing = LEVEL_REQUIRED.filter((key) => !Object.hasOwn(level, key));
  for (const key of missing) errors.push(error("MISSING", `${path}.${key}`));
  if (missing.length) return errors;
  if (!isIdentifier(level.id)) errors.push(error("LEVEL_ID", `${path}.id`));
  if (!isPair(level.cells, isInteger) || level.cells.some((value) => value < MIN_CELLS || value > MAX_CELLS)) errors.push(error("LEVEL_CELLS", `${path}.cells`));
  if (!isInteger(level.money) || level.money < 0) errors.push(error("LEVEL_MONEY", `${path}.money`));
  for (const key of ["day", "night"]) if (!isNumber(level[key]) || level[key] <= 0 || level[key] > MAX_SECONDS) errors.push(error("LEVEL_TIME", `${path}.${key}`));
  if (!isInteger(level.seed)) errors.push(error("LEVEL_SEED", `${path}.seed`));
  if (!isPair(level.drop, isUnit)) errors.push(error("LEVEL_POSITION", `${path}.drop`));
  if (level.world !== null && !isPair(level.world, isUnit)) errors.push(error("LEVEL_POSITION", `${path}.world`));
  if (!Array.isArray(level.structures)) errors.push(error("LEVEL_STRUCTURE", `${path}.structures`));
  else if (within(level.structures, MAX_ITEMS, `${path}.structures`, errors)) level.structures.forEach((entry, index) => {
    const valid = Array.isArray(entry) && entry.length === 2 && STRUCTURE_KINDS.includes(entry[0]) && isPair(entry[1], isUnit);
    if (!valid) errors.push(error("LEVEL_STRUCTURE", `${path}.structures.${index}`));
  });
  checkTerrain(level.terrain, `${path}.terrain`, errors);
  checkWaves(level.waves, kinds, `${path}.waves`, errors);
  if (level.extra_waves !== undefined) checkExtraWaves(level.extra_waves, kinds, `${path}.extra_waves`, errors);
  if (!Array.isArray(level.challenges)) errors.push(error("CHALLENGE", `${path}.challenges`));
  else if (within(level.challenges, MAX_ITEMS, `${path}.challenges`, errors)) level.challenges.forEach((entry, index) => {
    const valid = Array.isArray(entry) && entry.length === 2 && CHALLENGE_KINDS.includes(entry[0]) && isInteger(entry[1]) && entry[1] >= 0;
    if (!valid) errors.push(error("CHALLENGE", `${path}.challenges.${index}`));
  });
  return errors;
}

export function validateLevels(levels, kinds) {
  const known = kinds instanceof Set ? kinds : new Set(kinds);
  if (!Array.isArray(levels) || levels.length < 1 || levels.length > MAX_LEVELS) return [error("LEVEL_SET", "levels")];
  const errors = [];
  const seen = new Set();
  levels.forEach((level, index) => {
    errors.push(...validateLevel(level, known, `levels.${index}`));
    if (isText(level?.id)) {
      if (seen.has(level.id)) errors.push(error("LEVEL_ID_DUPLICATE", `levels.${index}.id`));
      seen.add(level.id);
    }
  });
  return errors;
}

export function validateRoutes(routes, count) {
  if (routes === null || routes === undefined) return [];
  if (!Array.isArray(routes)) return [error("ROUTES", "routes")];
  if (routes.length > MAX_ROUTES) return [error("LIMIT", "routes")];
  const errors = [];
  const seen = new Set();
  routes.forEach((route, index) => {
    const valid = isPair(route, isInteger) && route.every((value) => value >= 0 && value < count) && route[0] !== route[1];
    if (!valid) {
      errors.push(error("ROUTES", `routes.${index}`));
      return;
    }
    const key = routeKey(route);
    if (seen.has(key)) errors.push(error("ROUTES", `routes.${index}`));
    seen.add(key);
  });
  return errors;
}

export function errorsFor(errors, path) {
  return errors.filter((item) => item.path === path || item.path.startsWith(`${path}.`));
}
