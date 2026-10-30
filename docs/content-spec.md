# Inhalts-Vertrag: Monster, Wellen, Level, Panzerung

Gemeinsame Schnittstelle zwischen Spielkern (GDScript), Upgrade-Editor-Backend (Python/Godot-Export) und Editor-Oberfläche (JS). Alle Beteiligten halten sich an diese Namen.

## Laufzeit-Overrides: `data/content_overrides.json`

Wird vom Editor beim „Anwenden“ geschrieben (wie `data/upgrade_overrides.json`) und vom Spiel beim Start gelesen (`ContentOverrides`, Core). Fehlt ein Schlüssel oder die Datei, gelten die Standardwerte aus `GameConfig`.

```json
{
  "armor": {"constant": 100.0, "max_reduction": 0.9, "min_damage": 1.0},
  "enemies": {"<kind>": { ...vollständiges Gegner-Dictionary, siehe unten... }},
  "buildings": {"<kind>": {"armor": 20.0}},
  "levels": [ { ...vollständiges Level, siehe unten... } ],
  "routes": [[0, 1], [0, 2]]
}
```

- `enemies`: pro Kind ein **vollständiger Ersatz** des Gegner-Dictionaries. Neue Kinds sind erlaubt (Editor darf Monster nur ändern, nicht neu anlegen; neue Standard-Kinds liefert `GameConfig`).
- `buildings`: nur `armor` (Grund-Panzerung) je Gebäude-Kind; der Upgrade-Pfad `armor` der Türme multipliziert diesen Grundwert (`Formulas.armor` = Grundwert × Pfad-Multiplikator). Weitere Basiswerte bleiben Sache von `game_config.gd` (Patcher).
- `levels`: **komplette Liste** (ersetzt `GameConfig.LEVELS`). Vector2/Vector2i werden als Arrays `[x, y]` gespeichert.
- `routes`: Wegekanten der Weltkarte (`WORLD_ROUTES`); `null`/fehlend → automatisch (jedes Level `i>0` verbindet sich mit `i-1`, bei Standardlevels gilt `WORLD_ROUTES`).

## Gegner-Dictionary (`GameConfig.ENEMIES[kind]`)

```
class: "air" | "ranged" | "melee"
hp, speed, damage, cooldown, reach, radius: float
bounty: int
armor: float            (Panzerung, >= 0)
boss: bool              (optional)
nocturnal: bool         (optional, brennt bei Tagesanbruch)
sabotage: bool          (optional)
faction: "nest" | "camp"   (welcher Spawner ihn ausspielt)
look: String            (Optik-Schlüssel für Painter/JS-Port, Standard = kind)
buffs: {
  "night": {"hp": 0.0, "damage": 0.0, "speed": 0.0, "armor": 0.0},   // relative Zuschläge, wenn nachts gespawnt (0.2 = +20 %)
  "level": {"hp": 0.0, "damage": 0.0, "speed": 0.0, "armor": 0.0}    // relative Zuschläge pro Level-Index (Level 0 = kein Zuschlag)
}
```

`buffs` ist optional (fehlt = 0). Anwendung (Core, `Formulas`): `value = base × (1 + night_buff × is_night) × (1 + level_buff × level_index)`; Panzerung analog additiv auf den Basiswert multipliziert.

Texte (i18n, `i18n/translations.csv`): `ENEMY_<KIND_UPPER>` (Name) und `ENEMY_<KIND_UPPER>_DESC` (Kurzbeschreibung: was ist besonders). Für Gebäude: `BUILDING_<KIND_UPPER>_DESC` (was macht den Turm besonders/wichtig); bestehendes `_INFO` bleibt die Einzeiler-Zeile.

## Monster-Katalog (Ziel)

| Klasse | Anzahl (ohne Boss) | Boss |
|---|---|---|
| Luft (`air`) | 5 | |
| Nahkampf (`melee`) | 10 | |
| Fernkampf (`ranged`) | 5 | |
| Boss (`boss: true`) | | 10 – beliebig `air`/`melee`/`ranged` |

Bestehend: Luft wasp/nightwing/drone/phantom, Nahkampf crawler/beetle/stalker/saboteur, Fernkampf spitter/soldier/raider, Boss behemoth (melee)/tank (ranged). Fehlende werden ergänzt.

## Level-Dictionary (`GameConfig.LEVELS[i]`, in JSON mit Arrays statt Vector)

```
id: String, cells: [w, h], money: int, day: float, night: float, seed: int,
drop: [x, y],
structures: [[kind, [x, y]], ...],           // kind: nest | camp | turret
terrain: {plateaus, chasms, ponds, groves, forests, rocks: int, spots: [[[x,y], size, [[dx,dy],...]], ...]},
waves: {interval, base, ramp, night, growth: float, roster: [[kind, tier, weight]], night_roster: [[kind, tier, weight]]},
world: [x, y] | null,                         // null → automatische Platzierung
challenges: [[kind, value], ...]
```

`day`/`night` = Tag-/Nachtdauer in Sekunden. Neue Level dürfen `world: null` haben; die Weltkarte platziert sie automatisch und verlängert sich dynamisch.

## `data/game.json` (Editor-Datenstand) — neue Schlüssel

```
armor:      {constant, max_reduction, min_damage}
enemies:    {kind: Gegner-Dictionary inkl. faction/look/buffs}
levels:     [Level-Dictionary]
routes:     [[a, b], ...]                      (effektive Kanten)
buildings[*].armor, buildings[*].description_key
names:      wie bisher aus translations.csv, zusätzlich *_DESC-Schlüssel
groups:     [{name, items: ["gebäude:pfad"], sections: [{name, items}]}]   (optional, nur Editor, nie im Spiel)
```
