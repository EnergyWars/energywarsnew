import { readFileSync } from "node:fs";

export const game = JSON.parse(readFileSync(new URL("../../data/game.json", import.meta.url), "utf8"));

export function fresh() {
  return JSON.parse(JSON.stringify(game));
}

export function find(doc, id) {
  return doc.buildings.find((entry) => entry.id === id);
}
