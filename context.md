# Energy Wars – Kontext

## Aufbau eines Projektes

- **FEATURES.md**: Jedes Projekt bekommt eine eigene im Projektstamm.
  - Sie pflegt sich selbst. Projektspezifische Ausnahmen von globalen Regeln werden dort explizit vermerkt.
  - Sie enthält **alle Features der App** vollständig beschrieben.
  - Bei jeder Feature-Änderung (neu, geändert, entfernt) wird sie nach Abschluss aktualisiert.
  - Eine CLAUDE.md mit Feature-Beschreibungen wird geleert und die Beschreibungen hierher migriert.
  - Sie wird erst angepasst, wenn ein Feature fertig ist.
  - In der FEATURES.md nur nachschlagen, wenn unbedingt nötig.
- **.gitignore**: Mindestens eine im Projektstamm. Bei Subprojekten mit abweichendem Stack kommen zusätzliche im Unterverzeichnis dazu. Laufend befüllen.
- **context.md**: Falls vorhanden, zuerst lesen. Sie enthält Implementierungsstand, Dateistruktur und Architekturentscheidungen. Sie wird nach jeder Codeänderung sofort aktualisiert, nicht erst am Ende. Inhalt:
  - der gesamte Inhalt von „Aufbau eines Projektes“
  - der Implementierungsstatus aller Features
  - zu jedem Feature die zugehörigen Dateien
  - Bei Widersprüchen zwischen `CLAUDE.md` und `context.md` hat `CLAUDE.md` Vorrang.
  - Nach Abschluss jeder Funktionsänderung der App wird sie ausnahmslos gepflegt.
  - Sie beschreibt nur den aktuellen Stand, niemals eine History.
  - Nach jeder fertigen Umsetzung wird sie so weit wie möglich gekürzt.

## Technik

- **Engine:** Godot 4.7.2 stable (`~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`, im Folgenden `$G`).
  - Typisiertes GDScript, Mobile-Renderer.
  - Hochformat 720×1280, Stretch `canvas_items`/`expand`.
- **Android-Export:**
  - Preset „Android“ in `export_presets.cfg`, Paket `com.wafflehq.energywars`.
  - Keystore und SDK kommen aus den Editor-Einstellungen.
  - `$G --headless --export-debug "Android" build/energy-wars.apk`
- **Tests:** GUT 9.7.1 (`addons/gut`).
  - Bei neuen Klassen oder Übersetzungen zuerst `$G --headless --import` ausführen.
  - Dann `$G --headless -s addons/gut/gut_cmdln.gd`.
- **Screenshots:** `DISPLAY=:1 $G --rendering-driver opengl3 -s tests/tools/screenshot.gd -- --out=PFAD --locale=de --level=N [--rich] [--simulate=S] [--select=kind] [--build=kind] [--connect] [--result=win|lose] [--deploy] [--reveal] [--drop] [--zoom=Z]`
- **Belagerungstest:** `$G --headless -s tests/tools/siege_test.gd -- --level=N [--ring=5] [--towers=4]` – feste kompakte Basis mit idealer Energie auf offenem Gelände; vergleicht Mauerring, nur Türme und Türme für das Mauergeld. Aktueller Stand: Mauerring verzögert den ersten Turmverlust in Level 2–6 um das 2–3-Fache.
- **Balance-Bot:** `$G --headless -s tests/tools/balance_bot.gd -- [--level=N]… [--seed=N] [--money=N] [--verbose]`
  - Setzt den Kern am Drop-Punkt (Nebel aufgedeckt) und spielt heuristisch. `--walls` umgibt Türme und Kern mit einem Bollwerk-Ring (Abstand 2 Zellen), `--hold` verzichtet auf den Angriff, `--profile` gibt die Tick- und Denkzeit pro Minute aus.
  - Aktueller Stand ohne Mauern: Level 1 und 4 gewonnen, Level 2–3 je zur Hälfte, ab Level 5 meist verloren. Mit `--walls` überlebt der Bot Level 5–8 über 50 min ohne Kernschaden, beendet sie aber nicht (sein Angriff stockt).
- **i18n:** `i18n/translations.csv` (keys, en, de), Englisch ist Fallback. Zugriff nur über `Texts` (`src/ui/texts.gd`).
- **Assets:**
  - Grafik ist prozedural (`Painter`), Sounds werden synthetisiert (`SoundSynth`/`SoundBank`).
  - Fonts mit Lizenzdateien liegen in `assets/fonts`.

## Architektur

