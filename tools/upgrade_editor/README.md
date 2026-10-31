# Upgrade-Editor

Web-App, die alle Gebäude mit ihren Upgrade-Pfaden zeigt und interaktiv anpassen lässt. Die Oberfläche ist dem Spiel nachempfunden (Baumenü, Gebäude-Bilder, Panel). Sie bearbeitet die Balance-Werte inklusive aller Basiswerte aus `src/core/game_config.gd`.

## Start

```
make upgrades
```

Der Server läuft auf dem festen Port 48731 und standardmäßig nur auf `127.0.0.1` (`--port` ändert den Port). Es gibt keinen Zugriffsschlüssel: Der Editor ist unter `http://127.0.0.1:48731/` erreichbar. Ohne Browser: `python3 -m upgrade_editor serve --no-browser` im Ordner `tools/upgrade_editor`.

Im lokalen Netz (z. B. Tablet): `make upgrades-lan` bzw. `serve --host 0.0.0.0`. Dann werden zusätzlich die LAN-Links ausgegeben. Zugriff nur aus privaten Adressbereichen (Loopback, 10.x, 172.16–31.x, 192.168.x, Link-Local). Die Verbindung ist unverschlüsseltes HTTP, also nur in vertrauenswürdigen Netzen nutzen.

Sicherheit (Details in `docs/security-review.md`): Host-Header-Prüfung gegen DNS-Rebinding (im Standardbetrieb nur `localhost`/`127.0.0.1`/`[::1]`), CSRF-Schutz für schreibende Aufrufe (Header `X-Upgrade-Editor: 1`, `Origin`/`Sec-Fetch-Site` müssen same-origin sein, `Content-Type: application/json`), Body bis 8 MiB, JSON ohne `NaN`/`Infinity` und mit höchstens 64 Ebenen (`upgrade_editor/safejson.py`), Socket-Timeout 20 s, höchstens 32 gleichzeitige Verbindungen, strikte Content-Security-Policy (`script-src 'self'`, keine Inline-Skripte oder -Styles, `frame-ancestors 'none'`) und weitere Sicherheits-Header auf jeder Antwort, Fehler als JSON ohne Stacktrace, statische Dateien nur aus `web/` mit erlaubten Endungen (kein `..`, keine versteckten Dateien, keine Symlinks nach außen). Die Validierung lässt nur endliche Zahlen bis 10¹⁵ (Inhalte bis 10⁹), Level-IDs und Monster-Aussehen aus `[A-Za-z0-9_-]{1,48}`, Formeln nur in der Grammatik von `web/js/expr.js` (`upgrade_editor/expr.py`) und begrenzte Listen zu; der Patcher schreibt nur Zahlenliterale und bekannte Bezeichner. Alle Dateien werden atomar geschrieben (`atomic_write`), Archive bekommen eindeutige Namen.

## Ablauf

1. Werte in der Oberfläche ändern (Tabs Gebäude, Übersicht, Pfade, Level, Monster & Wellen, Balance-Check, Änderungen).
2. Speichern erzeugt `data/game.edited.json`; danach wird nur noch die Kopie dargestellt. „Zurücksetzen“ archiviert sie.
3. `make upgrades-app-to-game` validiert die Kopie, schreibt die Werte in `src/core/game_config.gd`, archiviert das Original in `data/archive/` und übernimmt die Kopie als `data/game.json`. Mit `--no-ai` (über `tools/upgrade_editor/app-to-game.sh --no-ai`) entfällt der Claude-Aufruf. Der Aufruf läuft über `claude.sh` (`run_claude`): Prompt über stdin, nur die Werkzeuge Read, Edit, Write, Glob und Grep, `--permission-mode dontAsk`, keine MCP-Server; `CLAUDE_CMD` darf Zusatzargumente enthalten (Wortaufteilung ohne Globbing). Den Diff von `game_config.gd` schreibt das Skript nach `data/last_config.diff`.
4. Hat sich das Spiel geändert, `make upgrades-game-to-app` ausführen: `export_game.gd` (Godot über `GODOT` oder `G`) schreibt `data/game.json` neu.

## Inhalte: Panzerung, Monster, Wellen, Level

Das Dokument enthält zusätzlich `armor` (Panzerungs-Formel), `enemies` (alle Monster, Kind-Menge fest), `levels` (hinzufügen und löschen erlaubt, mindestens 1), `routes` (Weltkarten-Kanten) und je Gebäude `armor`/`description_key` (Vertrag: `docs/content-spec.md`). `export_game.gd` liest dafür `GameConfig` samt `data/content_overrides.json` und schreibt außerdem `defaults` (reine Standardwerte als Vergleichsbasis). Beim Anwenden entsteht `data/content_overrides.json` nur mit Abweichungen zu `defaults` (`armor`-Schlüssel, geänderte Monster komplett, `levels` komplett samt `routes`); sind alle Inhalte Standard, wird die Datei entfernt. Die Gebäude-Panzerung wird als Grundwert in `game_config.gd` geschrieben; der Upgrade-Pfad `armor` (alle Türme) multipliziert ihn im Spiel und ist wie jeder Pfad bearbeitbar (absoluter Zuwachs bezogen auf `buildings[*].armor`). Validierung: `upgrade_editor/content_model.py`.

