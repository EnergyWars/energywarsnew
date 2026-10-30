# Sicherheits-Review

Stand: 30.10.2026. Geprüft wurden das Spiel (`src/`, Android-Export), der Upgrade-Editor (`tools/upgrade_editor`: Python-Server, Web-App, Patcher, Shell-Skripte, Prompts) und das Repository. Maßstab: OWASP Top 10 (2021), Angriffe aus dem lokalen Netz und aus dem Browser (CSRF, DNS-Rebinding), Dateisystem (Traversal, atomisches Schreiben), Injection (GDScript, Shell, Prompt) und manipulierte Spieldateien.

Jedes Finding ist behoben und durch mindestens einen Regressionstest abgesichert. Die Tests laufen mit

```
cd tools/upgrade_editor && node --test tests/js && python3 -m unittest discover -s tests/py -t .
G=~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
$G --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gselect=test_security -gexit
```

## Schweregrade

| Stufe | Bedeutung |
|---|---|
| Hoch | Fremder Code oder fremde Werte können ohne Zutun des Entwicklers ins Spiel oder auf den Rechner gelangen |
| Mittel | Ausnutzbar unter Voraussetzungen (Zugriff aufs Netz, auf Dateien oder auf ein Backup) oder mit Folgen für Integrität und Verfügbarkeit |
| Niedrig | Härtung, Informationsabfluss oder Verfügbarkeit ohne direkten Schaden |

## Übersicht

| Nr. | Bereich | Finding | Stufe |
|---|---|---|---|
| S-01 | Editor-Server | Bindung an alle Schnittstellen ohne Authentifizierung | Hoch |
| S-02 | Patcher | Werte gelangen ungeprüft als GDScript-Quelltext in `game_config.gd` | Hoch |
| S-03 | Skripte | Claude-Aufruf mit allen lokal freigegebenen Werkzeugen auf ungeprüften Editor-Daten | Hoch |
| S-04 | Editor-Server | Robustheit beim Einlesen von Anfragen (Content-Length, NaN, Tiefe, große Zahlen) | Mittel |
| S-05 | Validierung | Absturz bei falschen Typen, unbekannte und schreibgeschützte Felder änderbar | Mittel |
| S-06 | Validierung | Formeln und Plan-Felder als Freitext (Prompt-Injection-Kanal) | Mittel |
| S-07 | Validierung | Level-ID und Aussehen als Freitext, unbegrenzte Listen und Größen | Mittel |
| S-08 | Editor-Server, Web | Keine Security-Header und keine CSP, Inline-Styles verhindern eine strikte CSP | Mittel |
| S-09 | Dateisystem | Nicht atomisches Schreiben, Archive überschreiben sich, `promote` halb ausgeführt | Mittel |
| S-10 | Web-App | Prototype-Pollution über Store-Pfade | Mittel |
| S-11 | Spiel | `ConfigFile` instanziiert Objekte aus der Einstellungsdatei (Codeausführung) | Mittel |
| S-12 | Editor-Server | CSRF nur über einen Pflicht-Header abgesichert | Niedrig |
| S-13 | Editor-Server | Host-Prüfung im Loopback-Betrieb zu breit | Niedrig |
| S-14 | Editor-Server | Fehlerseiten mit Details, Python-Version im Server-Header, absoluter Archivpfad | Niedrig |
| S-15 | Editor-Server | Statische Dateien: Dotfiles, beliebige Endungen, Null-Bytes, Kodierung | Niedrig |
| S-16 | Editor-Server | Unbegrenzte Threads ohne Timeout (Slowloris) | Niedrig |
| S-17 | Spiel | Spielstand: Skriptfehler bei falschen Typen, unbegrenzte Werte und Daten | Niedrig |
| S-18 | Spiel | Overrides unter `data/`: Typen, Mengen und Dateigröße unbegrenzt | Niedrig |

## Findings

### S-01 Bindung an alle Schnittstellen ohne Authentifizierung (Hoch)

