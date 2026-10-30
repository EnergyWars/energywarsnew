import { FACTIONS } from "./monsters.js";
import { MAX_EXTRA_COUNT } from "./levels.js";

export const WAVE_RULES = {
  hpGrowth: 1.22,
  damageGrowth: 0.08,
  bountyGrowth: 0.12,
  first: 3.0,
  groundBonus: 1.35,
  maxQueue: 30,
};

export function dayLength(level) {
  return Number(level.day) + Number(level.night);
}

export function isNight(time, level) {
  return time >= Number(level.day) && time < dayLength(level);
}

export function waveTimes(level) {
  const span = dayLength(level) - WAVE_RULES.first;
  return span > 0 ? Math.ceil(span / Number(level.waves.interval)) : 0;
}

export function waveTime(level, index) {
  return WAVE_RULES.first + Number(level.waves.interval) * index;
}

export function waveTier(round) {
  return Math.max(round - 1, 0);
}

export function waveCount(waves, round, progress, night) {
  const clamped = Math.min(Math.max(progress, 0), 1);
  const count = Number(waves.base) * (1 + Number(waves.ramp) * clamped) * (1 + Number(waves.growth) * Math.max(round - 1, 0));
  return night ? count * Number(waves.night) : count;
}

export function hpScale(round) {
  return Math.pow(WAVE_RULES.hpGrowth, Math.max(round - 1, 0));
}

export function damageScale(round) {
  return 1 + WAVE_RULES.damageGrowth * Math.max(round - 1, 0);
}

export function bountyScale(round) {
  return 1 + WAVE_RULES.bountyGrowth * Math.max(round - 1, 0);
}

export function eligibleRoster(roster, round) {
  const tier = waveTier(round);
  return roster.filter((entry) => tier >= entry[1]);
}

export function rosterAverage(roster, round, enemies, stat) {
  const options = eligibleRoster(roster, round).filter((entry) => enemies[entry[0]]);
  const weight = options.reduce((sum, entry) => sum + Number(entry[2]), 0);
  if (weight <= 0) return 0;
  return options.reduce((sum, entry) => sum + Number(enemies[entry[0]][stat]) * Number(entry[2]), 0) / weight;
}

export function roundWaves(level, round) {
  const length = dayLength(level);
  const times = waveTimes(level);
  const result = [];
  let carry = 0;
  for (let index = 0; index < times; index += 1) {
    const time = waveTime(level, index);
    const night = isNight(time, level);
    const count = waveCount(level.waves, round, time / length, night) * WAVE_RULES.groundBonus;
    carry += count;
    const whole = Math.max(Math.floor(carry), 1);
    carry -= whole;
    result.push({ index, time, night, count, units: Math.min(whole, WAVE_RULES.maxQueue) });
  }
  return result;
}

export function roundSummary(level, round, enemies) {
  const waves = roundWaves(level, round);
  let units = 0;
  let hp = 0;
  let bounty = 0;
  for (const wave of waves) {
    const roster = wave.night ? level.waves.night_roster : level.waves.roster;
    units += wave.units;
    hp += wave.units * rosterAverage(roster, round, enemies, "hp");
    bounty += wave.units * rosterAverage(roster, round, enemies, "bounty");
    for (const entry of extraWavesAt(level, round, wave.index)) {
      if (!enemies[entry.kind]) continue;
      const share = extraShare(level, enemies, entry);
      units += share;
      hp += share * Number(enemies[entry.kind].hp);
      bounty += share * Number(enemies[entry.kind].bounty);
    }
  }
  const hpFactor = hpScale(round);
  const bountyFactor = bountyScale(round);
  return {
    round,
    waves: waves.length,
    first: waves.length ? waves[0].units : 0,
    last: waves.length ? waves[waves.length - 1].units : 0,
    units,
    hpScale: hpFactor,
    damageScale: damageScale(round),
    bountyScale: bountyFactor,
    totalHp: hp * hpFactor,
    totalBounty: bounty * bountyFactor,
  };
}

