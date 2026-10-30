# Datensicherheit (Play Console → App-Inhalte → Datensicherheit)

Stand: 30. Oktober 2026, App-Version 1.0.0. Bei jeder Änderung an Berechtigungen, Bibliotheken oder Netzwerkzugriffen neu prüfen.

## Grundlage der Antworten (im Code geprüft)

| Prüfpunkt | Ergebnis | Nachweis |
|---|---|---|
| Netzwerkzugriffe | keine | Kein `HTTPRequest`, `HTTPClient`, `StreamPeerTCP`, `PacketPeerUDP`, `WebSocket*` in `src/`; Preset `permissions/internet=false`; die bestehende Debug-APK fordert nur `android.permission.VIBRATE` an (`aapt2 dump permissions`). |
| Analyse, Tracking, Werbung, Absturzberichte | keine | Keine SDKs/Plugins; das Godot-Android-Template enthält nur AndroidX- und Kotlin-Bibliotheken, keine Google-Play-Services. |
| Berechtigungen | nur `VIBRATE` | `export_presets.cfg`, geprüft in `tests/unit/test_release.gd`. |
| Gespeicherte Daten | nur lokal | `user://progress.json` (Spielstand), `user://settings.json` (Sprache/Ton/Vibration), atomar geschrieben über `SafeFile`. |
| Externe Links | optional | Nur die Datenschutzerklärung (`AppInfo.PRIVACY_POLICY_URL`, nur `https://`), geöffnet im Browser des Nutzers; die App selbst überträgt dabei nichts. |
| Android-Sicherung | erlaubt | `user_data_backup/allow=true`; die Sicherung führt Android in das Google-Konto des Nutzers aus (Ende-zu-Ende-verschlüsselt ab Android 9 mit Displaysperre). Das ist keine Erhebung durch den Entwickler, da die App selbst keine Daten vom Gerät überträgt. |

## Antworten im Formular

### Datenerhebung und Sicherheit

| Frage | Antwort |
|---|---|
| Erhebt oder teilt deine App erforderliche Nutzerdatentypen? | **Nein** |

Damit entfallen die Fragen zu Verschlüsselung bei der Übertragung, Löschanfragen und den einzelnen Datentypen. Im Store erscheint „Keine Daten erhoben“ und „Keine Daten mit Dritten geteilt“.

### Optionale Angaben

| Frage | Antwort |
|---|---|
| Unabhängige Sicherheitsprüfung (MASA) | Nein (nicht erforderlich) |
| Datenschutzerklärung (URL) | öffentliche HTTPS-Adresse der veröffentlichten `privacy-policy-de.md` bzw. `privacy-policy-en.md` |

## Weitere Angaben unter „App-Inhalte“

| Abschnitt | Antwort |
|---|---|
| Datenschutzerklärung | URL wie oben (Pflicht, auch ohne Datenerhebung) |
| Werbung | Enthält **keine** Werbung |
| App-Zugriff | Alle Funktionen ohne besondere Zugriffsrechte verfügbar (kein Login) |
| Zielgruppe und Inhalte | Empfehlung: 13–15, 16–17, 18+ (siehe `release-checklist.md`, Abschnitt Zielgruppe) |
| Content-Einstufung | siehe `content-rating.md` |
| Finanzfunktionen | Keine |
| Gesundheit | Keine Gesundheits-App |
| Behörden-App | Nein |
| Nachrichten-App | Nein |
| Kontoerstellung / Kontolöschung | Keine Konten, daher keine Kontolöschung nötig |
| Foreground-Service-, Standort-, Foto-/Video-Berechtigungen | Nicht verwendet |

## Wann die Antworten neu geprüft werden müssen

- Eine neue Berechtigung (z. B. `INTERNET`) oder ein neues Plugin/SDK kommt hinzu.
- Es werden Lizenzprüfung, Play Integrity, Cloud-Speicherstände, Bestenlisten, Analyse oder Absturzberichte eingebaut.
- Die App öffnet weitere externe Dienste.