**Befund:** `make upgrades` band den Server an `0.0.0.0`. Jeder Rechner aus einem privaten Adressbereich (WLAN, Gäste-WLAN, VPN) konnte das Dokument lesen, speichern und zurücksetzen, ohne Anmeldung. Der Pflicht-Header schützt nur vor Browsern, nicht vor `curl`. Über `make upgrades-app-to-game` landen gespeicherte Werte im Spielcode und im Claude-Prompt (siehe S-02, S-03).

**Fix:**
- Standard-Host ist `127.0.0.1` (`__main__.DEFAULT_HOST`). Das LAN ist nur noch ausdrücklich erreichbar über `make upgrades-lan` bzw. `--host 0.0.0.0`.
- Nachträglich entfernt: Der Zugriffsschlüssel (Token) wurde auf Wunsch abgeschafft. Es bleiben Loopback-Bindung, Host-Prüfung (DNS-Rebinding) und die CSRF-Schutzmaßnahmen aus S-02; im LAN-Modus kann jeder Rechner aus einem privaten Adressbereich den Editor nutzen.

### S-02 GDScript-Injection im Patcher (Hoch)

**Befund:** `patcher.py` hat Werte mit `str()`/`repr()` in `src/core/game_config.gd` eingesetzt und die Ersetzungen als `re.sub`-Vorlage übergeben (Backslash-Sequenzen werden dort interpretiert). Der Patcher hat sich vollständig auf die Validierung verlassen, und die ließ sich über falsche Typen umgehen (S-05). Außerdem akzeptierte `json.loads` die Werte `NaN` und `Infinity`, die als `nan`/`inf` ein ungültiges Skript ergeben. Da `game_config.gd` mit dem Spiel ausgeliefert wird, hätte eingeschleuster Quelltext in der App landen können.

**Fix:**
- Jede Zahl muss vor dem Schreiben auf das Literal-Muster `NUMBER_LITERAL` passen. Ganzzahlen dürfen keinen Nachkommaanteil haben, Beträge sind auf ≤ 10¹⁵ begrenzt.
- Bezeichner (Gebäude, Pfade, Stats) müssen auf `IDENTIFIER` passen und bekannt sein; unbekannte Stats führen zu `UnsafeValue`.
- Alle Ersetzungen laufen über Lambdas, Suchmuster über `re.escape`.
- Zusätzlich lehnt `safejson.loads` nicht endliche Zahlen schon beim Einlesen ab, und `model._is_number` verlangt endliche Werte innerhalb der Grenze.

**Tests:**
- `tests/py/test_security.py`:
  - `PatcherInjectionTest` (vier Tests, u. a. Code-Fragmente, `nan`, `±inf`, falsche Typen sowie Bezeichner mit Zeilenumbrüchen, Leerzeichen und Pfaden)
  - `ValidationHardeningTest.test_non_finite_and_huge_numbers_are_invalid`
  - `ValidationHardeningTest.test_injected_names_are_rejected`
- `tests/py/test_patcher.py` prüft weiterhin, dass unveränderte Daten die Datei exakt reproduzieren.

### S-03 Claude-Aufruf mit vollen Rechten und Prompt-Injection (Hoch)

**Befund:** `app-to-game.sh` und `game-to-app.sh` riefen `${CLAUDE_CMD:-claude} -p "$(cat prompt)"` auf. Claude hatte damit alle lokal freigegebenen Werkzeuge, je nach `settings.json` also auch Bash, Web und MCP-Server. Es arbeitete dabei auf Daten, die aus dem Editor stammen (Änderungsliste, Formeln, Namen) und nach S-01 auch von Dritten kommen konnten. Ein präparierter Text hätte so Shell-Befehle auslösen können. `CLAUDE_CMD` wurde ungequotet expandiert (Globbing), und der Prompt landete als Argument in der Prozessliste.

