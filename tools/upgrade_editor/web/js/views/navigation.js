import { monsterUi } from "./monsterState.js";

export function openTrack(view, building, track) {
  view.tab = "buildings";
  view.building = building;
  view.collapsed.delete(`upgrades:${building}`);
  if (track) view.open.add(`${building}:${track}`);
  return view;
}

export function openMonster(view, kind) {
  const ui = monsterUi(view);
  view.tab = "monsters";
  ui.section = "monsters";
  ui.kind = kind;
  ui.query = "";
  ui.klass = "all";
  ui.faction = "all";
  ui.flavor = "all";
  return view;
}

export function openLevel(view, index) {
  view.tab = "levels";
  view.levelUi ??= { index: 0, rounds: 10 };
  view.levelUi.index = index;
  view.collapsed.delete("levels.waves");
  return view;
}

export function openWaves(view, level, day) {
  const ui = monsterUi(view);
  view.tab = "monsters";
  ui.section = "waves";
  ui.level = level;
  if (Number.isInteger(day) && day >= 1) {
    ui.day = day;
    ui.rounds = Math.max(ui.rounds, day);
  }
  return view;
}
