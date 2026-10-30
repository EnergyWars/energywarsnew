# Upgrade-Editor

Web-App, die alle Gebäude mit ihren Upgrade-Pfaden zeigt und interaktiv anpassen lässt. Die Oberfläche ist dem Spiel nachempfunden (Baumenü, Gebäude-Bilder, Panel). Sie bearbeitet die Balance-Werte inklusive aller Basiswerte aus `src/core/game_config.gd`.

## Start

```
make upgrades
```

Der Server läuft auf dem festen Port 48731 auf allen Netzwerkschnittstellen (`--host 127.0.0.1` beschränkt auf den eigenen Rechner, `--port` ändert den Port). Beim Start werden die Adressen für das lokale Netz ausgegeben. Zugriff nur aus privaten Adressbereichen (Loopback, 10.x, 172.16–31.x, 192.168.x, Link-Local), Host-Header-Prüfung gegen DNS-Rebinding, keine Anmeldung und öffnet den Browser. Ohne Browser: `python3 -m upgrade_editor serve --no-browser` im Ordner `tools/upgrade_editor`.

## Ablauf

1. Werte in der Oberfläche ändern (Tabs Gebäude, Übersicht, Pfade, Änderungen).
2. Speichern erzeugt `data/game.edited.json`; danach wird nur noch die Kopie dargestellt. „Zurücksetzen“ archiviert sie.
3. `make upgrades-app-to-game` validiert die Kopie, schreibt die Werte in `src/core/game_config.gd`, archiviert das Original in `data/archive/` und übernimmt die Kopie als `data/game.json`. Mit `--no-ai` (über `tools/upgrade_editor/app-to-game.sh --no-ai`) entfällt der Claude-Aufruf.
4. Hat sich das Spiel geändert, `make upgrades-game-to-app` ausführen: `export_game.gd` (Godot über `GODOT` oder `G`) schreibt `data/game.json` neu.

## Berechnungsarten je Upgrade

Pro Gebäude und Pfad (Zahnrad in der Upgrade-Zeile) wählbar:

- **Parameter:** wie bisher Stufen, Zuwachs, Preisfaktor, Wachstum (geteilte Pfade wirken auf alle Gebäude).
- **Formel:** Kostenformel (Kosten von Stufe `level` auf `level + 1`) und Nutzenformel (Wirkung auf Stufe `level`, Stufe 0 = Ausgangswert) als mathematischer Ausdruck. Variablen `level`, `base` (Upgrade-Basis), `build` (Baukosten), `max`, `growth`; Operatoren `+ - * / ^`, Klammern, Funktionen `min max abs sqrt exp ln log log10 floor ceil round pow sign`, Konstanten `pi e`. Der Parser (`web/js/expr.js`) ist ein eigener Rekursiv-Abstiegs-Parser ohne `eval`.
- **Tabelle:** Kosten und Wertzuwachs jeder Stufe frei setzen; Stufen lassen sich anhängen und entfernen.

Beim Wechsel bleiben die aktuellen Werte erhalten. Formel und Tabelle werden als Stufenliste gespeichert (`plans` im Dokument) und beim Übernehmen nach `data/upgrade_overrides.json` geschrieben, die das Spiel beim Start liest (`UpgradeOverrides`); Pfade im Parameter-Modus bleiben in `game_config.gd`.

## Kosten-Nutzen-Faktor

Relativer Effektzuwachs in Prozent pro 1.000 Kosten (`web/js/formulas.js`). Höher ist besser.

## Tests

```
make upgrades-test
```

Python (`tests/py`, unittest) und JavaScript (`tests/js`, `node --test`). Die JS-Kosten werden gegen die vom Spiel exportierten Kosten geprüft; der Patcher muss die unveränderte Datei exakt reproduzieren.