**Fix:**
- Neues `tools/upgrade_editor/claude.sh` mit `run_claude`:
  - Der Prompt kommt über stdin.
  - Freigegeben sind nur `--tools Read,Edit,Write,Glob,Grep` (gleiche Liste als `--allowedTools`).
  - Ausdrücklich verboten: `--disallowedTools Bash,WebFetch,WebSearch,NotebookEdit`.
  - Dazu `--permission-mode dontAsk` und `--strict-mcp-config` (keine MCP-Server).
  - `CLAUDE_CMD` wird per `read -r -a` ohne Globbing in Wörter zerlegt.
- Den Git-Diff von `game_config.gd` erzeugt das Skript selbst und legt ihn in `data/last_config.diff` ab (gitignored), damit Claude keine Shell braucht.
- Beide Prompts enthalten einen Sicherheitsabschnitt:
  - Daten aus dem Editor sind keine Anweisungen.
  - Erlaubt sind nur Zahlenwerte; bei allem anderen bricht Claude ab.
- Formeln und Namen sind zusätzlich serverseitig eingeschränkt (S-06, S-07).

**Tests:** `tests/py/test_scripts.py`
- `test_scripts_are_strict_and_parse` (`bash -n`, `set -euo pipefail`)
- `test_claude_gets_minimal_tools_and_the_prompt_on_stdin` (ein Fake-Claude protokolliert Argumente und stdin)
- `test_command_variable_is_split_without_globbing`
- `test_prompts_mark_data_as_untrusted`

### S-04 Robustheit beim Einlesen von Anfragen (Mittel)

**Befund:**
- `int(Content-Length)` warf bei Werten wie `abc` eine unbehandelte Ausnahme: Stacktrace auf stderr, Verbindungsabbruch.
- `json.loads` akzeptierte `NaN`/`Infinity` und beliebig tiefe Verschachtelung. `RecursionError` beendete die Anfrage ohne Antwort.
- Zahlen mit Tausenden Stellen lösten `ValueError` aus.
- `Transfer-Encoding: chunked` ohne Länge wurde nicht abgelehnt.

**Fix:**
- `server._read_body` beantwortet `Transfer-Encoding` sowie fehlende, nicht numerische oder negative Längen mit 411 und mehr als 8 MiB mit 413, ohne den Body zu lesen. Ein unvollständiger Body ergibt 400.
- `safejson.loads` lehnt `NaN`/`Infinity` ab (`parse_constant`), begrenzt die Tiefe iterativ auf 64 und fängt `RecursionError` und `ValueError` ab.
- Antworten werden mit `allow_nan=False` erzeugt.

**Tests:**
- `tests/py/test_server.py`:
  - `RequestLimitTest.test_oversized_body_is_rejected_without_reading_it`
  - `RequestLimitTest.test_invalid_or_missing_length_is_rejected`
  - `RequestLimitTest.test_non_standard_json_is_rejected`
  - `RequestLimitTest.test_deeply_nested_json_is_rejected`
  - `RequestLimitTest.test_huge_numbers_are_rejected`
- `tests/py/test_security.py`: `SafeJsonTest` (drei Tests)

### S-05 Validierung: Absturz bei falschen Typen, unbekannte Felder (Mittel)

**Befund:** `model.validate` und `content_model` setzten Typen voraus. Eine Liste statt eines Objekts oder `null` statt einer Zahl führte zu `TypeError`/`AttributeError` und damit zu einem Absturz der Anfrage ohne Antwort, schlimmstenfalls zu ungeprüften Daten beim Speichern. Unbekannte Gebäudeschlüssel und die schreibgeschützten Felder `description_key` und `cost_every` ließen sich frei ändern.

**Fix:**
- `model.safe_validate` fängt Typfehler ab und meldet `TYPE` bzw. `MALFORMED` (fail closed). `store.validate`, `save_edited` und `promote` verwenden es.
- `_check_building` meldet `UNKNOWN_KEY` und `READONLY`.
- Die Mengenprüfungen laufen erst nach den Typprüfungen.

