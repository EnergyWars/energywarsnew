export const LAYOUT_LIMIT = 20;
export const LAYOUT_TITLE_LIMIT = 60;

const clone = (groups) => groups.map((group) => ({ title: group.title, tracks: [...group.tracks] }));

function entryOf(doc, id) {
  return doc.buildings.find((item) => item.id === id) ?? null;
}

export function layoutOf(entry) {
  const known = new Set(entry.tracks);
  const seen = new Set();
  const groups = [];
  for (const group of Array.isArray(entry.layout) ? entry.layout : []) {
    const tracks = (group.tracks ?? []).filter((track) => known.has(track) && !seen.has(track));
    tracks.forEach((track) => seen.add(track));
    groups.push({ title: typeof group.title === "string" ? group.title : "", tracks });
  }
  const missing = entry.tracks.filter((track) => !seen.has(track));
  if (groups.length === 0) return [{ title: "", tracks: [...entry.tracks] }];
  if (missing.length) groups[groups.length - 1].tracks.push(...missing);
  return groups;
}

export function groupLabel(names, title, lookup) {
  return title ? lookup(names, title, title) : "";
}

function write(entry, groups) {
  entry.layout = groups;
  return true;
}

export function moveTrack(doc, id, track, groupIndex, position = null) {
  const entry = entryOf(doc, id);
  if (!entry || !entry.tracks.includes(track)) return false;
  const groups = clone(layoutOf(entry));
  if (!groups[groupIndex]) return false;
  const source = groups.findIndex((group) => group.tracks.includes(track));
  const from = groups[source].tracks.indexOf(track);
  groups[source].tracks.splice(from, 1);
  const target = groups[groupIndex].tracks;
  let at = position === null ? target.length : Math.max(0, Math.min(position, target.length + 1));
  if (source === groupIndex && from < at) at -= 1;
  target.splice(Math.min(at, target.length), 0, track);
  return write(entry, groups);
}

export function moveTrackBy(doc, id, track, delta) {
  const entry = entryOf(doc, id);
  if (!entry || !entry.tracks.includes(track) || (delta !== -1 && delta !== 1)) return false;
  const groups = clone(layoutOf(entry));
  const source = groups.findIndex((group) => group.tracks.includes(track));
  const from = groups[source].tracks.indexOf(track);
  const inside = groups[source].tracks.length;
  if (delta === -1 && from > 0) return moveTrack(doc, id, track, source, from - 1);
  if (delta === 1 && from < inside - 1) return moveTrack(doc, id, track, source, from + 2);
  const next = source + delta;
  if (!groups[next]) return false;
  return moveTrack(doc, id, track, next, delta === -1 ? null : 0);
}

export function addGroup(doc, id, title = "") {
  const entry = entryOf(doc, id);
  const groups = entry ? clone(layoutOf(entry)) : null;
  if (!groups || groups.length >= LAYOUT_LIMIT) return false;
  groups.push({ title: String(title).trim().slice(0, LAYOUT_TITLE_LIMIT), tracks: [] });
  return write(entry, groups);
}

export function renameGroup(doc, id, index, title) {
  const entry = entryOf(doc, id);
  const groups = entry ? clone(layoutOf(entry)) : null;
  if (!groups || !groups[index]) return false;
  groups[index].title = String(title).trim().slice(0, LAYOUT_TITLE_LIMIT);
  return write(entry, groups);
}

export function moveGroup(doc, id, from, to) {
  const entry = entryOf(doc, id);
  const groups = entry ? clone(layoutOf(entry)) : null;
  if (!groups || !groups[from] || !groups[to] || from === to) return false;
  const [group] = groups.splice(from, 1);
  groups.splice(to, 0, group);
  return write(entry, groups);
}

export function deleteGroup(doc, id, index) {
  const entry = entryOf(doc, id);
  const groups = entry ? clone(layoutOf(entry)) : null;
  if (!groups || !groups[index] || groups.length < 2) return false;
  const [removed] = groups.splice(index, 1);
  const receiver = groups[index - 1] ?? groups[0];
  receiver.tracks.push(...removed.tracks);
  return write(entry, groups);
}

export function resetLayout(doc, id) {
  const entry = entryOf(doc, id);
  if (!entry || !Array.isArray(entry.default_layout)) return false;
  return write(entry, clone(entry.default_layout));
}

export function layoutAddTrack(entry, track) {
  if (!Array.isArray(entry.layout)) return;
  const groups = clone(layoutOf(entry));
  if (groups.some((group) => group.tracks.includes(track))) return;
  groups[groups.length - 1].tracks.push(track);
  entry.layout = groups;
}

export function layoutRemoveTrack(entry, track) {
  if (!Array.isArray(entry.layout)) return;
  entry.layout = entry.layout.map((group) => ({ title: group.title, tracks: group.tracks.filter((item) => item !== track) }));
}
