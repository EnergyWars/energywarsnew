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
- **Screenshots:** `DISPLAY=:1 $G --rendering-driver opengl3 -s tests/tools/screenshot.gd -- --out=PFAD --locale=de --level=N [--rich] [--simulate=S] [--select=kind] [--build=kind] [--connect] [--result=win|lose] [--deploy] [--reveal] [--drop] [--zoom=Z] [--pick=link|focus]`
- **Belagerungstest:** `$G --headless -s tests/tools/siege_test.gd -- --level=N [--ring=5] [--towers=4]` – feste kompakte Basis mit idealer Energie auf offenem Gelände; vergleicht Mauerring, nur Türme und Türme für das Mauergeld. Aktueller Stand: Mauerring verzögert den ersten Turmverlust in Level 2–6 um das 2–3-Fache.
- **Balance-Bot:** `$G --headless -s tests/tools/balance_bot.gd -- [--level=N]… [--seed=N] [--money=N] [--verbose]`
  - Setzt den Kern am Drop-Punkt (Nebel aufgedeckt) und spielt heuristisch. `--walls` umgibt Türme und Kern mit einem Bollwerk-Ring (Abstand 2 Zellen), `--hold` verzichtet auf den Angriff, `--profile` gibt die Tick- und Denkzeit pro Minute aus.
  - Startet jede Planungsphase sofort mit `Battle.start_round`. Ausgabe u. a. `rounds=` (erreichter Tag).
  - Aktueller Stand: Level 1–3 und 7 gewonnen (5 Tage), Level 4–5 nach 8–9 Tagen verloren, Level 6 und 8 nach 50 min offen. In Level 6 kappen Saboteure dauerhaft die Front-Strahlen des Bots.
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
- **Phasen:** SCOUT (Soldat erkundet per Joystick) → PLAN (nach `Battle.deploy_core`, Soldat sitzt im Kern: `Scout.boarded`) ⇄ FIGHT → WON/LOST.
  - PLAN: Zeit steht, nur Münzflug/Combo-Ablauf (`Economy.update_pickups`) und Siegprüfung laufen. `Battle.start_round` (`SpawnDirector.start_round`) → FIGHT, setzt `round_time`/`waves_sent`/`night_over` und alle `Building.plan_spent` zurück.
  - FIGHT: `round_time` läuft. Bei `DayCycle.is_finished` → `SpawnDirector.end_night` (`night_over`). Sind danach alle Gegner tot, folgt `_check_round`: zurück in PLAN, `round_number += 1`, Event `round_cleared`.
  - `BattleState.is_night()`/`light()` gelten nur in FIGHT (sonst Tageslicht).
