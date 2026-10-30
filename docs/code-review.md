# Code-Review: Panzer, Monster-Katalog, Content-Overrides, dynamische Weltkarte, Editor-Reiter

Geprüft wurde der Stand gegen Commit `a504ec5`: Spielkern (`src/core`), Darstellung (`src/ui`), Upgrade-Editor (`tools/upgrade_editor`, Python und JS). Schwerpunkte waren Korrektheit, Grenzfälle, Last im Spiel-Tick, Architektur, Duplikate, die Gleichheit der JS-Spiegel mit dem GDScript-Code, die Balance, i18n und alte Spielstände.

## Behobene Findings

| # | Bereich | Finding | Fix | Test |
|---|---|---|---|---|
| 1 | Tests | `tests/unit/test_level_rosters.gd` lief nie. `var early := …waves.roster.size()` lässt sich nicht ableiten (Variant), dadurch gab es einen Parse-Fehler, und GUT hat die Datei nur mit einer Warnung übersprungen. | Typen explizit angegeben (`int`). | Die Datei läuft jetzt (9 Tests) und hat Finding 2 aufgedeckt. |
| 2 | Balance | In der Nacht-Aufstellung von `final_war` hatte der Boss `tank` das Gewicht 0,2. Die Regel erlaubt für Bosse höchstens 0,15. | Gewicht auf 0,15 gesetzt, in `game_config.gd` und in `data/game.json` (`levels` und `defaults`). | `test_bosses_are_rare_and_appear_late` |
| 3 | Panzer/Kampf | **Der Laser ignorierte Panzer.** Der Mindestschaden (1) galt pro Tick. Ein Laser-Tick macht 30 × 1/30 = 1,0 Schaden; nach dem Panzer ist das weniger als 1 und wurde wieder auf 1 angehoben. Gegen einen Basis-Laser war Panzer damit wirkungslos. Außerdem meldete der Laser den Schaden ohne Panzer. | `Formulas.mitigate(amount, armor, share)`: Der Mindestschaden wird mit `share` multipliziert, der Laser übergibt `delta` (Mindestschaden pro Sekunde). Die `Combat.damage*`-Funktionen geben jetzt den echten Schaden zurück, der Laser summiert für seine Meldung diesen Wert. Der JS-Spiegel `armor.js` `mitigate(…, share)` ist nachgezogen, die Editor-Beschreibung ebenso. | `test_armor.gd` (`test_laser_ticks_are_reduced…`, `test_laser_reports…`), `test_parity.gd`, `parity.test.js` |
| 4 | Panzer/Kampf | Treffer auf Feindgebäude meldeten im `hit`-Event den Schaden ohne Panzer. Bei Gegnern wird der reduzierte Schaden gemeldet. | `Combat.damage` meldet für Gebäude den reduzierten Schaden. | `test_hits_on_enemy_structures_report_the_reduced_damage` |
| 5 | Fraktionen | `faction` lässt sich im Editor ändern, und die Wellen-Vorschau (`waveMix`) nutzt dieses Feld. Das Spiel nutzte aber nur die feste Liste `SPAWNER_FACTIONS`. Die Vorschau zeigte also etwas anderes als das Spiel, und neue Override-Kinds kamen nie aus einem Spawner. | Neu: `GameConfig.faction_kinds(spawner)`, abgeleitet aus `faction` und gecacht pro `ContentOverrides.version()`. `SpawnDirector` (`eligible`, `air_kinds`, `extra_spawners`, `fallback_for`) nutzt die Funktion. `SPAWNER_FACTIONS` bleibt als Standardliste erhalten; ein Test prüft, dass beide gleich sind. | `test_faction_kinds_follow_the_faction_field`, `test_new_enemy_kinds_need_the_positive_basics` |
| 6 | Robustheit | `ContentOverrides` hat Gegner und Level kaum geprüft. Mögliche Folgen: Ein fehlendes `radius` ließ `Enemy._init` abstürzen. Eine unbekannte `class` machte einen Gegner unangreifbar und damit unbesiegbar. `interval: 0` führte zu einer Division durch 0. `day: 0`, unbekannte Strukturarten (Absturz beim Aufbau), Roster mit unbekannten Kinds und doppelte Level-IDs (Kollision im Spielstand) kamen ungeprüft durch. | Defensive Bereinigung: Pflichtzahlen fallen auf den Standardgegner zurück, sonst wird der Kind verworfen. `class`, `faction`, `look`, Flags und `buffs` werden geprüft. Level: `cells` 20–400, `drop`/`world` 0–1, nur Feindstrukturen, `waves` mit Standardwerten (`interval` > 0), Roster/Herausforderungen/Zusatz-Wellen nur mit gültigen Kinds, `day`/`night` > 0, doppelte IDs werden verworfen. | `test_enemy_overrides_are_sanitized…`, `test_levels_are_sanitized…` |
| 7 | Performance | `Campaign.positions()/routes()/neighbors()` wurden bei jedem Aufruf neu gebaut. `WorldMapView` ruft sie pro Frame rund 100-mal auf (`node_position`, `is_frontier`, `is_route_open`), das sind O(n²) Allokationen pro Frame. | Cache pro `ContentOverrides.version()` (neuer Versionszähler) mit read-only Arrays und Nachbarlisten. Toter Code entfernt (Schleife über `LEVELS.size()..region_count()`). | `test_layout_and_routes_are_cached_until_the_content_changes`, `test_version_changes_with_every_data_switch` |
| 8 | Kampagne | Automatische Wege verbanden nur Gebiete ganz ohne Weg. Getrennte Teilnetze (`[[0,1],[2,3]]`) oder ein isoliertes Startgebiet (`[[1,2]]`) machten den Rest der Kampagne unerreichbar. | `Campaign.connect_all` (Union-Find) verbindet jede vom Start nicht erreichbare Komponente mit dem Vorgänger. Der JS-Spiegel `worldLayout.js` `connectAll` ist identisch. | Feste Referenzwerte in `test_parity.gd` und `parity.test.js`, dazu `test_disconnected_custom_routes…` und `test_isolated_start_region…` |
| 9 | Editor/Wege | Bei „Wege automatisch“ und unveränderten Leveln zeigte der Editor eine Kette 0–1–2…, das Spiel nutzte aber weiter `WORLD_ROUTES`, weil `overrides.py` nichts schrieb. | `build_content_overrides` schreibt in diesem Fall die Kette explizit. | `test_automatic_routes_with_default_levels_write_the_editor_chain`, `…changed_levels_stay_automatic` |
| 10 | JS-Spiegel Wellen | `roundSummary` addierte Zusatz-Monster mit ihrer vollen Zahl zu Werten, die „je Spawner“ gelten. Es zählte sie auch dann, wenn ihr Abschnitt (z. B. Nacht) keine Welle hat; das Spiel spawnt sie dann nie. | Zusatz-Monster werden pro Welle über `extraWavesAt` gezählt, als Anteil je passendem Spawner (`extraShare`, wie `SpawnDirector.spawn_extra`/`extra_spawners`). | Bestehender Test angepasst (er erwartete +4 je Spawner bei 2 Nestern, richtig sind +2: Werte und Beschreibung gelten je Spawner). Neuer Test `…only when their section has a wave and splits them per spawner`. |
| 11 | JS-Spiegel Validierung | `levels.js` prüfte keine Pflicht- oder Fremdschlüssel (Level, `waves`, `terrain`), `content_model.py` schon. Die Live-Prüfung war grün, das Backend lehnte trotzdem ab. | Gleiche Prüfungen (`MISSING`, `UNKNOWN_KEY`, `TYPE`, `WAVES`, `LEVEL_TERRAIN`). | `parity.test.js` (Konstanten gegen `content_model.py`/`ContentOverrides`), bestehende Tests in `levels.test.js` |
| 12 | Duplikate/Drift | `MAX_EXTRA_COUNT` war doppelt definiert (`waves.js`, `levels.js`), `SPAWNER_KINDS` doppelt zu `FACTIONS`. Die JS-Konstanten (`WAVE_RULES`, `AUTO`, Farben in `EnemyPainter`) waren nur von Hand gespiegelt. | Re-Export statt Kopie. Paritätstests lesen `game_config.gd`, `campaign.gd`, `content_overrides.gd`, `content_model.py`, `enemy_painter.gd`, `app_theme.gd` und `painter.gd`. | `tests/js/parity.test.js` (10 Tests) |
| 13 | Spielstand | Der Standort war nur als Index gespeichert und zeigte nach dem Umsortieren der Level auf ein anderes Gebiet. Regionen mit unbekannter ID wurden beim Laden verworfen und beim nächsten Speichern endgültig gelöscht, z. B. nach einem Test mit einem kürzeren Override. | Zusätzlich wird `location_id` gespeichert, beim Laden gilt die ID vor dem Index. Unbekannte Regionen bleiben in `_retained` und werden zurückgeschrieben; `reset_all` löscht sie. Alte v2-Spielstände ohne `location_id`/`seen` laden unverändert. | `test_location_is_restored_by_id_after_reordering`, `test_regions_of_unknown_levels_survive_a_save`, `test_old_version_two_saves_still_load` |
| 14 | i18n | `Texts.enemy_name/enemy_desc` gaben für Kinds ohne Übersetzung (Override-Kinds) den rohen Schlüssel zurück. | Lesbarer Fallback (`kind.capitalize()`) bzw. leerer Text, wie bei `building_desc`. Weil der Fallback den alten Namens-Test schwächer macht, prüft ein zusätzlicher Test die Schlüssel direkt. | `test_every_enemy_name_key_is_translated`, `test_override_kinds_without_texts_get_readable_fallbacks` |
| 15 | Tick-Last | `EnemyPainter.paint` schlug die Definition pro Gegner und Frame zweimal nach. `StatText.stats` rechnete den Panzer dreimal. `armor_reduction`/`mitigate` lasen die Konfiguration auch bei Panzer 0, dem häufigsten Fall. | Ein Lookup, eine lokale Variable, Schnellpfad bei Panzer ≤ 0 ohne Konfigurationszugriff. | Abgedeckt durch bestehende Tests und `test_parity.gd` |