**Tests:**
- `tests/py/test_security.py`:
  - `ValidationHardeningTest.test_random_type_mutations_never_crash_validation` (600 zufällige Typmutationen des echten Dokuments)
  - `ValidationHardeningTest.test_unknown_and_read_only_building_fields_are_rejected`
  - `StoreSafetyTest.test_malformed_documents_are_rejected_on_save`
- `tests/py/test_server.py`: `RequestLimitTest.test_malformed_documents_fail_validation_instead_of_crashing`

### S-06 Formeln und Plan-Felder als Freitext (Mittel)

**Befund:** Upgrade-Pläne (`plans`) durften beliebige Felder enthalten, Formeln (`cost`, `effect`, `formula_history`) beliebigen Text in beliebiger Länge. Diese Texte gelangten in `game.json`, `last_changes.jsonl` und damit in den Claude-Prompt (Kanal für Prompt-Injection), außerdem in `data/upgrade_overrides.json` im Spiel.

**Fix:**
- `model.PLAN_KEYS` lässt nur bekannte Plan-Felder zu.
- Formeln sind höchstens 500 Zeichen lang (der Parser begrenzt auf 400) und müssen sich mit `upgrade_editor/expr.py` parsen lassen. Das ist ein Port der Grammatik aus `web/js/expr.js`: nur die Variablen `level`, `base`, `build`, `max`, `growth` sowie die bekannten Funktionen und Konstanten; Rekursionstiefe abgesichert.
- `overrides.EXPORTED_PLAN_KEYS` schreibt nur `mode`, `max`, `cost` und `effect` in die Spieldatei.

**Tests:**
- `tests/py/test_security.py`:
  - `FormulaValidationTest` (drei Tests)
  - `ValidationHardeningTest.test_plans_only_carry_known_fields_and_short_formulas`
  - `StoreSafetyTest.test_upgrade_overrides_only_export_known_plan_fields`
- `tests/js/security.test.js`: „formulas cannot reach object internals and stay fast on hostile input“ (feindliche Eingaben bis 400 Zeichen, zusammen unter 500 ms)

### S-07 Inhalte: Freitext-IDs und unbegrenzte Mengen (Mittel)

**Befund:** Level-`id` und Monster-`look` waren beliebige Texte, und die Listen (Aufstellung, Zusatz-Wellen, Bauwerke, Herausforderungen, Hochebenen, Wege) hatten keine Obergrenze, ebenso Geländezähler, Wellenwerte und Zeiten. Ein Dokument mit Millionen Einträgen oder Geländezählern von 10⁹ hätte den Kartenaufbau im Spiel blockiert und das Spiel mit Speicher überlastet.

**Fix:**
- `content_model.py`:
  - `IDENTIFIER` = `[A-Za-z0-9_-]{1,48}` für `id` und `look`
  - `MAX_ITEMS` 64 je Liste, `MAX_ROUTES` 2000, `MAX_TERRAIN` 100
  - Obergrenzen für Wellenabstand, Wellenfaktoren (1000), Zeiten (3600 s), Tag der Zusatz-Wellen (10000), Gewichte, Spot-Größen und Offsets
  - Beträge bis 10⁹; neuer Fehlercode `LIMIT`
- `web/js/levels.js` spiegelt alle Grenzen für die Live-Prüfung.
- Das Spiel klemmt dieselben Werte beim Laden zusätzlich (S-18).

**Tests:**
- `tests/py/test_security.py`: `ValidationHardeningTest.test_content_lists_and_magnitudes_are_limited`
- `tests/js/security.test.js`: „level ids and lists are limited like the server validation“
- `tests/js/security.test.js`: „every validation error code and the access message are translated“

### S-08 Security-Header und CSP fehlten (Mittel)

**Befund:** Die Antworten hatten weder eine Content-Security-Policy noch `X-Content-Type-Options` oder `X-Frame-Options`. Die Seite ließ sich daher einbetten (Clickjacking), und eine künftige XSS-Lücke hätte Inline-Skripte nachladen können. SVG-Elemente bekamen ihre Styles per `setAttribute("style")`, das mit einer strikten CSP (ohne `unsafe-inline`) blockiert wird.