## Reiter Level

Bearbeitet `levels` und `routes`: Liste mit Hinzufügen, Duplizieren, Löschen (mindestens 1) und Umsortieren (Wege werden mitgeführt), alle Level-Felder samt Beschreibung, Wellen mit Tag- und Nacht-Aufstellung (Monster per Dropdown mit Suchfeld, `searchSelect` in `web/js/views/components.js`), eine Weltkarten-Vorschau (Klick wählt, Ziehen setzt die Position, Wege hinzufügen/entfernen oder automatisch) und die Wellenstärke je Tag als Diagramm und Tabelle. Die Spiel-Formeln stehen gespiegelt in `web/js/waves.js` (`Formulas.wave_count`, `wave_times`, `enemy_hp_scale`, `enemy_damage_scale`, `enemy_bounty_scale`, Konstanten aus `GameConfig`) und müssen bei Änderungen dort nachgezogen werden; die automatische Platzierung der Weltkarte (`web/js/worldLayout.js`) spiegelt `Campaign.positions`. Die Live-Prüfung (`web/js/levels.js`) entspricht `content_model.py`.

## Reiter Monster & Wellen

Drei Unterbereiche in `web/js/views/monstersView.js` (Zustand `view.monsterUi`, i18n-Präfixe `monsters.`, `armor.`, `waves.`):

- **Monster:** Katalog mit Bildern (`web/js/enemyPainter.js`, Port von `src/ui/enemy_painter.gd`, gleiche Look-Tabelle; ein Test vergleicht sie mit der GDScript-Datei; animierte Canvas-Icons in `views/enemyIcon.js`), Filter und Suche (`monsters.js` `filterMonsters`). Das Detail (`views/monsterDetail.js`) bearbeitet Grundwerte, Flags und Zuschläge. Die Tabelle/das Diagramm „Stärke über Level und Tageszeit“ (`views/monsterStrength.js`, Metrik-Definition in `views/monsterMetrics.js`, Rechenlogik in `monsters.js`) spiegelt `Formulas.enemy_buff`: Wert = Grundwert × (1 + Nachtzuschlag × Nacht) × (1 + Levelzuschlag × Level-Index). Zellen-Edits (`editMonster`) ändern bei Level 1/Tag den Grundwert, bei anderen Tag-Zeilen den Level-Zuschlag, bei Nacht-Zeilen den Nacht-Zuschlag; Reduktion, Effektives Leben und Schaden/s laufen über Panzerung, Leben und Schaden. Der Entwurf (`view.monsterUi.drafts[kind]`) gilt erst nach „Anwenden“.
- **Panzerung:** `armor.js` spiegelt `Formulas.armor_reduction`/`mitigate`; Konstante, Obergrenze, Mindestschaden, Beispiel, Kurve und die editierbare Panzerungs-Tabelle (Grundwerte) aller Gebäude (`buildings[*].armor`) und Monster (`enemies[*].armor`).
- **Wellen & Tageszeiten:** nutzt `waveSettings`/`strengthPanel` aus `views/levelWaves.js` und `waves.js` (um `waveComposition`, `dayComposition`, `extraWavesAt` erweitert). Zusatz-Monster liegen am Level als optionales `extra_waves: [{day, night, kind, count}]` (Backend `content_model.py` Fehler `EXTRA_WAVE`, Spiel `Formulas.extra_waves`, `SpawnDirector.send_extras`, `ContentOverrides._extra_waves`).

## Bereiche und Zwischenüberschriften (`groups`)

Nur für den Editor: Upgrades (Schlüssel `Gebäude:Pfad`) lassen sich frei in Bereiche mit beliebig vielen Zwischenüberschriften einsortieren; ein Upgrade darf in beliebig vielen Bereichen und Zwischenüberschriften gleichzeitig stehen. Format im Dokument:

```json
"groups": [
  {"name": "Offensive", "items": ["zapper:power"], "sections": [{"name": "Schaden", "items": ["zapper:power", "laser:power"]}]}
]
```