export function strengthRows(level, enemies, rounds) {
  const rows = [];
  for (let round = 1; round <= rounds; round += 1) rows.push(roundSummary(level, round, enemies));
  return rows;
}

export const SPAWNER_KINDS = FACTIONS;
export { MAX_EXTRA_COUNT };

export function extraEntries(level) {
  return Array.isArray(level.extra_waves) ? level.extra_waves : [];
}

export function extraWavesAt(level, round, index) {
  const night = isNight(waveTime(level, index), level);
  const opens = index === 0 || isNight(waveTime(level, index - 1), level) !== night;
  if (!opens) return [];
  return extraEntries(level).filter((entry) => entry.day === round && entry.night === night);
}

export function spawnerCounts(level) {
  const counts = Object.fromEntries(SPAWNER_KINDS.map((kind) => [kind, 0]));
  for (const structure of level.structures ?? []) if (structure[0] in counts) counts[structure[0]] += 1;
  return counts;
}

export function extraShare(level, enemies, entry) {
  const counts = spawnerCounts(level);
  const matching = counts[enemies[entry.kind]?.faction] ?? 0;
  const spawners = matching > 0 ? matching : SPAWNER_KINDS.reduce((sum, kind) => sum + counts[kind], 0);
  return spawners > 0 ? Number(entry.count) / spawners : 0;
}

export function fallbackKind(enemies, faction, night) {
  const members = Object.entries(enemies).filter(([, enemy]) => enemy.faction === faction);
  const match = members.find(([, enemy]) => Boolean(enemy.nocturnal) === night);
  return (match ?? members[0])?.[0] ?? null;
}

export function waveMix(roster, enemies, round, faction, night) {
  const options = eligibleRoster(roster, round).filter((entry) => enemies[entry[0]]?.faction === faction);
  const total = options.reduce((sum, entry) => sum + Number(entry[2]), 0);
  if (total <= 0) {
    const kind = fallbackKind(enemies, faction, night);
    return kind ? [{ kind, share: 1, fallback: true }] : [];
  }
  return options.map((entry) => ({ kind: entry[0], share: Number(entry[2]) / total, fallback: false }));
}

export function waveComposition(level, enemies, round) {
  const counts = spawnerCounts(level);
  return roundWaves(level, round).map((wave) => {
    const roster = wave.night ? level.waves.night_roster : level.waves.roster;
    const groups = SPAWNER_KINDS.filter((faction) => counts[faction] > 0).map((faction) => ({
      faction,
      spawners: counts[faction],
      items: waveMix(roster, enemies, round, faction, wave.night).map((item) => ({ ...item, expected: item.share * wave.units })),
    }));
    return { ...wave, groups, extras: extraWavesAt(level, round, wave.index) };
  });
}

export function dayComposition(level, enemies, round) {
  const total = {};
  for (const wave of waveComposition(level, enemies, round)) {
    for (const group of wave.groups) {
      for (const item of group.items) {
        const key = `${group.faction}:${item.kind}`;
        total[key] ??= { faction: group.faction, kind: item.kind, spawners: group.spawners, expected: 0, extra: 0 };
        total[key].expected += item.expected;
      }
    }
    for (const entry of wave.extras) {
      const key = `extra:${entry.kind}`;
      total[key] ??= { faction: "extra", kind: entry.kind, spawners: 1, expected: 0, extra: 0 };
      total[key].extra += entry.count;
    }
  }
  return Object.values(total);
}

export function addExtra(level, entry) {
  level.extra_waves = [...extraEntries(level), { day: 1, night: false, kind: "wasp", count: 1, ...entry }];
}

export function removeExtra(level, index) {
  level.extra_waves = extraEntries(level).filter((_, position) => position !== index);
  if (level.extra_waves.length === 0) delete level.extra_waves;
}