## Geprüft ohne Befund

- **JS ↔ GDScript:**
  - `waves.js` `waveCount/waveTimes/waveTime/roundWaves` stimmen mit `Formulas.wave_*` und `SpawnDirector.send_wave` überein (Übertrag, Mindestwert 1). Der Spielertest simuliert echte Spawner-Wellen und erwartet `[2, 4, 6]`, genau wie der JS-Test.
  - `monsters.js` `buffFactor` entspricht `Formulas.enemy_buff`, `armor.js` entspricht `armor_reduction`/`mitigate`.
  - Die Tabelle und die Konstanten in `enemyPainter.js` (Form, Farben, Größen) entsprechen `EnemyPainter`.
  - `worldLayout.js` `autoPositions` entspricht `Campaign.layout`.
- **i18n:** Alle `Texts.t`-Schlüssel des Spiels existieren in `en` und `de` ohne leere Zellen, Platzhalter sind in beiden Sprachen gleich. Alle 30 Gegner haben Name und Beschreibung, alle 17 Gebäude eine Beschreibung. Die Editor-Wörterbücher sind laut `i18n.test.js` deckungsgleich.
- **Alte Spielstände:**
  - v1 wird weiter migriert.
  - v2-Spielstände ohne `seen`/`location_id` laden, IDs der Standardlevel sind unverändert.
  - Checkpoints enthalten keine Gegner; die neuen Gegnerfelder (`_armor`, `_speed_factor`) brauchen deshalb keine Migration.
