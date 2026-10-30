export const NAME_LIMIT = 60;
export const AREA_LIMIT = 50;
export const SECTION_LIMIT = 50;
export const ITEM_LIMIT = 500;
export const AREA_KEYS = ["name", "items", "sections"];
export const SECTION_KEYS = ["name", "items"];
export const DIRECT = -1;

export function areas(doc) {
  return Array.isArray(doc.groups) ? doc.groups : [];
}

export function itemKey(building, track) {
  return `${building}:${track}`;
}

export function parseItem(key) {
  const text = String(key);
  const split = text.indexOf(":");
  if (split <= 0 || split === text.length - 1) return null;
  return { building: text.slice(0, split), track: text.slice(split + 1) };
}

export function knownItems(doc) {
  return new Set(doc.buildings.flatMap((entry) => entry.tracks.map((track) => itemKey(entry.id, track))));
}

export function normalName(name) {
  return String(name ?? "").trim().toLowerCase();
}

export function cleanName(name) {
  return String(name ?? "").trim();
}

function nameUsed(list, name, skip = -1) {
  const wanted = normalName(name);
  return list.some((entry, index) => index !== skip && normalName(entry.name) === wanted);
}

export function nameProblem(list, name, skip = -1) {
  const clean = cleanName(name);
  if (!clean || clean.length > NAME_LIMIT) return "GROUP_NAME";
  if (nameUsed(list, clean, skip)) return "GROUP_DUPLICATE";
  return null;
}

export function uniqueName(list, base) {
  if (!nameUsed(list, base)) return base;
  for (let number = 2; ; number += 1) {
    const candidate = `${base} ${number}`;
    if (!nameUsed(list, candidate)) return candidate;
  }
}

function move(list, index, delta) {
  const target = index + delta;
  if (index < 0 || index >= list.length || target < 0 || target >= list.length) return index;
  [list[index], list[target]] = [list[target], list[index]];
  return target;
}

export function addArea(doc, base) {
  doc.groups = areas(doc);
  if (doc.groups.length >= AREA_LIMIT) return -1;
  doc.groups.push({ name: uniqueName(doc.groups, base), items: [], sections: [] });
  return doc.groups.length - 1;
}

export function renameArea(doc, index, name) {
  const list = areas(doc);
  if (!list[index]) return "GROUPS";
  const problem = nameProblem(list, name, index);
  if (!problem) list[index].name = cleanName(name);
  return problem;
}

export function removeArea(doc, index) {
  const list = areas(doc);
  if (!list[index]) return -1;
  list.splice(index, 1);
  return list.length ? Math.min(index, list.length - 1) : -1;
}

export function moveArea(doc, index, delta) {
  return move(areas(doc), index, delta);
}

export function sectionsOf(area) {
  return Array.isArray(area?.sections) ? area.sections : [];
}

export function itemsOf(holder) {
  return Array.isArray(holder?.items) ? holder.items : [];
}

export function addSection(doc, areaIndex, base) {
  const area = areas(doc)[areaIndex];
  if (!area) return -1;
  area.sections = sectionsOf(area);
  if (area.sections.length >= SECTION_LIMIT) return -1;
  area.sections.push({ name: uniqueName(area.sections, base), items: [] });
  return area.sections.length - 1;
}

export function renameSection(doc, areaIndex, sectionIndex, name) {
  const list = sectionsOf(areas(doc)[areaIndex]);
  if (!list[sectionIndex]) return "GROUPS";
  const problem = nameProblem(list, name, sectionIndex);
  if (!problem) list[sectionIndex].name = cleanName(name);
  return problem;
}

export function removeSection(doc, areaIndex, sectionIndex) {
  const list = sectionsOf(areas(doc)[areaIndex]);
  if (!list[sectionIndex]) return false;
  list.splice(sectionIndex, 1);
  return true;
}

export function moveSection(doc, areaIndex, sectionIndex, delta) {
  return move(sectionsOf(areas(doc)[areaIndex]), sectionIndex, delta);
}

export function holder(doc, areaIndex, sectionIndex = DIRECT) {
  const area = areas(doc)[areaIndex];
  if (!area) return null;
  if (sectionIndex === DIRECT) return area;
  return sectionsOf(area)[sectionIndex] ?? null;
}

export function addItem(doc, areaIndex, sectionIndex, key) {
  const target = holder(doc, areaIndex, sectionIndex);
  if (!target || !knownItems(doc).has(key)) return false;
  target.items = itemsOf(target);
  if (target.items.includes(key) || target.items.length >= ITEM_LIMIT) return false;
  target.items.push(key);
  return true;
}

export function removeItem(doc, areaIndex, sectionIndex, key) {
  const target = holder(doc, areaIndex, sectionIndex);
  if (!target || !itemsOf(target).includes(key)) return false;
  target.items = itemsOf(target).filter((item) => item !== key);
  return true;
}

export function moveItem(doc, areaIndex, sectionIndex, index, delta) {
  const target = holder(doc, areaIndex, sectionIndex);
  return target ? move(itemsOf(target), index, delta) : index;
}