- **`src/core`:** reine Spiellogik (RefCounted, keine Nodes), fester Tick `GameConfig.TICK` = 1/30 s.
  - Die Logik meldet alles über `BattleEvents` (emit/drain).
  - Alle Balance-Werte stehen in `game_config.gd`, abgeleitete Werte in `formulas.gd`.
- **`src/ui`:** Darstellung und Eingabe.
  - `RewardDirector` übersetzt Events in Effekte, Sounds, Vibration, Banner und Münzflüge.
- **Phasen:** SCOUT (Soldat erkundet, keine Zeit, keine Spawns) → PREP (nach `Battle.deploy_core`) → FIGHT → WON/LOST.
- **Tick-Reihenfolge** (`Battle.tick`): Soldat (`ScoutControl`) → Nebel → [ab PREP] Gegnerfluss → Energiefluss → Kampf → KI → Aufräumen → Wirtschaft → Tag/Nacht-Events → Siegprüfung.
- **Raster:** `LevelMap` (Kacheln OPEN/RAMP/CLIFF/CHASM/TREE/ROCK + Höhe, Zelle `GameConfig.CELL`), erzeugt von `MapGenerator` (Spots, Plateaus mit Rampen, Schluchten mit Brücken, Wald, Felsen, `connect_all`). Gebäude rasten auf ihren Footprint (`LevelMap.snap`).
- **Navigation:** `NavGrid` mit zwei `AStarGrid2D` – `ground` (Terrain + alle Gebäude solide, Gegner) und `walker` (Terrain + feindliche Strukturen, Soldat). Zusammenhangskomponenten (4er-BFS, lazy pro `version`) bestimmen die Erreichbarkeit: Ein Gebäude ist erreichbar, wenn es an die Komponente des Gegners grenzt. Max. `PATHS_PER_TICK` Pfadberechnungen pro Tick.
- **Nebel:** `FogOfWar` (HIDDEN/EXPLORED/VISIBLE pro Zelle, Refresh alle `FOG_INTERVAL`). Die Sicht der Gebäude ist als Maske gecacht und wird nur bei `nav.version`-Wechsel oder `invalidate()` (Upgrade) neu berechnet. Darstellung: `FogTexture` (R8-Bild direkt aus `cells`, Alpha-Mapping im Shader `src/ui/fog.gdshader`, linear gefiltert).
- **Performance-Regeln:** Türme suchen Ziele nur, wenn sie schießen könnten; ohne Treffer pausiert die Suche `TARGET_SCAN` s. Laser behalten ihr Ziel und prüfen die Priorität alle `TARGET_SCAN` s neu. `Combat.group_enemies` bündelt Gegner pro Klasse einmal pro Tick. `EnemyAI` cacht die Ziel-Rangliste (`Targeting.rank`) höchstens `TARGET_SCAN` s bzw. bis zum nächsten `nav.version`-Wechsel, gefiltert pro Komponente. `Building` und `Enemy` cachen Team, Klasse und Radius.
- **`GameConfig.is_tower`** gilt für echte Türme. **`GameConfig.has_attack`** gilt für alles, was schießt, also auch den Kern. **`GameConfig.uses_energy_actively`** umfasst zusätzlich Heilturm und Schild (für Energiebalken). **`GameConfig.is_wall`** markiert Bollwerke (keine Energie, kein Bauradius, Kosten über `Formulas.build_cost`).
- **Gegnerfluss:** Spawnrate = Zyklusanzahl / Zykluslänge × Dichte(Phase). Die Dichte steigt kubisch von `SPAWN_CALM` zum Zyklusende und hat im Mittel den Wert 1 (`Formulas.spawn_density`). Jeder Spawner sammelt Bruchteile in `spawn_progress` und schickt Gegner in Rudeln (`Formulas.pack_size`, wächst mit dem Zyklus) aus einer gemeinsamen Richtung.
- **Pfade der Gegner:** Neu geplant wird nur bei Zielwechsel oder wenn der nächste Wegpunkt blockiert ist (nicht bei jeder Kartenänderung). Saboteure laufen zu einer „Schnittzelle“ (`EnemyAI.cut_cells`: freie Zellen direkt am Strahl, pro `nav.version` gecacht) und kappen den Strahl bei Ankunft.
- **Ziele der Gegner:** `Targeting.best` – höchste Stufe (`Targeting.tier`: Exporteur 6, Heiler 5, Verteidigung 4, Mauer 3, Netz 2, untätig ohne Energie 1, Kern 0), dann kleinster Randabstand. Bodengegner wählen nur aus `NavGrid.reachable`, Luftgegner aus allen Gebäuden. Feindliche Geschütztürme nutzen dieselbe Funktion.
- **Turmziele:** `Building.target_order`/`target_disabled` (Standard Luft → Fernkampf → Nahkampf), ausgewertet in `Combat.find_target`.
- **Bedienmodi:** `BattleView.Mode` (MOVE/CONNECT). Strahl-Sichtbarkeit über `BattleView.beam_visibility` (geglätteter Fluss).