- **Styling:**
  - Der Info-Bereich im Gebäudepanel folgt den Projektregeln (FEATURES.md: `AppTheme` + `UiKit` statt der Compose-Regeln): `UiKit.button` Variante „Button“ mit Material-Icon und Text wie die anderen Buttons, `Caption`-Label mit Umbruch, Abstände aus `AppTheme`.
  - Die Weltkarte nutzt nur `AppTheme`-Farben.
  - `fit()` wird pro Frame aufgerufen, Auf- und Zuklappen passt die Höhe also sofort an.
- **Balance:**
  - Kein Gegner erreicht mit allen Zuschlägen (Nacht + letztes Level) die Reduktionsgrenze. Das Maximum hat der Koloss: Panzer 147 entspricht 59,5 % Reduktion, die Grenze liegt bei 90 % (Test mit Abstand 0,2).
  - Jede Gegnerklasse kann von mindestens einem Turm getroffen werden.
  - Ein Zapper-Basistreffer liegt gegen jeden Gegner über dem Mindestschaden.

## Offene Punkte / Empfehlungen (nicht geändert)

1. **Zusatz-Wellen als Lastspitze:** `spawn_extra` erzeugt bis zu 200 Gegner in einem Tick, jeweils mit `nearest_free`. Besser wäre, sie über die `spawn_queue` und den Trickle-Takt zu verteilen. Die Tests in `test_extra_waves.gd` verlangen derzeit aber sofortiges Spawnen.
2. **Luft-Bosse ungenutzt:** `dreadwing` und `gunship` stehen in keinem Roster (Roster enthalten keine Flieger, Luftangriffe keine Bosse). Sie erscheinen nur über `extra_waves`.
3. **Balance mit Bot vermessen:**
  - Level-Zuschläge multiplizieren sich mit dem Tageswachstum. Beispiel Koloss in `final_war` an Tag 8 bei Nacht: etwa 22.200 HP und 59,5 % Reduktion, also rund 54.900 effektive HP. Der alte Behemoth kam an Tag 8 auf etwa 5.800.
  - Rechnerisch ist der Koloss nicht unbesiegbar, gemessen ist das aber noch nicht.
4. **Forschung bei kürzeren Overrides:** Hat ein Override weniger Level, sinken die verdienten SP. Das Laden setzt dann die Forschung zurück. Das betrifft nur Entwickler; die Regionen bleiben inzwischen erhalten.
5. **Parallel entstandene Dateien:** Bestiarium und Wellenvorschau (`sightings.gd`, `wave_preview.gd`, `bestiary_*`) sind nicht Teil dieses Reviews.

## Testläufe nach dem Review

- GUT (`-gdir=res://tests/unit`): 70 Skripte, 1017 Tests, 1015 grün. Rot sind nur 2 Tests in `test_release.gd` (`test_launcher_icons_exist_with_android_sizes`, `test_store_documents_exist_and_listings_fit_play_limits`). Diese Datei und die Store-Grafiken/-Unterlagen entstehen gerade parallel beim Store-Readiness-Agenten; mit diesem Review haben sie nichts zu tun.
- Editor JS (`node --test tests/js`): 247/247 grün.
- Editor Python (`python3 -m unittest discover -s tests/py -t .`): 206/206 grün.
