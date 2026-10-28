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
  - `--level=N` erobert vorher alle Gebiete < N und kauft die gesamte Forschung. Ohne `--level` zeigt das Tool die Weltkarte, `--conquered=N` erobert dafür die ersten N Gebiete.
- **Belagerungstest:** `$G --headless -s tests/tools/siege_test.gd -- --level=N [--ring=5] [--towers=4]` – feste kompakte Basis mit idealer Energie auf offenem Gelände; vergleicht Mauerring, nur Türme und Türme für das Mauergeld. Aktueller Stand: Mauerring verzögert den ersten Turmverlust in Level 2–6 um das 2–3-Fache.
- **Balance-Bot:** `$G --headless -s tests/tools/balance_bot.gd -- [--level=N]… [--seed=N] [--money=N] [--verbose]`
  - Setzt den Kern am Drop-Punkt (Nebel aufgedeckt) und spielt heuristisch. `--walls` umgibt Türme und Kern mit einem Bollwerk-Ring (Abstand 2 Zellen), `--hold` verzichtet auf den Angriff, `--profile` gibt die Tick- und Denkzeit pro Minute aus.
  - Startet jede Planungsphase sofort mit `Battle.start_round`. Ausgabe u. a. `rounds=` (erreichter Tag).
  - Bot und Belagerungstest spielen mit voller Forschung (`Arsenal.everything()`). Die Balance mit getrennten Tag-/Nachtmonstern ist noch nicht vermessen.
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
- **Phasen:** SCOUT (Soldat erkundet, noch keine Feindstrukturen) → PLAN (nach `Battle.deploy_core`, Soldat sitzt im Kern: `Scout.boarded`) ⇄ FIGHT → WON/LOST.
  - PLAN: Zeit steht, nur Münzflug/Combo-Ablauf (`Economy.update_pickups`) und Siegprüfung laufen. `Battle.start_round` (`SpawnDirector.start_round`) → FIGHT, setzt `round_time`/`waves_sent`/`night_over` und alle `Building.plan_spent` zurück.
  - FIGHT: `round_time` läuft. Bei `DayCycle.is_finished` → `SpawnDirector.end_night` (`night_over`): nachtaktive Gegner (`Enemy.is_nocturnal`) bekommen einen `burn`-Timer (`BURN_MIN`..`BURN_MAX`), `SpawnDirector.burn` tötet sie ohne Kopfgeld/Kill (Event `burned`). Sind danach alle Angreifer tot (`BattleState.has_attackers`, Wächter zählen nicht), folgt `_check_round`: `days_survived` = Tag; im Survival mit `days > 0` und erreichtem Ziel → WON (Event `victory`), sonst zurück in PLAN, `round_number += 1`, `SpawnDirector.ignite_guards` (Event `guards_ignited`), Event `round_cleared`. In PLAN laufen `SpawnDirector.burn` und `_sweep` weiter, solange Gegner existieren.
  - WON durch Strukturen (`_check_end`) nur in der Kampagne.
  - `BattleState.is_night()`/`light()` gelten nur in FIGHT (sonst Tageslicht).