## Features → Dateien (alle umgesetzt)

| Feature | Dateien |
|---|---|
| Konfiguration und Formeln | `src/core/game_config.gd`, `src/core/formulas.gd` |
| Karte, Gelände, Generator | `src/core/level_map.gd`, `src/core/map_generator.gd`, `src/ui/terrain_painter.gd` |
| Pfadsuche und Erreichbarkeit | `src/core/nav_grid.gd` |
| Nebel des Krieges | `src/core/fog_of_war.gd`, `src/ui/fog_texture.gd` |
| Soldat, Erkundung, Roden, Kern setzen | `src/core/scout.gd`, `src/core/scout_control.gd`, `src/core/battle.gd` |
| Zielprioritäten | `src/core/targeting.gd` |
| Kampfzustand und Orchestrierung | `src/core/battle_state.gd`, `src/core/battle.gd`, `src/core/battle_events.gd`, `src/core/building.gd`, `src/core/enemy.gd`, `src/core/projectile.gd`, `src/core/pickup.gd` |
| Bauregeln | `src/core/build_rules.gd` |
| Energienetz, Strahlen, Schneiden | `src/core/energy_network.gd`, `src/core/energy_link.gd` |
| Türme (inkl. Zielklassen pro Turm), Kern-Verteidigung, Schild, Heilturm, Geschütze | `src/core/combat.gd` |
| Gegner-KI (Pfade, Erreichbarkeit, Sabotage) | `src/core/enemy_ai.gd` |
| Gegnerfluss, Ansturm und Vorbereitung | `src/core/spawn_director.gd` |
| Tag/Nacht | `src/core/day_cycle.gd` |
| Geld, Münzen, Combo, Exporteur | `src/core/economy.gd` |
| Fortschritt und Sterne | `src/core/progress.gd` |
| Tutorial | `src/core/tutorial.gd` |
| Spielfeld, Bedienmodi, Gesten (Doppeltipp-Pan im Verbinden-Modus), Mauer-Malen, Soldatensteuerung, Kamera, Strahlen-Rendering | `src/ui/battle_view.gd`, `src/ui/gesture_tracker.gd`, `src/ui/camera_math.gd`, `src/ui/draw_layer.gd`, `src/ui/lightning.gd` |
| Prozedurale Grafik | `src/ui/painter.gd`, `src/ui/building_icon.gd`, `src/ui/menu_backdrop.gd` |
| HUD, Bauleiste, Gebäudepanel (inkl. Zielpriorität) | `src/ui/battle_hud.gd`, `src/ui/build_bar.gd`, `src/ui/building_panel.gd`, `src/ui/stat_text.gd` |
| Belohnungseffekte | `src/ui/reward_director.gd`, `src/ui/effect_pool.gd`, `src/ui/celebration_layer.gd`, `src/ui/juice.gd`, `src/ui/rolling_number.gd` |
| Sound und Vibration | `src/ui/sound_synth.gd`, `src/ui/sound_bank.gd`, `src/ui/sfx_player.gd` |
| Kampfbildschirm, Modus-Button, Ergebnis, Pause | `src/ui/battle_screen.gd`, `src/ui/result_overlay.gd`, `src/ui/pause_overlay.gd` |
| Menü, Levelauswahl, Einstellungen | `src/ui/main.gd`, `src/ui/level_select.gd`, `src/ui/app_settings.gd`, `scenes/main.tscn` |
| Theme, Icons, UI-Bausteine, Texte | `src/ui/app_theme.gd`, `src/ui/icons.gd`, `src/ui/ui_kit.gd`, `src/ui/texts.gd`, `i18n/translations.csv` |

## Tests

- `tests/unit/test_*.gd`: 291 Tests (Core-Logik, UI-Logik, Szenen-Flows). Alle grün.
- `tests/support/battle_fixtures.gd`: Test-Helfer – `battle()` (offenes Gelände, Nebel aufgedeckt, Kern am Drop), `deployed()` (echte Karte, Kern gesetzt), `open_terrain`, `wall`, `add`, `enemy`.
- `tests/tools/`: Screenshot-Tool und Balance-Bot, beide nicht Teil der Testsuite.