export function pruneItem(doc, key) {
  let removed = 0;
  for (const area of areas(doc)) {
    for (const target of [area, ...sectionsOf(area)]) {
      const before = itemsOf(target).length;
      target.items = itemsOf(target).filter((item) => item !== key);
      removed += before - target.items.length;
    }
  }
  return removed;
}

export function membership(doc, key) {
  const places = [];
  areas(doc).forEach((area, areaIndex) => {
    if (itemsOf(area).includes(key)) places.push({ area: areaIndex, section: DIRECT, areaName: area.name, sectionName: null });
    sectionsOf(area).forEach((section, sectionIndex) => {
      if (itemsOf(section).includes(key)) places.push({ area: areaIndex, section: sectionIndex, areaName: area.name, sectionName: section.name });
    });
  });
  return places;
}

export function targetValue(areaIndex, sectionIndex) {
  return `${areaIndex}/${sectionIndex}`;
}

export function parseTarget(value) {
  const [area, section] = String(value).split("/").map(Number);
  return Number.isInteger(area) && Number.isInteger(section) ? { area, section } : null;
}

export function targetOptions(doc, key) {
  const taken = new Set(membership(doc, key).map((place) => targetValue(place.area, place.section)));
  const options = [];
  areas(doc).forEach((area, areaIndex) => {
    options.push({ value: targetValue(areaIndex, DIRECT), label: area.name });
    sectionsOf(area).forEach((section, sectionIndex) => options.push({ value: targetValue(areaIndex, sectionIndex), label: `${area.name} › ${section.name}` }));
  });
  return options.filter((option) => !taken.has(option.value));
}

export function itemCount(area) {
  return new Set([...itemsOf(area), ...sectionsOf(area).flatMap((section) => itemsOf(section))]).size;
}

export function blocks(area) {
  if (!area) return [];
  return [{ section: DIRECT, name: null, items: itemsOf(area) }, ...sectionsOf(area).map((section, index) => ({ section: index, name: section.name, items: itemsOf(section) }))];
}

export function groupRows(rows, area) {
  const byKey = new Map(rows.map((row) => [row.key, row]));
  return blocks(area)
    .filter((block) => block.section !== DIRECT || block.items.length > 0)
    .map((block) => ({ ...block, rows: block.items.map((key) => byKey.get(key)).filter(Boolean) }));
}

function checkName(name, path, errors) {
  if (typeof name !== "string" || !name.trim() || name.trim().length > NAME_LIMIT) errors.push({ code: "GROUP_NAME", path });
}

function checkKeys(value, keys, path, errors) {
  if (!value || typeof value !== "object" || Array.isArray(value) || Object.keys(value).some((key) => !keys.includes(key))) {
    errors.push({ code: "GROUPS", path });
    return false;
  }
  return true;
}

function checkItems(items, known, path, errors) {
  if (items === undefined || items === null) return;
  if (!Array.isArray(items) || items.length > ITEM_LIMIT) {
    errors.push({ code: "GROUPS", path });
    return;
  }
  const seen = new Set();
  items.forEach((item, index) => {
    if (typeof item !== "string" || !known.has(item)) errors.push({ code: "GROUP_ITEM", path: `${path}.${index}` });
    else if (seen.has(item)) errors.push({ code: "GROUP_DUPLICATE", path: `${path}.${index}` });
    seen.add(item);
  });
}

function checkUnique(list, path, errors) {
  const seen = new Set();
  list.forEach((entry, index) => {
    if (typeof entry?.name !== "string") return;
    const name = normalName(entry.name);
    if (name && seen.has(name)) errors.push({ code: "GROUP_DUPLICATE", path: `${path}.${index}.name` });
    seen.add(name);
  });
}

export function validateGroups(doc) {
  const errors = [];
  const groups = doc.groups;
  if (groups === undefined || groups === null) return errors;
  if (!Array.isArray(groups) || groups.length > AREA_LIMIT) return [{ code: "GROUPS", path: "groups" }];
  const known = knownItems(doc);
  groups.forEach((area, areaIndex) => {
    const path = `groups.${areaIndex}`;
    if (!checkKeys(area, AREA_KEYS, path, errors)) return;
    checkName(area.name, `${path}.name`, errors);
    checkItems(area.items, known, `${path}.items`, errors);
    if (area.sections === undefined || area.sections === null) return;
    if (!Array.isArray(area.sections) || area.sections.length > SECTION_LIMIT) {
      errors.push({ code: "GROUPS", path: `${path}.sections` });
      return;
    }
    area.sections.forEach((section, sectionIndex) => {
      const where = `${path}.sections.${sectionIndex}`;
      if (!checkKeys(section, SECTION_KEYS, where, errors)) return;
      checkName(section.name, `${where}.name`, errors);
      checkItems(section.items, known, `${where}.items`, errors);
    });
    checkUnique(area.sections, `${path}.sections`, errors);
  });
  checkUnique(groups, "groups", errors);
  return errors;
}
