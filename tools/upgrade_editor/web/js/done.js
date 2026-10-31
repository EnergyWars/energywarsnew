export const DONE_LIMIT = 1000;

export const doneKey = (entry, track) => `${entry.id}:${track}`;

export function isDone(doc, entry, track) {
  return Array.isArray(doc.done) && doc.done.includes(doneKey(entry, track));
}

export function setDone(doc, entry, track, done) {
  const key = doneKey(entry, track);
  const rest = (Array.isArray(doc.done) ? doc.done : []).filter((item) => item !== key);
  doc.done = done ? [...rest, key] : rest;
}

export function pruneDone(doc, id, track) {
  if (Array.isArray(doc.done)) doc.done = doc.done.filter((item) => item !== `${id}:${track}`);
}