- **Tick-Reihenfolge in FIGHT** (`Battle.tick`): Soldat → Nebel → Zeit → Wellen → mobile Gebäude → Energiefluss → Kampf → KI → Aufräumen → Wirtschaft → Tag/Nacht-Events → Siegprüfung → Rundenende.
- **Planungs-Historie:** `Battle.history` (`PlanHistory`) startet bei `deploy_core`, `_check_round` und in `Battle._init`, wenn der Zustand schon PLAN ist; `start_round` beendet sie (`baseline_stats` bleibt für die Energiebilanz). Jede erfolgreiche Spieleraktion in PLAN legt vorher einen `PlanSnapshot` ab (`_checkpoint`/`_commit`): Spielergebäude-Objekte samt Feldern, Links als Paare, Geld/`earned`. `restore` entfernt alle Spielergebäude, setzt die gespeicherten wieder ein (`BattleState.reinstate`, `replace_links`) und rechnet zwischenzeitliche Einnahmen dazu. Gesten (`BattleView.begin`/`finish`/`tap` → `begin_stroke`/`end_stroke`) fassen Mauer-Malen (`STEP_PAINT`) und Kappen (`STEP_CUT`) zu einem Schritt zusammen. Max. `MAX_STEPS` Schritte. Event `plan_restored`.
- **Energiebilanz:** `EnergyStats.measure(state, audit)` (Metriken per Enum, `fire_draw`/`self_reserve`/`shots_per_charge`/`drain_time`; Strahlverlust, Effizienz, Deckung und Exporterlös aus dem Audit), Formatierung und Deltas in `EnergyStatsText` (Formate u. a. PERCENT, INCOME), Anzeige in `EnergyStatsPanel` (HUD, Deltas gegen `history.baseline_stats`, Puls bei `BattleScreen.PULSE_EVENTS`).
- **Netzdiagnose:** `EnergyAudit.measure` ist eine stationäre Prognose für DAY/NIGHT. `demand` = Dauerfeuer bzw. Exportrate (`EnergyAudit.draw`, überladen → 0). `needs` = eigener Bedarf + Weiterleitung (rückwärts topologisch, je Link `min(beam_rate, need_ziel / yield)`), damit Verteiler und Speicher einen Bedarf haben. Eigenes Budget = `generation` (Solar nachts 0) + `storage` (nur NIGHT, nur angebundene Sender außer Solar: Kapazität ÷ `level.night`). Vorwärts per Water-Filling (`water_fill`), bei Zyklen bis `MAX_PASSES`. `gathered` = Budget + Empfang, `ratio` = `gathered / need`, `served` = eigener gedeckter Bedarf (für Energiebilanz und Exporterlös). Erzeuger (`output > 0`) bekommen kein Urteil (`shows` false). Urteile `Verdict` (OK/LOW/OVERLOADED) und Ursachen `Cause` (u. a. NIGHT, STORAGE mit Speicher als Schuldigem) werden pro Szenario abgelegt; das Pseudo-Szenario `WORST` löst pro Gebäude (Links über ihr Ziel) auf die schlechtere Tageszeit auf. `view_scenario(state)`: FIGHT → aktuelle Tageszeit, sonst WORST. `missing` = fehlender Anteil (roter Ringanteil), `night_reserve` = Speicherdauer bei Dauerfeuer. `chain(id)` liefert die Versorgungskette inklusive inaktiver Links. `Battle.audit()` cacht per `Vector3i(roster_version, links_version, layout_version)`; `BattleState.mark_changed` (Versetzen, Fahren, Upgrade, Restore) erhöht `layout_version`.
- **Strahlverlust:** `Formulas.beam_span(s, t)` = Abstand − (`half_extent` s + t) × √2 − `BEAM_FREE_MARGIN` (Nachbarn und Diagonalen = 0). `beam_loss(source, span, receiver)` = `BEAM_LOSS_PER_CELL` × span/Feld × `transfer_factor(source)` × receiver / `boost(BOOST_TRANSFER)`, gedeckelt auf `BEAM_LOSS_MAX`; `transfer_factor` = 1 − 0,1 × Stufe (Stufe 10 = 0). `link_loss`/`link_efficiency(source, target)` nutzen den Faktor des Ziels als receiver. `EnergyNetwork._push` sendet `min(limit, share, space/yield)`, das Ziel erhält `amount × yield`.
- **Exporteur:** `Economy._export` verbraucht `min(energy, export_rate × delta)` in `Building.export_buffer`. Bei `Formulas.export_batch` (Rate × `EXPORT_CYCLE`) wird `export_income(batch)` + `export_carry` abgerundet gutgeschrieben (Event `export` mit `value`, `id`), der Rest bleibt in `export_carry`. Der blaue Ring (`Painter._exporter`) zeigt `Formulas.export_progress`.
- **Überladung:** `TRACK_OVERCLOCK` multipliziert den Schaden mit `multiplier` und die Schussenergie mit `TRACKS.overclock.energy ^ level`. `Formulas.is_overloaded` = `action_energy > capacity`; die vorhandene Energieprüfung in `Combat` verhindert dann jeden Schuss. Das Event `upgraded` trägt `overloaded`.
- **Wächter:** `GameConfig.GUARDS` pro Spawner-Art. `SpawnDirector.reinforce` (nur FIGHT vor `night_over`) hält `Formulas.guard_count(round)` Wächter je lebender Basis (`guard_timer`: `GUARD_FIRST`, `GUARD_TRICKLE`, `GUARD_RESPAWN`) und zündet verwaiste an. `Enemy.post` ≥ 0 markiert Wächter (`is_guard`; `is_attacker` für alle anderen lebenden). `EnemyAI._patrol` läuft Ringpunkte (`patrol_point`, `Formulas.guard_ring`) mit Pausen ab und greift nie an.
- **Statusmodus:** `BattleView.status_mode` (Signal `status_mode_changed`) zeichnet in `_paint_status` Link-Farben/-Labels, Kettenhighlight, Schuldigen-Puls, Abzeichen (`_paint_badge`: Ring in Urteilsfarbe, roter Bogen über `missing`) und Labels im `view_scenario`. Ohne Statusmodus beschriftet `_paint_beam_labels` alle sichtbaren Strahlen, solange ein eigenes Gebäude ausgewählt ist (`shows_beam_labels`). Texte, Farben und Ursachen kommen aus `StatusText`, Panel-Zeilen aus `StatText.status_rows`. Der HUD-Button `status_pressed` und die Legende stehen in `BattleHud`; `BattleScreen.toggle_status` ist beim Erkunden und nach Spielende gesperrt, `handle_back` verlässt den Modus.
- **Gebäudepanel minimieren:** `BuildingPanel.minimized` (Button `_minimize`, `toggle_minimized`/`set_minimized`) blendet `_body` (Werte, Statuszeilen, Ziele, Upgrades, Aktionen, Verkaufen) und `_info` aus; Kopf und Statuszeile bleiben. Der Zustand bleibt über Auswahlwechsel erhalten, die Auswahl selbst bleibt bestehen.
- **Balance:** `TRACK_GROWTH` 1,18, `ROUND_HP_GROWTH` 1,22, Wellen-`growth` 0,4, Gegner-HP ×1,6 und Kopfgeld ×0,7 gegenüber dem früheren Stand, Wellen-`base` je Level etwa ×1,6–1,8, `ENERGY_PER_COIN` 8. Ziel: ab Tag 3 mehrere Türme nötig, Endlos kippt um Tag 15–18. Nur rechnerisch geprüft, mit dem Balance-Bot zu vermessen.
- **Planungs-Erstattung:** `Building.plan_spent` sammelt Bau- und Upgradekosten der laufenden Planungsphase. `Formulas.sell_value` = `plan_spent` + (Rest × `SELL_REFUND` × HP-Anteil). `Formulas.relocate_cost(b, planning)` ist in PLAN 0.
- **Sperrzone:** `BuildRules.enemy_clearance` = `ENEMY_PLAN_CLEAR` in PLAN, sonst `ENEMY_NO_BUILD`. Grund `ENEMY_ZONE` (nur PLAN) bzw. `ENEMY_NEAR`.
- **Direktsteuerung:** Soldat und mobiler Turm bewegen sich per Lenkvektor (`steer`) mit Kreis-Kollision gegen Zellen (`Steering.slide`, gleitet an Wänden). Eingabe: Tasten über die Aktionen `steer_left/right/up/down` (`project.godot`, nur wenn `BattleScreen.steering_enabled`), sonst der schwebende Joystick `BattleView.stick_vector`; einen festen Joystick gibt es nicht. Er startet in `begin(world, screen)` als Geste STEER_PENDING, wenn `can_steer()` gilt (Modus MOVE, kein Bau- oder Zielmodus, Soldat aktiv oder mobiler Turm ausgewählt im Kampf). Ab dem Ziehen gilt STEER (`steer_to`: Radius `STICK_RADIUS`, Ursprung folgt dem Finger, Totzone `STICK_DEADZONE`). Tippen wählt weiter aus; zweiter Finger, Loslassen oder Wegfall von `can_steer` setzen ihn zurück. Gelesen wird alles in `BattleScreen.steering_input`. Mobile Gebäude wechseln ihre Nav-Zelle über `BattleState.drive`.
- **Strahlen außer Reichweite:** `EnergyNetwork._push` prüft pro Tick `in_range`; inaktive Links (`EnergyLink.active`) bleiben bestehen. Beim Versetzen (`Battle.relocate`) werden zu lange Links gekappt (`drop_out_of_range`).
- **Solar-Transfer:** `rate_from_output` – `Formulas.rate` = Leistung, `Formulas.beam_rate` teilt sie auf die verbundenen Strahlen.
- **Fokus:** `Building.focus` (Enemy, feindliches Building oder `Obstacle`), ausgewertet zuerst in `Combat.find_target`/`_laser_target`, sofern in Reichweite. Hindernisse sind lazy angelegte `Obstacle`-Objekte (`BattleState.obstacle_at`, HP aus `GameConfig.OBSTACLE_HP`), Entfernen über `BattleState.clear_obstacle`.
- **Abdeckung:** `Coverage` liefert pro Zelle 0–4 (keine/1/2/3+/nur volle Sender), `CoverageTexture` malt das als RGBA-Bild (eigener DrawLayer, Nearest-Filter), Refresh alle `COVERAGE_REFRESH` s nur solange aktiv.
- **Raster:** `LevelMap` (Kacheln OPEN/RAMP/CLIFF/CHASM/TREE/ROCK/POND + Höhe, Zelle `GameConfig.CELL`), erzeugt von `MapGenerator` (Spots, Plateaus mit Rampen, Schluchten mit Brücken, Teiche `pond_at` mit bis zu `ATTEMPTS` Versuchen, große Wälder `grove_at` mit lückenlosem Kern `GROVE_CORE`, kleine Wälder `forest_at`, Felsen, `connect_all` furtet auch Teiche). Formen über `blob`. Level-`terrain`: `ponds`, `groves`, `forests`, `rocks`. Gebäude rasten auf ihren Footprint (`LevelMap.snap`).
- **Feindstrukturen:** `map.structures` sind nur noch Art + Ausweichposition (vom Generator freigehalten). `BattleState.create` legt keine Strukturen an; `place_core` ruft einmalig (`structures_spawned`) `spawn_structures(StructurePlacer.sites(state, kern))` auf. `StructurePlacer` (RNG-Seed = Hash aus `rng.seed` und Kernzelle) bildet Summentabellen (frei, flach OPEN, Höhe) und prüft Kandidaten in O(1): Footprint OPEN und eben, Rand `STRUCTURE_MARGIN` frei, gleiche Nav-Komponente wie der Kern. Spawner zuerst: Abstand ≥ `far_limit` (max(`CORE_ENEMY_CLEAR`, `STRUCTURE_FAR_SHARE` × größte Kandidatendistanz)), untereinander `STRUCTURE_SPACING` Felder (sonst gelockert); Geschütztürme im Ring `TURRET_POST_RING` um einen Spawner. Kein Kandidat → Ausweichposition. `Battle.deploy_core` meldet `structures_spawned` (`count`), `RewardDirector` zeigt den Hinweis. Fixtures setzen Strukturen direkt mit `spawn_structures(map.structures)`.
- **Karte (Minimap):** `MiniMapTexture` (RGBA-Bild, 1 Pixel pro Zelle, vorberechnete Palette Kachel × Höhe × Nebelzustand, Refresh nur bei `map.version`/`fog.version`-Wechsel), `MiniMap` (Control, Nearest-Filter, `markers()` für Spawner/Geschütze/Kern/Gebäude/Soldat, Kamerarahmen aus `BattleView.world_rect`, Tippen → `focus_requested`), `MapPanel` (Kopf mit Zähler, Legende). `BattleHud` bekommt das Panel über `setup(safe_top, map)`, Button `map_button` (HUD-Kind, Position rechts unten setzt `BattleScreen._refresh_ui`), `toggle_map`/`hide_map` (schließt die Statistik und umgekehrt), Signal `map_focus_requested`. `BattleScreen` aktualisiert das Panel nur, solange es offen ist.
- **Navigation:** `NavGrid` mit zwei `AStarGrid2D` – `ground` (Terrain + alle Gebäude solide, Gegner) und `walker` (Terrain + feindliche Strukturen; dient als Kollisionsraster des Soldaten). Zusammenhangskomponenten (4er-BFS, lazy pro `version`) bestimmen die Erreichbarkeit: Ein Gebäude ist erreichbar, wenn es an die Komponente des Gegners grenzt. Max. `PATHS_PER_TICK` Pfadberechnungen pro Tick.
- **Soldat:** `SCOUT_SPEED` 195, `SCOUT_VISION` 460, `CLEAR_TIME` Baum 0 (`ScoutControl.clear` fällt sofort über `_finish`), Fels 1,1 s; `clear_time(cell)`, `clear_ratio` ist bei Zeit 0 abgesichert.
- **Nebel:** `FogOfWar` (HIDDEN/EXPLORED/VISIBLE pro Zelle, Refresh alle `FOG_INTERVAL`), inkrementell: Jede Sichtquelle (Gebäude-ID bzw. `SCOUT_MARK`) ist eine Marke mit Zentrum und Radius, `_seen` zählt Referenzen pro Zelle. Gebäudemarken werden nur bei `nav.version`-Wechsel abgeglichen, `version` steigt nur bei Änderungen. Externe Zelländerungen brauchen `invalidate()`. Darstellung: `FogTexture` (R8-Bild direkt aus `cells`, Alpha-Mapping im Shader `src/ui/fog.gdshader`, linear gefiltert).
- **Performance-Regeln:**
  - Türme suchen Ziele nur, wenn sie schießen könnten; ohne Treffer pausiert die Suche `TARGET_SCAN` s. Laser behalten ihr Ziel und prüfen die Priorität alle `TARGET_SCAN` s neu. `Combat.group_enemies` bündelt Gegner pro Klasse einmal pro Tick.
  - `BattleState` cacht Ranglisten (`player_buildings`, `enemy_buildings`, `of_kind`, `combatants`, `producers`, `stores`) bis `roster_version` sich ändert, Links über `add_link`/`remove_link_at` mit `links_version` und `outgoing_count`. `EnergyNetwork.groups` gruppiert Links pro Quelle bis zum nächsten `links_version`.
  - `Building` cacht Definition, Flags (`armed`, `healing`, `shielding`, `exporting`, `mobile`, `spawner`), Geometrie und alle abgeleiteten Werte (`Formulas.compute_stats` → `Building.stat`). Invalidiert wird über die Setter von `levels`/`elevation` bzw. `set_level`. `Enemy` cacht Klasse, Radius, Tempo, Reichweite und Flags; `NavGrid` hält ein Byte-Raster `_blocked` für `is_free`.
  - `EnemyAI` cacht die Ziel-Rangliste (`Targeting.rank`, nach Stufe vorsortiert, damit `best_ranked` früh abbricht) höchstens `TARGET_SCAN` s bzw. bis zum nächsten `nav.version`-Wechsel, gefiltert pro Komponente.
  - `BattleView` zeichnet nur, was im sichtbaren Weltausschnitt (`visible_world_rect` + `CULL_MARGIN`) liegt. Mauern liegen auf einer eigenen Ebene, die nur bei `roster_version`-Wechsel neu gezeichnet wird. `EffectPool` begrenzt Partikel auf `MAX_PARTICLES`.
  - Referenzmessung (88 Gebäude, 30 Gegner): ca. 1,1 ms pro Tick.