**Fix:**
- Jede Antwort (auch Fehler) trägt:
  - `Content-Security-Policy: default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`
  - `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`
  - `Cross-Origin-Opener-Policy`/`-Resource-Policy: same-origin`, `Permissions-Policy`, `Cache-Control: no-store`
- `components.svgNode` setzt Styles über `node.style.cssText` (CSSOM, von der CSP erlaubt).
- `index.html` enthält keine Inline-Skripte oder -Styles.

**Tests:**
- `tests/py/test_server.py`: `SecurityHeaderTest` (vier Tests)
- `tests/js/security.test.js`: „svg styles go through the CSS object model, not inline style attributes“

### S-09 Nicht atomisches Schreiben und überschreibende Archive (Mittel)

**Befund:**
- `game.edited.json`, `game.json`, `content_overrides.json`, `upgrade_overrides.json` und `game_config.gd` wurden direkt überschrieben. Ein Abbruch mitten im Schreiben hinterließ halbe Dateien.
- Archive mit Sekunden-Zeitstempel überschrieben sich bei zwei Aktionen in derselben Sekunde.
- `promote` schrieb schrittweise und ließ bei einem Fehler in der Mitte einen gemischten Zustand zurück.
- Ein Symlink an der Zielstelle wäre verfolgt worden.

**Fix:**
- `safejson.atomic_write`: temporäre Datei im Zielordner (`mkstemp`), `fsync`, alter Dateimodus, `os.replace`; bei Fehlern wird die temporäre Datei entfernt. Ein Symlink am Ziel wird ersetzt, nicht verfolgt.
- `store._archive_target` legt Archivnamen exklusiv an (Modus `x`, bis zu 1000 Versuche).
- `promote` berechnet erst alle Ergebnisse (Patch, Overrides, Inhalte) und schreibt dann.

**Tests:** `tests/py/test_security.py`
- `AtomicWriteTest` (drei Tests)
- `StoreSafetyTest.test_archives_never_overwrite_each_other`
- `StoreSafetyTest.test_failed_promote_leaves_every_file_untouched`
- `StoreSafetyTest.test_saved_files_are_strict_json`

### S-10 Prototype-Pollution in der Web-App (Mittel)

**Befund:** `store.setPath` und `unset` gingen Pfade ohne Prüfung durch und legten fehlende Zwischenobjekte an. Pfadsegmente stammen teils aus Dokumentschlüsseln (Gebäude, Monster, Level). Ein Segment wie `__proto__` oder `constructor` hätte `Object.prototype` verändert, und das hätte die ganze Web-App beeinflusst.

**Fix:** `store.js`:
- `FORBIDDEN_KEYS` (`__proto__`, `prototype`, `constructor`) werden abgelehnt.
- `parentOf` folgt nur eigenen Eigenschaften (`Object.hasOwn`) und legt keine Zwischenobjekte an.
- `unset` nutzt das gemeinsame `unsetPath`.

**Tests:** `tests/js/security.test.js`
- „store paths cannot reach prototypes or create missing parents“
- „documents with a __proto__ key stay plain data“

### S-11 Codeausführung über die Einstellungsdatei (Mittel)

**Befund:** `AppSettings` las `user://settings.cfg` mit `ConfigFile`. Eine Probe hat belegt, dass `ConfigFile` (wie `str_to_var`) Werte der Form `Object(Script, "script": …)` instanziiert und das `_init` eines Skripts ausführt. Wer die Datei manipulieren kann, führt damit Code in der App aus. Wege dorthin: Wiederherstellung eines Android-Backups (`user_data_backup/allow=true`), Desktop-Builds, gerootete Geräte.

**Fix:**
- Einstellungen liegen jetzt als JSON in `user://settings.json`, gelesen über `SafeFile.read_json` (höchstens 64 KiB) und typgeprüft angewendet (`_apply`).
- Eine vorhandene `settings.cfg` wird einmalig über `AppSettings.parse_legacy` übernommen. Der Parser liest nur Zeilen der Form `locale="de"`, `sound=true` und `haptics=false` (nur `true`/`false` und bekannte Sprachen) und instanziiert nie Objekte.
- Nach dem nächsten Speichern wird die alte Datei gelöscht.