- **Tick-Reihenfolge in FIGHT** (`Battle.tick`): Soldat → Nebel → Zeit → Wellen → mobile Gebäude → Energiefluss → Kampf → KI → Aufräumen → Wirtschaft → Tag/Nacht-Events → Siegprüfung → Rundenende.
- **Planungs-Historie:** `Battle.history` (`PlanHistory`) startet bei `deploy_core`, `_check_round` und in `Battle._init`, wenn der Zustand schon PLAN ist; `start_round` beendet sie (`baseline_stats` bleibt für die Energiebilanz). Jede erfolgreiche Spieleraktion in PLAN legt vorher einen `PlanSnapshot` ab (`_checkpoint`/`_commit`): Spielergebäude-Objekte samt Feldern, Links als Paare, Geld/`earned`. `restore` entfernt alle Spielergebäude, setzt die gespeicherten wieder ein (`BattleState.reinstate`, `replace_links`) und rechnet zwischenzeitliche Einnahmen dazu. Gesten (`BattleView.begin`/`finish`/`tap` → `begin_stroke`/`end_stroke`) fassen Mauer-Malen (`STEP_PAINT`) und Kappen (`STEP_CUT`) zu einem Schritt zusammen. Max. `MAX_STEPS` Schritte. Event `plan_restored`.
- **Energiebilanz:** `EnergyStats.measure` (Metriken per Enum, `fire_draw`/`self_reserve`/`shots_per_charge`/`drain_time`), Formatierung und Deltas in `EnergyStatsText`, Anzeige in `EnergyStatsPanel` (HUD, Deltas gegen `history.baseline_stats`, Puls bei `BattleScreen.PULSE_EVENTS`).
- **Planungs-Erstattung:** `Building.plan_spent` sammelt Bau- und Upgradekosten der laufenden Planungsphase. `Formulas.sell_value` = `plan_spent` + (Rest × `SELL_REFUND` × HP-Anteil). `Formulas.relocate_cost(b, planning)` ist in PLAN 0.
- **Sperrzone:** `BuildRules.enemy_clearance` = `ENEMY_PLAN_CLEAR` in PLAN, sonst `ENEMY_NO_BUILD`. Grund `ENEMY_ZONE` (nur PLAN) bzw. `ENEMY_NEAR`.
- **Direktsteuerung:** Soldat und mobiler Turm bewegen sich per Lenkvektor (`steer`) mit Kreis-Kollision gegen Zellen (`Steering.slide`, gleitet an Wänden). Eingabe: nativer `VirtualJoystick` (Godot 4.7) bzw. Tasten über die Aktionen `steer_left/right/up/down` (`project.godot`), gelesen in `BattleScreen.steering_input`. Mobile Gebäude wechseln ihre Nav-Zelle über `BattleState.drive`.
- **Strahlen außer Reichweite:** `EnergyNetwork._push` prüft pro Tick `in_range`; inaktive Links (`EnergyLink.active`) bleiben bestehen. Beim Versetzen (`Battle.relocate`) werden zu lange Links gekappt (`drop_out_of_range`).
- **Solar-Transfer:** `rate_from_output` – `Formulas.rate` = Leistung, `Formulas.beam_rate` teilt sie auf die verbundenen Strahlen.
- **Fokus:** `Building.focus` (Enemy, feindliches Building oder `Obstacle`), ausgewertet zuerst in `Combat.find_target`/`_laser_target`, sofern in Reichweite. Hindernisse sind lazy angelegte `Obstacle`-Objekte (`BattleState.obstacle_at`, HP aus `GameConfig.OBSTACLE_HP`), Entfernen über `BattleState.clear_obstacle`.
- **Abdeckung:** `Coverage` liefert pro Zelle 0–4 (keine/1/2/3+/nur volle Sender), `CoverageTexture` malt das als RGBA-Bild (eigener DrawLayer, Nearest-Filter), Refresh alle `COVERAGE_REFRESH` s nur solange aktiv.
- **Raster:** `LevelMap` (Kacheln OPEN/RAMP/CLIFF/CHASM/TREE/ROCK + Höhe, Zelle `GameConfig.CELL`), erzeugt von `MapGenerator` (Spots, Plateaus mit Rampen, Schluchten mit Brücken, Wald, Felsen, `connect_all`). Gebäude rasten auf ihren Footprint (`LevelMap.snap`).
- **Navigation:** `NavGrid` mit zwei `AStarGrid2D` – `ground` (Terrain + alle Gebäude solide, Gegner) und `walker` (Terrain + feindliche Strukturen; dient als Kollisionsraster des Soldaten). Zusammenhangskomponenten (4er-BFS, lazy pro `version`) bestimmen die Erreichbarkeit: Ein Gebäude ist erreichbar, wenn es an die Komponente des Gegners grenzt. Max. `PATHS_PER_TICK` Pfadberechnungen pro Tick.
- **Nebel:** `FogOfWar` (HIDDEN/EXPLORED/VISIBLE pro Zelle, Refresh alle `FOG_INTERVAL`), inkrementell: Jede Sichtquelle (Gebäude-ID bzw. `SCOUT_MARK`) ist eine Marke mit Zentrum und Radius, `_seen` zählt Referenzen pro Zelle. Gebäudemarken werden nur bei `nav.version`-Wechsel abgeglichen, `version` steigt nur bei Änderungen. Externe Zelländerungen brauchen `invalidate()`. Darstellung: `FogTexture` (R8-Bild direkt aus `cells`, Alpha-Mapping im Shader `src/ui/fog.gdshader`, linear gefiltert).
- **Performance-Regeln:**
  - Türme suchen Ziele nur, wenn sie schießen könnten; ohne Treffer pausiert die Suche `TARGET_SCAN` s. Laser behalten ihr Ziel und prüfen die Priorität alle `TARGET_SCAN` s neu. `Combat.group_enemies` bündelt Gegner pro Klasse einmal pro Tick.
  - `BattleState` cacht Ranglisten (`player_buildings`, `enemy_buildings`, `of_kind`, `combatants`, `producers`, `stores`) bis `roster_version` sich ändert, Links über `add_link`/`remove_link_at` mit `links_version` und `outgoing_count`. `EnergyNetwork.groups` gruppiert Links pro Quelle bis zum nächsten `links_version`.
  - `Building` cacht Definition, Flags (`armed`, `healing`, `shielding`, `exporting`, `mobile`, `spawner`), Geometrie und alle abgeleiteten Werte (`Formulas.compute_stats` → `Building.stat`). Invalidiert wird über die Setter von `levels`/`elevation` bzw. `set_level`. `Enemy` cacht Klasse, Radius, Tempo, Reichweite und Flags; `NavGrid` hält ein Byte-Raster `_blocked` für `is_free`.
  - `EnemyAI` cacht die Ziel-Rangliste (`Targeting.rank`, nach Stufe vorsortiert, damit `best_ranked` früh abbricht) höchstens `TARGET_SCAN` s bzw. bis zum nächsten `nav.version`-Wechsel, gefiltert pro Komponente.
  - `BattleView` zeichnet nur, was im sichtbaren Weltausschnitt (`visible_world_rect` + `CULL_MARGIN`) liegt. Mauern liegen auf einer eigenen Ebene, die nur bei `roster_version`-Wechsel neu gezeichnet wird. `EffectPool` begrenzt Partikel auf `MAX_PARTICLES`.
  - Referenzmessung (88 Gebäude, 30 Gegner): ca. 1,1 ms pro Tick.