- **`GameConfig.is_tower`** gilt für echte Türme. **`GameConfig.has_attack`** gilt für alles, was schießt, also auch den Kern. **`GameConfig.uses_energy_actively`** umfasst zusätzlich Heilturm und Schild (für Energiebalken). **`GameConfig.is_wall`** markiert Bollwerke (keine Energie, kein Bauradius, Kosten über `Formulas.build_cost`).
- **Wellen:** `level.waves` (`interval`, `base`, `ramp`, `night`, `growth`, `roster` = Tagmonster, `night_roster` = Nachtmonster; `SpawnDirector.roster` wählt nach `is_night`, `fallback_kind` nach Fraktion und Tageszeit). Welle i startet bei `WAVE_FIRST + i × interval`, solange `round_time` < Tag + Nacht (`Formulas.wave_times`/`wave_time`). Größe pro Spawner = `Formulas.wave_count` (mind. 1, Bruchteile in `spawn_progress`), landet in `Building.spawn_queue` (max. `WAVE_MAX`) und wird alle `WAVE_TRICKLE` s aus `spawn_heading` freigegeben. Gegnerstärke über `Formulas.enemy_hp_scale`/`enemy_damage_scale`/`enemy_bounty_scale`, Gegnertypen über `Formulas.wave_tier`.
- **Upgrades:** `GameConfig.TRACKS` (max, step, price, optional growth) und `tracks` pro Gebäude. `Formulas.multiplier`, `efficiency`, `crit_chance`, `chain_count`, `splash`, `upgrade_cost`, `max_level`.
- **Pfade der Gegner:** Neu geplant wird nur bei Zielwechsel oder wenn der nächste Wegpunkt blockiert ist (nicht bei jeder Kartenänderung). Saboteure laufen zu einer „Schnittzelle“ (`EnemyAI.cut_cells`: freie Zellen direkt am Strahl, pro `nav.version` gecacht) und kappen den Strahl bei Ankunft.
- **Ziele der Gegner:** `Targeting.best` – höchste Stufe (`Targeting.tier`: Exporteur 6, Heiler 5, Verteidigung 4, Mauer 3, Netz 2, untätig ohne Energie 1, Kern 0), dann kleinster Randabstand. Bodengegner wählen nur aus `NavGrid.reachable`, Luftgegner aus allen Gebäuden. Feindliche Geschütztürme nutzen dieselbe Funktion.
- **Turmziele:** `Building.target_order`/`target_disabled` (Standard Luft → Fernkampf → Nahkampf), ausgewertet in `Combat.find_target`.
- **Kampfregeln:** `BattleSetup` (Modus CAMPAIGN/SURVIVAL, `days` mit 0 = endlos, `arsenal`) wird an `Battle.start`/`BattleState.create` übergeben. Im Survival sind Spawner `Building.immune` (`Combat.find_target` überspringt sie, `damage_building` ignoriert sie, Fokus `CANNOT`). Sterne nur im gewonnenen Survival (`Formulas.survival_stars`, Ziele `SURVIVAL_TARGETS`).
- **Forschung:** `GameConfig.TECHS` (Zweig, Kosten, `requires`, `unlock` | `kind`+`boost`+`value` | `money`). `TechTree` prüft und kauft (`reason`/`buy`). `Arsenal.from_techs` sammelt freigeschaltete Arten (Start: `STARTER_KINDS`), Boni pro Art (`targets`: Art, `towers`, `all` inkl. Kern) und Startgeld. `BattleState.add_building` setzt `Building.boosts` für Spielergebäude, `Formulas.compute_stats` multipliziert mit `Building.boost(name)`.
- **Kampagne:** `Campaign` (Graph aus `WORLD_ROUTES`, Positionen aus `level.world`): freigeschaltet = erstes Gebiet, erobert oder Nachbar erobert. `route` ist eine BFS, deren Zwischenhalte erobert sein müssen (vom Start darf ein Feindgebiet nur in ein erobertes Nachbargebiet verlassen werden). `WorldWalker` läuft eine Route mit `WORLD_WALK_SPEED` (normierte Koordinaten) ab; Umleiten behält den nächsten Halt.
- **Herausforderungen:** `Challenges.of_level` = „conquer“ (2 SP) + `level.challenges` (je 1 SP). `is_met`: `survive` nur im Survival nach `days_survived`, alle anderen nur bei Kampagnensieg.
- **Ergebnis/Fortschritt:** `BattleReport.from_state` → `Progress.record` (setzt `first_conquest`, `new_challenges`, `points`, `improved`, Sterne, Endlos-Rekord, Standort). `Progress` v2: `regions[id] = {conquered, stars, best_days, done}`, `techs`, `location`, Summen; SP = verdient − ausgegeben. Laden bereinigt (Regionen, Herausforderungen, Forschung ohne Voraussetzungen, Überziehung) und migriert v1 (Sterne > 0 → erobert).
- **Bedienmodi:** `BattleView.Mode` (MOVE/CONNECT), dazu Zielauswahl `BattleView.Pick` (LINK/FOCUS, Geste `PICK`) und Versetzen (`relocate_id` + Baumodus). Strahl-Sichtbarkeit über `BattleView.beam_visibility` (geglätteter Fluss).