**Tests:** `tests/unit/test_security.gd`
- `test_the_probe_detects_object_instantiation` (Beleg für die Gefahr)
- `test_settings_never_instantiate_objects_from_files`
- `test_legacy_settings_migrate_to_json`
- `test_legacy_parser_only_accepts_plain_values`
- `test_settings_reject_wrong_types_and_oversized_files`
- `test_default_settings_path_is_json`
- Weiterhin grün: `test_sound.gd` und `test_settings_and_numbers.gd`

### S-12 CSRF nur über einen Pflicht-Header (Niedrig)

**Befund:** Schreibende Aufrufe verlangten nur `X-Upgrade-Editor: 1`. Das erzwingt bei fremden Seiten einen CORS-Preflight und schützt damit im Grundsatz. `Origin`, `Sec-Fetch-Site` und `Content-Type` wurden aber nicht geprüft, sodass der Schutz von einem einzigen Mechanismus abhing.

**Fix:** `server._check_mutation` verlangt den Pflicht-Header. Ein vorhandenes `Origin` muss `http://{Host}` sein, `Sec-Fetch-Site` nur `same-origin` oder `none`, und `Content-Type: application/json` (sonst 415).

**Tests:** `tests/py/test_server.py`
- `CsrfTest` (drei Tests)
- `ServerTest.test_mutations_need_guard_header`

### S-13 Host-Prüfung im Loopback-Betrieb zu breit (Niedrig)

**Befund:** `host_name_allowed` akzeptierte auch beim Betrieb auf `127.0.0.1` jede IP-Adresse und den Rechnernamen mit `.local`, `.lan` und `.fritz.box` als Host-Header. Für den Schutz gegen DNS-Rebinding reicht im Loopback-Betrieb `localhost`.

**Fix:** `host_name_allowed(name, loopback_only)` lässt im Standardbetrieb nur `localhost`, `127.0.0.1` und `[::1]` zu. Die LAN-Namen gelten nur mit `--host 0.0.0.0`. Port und Client-Adresse (privat) werden weiterhin geprüft.

**Tests:** `tests/py/test_server.py`
- `ServerTest.test_loopback_server_rejects_lan_host_names`
- `ServerTest.test_foreign_host_is_rejected`
- `NetworkTest.test_loopback_only_host_names`
- `NetworkTest.test_host_names`

### S-14 Informationsabfluss über Fehler (Niedrig)

**Befund:**
- Unbehandelte Ausnahmen schrieben Stacktraces auf stderr und brachen die Verbindung ab.
- Nicht unterstützte Methoden lieferten die Standard-HTML-Fehlerseite.
- Der `Server`-Header verriet die Python-Version.
- „Zurücksetzen“ gab den absoluten Archivpfad zurück.

**Fix:**
- `_guarded` antwortet bei unerwarteten Fehlern mit `500 {"error":"INTERNAL"}` und protokolliert nur den Typnamen.
- `error_message_format` ist JSON, und `version_string` liefert nur `UpgradeEditor`.
- Reset gibt nur den Dateinamen des Archivs zurück.

**Tests:** `tests/py/test_server.py`
- `ErrorPageTest` (drei Tests)
- `ServerTest.test_save_reset_cycle`

### S-15 Auslieferung statischer Dateien (Niedrig)

**Befund:** Der Pfad wurde nicht dekodiert, versteckte Dateien und beliebige Endungen wurden ausgeliefert, und der MIME-Typ hing von der Systemkonfiguration ab (`mimetypes`). Null-Bytes erzeugten eine Ausnahme. Traversal war bereits durch `resolve()` verhindert.