- **`GameConfig.is_tower`** gilt für echte Türme. **`GameConfig.has_attack`** gilt für alles, was schießt, also auch den Kern. **`GameConfig.uses_energy_actively`** umfasst zusätzlich Heilturm und Schild (für Energiebalken). **`GameConfig.is_wall`** markiert Bollwerke (keine Energie, kein Bauradius, Kosten über `Formulas.build_cost`).
- **Wellen:** `level.waves` (`interval`, `base`, `ramp`, `night`, `growth`, `roster`). Welle i startet bei `WAVE_FIRST + i × interval`, solange `round_time` < Tag + Nacht (`Formulas.wave_times`/`wave_time`). Größe pro Spawner = `Formulas.wave_count` (mind. 1, Bruchteile in `spawn_progress`), landet in `Building.spawn_queue` (max. `WAVE_MAX`) und wird alle `WAVE_TRICKLE` s aus `spawn_heading` freigegeben. Gegnerstärke über `Formulas.enemy_hp_scale`/`enemy_damage_scale`/`enemy_bounty_scale`, Gegnertypen über `Formulas.wave_tier`.
- **Upgrades:** `GameConfig.TRACKS` (max, step, price, optional growth) und `tracks` pro Gebäude. `Formulas.multiplier`, `efficiency`, `crit_chance`, `chain_count`, `splash`, `upgrade_cost`, `max_level`.
- **Pfade der Gegner:** Neu geplant wird nur bei Zielwechsel oder wenn der nächste Wegpunkt blockiert ist (nicht bei jeder Kartenänderung). Saboteure laufen zu einer „Schnittzelle“ (`EnemyAI.cut_cells`: freie Zellen direkt am Strahl, pro `nav.version` gecacht) und kappen den Strahl bei Ankunft.
- **Ziele der Gegner:** `Targeting.best` – höchste Stufe (`Targeting.tier`: Exporteur 6, Heiler 5, Verteidigung 4, Mauer 3, Netz 2, untätig ohne Energie 1, Kern 0), dann kleinster Randabstand. Bodengegner wählen nur aus `NavGrid.reachable`, Luftgegner aus allen Gebäuden. Feindliche Geschütztürme nutzen dieselbe Funktion.
- **Turmziele:** `Building.target_order`/`target_disabled` (Standard Luft → Fernkampf → Nahkampf), ausgewertet in `Combat.find_target`.
- **Bedienmodi:** `BattleView.Mode` (MOVE/CONNECT), dazu Zielauswahl `BattleView.Pick` (LINK/FOCUS, Geste `PICK`) und Versetzen (`relocate_id` + Baumodus). Strahl-Sichtbarkeit über `BattleView.beam_visibility` (geglätteter Fluss).

## Features → Dateien (alle umgesetzt)

