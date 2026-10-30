Upgrade-Editor -> Spiel anwenden.

Das Skript hat soeben `tools/upgrade_editor/data/game.edited.json` validiert und per `python3 -m upgrade_editor apply` in `src/core/game_config.gd` geschrieben (`TRACKS`, `TRACK_GROWTH`, `WALL_HULL`, je Gebäude `cost`, `upgrade_base`, `hp`, `tracks`). Das Original wurde unter `tools/upgrade_editor/data/archive/` archiviert, `game.json` ist jetzt der neue Stand. Die Änderungsliste steht in `tools/upgrade_editor/data/last_changes.jsonl`.

Aufgaben:
1. Prüfe `git diff src/core/game_config.gd`: Es dürfen nur Werte der oben genannten Felder geändert sein.
2. Passe Tests an, die feste Werte der alten Daten annehmen (z. B. `tests/unit/test_config.gd`, `test_formulas.gd`, `test_economy.gd`, `test_battle.gd`). Die Tests sind die Wahrheit für das Verhalten; ändere nur Daten-Annahmen, nicht die Logik. Führe keine Gradle-Befehle und keine Godot-Tests aus, prüfe sie nur gedanklich.
3. Kosten-Nutzen-Faktor: Erstelle für jedes geänderte Upgrade-Pfad-Paar einen Bericht vorher/nachher (Faktor = relativer Effektzuwachs in % pro 1.000 Kosten, Definition in `tools/upgrade_editor/web/js/formulas.js`, `benefitTotal`). Weise auf stark verbesserte oder verschlechterte Pfade hin.
4. Aktualisiere `docs/gebaeude-upgrades.md` passend zu den neuen Werten, `FEATURES.md` und `context.md` nur bei Funktionsänderungen (context.md nur aktueller Stand).

Regeln: keine Code-Kommentare, UI-Texte nur über i18n (de + en Fallback), keine Gradle-Befehle. Berichte am Ende auf Deutsch.