**Fix:** `server.static_target`:
- Der Pfad wird strikt dekodiert.
- Abgelehnt werden Null-Bytes, Backslashes, leere Segmente, `..` und Segmente, die mit `.` beginnen.
- Erlaubt sind nur die Endungen aus `STATIC_TYPES`, jeweils mit festem Content-Type.
- Das Ziel muss nach `resolve()` innerhalb von `web/` liegen (`is_relative_to`, deckt auch Symlinks ab).

**Tests:** `tests/py/test_server.py`
- `StaticPathTest` (zwei Tests)
- `ServerTest.test_static_index_and_traversal`
- `SecurityHeaderTest.test_static_content_types_are_explicit`

### S-16 Unbegrenzte Threads ohne Timeout (Niedrig)

**Befund:** `ThreadingHTTPServer` startete für jede Verbindung einen Thread, ohne Socket-Timeout. Offene, langsame Verbindungen (Slowloris) konnten Threads unbegrenzt binden.

**Fix:** `EditorServer` begrenzt die Zahl gleichzeitiger Verbindungen auf 32 (`BoundedSemaphore`, überzählige Verbindungen werden sofort geschlossen), und der Handler hat ein Timeout von 20 s.

**Tests:** `tests/py/test_server.py`
- `ConnectionLimitTest.test_excess_connections_are_closed`
- `RequestLimitTest.test_handler_has_a_socket_timeout`

### S-17 Spielstand: Typen, Werte und Datenmenge (Niedrig)

**Befund:**
- `Progress` rief `int()` auf Rohdaten auf. `int(null)` oder `int([])` erzeugen in Godot einen Skriptfehler, und Werte wie `1e300` liefen über.
- Unbekannte Gebiete (`retained`) wurden ungeprüft und unbegrenzt mitgeschleppt.
- Die Datei hatte keine Größengrenze.
- Zugang: Backup-Wiederherstellung, Desktop-Builds.

**Fix:**
- `SafeFile.read_json(path, max_bytes)` liest nur Dateien bis 1 MiB und liefert bei Fehlern `null`.
- `Progress._int` akzeptiert Ganzzahlen, endliche Fließkommazahlen und numerische Texte (z. B. `"4"`, geprüft mit `is_valid_float`), klemmt auf ±10¹⁵ und liefert sonst 0.
- `retained` ist auf 256 Gebiete begrenzt; IDs bis 48 Zeichen, Inhalte werden bereinigt (`_sanitize_retained`).

**Tests:**
- `tests/unit/test_security.gd`:
  - `test_progress_survives_manipulated_types`
  - `test_progress_numbers_are_clamped`
  - `test_retained_regions_are_bounded_and_sanitized`
  - `test_oversized_or_broken_saves_are_ignored`
  - `test_safe_file_reads_bounded_json_only`
- `tests/unit/test_progress.gd`: `test_invalid_data_is_sanitized` (numerische Texte bleiben gültig)

### S-18 Overrides unter `data/` (Niedrig)

**Befund:** `data/content_overrides.json` und `data/upgrade_overrides.json` werden mit dem Spiel ausgeliefert. Manipulieren lassen sie sich nur über die Build-Kette (Editor, siehe S-01/S-07). Das Laden prüfte Typen nur teilweise und begrenzte weder Mengen noch Dateigröße. Unbekannte Level-Felder blieben erhalten, und die Wege-Deduplizierung lief in O(n²).

**Fix:**
- `ContentOverrides`:
  - liest höchstens 4 MiB über `SafeFile.read_json`
  - höchstens 200 Gebiete, je Liste 64 Einträge (`_head`), 2000 Wege mit Dictionary-Deduplizierung
  - Geländezähler bis 100, Offsets und Spot-Größen auf die Kartengröße geklemmt
  - IDs und Aussehen bis 48 Zeichen; unbekannte Level-Felder werden verworfen
- `UpgradeOverrides` prüft Typen je Ebene (`_build`, `_levels`), begrenzt auf 200 Stufen und klemmt Kosten auf 1..10¹².