## Features → Dateien (alle umgesetzt)

| Feature | Dateien |
|---|---|
| Konfiguration und Formeln | `src/core/game_config.gd`, `src/core/formulas.gd` |
| Karte, Gelände, Generator (Teiche, große Wälder) | `src/core/level_map.gd`, `src/core/map_generator.gd`, `src/ui/terrain_painter.gd`, `src/ui/app_theme.gd` |
| Zufällige Platzierung der Feindstrukturen beim Kernsetzen | `src/core/structure_placer.gd`, `src/core/battle_state.gd`, `src/core/battle.gd`, `src/core/game_config.gd`, `src/ui/reward_director.gd` |
| Karte (Minimap mit Feindbasen) | `src/ui/mini_map_texture.gd`, `src/ui/mini_map.gd`, `src/ui/map_panel.gd`, `src/ui/battle_hud.gd`, `src/ui/battle_screen.gd`, `src/ui/battle_view.gd`, `src/ui/icons.gd` |
| Pfadsuche und Erreichbarkeit | `src/core/nav_grid.gd` |
| Nebel des Krieges | `src/core/fog_of_war.gd`, `src/ui/fog_texture.gd` |
| Soldat (Lenken, Ein-Schlag-Roden, Kern setzen, Gewehr im Kern) | `src/core/scout.gd`, `src/core/scout_control.gd`, `src/core/steering.gd`, `src/core/battle.gd`, `src/core/combat.gd` |
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
| Netzdiagnose und Statusmodus (Kette, Urteile, Nachtspeicher, Ursachen, Ring-Abzeichen, Strahl-Labels bei Auswahl, Legende, Verkaufsmarker) | `src/core/energy_audit.gd`, `src/core/battle.gd`, `src/core/battle_state.gd`, `src/ui/status_text.gd`, `src/ui/battle_view.gd`, `src/ui/battle_hud.gd`, `src/ui/battle_screen.gd`, `src/ui/building_panel.gd`, `src/ui/stat_text.gd`, `src/ui/icons.gd` |
| Strahlverlust (verlustfreie Nachbarn), Strahlübertragung an Sender und Empfänger, Supraleiter | `src/core/formulas.gd`, `src/core/energy_network.gd`, `src/core/energy_audit.gd`, `src/core/game_config.gd`, `src/ui/stat_text.gd` |
| Überladung (Fehl-Upgrade) | `src/core/game_config.gd`, `src/core/formulas.gd`, `src/core/battle.gd`, `src/ui/stat_text.gd`, `src/ui/building_panel.gd`, `src/ui/reward_director.gd` |
| Wächter um Feindbasen | `src/core/spawn_director.gd`, `src/core/enemy.gd`, `src/core/enemy_ai.gd`, `src/core/battle.gd`, `src/core/battle_state.gd`, `src/core/building.gd`, `src/ui/painter.gd`, `src/ui/battle_view.gd`, `src/ui/reward_director.gd` |
| Verkaufsanzeige (volle Erstattung/Verlust) | `src/core/formulas.gd`, `src/ui/building_panel.gd` |
| Tag/Nacht innerhalb eines Kampftags | `src/core/day_cycle.gd` |
| Geld, Münzen, Combo, Exporteur (5-s-Zyklus, Fortschrittsring) | `src/core/economy.gd`, `src/core/formulas.gd`, `src/core/building.gd`, `src/ui/battle_view.gd`, `src/ui/painter.gd`, `src/ui/stat_text.gd` |
| Fortschritt, Migration v1→v2, Skillpunkte | `src/core/progress.gd`, `src/core/battle_report.gd` |
| Kampagne, Wege, Weltkarten-Laufen | `src/core/campaign.gd`, `src/core/world_walker.gd`, `src/ui/world_map_view.gd`, `src/ui/world_map_screen.gd`, `src/ui/region_panel.gd` |
| Survival (5/10/15/endlos, unverwundbare Spawner) | `src/core/battle_setup.gd`, `src/core/battle.gd`, `src/core/battle_state.gd`, `src/core/combat.gd`, `src/ui/region_panel.gd`, `src/ui/battle_hud.gd`, `src/ui/battle_view.gd` |
| Herausforderungen | `src/core/challenges.gd`, `src/ui/region_panel.gd`, `src/ui/result_overlay.gd` |
| Forschung (Tech-Baum) | `src/core/tech_tree.gd`, `src/core/arsenal.gd`, `src/core/building.gd`, `src/core/formulas.gd`, `src/ui/tech_overlay.gd` |
| Tag-/Nachtmonster, Verbrennen bei Tagesanbruch | `src/core/game_config.gd`, `src/core/spawn_director.gd`, `src/core/enemy.gd`, `src/ui/painter.gd`, `src/ui/battle_view.gd`, `src/ui/reward_director.gd` |
| Tutorial | `src/core/tutorial.gd` |
| Spielfeld, Bedienmodi, Zielauswahl, Verbindungs-Highlight, Gesten (Doppeltipp-Pan im Verbinden-Modus), Mauer-Malen, Kamera, Strahlen-Rendering | `src/ui/battle_view.gd`, `src/ui/gesture_tracker.gd`, `src/ui/camera_math.gd`, `src/ui/draw_layer.gd`, `src/ui/lightning.gd` |
| Prozedurale Grafik | `src/ui/painter.gd`, `src/ui/building_icon.gd`, `src/ui/menu_backdrop.gd` |
| HUD, Bauleiste, Gebäudepanel (Zielpriorität, Verbinden/Angreifen/Versetzen, Minimieren) | `src/ui/battle_hud.gd`, `src/ui/build_bar.gd`, `src/ui/building_panel.gd`, `src/ui/stat_text.gd` |
| Belohnungseffekte | `src/ui/reward_director.gd`, `src/ui/effect_pool.gd`, `src/ui/celebration_layer.gd`, `src/ui/juice.gd`, `src/ui/rolling_number.gd` |
| Sound und Vibration | `src/ui/sound_synth.gd`, `src/ui/sound_bank.gd`, `src/ui/sfx_player.gd` |
| Kampfbildschirm, Modus-Button, schwebender Joystick, Ergebnis, Pause | `src/ui/battle_screen.gd`, `src/ui/battle_view.gd`, `project.godot` (Eingabeaktionen), `src/ui/result_overlay.gd`, `src/ui/pause_overlay.gd` |
| Hauptszene (Weltkarte ⇄ Kampf, Nochmal, Zurück-Taste), Einstellungen | `src/ui/main.gd`, `src/ui/app_settings.gd`, `scenes/main.tscn` |
| Theme, Icons, UI-Bausteine, Texte | `src/ui/app_theme.gd`, `src/ui/icons.gd`, `src/ui/ui_kit.gd`, `src/ui/texts.gd`, `i18n/translations.csv` |