`items` direkt am Bereich stehen ohne Zwischenüberschrift. Bearbeitet wird im Reiter Übersicht (`views/groupsPanel.js`: anlegen, umbenennen, löschen, hoch/runter, Upgrades per `searchSelect` hinzufügen/entfernen/sortieren; Bereichs-Filter gruppiert die Tabelle) und je Pfad im Gebäude-Panel (Zuordnung als Chips, „Zu Bereich hinzufügen …“). Logik und Live-Prüfung: `web/js/groups.js`. Backend: `model.py` `_check_groups` mit den Fehlern `GROUPS` (Aufbau, Limits 50 Bereiche/50 Zwischenüberschriften/500 Einträge), `GROUP_NAME` (leer oder länger als 60 Zeichen), `GROUP_DUPLICATE` (doppelter Name ohne Groß-/Kleinschreibung oder doppeltes Upgrade in einer Liste) und `GROUP_ITEM` (Gebäude unbekannt oder Pfad nicht in dessen `tracks`). `groups` gelangt nie ins Spiel (Patcher und Overrides ignorieren es), steht aber im Änderungs-Diff (`groups.order`, `groups.<Bereich>.items`, `.sections`, `.section.<Name>`). Erhalten bleibt es beim Übernehmen (`store.promote` schreibt die Kopie samt `groups` als neues Original, fehlt `groups` in einer älteren Kopie, kommt es aus dem Original: `keep_editor_data`) und beim Neuexport (`export_game.gd` übernimmt `groups` aus dem bisherigen `data/game.json` und lässt Upgrades weg, die es nicht mehr gibt). Entfernt man einen Pfad im Gebäude-Panel, verschwindet er auch aus allen Bereichen.

## Reiter Balance-Check

Rein lesend (`web/js/balance.js`, Ansicht `views/balanceView.js`, Sprungziele `views/navigation.js`). Vier Prüfungen mit einstellbaren Schwellen (nur Ansicht, `BALANCE_RULES`): Upgrade-Pfade mit einer Stufe unter 25 % (`minLevelShare`) des Medians von „Faktor Stufe“ aller Pfade auf derselben Stufe (`levelMedians`); Monster, die der stärkste Turm mit Grundwerten (Schaden ÷ Abklingzeit, Panzerung per `mitigate`, Dauerstrahl pro Tick wie im Spiel, ohne Kritische Treffer) nicht in 20 s (Bosse 90 s) schafft, gerechnet mit Level- und Nachtzuschlägen im ungünstigsten Level/Tageszeit, in dem das Monster vorkommt (Aufstellung, Zusatz-Monster, Luftangriffe); Aufstellungen ohne Monster der Stufe 0; Bosse vor Tag 3 (Stufe < 2 oder Zusatz-Monster vor Tag 3). Ein Klick springt in den passenden Reiter (Pfad aufgeklappt, Monster bzw. Level ausgewählt).

## Auswahllisten

Auswahlen mit mehr als vier Einträgen nutzen `searchSelect` (Dropdown mit Suchfeld); `choiceSelect`/`choiceField` in `components.js` entscheiden das automatisch, kleine feste Auswahlen (z. B. Modus, Klasse) bleiben native `<select>`. `searchSelect` zeigt mit `prompt` einen Platzhalter, solange nichts gewählt ist.

## Berechnungsarten je Upgrade

Pro Gebäude und Pfad (Zahnrad in der Upgrade-Zeile) wählbar:

- **Parameter:** wie bisher Stufen, Zuwachs, Preisfaktor, Wachstum (geteilte Pfade wirken auf alle Gebäude).
- **Formel:** Kostenformel und eine zweite Formel, für die man den Wert (Wert, Effizienz, Gesamteffizienz, Faktor) wählt; beide gelten pro Zeile (`level` = Nummer des Upgrades ab 1) als mathematischer Ausdruck. Variablen `level`, `base` (Upgrade-Basis), `build` (Baukosten), `max`, `growth`, `start` (Startwert des Pfads), in der zweiten Formel zusätzlich `cost`; Operatoren `+ - * / ^`, Klammern, Funktionen `min max abs sqrt exp ln log log10 floor ceil round pow sign`, Konstanten `pi e`. Der Parser (`web/js/expr.js`) ist ein eigener Rekursiv-Abstiegs-Parser ohne `eval`.
- **Tabelle:** Kosten und Wertzuwachs jeder Stufe frei setzen; Stufen lassen sich anhängen und entfernen.

Beim Wechsel bleiben die aktuellen Werte erhalten. Formel und Tabelle werden als Stufenliste gespeichert (`plans` im Dokument) und beim Übernehmen nach `data/upgrade_overrides.json` geschrieben, die das Spiel beim Start liest (`UpgradeOverrides`); Pfade im Parameter-Modus bleiben in `game_config.gd`.

## Kosten-Nutzen-Faktor

Relativer Effektzuwachs in Prozent pro 1.000 Kosten (`web/js/formulas.js`). Höher ist besser.

## Tests

```
make upgrades-test
```

Python (`tests/py`, unittest) und JavaScript (`tests/js`, `node --test`). Die JS-Kosten werden gegen die vom Spiel exportierten Kosten geprüft; der Patcher muss die unveränderte Datei exakt reproduzieren. Bereiche: `tests/py/test_groups.py`, `tests/js/groups.test.js`; Balance-Check: `tests/js/balance.test.js`; Auswahllisten: `tests/js/selects.test.js`.
