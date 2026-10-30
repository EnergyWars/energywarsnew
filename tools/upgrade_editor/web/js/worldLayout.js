export const AUTO = { left: 0.28, right: 0.72, start: 0.9, step: 0.19, pad: 0.1 };

export function autoPositions(levels) {
  const result = [];
  levels.forEach((level, index) => {
    if (Array.isArray(level.world)) {
      result.push([level.world[0], level.world[1]]);
    } else if (result.length === 0) {
      result.push([index % 2 === 0 ? AUTO.left : AUTO.right, AUTO.start]);
    } else {
      const previous = result[index - 1];
      result.push([previous[0] <= 0.5 ? AUTO.right : AUTO.left, previous[1] - AUTO.step]);
    }
  });
  return result;
}

export function worldTop(positions) {
  return positions.reduce((lowest, point) => Math.min(lowest, point[1] - AUTO.pad), 0);
}

export function connectAll(base, count) {
  const parent = Array.from({ length: count }, (_, index) => index);
  const root = (index) => {
    let current = index;
    while (parent[current] !== current) {
      parent[current] = parent[parent[current]];
      current = parent[current];
    }
    return current;
  };
  const join = (a, b) => {
    parent[root(a)] = root(b);
  };
  const result = [];
  for (const [a, b] of base) {
    if (!Number.isInteger(a) || !Number.isInteger(b) || a < 0 || b < 0 || a >= count || b >= count || a === b) continue;
    result.push([a, b]);
    join(a, b);
  }
  for (let index = 1; index < count; index += 1) {
    if (root(index) !== root(0)) {
      result.push([index - 1, index]);
      join(index - 1, index);
    }
  }
  return result;
}

export function effectiveRoutes(routes, count) {
  return connectAll(Array.isArray(routes) ? routes : [], count);
}

export function clampUnit(value) {
  return Math.round(Math.min(Math.max(value, 0), 1) * 1000) / 1000;
}

export function toWorld(fraction, top) {
  return [clampUnit(fraction[0]), clampUnit(Math.min(Math.max(top + fraction[1] * (1 - top), 0), 1))];
}