## Tests

- `tests/unit/test_*.gd`: Core-Logik, Caches, UI-Logik, Szenen-Flows. Kampagne/Survival/Forschung: `test_campaign.gd`, `test_world_walker.gd`, `test_challenges.gd`, `test_tech_tree.gd`, `test_arsenal.gd`, `test_survival.gd`, `test_progress.gd` (inkl. Migration v1), dazu Weltkarte/Forschung/Survival in `test_ui_scenes.gd`.
- Netzdiagnose, Strahlverlust, Überladung, Wächter, Statustexte, Exportzyklus: `test_energy_audit.gd`, `test_energy_network.gd`, `test_overcharge.gd`, `test_guards.gd`, `test_status_text.gd`, `test_economy.gd`; schwebender Joystick, Statusmodus, Panel-Minimieren, Strahl-Labels, Karte und Wächter-Darstellung in `test_ui_scenes.gd`.
- Feindplatzierung, Minimap, Teiche/Wälder, Soldat: `test_structure_placer.gd`, `test_mini_map.gd`, `test_level_map.gd`, `test_terrain_painter.gd`, `test_scout.gd`, `test_config.gd`.
- Die Suite wurde nach den letzten Änderungen noch nicht ausgeführt (Godot-Läufe waren untersagt). Vor dem nächsten Commit `$G --headless --import` (neue Klassen und Übersetzungen) und die Suite laufen lassen; die Balance (u. a. `test_defended_core_survives_the_first_round`) ist nur rechnerisch geprüft.
- `tests/support/battle_fixtures.gd`: Test-Helfer – `battle()` (offenes Gelände, Nebel aufgedeckt, Strukturen an den Ausweichpositionen, Kern am Drop), `deployed()` (echte Karte, Kern gesetzt, Strukturen zufällig), `open_terrain`, `wall`, `add`, `enemy`.
- `tests/tools/`: Screenshot-Tool und Balance-Bot, beide nicht Teil der Testsuite.