**Tests:**
- `tests/unit/test_security.gd`:
  - `test_content_overrides_cap_sizes`
  - `test_content_overrides_reject_long_texts`
  - `test_upgrade_overrides_survive_broken_plans`
- Weiterhin grün: `test_content_overrides.gd`, `test_upgrade_overrides.gd`, `test_campaign_dynamic.gd`

## Geprüft ohne Befund

Diese Punkte sind jeweils durch einen Regressionstest gegen spätere Rückschritte abgesichert, sofern einer genannt ist.

- **XSS in der Web-App:**
  - Alle Inhalte entstehen über `h()` bzw. `svgNode` als Textknoten. Es gibt kein `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval` oder `new Function`.
  - Tests in `security.test.js`: „the web app never renders markup from strings or evaluates code“ und „text from the document is rendered as text nodes“.
- **`expr.js`:**
  - Ein eigener Parser ohne `eval`. Variablen und Funktionen werden per `Object.hasOwn` gelesen, damit `constructor`, `__proto__` und `toString` nicht erreichbar sind.
  - Lineare Laufzeit, es gibt keine ReDoS-anfälligen Regex (Test siehe S-06).
- **Spielcode (statischer Scan):**
  - Nicht verwendet werden `ConfigFile`, `str_to_var`, `bytes_to_var`, `get_var`, `OS.execute`/`create_process`/`shell_open`, `HTTPRequest`, `HTTPClient`, `WebSocket`, `StreamPeerTCP`, `PacketPeerUDP`, `JavaScriptBridge` sowie `print`-Ausgaben.
  - Test: `test_security.gd` `test_game_code_avoids_unsafe_apis_and_debug_output`.
- **Android-Export:**
  - Nur die Berechtigung Vibration.
  - `tests/`, `tools/`, `docs/`, `addons/gut` sind vom Export ausgeschlossen.
  - Keine Signatur-Zugangsdaten in `export_presets.cfg`; die Signatur kommt aus Umgebungsvariablen bzw. Editor-Einstellungen.
- **Git-Historie:**
  - Alle 7 Commits sind auf private Schlüssel, Passwörter, API-Schlüssel und Tokens durchsucht: kein Fund.
  - `.gitignore` deckt Keystores (`*.keystore`, `*.jks`, `*.p12`, `*.pem`), `export_credentials.cfg`, `*.env`, Editor-Archive, `last_changes.jsonl` und `last_config.diff` ab.
- **Abhängigkeiten:**
  - Der Editor nutzt nur die Python-Standardbibliothek und Vanilla-JS, ohne npm- oder pip-Pakete.
  - Im Spiel ist nur GUT 9.7.1 (MIT, nur für Tests, nicht im Export) eingebunden; keine bekannten Schwachstellen.
  - Die Lizenzen der Schriften und Bibliotheken pflegt der Lizenzkatalog (`test_release.gd`).

## Restrisiken

- **LAN-Modus:** `make upgrades-lan` überträgt per unverschlüsseltem HTTP. Wer im selben Netz mitliest, sieht alle Daten, und jeder im Netz kann schreiben. Den Modus daher nur in vertrauenswürdigen Netzen nutzen.
- **Freitext in Bereichsnamen:** Namen der Editor-Bereiche (`groups`, höchstens 60 Zeichen) sind bewusst Freitext. Sie erreichen nie das Spiel, wohl aber `last_changes.jsonl`. Abgesichert ist das durch die minimalen Claude-Werkzeuge und den Prompt-Hinweis (S-03).
- **`CLAUDE_CMD`:** Pfade mit Leerzeichen werden aufgeteilt und funktionieren daher nicht, weil die Variable bewusst in Wörter zerlegt wird.
- **Verfügbarkeit:** Ein Angreifer aus dem Loopback bzw. im LAN-Modus aus dem privaten Netz kann den Server weiterhin bis zu 32 Verbindungen × 20 s auslasten.
- **`SafeFile.rename`:** Atomisch nur, soweit das Zieldateisystem `rename` atomisch ausführt (auf Android und Linux gegeben).
