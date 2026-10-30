import { h } from "../dom.js";
import { t } from "../i18n.js";
import { sectionHeading, isCollapsed } from "./components.js";
import { numberInput, textInput, selectInput, checkInput, removeButton, addButton } from "./levelFields.js";
import { STRUCTURE_KINDS, CHALLENGE_KINDS, TERRAIN_COUNTS } from "../levels.js";

const POSITION = { step: 0.01, min: 0 };

function section(ctx, key, title, ...content) {
  const closed = isCollapsed(ctx, key);
  return h("section", { class: "level-section" }, sectionHeading(ctx, key, title), closed ? null : content);
}

function pairFields(label, pair, apply, descX, descY) {
  return [
    numberInput(`${label} X`, pair[0], (value) => apply([value, pair[1]]), descX, POSITION),
    numberInput(`${label} Y`, pair[1], (value) => apply([pair[0], value]), descY, POSITION),
  ];
}

function structureRows(level, edit) {
  const choices = STRUCTURE_KINDS.map((kind) => ({ value: kind, label: t(`levels.structure.${kind}`) }));
  return level.structures.map((entry, index) => h("div", { class: "row-edit" },
    selectInput(t("levels.f.structureKind"), entry[0], choices, (value) => edit((l) => { l.structures[index][0] = value; }), t("levels.d.structureKind")),
    ...pairFields(t("levels.f.position"), entry[1], (pair) => edit((l) => { l.structures[index][1] = pair; }), t("levels.d.positionX"), t("levels.d.positionY")),
    removeButton(() => edit((l) => { l.structures.splice(index, 1); }), t("action.remove"))));
}

function spotRows(level, edit) {
  return level.terrain.spots.map((spot, index) => h("div", { class: "row-edit spot" },
    ...pairFields(t("levels.f.spot"), spot[0], (pair) => edit((l) => { l.terrain.spots[index][0] = pair; }), t("levels.d.spotX"), t("levels.d.spotY")),
    numberInput(t("levels.f.spotSize"), spot[1], (value) => edit((l) => { l.terrain.spots[index][1] = value; }), t("levels.d.spotSize"), { integer: true, min: 1 }),
    h("div", { class: "ramps" },
      h("strong", {}, t("levels.f.ramps")),
      spot[2].map((offset, ramp) => h("div", { class: "row-edit" },
        numberInput("dx", offset[0], (value) => edit((l) => { l.terrain.spots[index][2][ramp][0] = value; }), t("levels.d.rampX"), { integer: true }),
        numberInput("dy", offset[1], (value) => edit((l) => { l.terrain.spots[index][2][ramp][1] = value; }), t("levels.d.rampY"), { integer: true }),
        removeButton(() => edit((l) => { l.terrain.spots[index][2].splice(ramp, 1); }), t("action.remove")))),
      addButton(t("levels.addRamp"), () => edit((l) => { l.terrain.spots[index][2].push([1, 0]); })),
      h("small", { class: "field-desc" }, t("levels.d.ramps"))),
    removeButton(() => edit((l) => { l.terrain.spots.splice(index, 1); }), t("action.remove"))));
}

function challengeRows(level, edit) {
  const choices = CHALLENGE_KINDS.map((kind) => ({ value: kind, label: t(`levels.challenge.${kind}`) }));
  return level.challenges.map((entry, index) => h("div", { class: "row-edit" },
    selectInput(t("levels.f.challengeKind"), entry[0], choices, (value) => edit((l) => { l.challenges[index][0] = value; }), t(`levels.challengeDesc.${entry[0]}`)),
    numberInput(t("levels.f.challengeValue"), entry[1], (value) => edit((l) => { l.challenges[index][1] = value; }), t("levels.d.challengeValue"), { integer: true, min: 0 }),
    removeButton(() => edit((l) => { l.challenges.splice(index, 1); }), t("action.remove"))));
}

export function levelForm(ctx, level, edit) {
  const world = Array.isArray(level.world) ? level.world : null;
  return h("div", { class: "level-form" },
    section(ctx, "levels.basics", t("levels.basics"),
      h("div", { class: "grid" },
        textInput(t("levels.f.id"), level.id, (value) => edit((l) => { l.id = value; }), t("levels.d.id")),
        numberInput(t("levels.f.cellsW"), level.cells[0], (value) => edit((l) => { l.cells[0] = value; }), t("levels.d.cellsW"), { integer: true, min: 20 }),
        numberInput(t("levels.f.cellsH"), level.cells[1], (value) => edit((l) => { l.cells[1] = value; }), t("levels.d.cellsH"), { integer: true, min: 20 }),
        numberInput(t("levels.f.money"), level.money, (value) => edit((l) => { l.money = value; }), t("levels.d.money"), { integer: true, min: 0 }),
        numberInput(t("levels.f.day"), level.day, (value) => edit((l) => { l.day = value; }), t("levels.d.day"), { min: 1 }),
        numberInput(t("levels.f.night"), level.night, (value) => edit((l) => { l.night = value; }), t("levels.d.night"), { min: 1 }),
        numberInput(t("levels.f.seed"), level.seed, (value) => edit((l) => { l.seed = value; }), t("levels.d.seed"), { integer: true }),
        ...pairFields(t("levels.f.drop"), level.drop, (pair) => edit((l) => { l.drop = pair; }), t("levels.d.dropX"), t("levels.d.dropY")))),
    section(ctx, "levels.world", t("levels.world"),
      h("div", { class: "grid" },
        checkInput(t("levels.f.worldAuto"), world === null, (auto) => edit((l) => { l.world = auto ? null : [0.5, 0.5]; }), t("levels.d.worldAuto")),
        world ? pairFields(t("levels.f.world"), world, (pair) => edit((l) => { l.world = pair; }), t("levels.d.worldX"), t("levels.d.worldY")) : null)),
    section(ctx, "levels.structures", t("levels.structures"),
      h("p", { class: "note" }, t("levels.d.structures")),
      structureRows(level, edit),
      addButton(t("levels.addStructure"), () => edit((l) => { l.structures.push(["nest", [0.5, 0.1]]); }))),
    section(ctx, "levels.terrain", t("levels.terrain"),
      h("div", { class: "grid" }, TERRAIN_COUNTS.map((key) => numberInput(t(`levels.terrain.${key}`), level.terrain[key], (value) => edit((l) => { l.terrain[key] = value; }), t(`levels.terrainDesc.${key}`), { integer: true, min: 0 }))),
      h("h4", {}, t("levels.spots")),
      h("p", { class: "note" }, t("levels.d.spots")),
      spotRows(level, edit),
      addButton(t("levels.addSpot"), () => edit((l) => { l.terrain.spots.push([[0.5, 0.5], 6, []]); }))),
    section(ctx, "levels.challenges", t("levels.challenges"),
      h("p", { class: "note" }, t("levels.d.challenges")),
      challengeRows(level, edit),
      addButton(t("levels.addChallenge"), () => edit((l) => { l.challenges.push(["survive", 5]); }))));
}
