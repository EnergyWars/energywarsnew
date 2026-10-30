export function monsterUi(view) {
  view.monsterUi ??= {
    section: "monsters",
    kind: null,
    query: "",
    klass: "all",
    faction: "all",
    flavor: "all",
    mode: "absolute",
    notice: "",
    drafts: {},
    hidden: new Set(),
    waveHidden: new Set(),
    armorHidden: new Set(),
    armorQuery: "",
    example: { armor: 50, damage: 20 },
    level: 0,
    rounds: 10,
    day: 1,
  };
  return view.monsterUi;
}

export function levelCount(doc) {
  return Math.max(doc.levels?.length ?? 1, 1);
}