| Feature | Dateien |
|---|---|
| Konfiguration und Formeln | `src/core/game_config.gd`, `src/core/formulas.gd` |
| Karte, Gelände, Generator | `src/core/level_map.gd`, `src/core/map_generator.gd`, `src/ui/terrain_painter.gd` |
| Pfadsuche und Erreichbarkeit | `src/core/nav_grid.gd` |
| Nebel des Krieges | `src/core/fog_of_war.gd`, `src/ui/fog_texture.gd` |
| Soldat (Joystick, Roden, Kern setzen, Gewehr im Kern) | `src/core/scout.gd`, `src/core/scout_control.gd`, `src/core/steering.gd`, `src/core/battle.gd`, `src/core/combat.gd` |
| Mobiler Turm | `src/core/mobile_control.gd`, `src/core/steering.gd`, `src/core/battle_state.gd` |
| Versetzen von Gebäuden | `src/core/battle.gd`, `src/core/build_rules.gd`, `src/core/battle_state.gd` |
| Fokus-Angriff, Hindernisse zerstören | `src/core/combat.gd`, `src/core/obstacle.gd`, `src/core/battle_state.gd`, `src/core/projectile.gd` |
| Energie-Abdeckung (Baumodus, mobiler Turm) | `src/core/coverage.gd`, `src/ui/coverage_texture.gd`, `src/ui/battle_view.gd` |
| Zielprioritäten | `src/core/targeting.gd` |
| Kampfzustand und Orchestrierung | `src/core/battle_state.gd`, `src/core/battle.gd`, `src/core/battle_events.gd`, `src/core/building.gd`, `src/core/enemy.gd`, `src/core/projectile.gd`, `src/core/pickup.gd` |
| Bauregeln | `src/core/build_rules.gd` |
| Energienetz, Strahlen, Schneiden | `src/core/energy_network.gd`, `src/core/energy_link.gd` |
| Türme (inkl. Zielklassen pro Turm), Kern-Verteidigung, Schild, Heilturm, Geschütze | `src/core/combat.gd` |
| Gegner-KI (Pfade, Erreichbarkeit, Sabotage) | `src/core/enemy_ai.gd` |
| Wellen, Rundenwechsel Planung/Kampf | `src/core/spawn_director.gd`, `src/core/battle.gd`, `src/ui/battle_hud.gd` (Planungskarte, Start-Button) |
| Rückgängig/Zurücksetzen in der Planung | `src/core/plan_history.gd`, `src/core/plan_snapshot.gd`, `src/core/battle.gd`, `src/core/battle_state.gd`, `src/ui/battle_hud.gd`, `src/ui/battle_screen.gd`, `src/ui/confirm_overlay.gd`, `src/ui/battle_view.gd` (Gesten-Gruppierung) |
| Energiebilanz und Energiewerte pro Gebäude | `src/core/energy_stats.gd`, `src/ui/energy_stats_text.gd`, `src/ui/energy_stats_panel.gd`, `src/ui/battle_hud.gd`, `src/ui/stat_text.gd`, `src/ui/building_panel.gd` |
| Tag/Nacht innerhalb eines Kampftags | `src/core/day_cycle.gd` |
| Geld, Münzen, Combo, Exporteur | `src/core/economy.gd` |
| Fortschritt und Sterne | `src/core/progress.gd` |
| Tutorial | `src/core/tutorial.gd` |
| Spielfeld, Bedienmodi, Zielauswahl, Verbindungs-Highlight, Gesten (Doppeltipp-Pan im Verbinden-Modus), Mauer-Malen, Kamera, Strahlen-Rendering | `src/ui/battle_view.gd`, `src/ui/gesture_tracker.gd`, `src/ui/camera_math.gd`, `src/ui/draw_layer.gd`, `src/ui/lightning.gd` |
| Prozedurale Grafik | `src/ui/painter.gd`, `src/ui/building_icon.gd`, `src/ui/menu_backdrop.gd` |
| HUD, Bauleiste, Gebäudepanel (Zielpriorität, Verbinden/Angreifen/Versetzen) | `src/ui/battle_hud.gd`, `src/ui/build_bar.gd`, `src/ui/building_panel.gd`, `src/ui/stat_text.gd` |
| Belohnungseffekte | `src/ui/reward_director.gd`, `src/ui/effect_pool.gd`, `src/ui/celebration_layer.gd`, `src/ui/juice.gd`, `src/ui/rolling_number.gd` |
| Sound und Vibration | `src/ui/sound_synth.gd`, `src/ui/sound_bank.gd`, `src/ui/sfx_player.gd` |
| Kampfbildschirm, Modus-Button, Joystick, Ergebnis, Pause | `src/ui/battle_screen.gd`, `project.godot` (Eingabeaktionen), `src/ui/result_overlay.gd`, `src/ui/pause_overlay.gd` |
| Menü, Levelauswahl, Einstellungen | `src/ui/main.gd`, `src/ui/level_select.gd`, `src/ui/app_settings.gd`, `scenes/main.tscn` |
| Theme, Icons, UI-Bausteine, Texte | `src/ui/app_theme.gd`, `src/ui/icons.gd`, `src/ui/ui_kit.gd`, `src/ui/texts.gd`, `i18n/translations.csv` |

## Tests

- `tests/unit/test_*.gd`: Core-Logik, Caches, UI-Logik, Szenen-Flows. Neu: `test_energy_stats.gd`, `test_energy_stats_text.gd`, `test_plan_history.gd` sowie Ergänzungen in `test_stat_text.gd` und `test_ui_scenes.gd` – noch nicht ausgeführt (Gradle/Godot-Läufe in dieser Sitzung untersagt), vor dem nächsten Commit `$G --headless --import` und die Suite laufen lassen.
- `tests/support/battle_fixtures.gd`: Test-Helfer – `battle()` (offenes Gelände, Nebel aufgedeckt, Kern am Drop), `deployed()` (echte Karte, Kern gesetzt), `open_terrain`, `wall`, `add`, `enemy`.
- `tests/tools/`: Screenshot-Tool und Balance-Bot, beide nicht Teil der Testsuite.
