# Release-Checkliste Google Play (kostenpflichtige App)

Stand: 30. Oktober 2026. Energy Wars wird als **Einmalkauf** ohne Werbung und ohne In-App-Käufe veröffentlicht. Diese Liste trennt, was im Projekt bereits erledigt ist, von dem, was in der Play Console und lokal von Hand zu tun ist.

## 1. Im Projekt erledigt

| Thema | Stand | Ort |
|---|---|---|
| Release-Preset für Play | „Android Play“: Gradle-Build, Format AAB, minSdk 24, targetSdk 36, arm64-v8a + armeabi-v7a + x86_64, signiert | `export_presets.cfg` |
| Debug-Preset | „Android“: vorgefertigte APK zum lokalen Testen (unverändert, nur Icons/Version/Backup ergänzt) | `export_presets.cfg` |
| Ziel-API | targetSdk 36 (Pflicht für neue Apps und Updates seit 31. 08. 2026) | Preset, `tests/unit/test_release.gd` |
| 16-KB-Speicherseiten | erfüllt: Die Godot-4.7.2-Bibliotheken (`libgodot_android.so`, `libc++_shared.so`) haben 16-KB-ausgerichtete ELF-Segmente (`readelf`: `LOAD`-Alignment `0x4000`, arm64-v8a und x86_64); gebaut mit NDK r29, AGP 8.6.1 (≥ 8.5.1) richtet unkomprimierte Bibliotheken im AAB auf 16 KB aus (`gradle_build/compress_native_libraries=false`). Pflicht für Updates ab 01. 02. 2027. | Preset |
| Versionierung | `versionName` = `application/config/version` (SemVer), `versionCode` = MAJOR × 10000 + MINOR × 100 + PATCH (1.0.0 → 10000); Konsistenz per Test | `project.godot`, Preset, `AppInfo.version_code` |
| Berechtigungen | nur `VIBRATE` (wird für haptisches Feedback genutzt, abschaltbar), kein `INTERNET` | Preset |
| Spielstand-Sicherung | Android Auto Backup erlaubt (`user_data_backup/allow=true`), Daten bleiben beim Deinstallieren nicht erhalten | Preset |
| Atomisches Speichern | Spielstand und Einstellungen werden in eine Temp-Datei geschrieben und dann umbenannt – kein halber Spielstand bei Abbruch | `src/core/safe_file.gd` |
| Pause im Hintergrund | App im Hintergrund → Kampf pausiert (Pause-Menü), offene Dialoge bleiben erhalten | `src/ui/main.gd`, `BattleScreen.suspend` |
| Zurück-Taste | navigiert schrittweise zurück, öffnet im Kampf die Pause; auf der Weltkarte schließt sie Dialoge/Overlays, erst dann wird die App beendet | `main.gd`, `WorldMapScreen.handle_back` |
| Hochformat, große Bildschirme | `screenOrientation` Hochformat, `appCategory=game` (Android 16 erzwingt auf Tablets bei Spielen keine Drehung) | Preset, `project.godot` |
| Vollbild/Notch | Immersive + Edge-to-Edge, Inhalte beginnen unter dem sicheren Bereich (`DisplayServer.get_display_safe_area`) | Preset, `main.gd` |
| Sprache | Deutsch und Englisch vollständig (Test), Standard = Gerätesprache, Englisch als Fallback | `i18n/translations.csv` |
| Keine Entwicklerdateien im Paket | `tests/`, `tools/`, `docs/`, `build/`, `addons/gut/` ausgeschlossen; Upgrade-Editor-Daten (`tools/upgrade_editor/data/*.json`) nicht im Paket | Preset (`exclude_filter`) |
| Über/Lizenzen | Info-Button auf der Weltkarte: Version, Credits, Datenschutz-Hinweis (Link, sobald URL gesetzt), alle Lizenztexte (Geist OFL, Material Icons Apache 2.0, Godot MIT, Godot-Drittkomponenten, AndroidX/Kotlin) | `src/ui/about_overlay.gd`, `src/ui/license_catalog.gd` |
| Launcher-Icons | 192 px (alt), adaptiv Vordergrund/Hintergrund 432 px, Monochrom 432 px (Android 13+ Themen-Icons) | `assets/android/`, Quellen `tools/store_assets/src/` |
| Store-Grafiken | App-Symbol 512 × 512, Feature-Grafik 1024 × 500 (de/en, ohne Alpha), 8 Screenshots 540 × 960 | `docs/store/` |
| Texte | Store-Eintrag de/en, Datenschutzerklärung de/en, Datensicherheit, Content-Einstufung | `docs/store/*.md` |

Grafiken neu erzeugen: `make store-assets` (Godot rastert die SVGs, Python/Pillow setzt die Feature-Grafik mit der Schrift Geist zusammen). Quellen: eigene SVGs in `tools/store_assets/src/` (Eigenkreation auf Basis von `assets/icon.svg`), Schrift Geist (SIL OFL 1.1). Screenshots: `tests/tools/screenshot.gd` (Befehl siehe Abschnitt 6).

## 2. Einmalig lokal einrichten

1. **Export-Vorlagen vollständig installieren:** Im Editor *Editor → Export-Vorlagen verwalten → Herunterladen* (4.7.2). Aktuell liegen in `~/.local/share/godot/export_templates/4.7.2.stable/` nur die beiden APK-Vorlagen; für AAB wird zusätzlich `android_source.zip` gebraucht.
2. **Android-Build-Vorlage installieren:** *Projekt → Android-Build-Vorlage installieren*. Das legt `android/` an (per `.gitignore` ausgeschlossen, nach Godot-Updates neu installieren).
3. **Android SDK:** Platform 36 und Build-Tools 36.1.0 (verlangt die Godot-Vorlage) über den SDK-Manager installieren, Lizenzen akzeptieren. JDK 17 oder 21 (vorhanden: Temurin 21).
4. **Upload-Schlüssel erzeugen** (einmalig, außerhalb des Repos, z. B. `~/.android-keys/`):

   ```sh
   keytool -genkeypair -v -keystore ~/.android-keys/energywars-upload.jks \
     -alias upload -keyalg RSA -keysize 4096 -validity 10000
   ```

   - Keystore- und Schlüsselpasswort müssen bei Godot **identisch** sein.
   - Keystore und Passwort sicher sichern (Passwortmanager + Offline-Kopie). Bei Verlust kann der Upload-Schlüssel über die Play Console zurückgesetzt werden, aber nur mit Wartezeit.
   - Niemals ins Repo: `*.jks`, `*.keystore`, `*.p12`, `*.pem`, `keystore.properties`, `*.env` und `export_credentials.cfg` sind in `.gitignore`; die Git-Historie enthält keine Schlüssel (geprüft).
5. **Signatur nur über Umgebungsvariablen** (oder Editor-Einstellungen, die in `.godot/export_credentials.cfg` landen, nicht in `export_presets.cfg`):

   ```sh
   export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=~/.android-keys/energywars-upload.jks
   export GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
   export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='…'
   ```

## 3. Jede Veröffentlichung bauen

1. **Version erhöhen** (jeder Upload braucht einen höheren `versionCode`):
   - `project.godot` → `config/version="X.Y.Z"`
   - `export_presets.cfg` → in **beiden** Presets `version/name="X.Y.Z"` und `version/code` nach Schema (z. B. 1.0.1 → 10001, 1.1.0 → 10100).
   - `tests/unit/test_release.gd` schlägt fehl, wenn die drei Stellen nicht zusammenpassen.
2. **Tests und Build:** `make android-aab` (prüft die Signatur-Variablen und `android/build`, führt Import und alle Tests aus, exportiert `build/energy-wars.aab` mit dem Preset „Android Play“).
3. **Lokal prüfen (optional):** Mit `bundletool build-apks --bundle=build/energy-wars.aab --output=build/energy-wars.apks --connected-device` und `bundletool install-apks` auf einem Gerät installieren; in der Play Console zeigt der App-Bundle-Explorer zusätzlich die 16-KB-Kompatibilität.

## 4. Play Console – Konto

1. **Entwicklerkonto** (einmalig 25 USD), Identitätsbestätigung abschließen. Kontotyp *privat* oder *Organisation* (Organisation braucht eine D-U-N-S-Nummer).
2. **Android-Entwicklerverifizierung:** Play-Apps werden automatisch registriert; auf der Startseite der Play Console prüfen, dass das Paket `com.wafflehq.energywars` als registriert angezeigt wird.
3. **Zahlungsprofil (Händlerkonto) einrichten** – Pflicht für kostenpflichtige Apps: Bankkonto, Steuerangaben (US-Steuerformular W-8BEN im Bereich Zahlungen), Umsatzsteuer-ID falls vorhanden. Google führt in der EU die Umsatzsteuer ab; Preise werden inklusive MwSt. angegeben.
4. **Händlerstatus (EU, Digital Services Act):** Wer Apps verkauft, ist in der Regel Händler. Dann zeigt Google Play in der EU **Name, Anschrift, Telefonnummer und E-Mail** öffentlich an. Bei Privatkonten ggf. eine ladungsfähige Geschäftsadresse verwenden.
5. **Impressum:** Für den gewerblichen Vertrieb in Deutschland eine Anbieterkennzeichnung (§ 5 DDG) bereitstellen, z. B. auf derselben Website wie die Datenschutzerklärung, und als Website im Store-Eintrag verlinken. Keine Rechtsberatung – im Zweifel prüfen lassen.

## 5. Play Console – App anlegen und App-Inhalte

1. **App erstellen:** Name „Energy Wars: Tower Defense“, Standardsprache Englisch (USA) oder Deutsch, Typ **Spiel**, **kostenpflichtig**.
   - **Wichtig:** Eine einmal kostenlos veröffentlichte App kann **nie** kostenpflichtig werden. Vor dem ersten Release in irgendeinem Track den Preis setzen.
2. **Preis und Länder:** *Monetarisierung → Preis der App* (z. B. 2,99 € als Basispreis, Umrechnung in lokale Preise prüfen), *Länder/Regionen* auswählen (nur Länder mit Händlerunterstützung sind möglich).
3. **App-Inhalte** (Antworten siehe die verlinkten Dateien):
   - Datenschutzerklärung: öffentliche HTTPS-URL (siehe Abschnitt 7) – `privacy-policy-de.md` / `privacy-policy-en.md`.
   - Werbung: Nein.
   - App-Zugriff: alle Funktionen ohne Anmeldung.
   - Einstufung des Inhalts: `content-rating.md`.
   - **Zielgruppe:** Empfehlung 13–15, 16–17 und 18+. Wird „unter 13“ gewählt, gelten die strengeren Familienrichtlinien (Teacher-Approved-Prüfung, Anforderungen an Datenschutzerklärung und Inhalte); technisch erfüllt das Spiel sie (keine Daten, keine Werbung), es bedeutet aber zusätzlichen Prüfaufwand.
   - Datensicherheit: `data-safety.md` (keine Daten erhoben/geteilt).
   - Behörden-, Finanz-, Gesundheits-, Nachrichten-App: jeweils Nein.
4. **Store-Präsenz:**
   - Texte aus `listing-de.md` und `listing-en.md`.
   - App-Symbol: `docs/store/icon-512.png` (Google rundet die Ecken selbst ab).
   - Feature-Grafik: `docs/store/feature-graphic-en.png` bzw. `-de.png` für den deutschen Eintrag.
   - Screenshots Smartphone: `docs/store/screenshots/{de,en}-*.png` (540 × 960, gültig: 320–3840 px, Seitenverhältnis ≤ 2:1). Für die Empfehlung in Spiele-Rubriken verlangt Google mindestens 4 Screenshots mit mindestens 1080 px – dafür am besten auf einem Gerät aufnehmen: `adb exec-out screencap -p > shot.png`.
   - Optional Tablet-Screenshots (7"/10") für bessere Sichtbarkeit auf Tablets.
   - Kategorie: Spiele → Strategie; Tags z. B. Tower Defense, Strategie, Offline.
   - Kontaktdaten: E-Mail (Pflicht, öffentlich), Website (empfohlen, mit Impressum und Datenschutzerklärung).

## 6. Testen und Produktionszugriff

1. **Interner Test** (bis 100 Tester): AAB hochladen, **Play App Signing** akzeptieren (Google verwaltet den App-Signaturschlüssel, der Upload-Schlüssel bleibt lokal). Interne Tester können auch kostenpflichtige Apps **kostenlos** installieren.
2. **Geschlossener Test – Pflicht für private Konten, die nach dem 13. 11. 2023 angelegt wurden:** mindestens **12 Tester**, die **14 Tage ohne Unterbrechung** angemeldet sind, bevor der Produktionszugriff beantragt werden kann. Google achtet zunehmend darauf, dass die Tester die App tatsächlich nutzen und Feedback geben.
   - Bei kostenpflichtigen Apps müssen Tester in geschlossenen und offenen Tests die App **kaufen**. Möglichkeiten: Tester kaufen und der Kauf wird anschließend über *Bestellverwaltung* erstattet; oder vorher prüfen, ob als Lizenztester eingetragene Konten (*Einstellungen → Lizenztests*) mit einer Testzahlungsmethode kaufen können.
3. **Pre-Launch-Bericht** prüfen (automatische Tests auf echten Geräten): Abstürze, ANRs, Barrierefreiheits- und Darstellungs-Hinweise. Hinweise zu „veralteten Edge-to-Edge-APIs“ stammen aus dem Godot-Android-Code und blockieren die Veröffentlichung nicht.
4. **Produktionszugriff beantragen** (Fragen zum Testverlauf beantworten), danach Release in **Produktion** mit Versionshinweisen de/en, ggf. gestaffeltem Rollout. Die erste Prüfung kann mehrere Tage dauern.

Screenshots neu erzeugen (Display `:1`, Fenster ≤ 995 px hoch, daher 540 × 960; in bash ausführen):

```sh
DISPLAY=:1 $G --rendering-driver opengl3 --resolution 540x960 -s tests/tools/screenshot.gd -- \
  --out=$PWD/docs/store/screenshots/de-2-battle.png --locale=de --level=2 --rich --simulate=25
```

## 7. Vor dem ersten Upload ausfüllen

- [ ] In `docs/store/privacy-policy-de.md` und `-en.md` Name, Anschrift und Kontakt-E-Mail eintragen, den Hinweisblock entfernen und beide Seiten öffentlich per HTTPS hosten (z. B. GitHub Pages, eigene Website).
- [ ] Die URL in `src/core/app_info.gd` als `PRIVACY_POLICY_URL` setzen (nur `https://` wird akzeptiert) – dann zeigt „Über Energy Wars“ den Button „Datenschutzerklärung öffnen“.
- [ ] Credits prüfen: `ABOUT_CREDITS` in `i18n/translations.csv` nennt „WaffleHQ“ als Entwickler.
- [ ] Preis festlegen und Länder wählen.
- [ ] Tester-Gruppe (≥ 12 Personen, Google-Konten) organisieren.

## 8. Lizenzprüfung bewerten (nicht eingebaut)

| Option | Aufwand | Nutzen | Folgen |
|---|---|---|---|
| Google Play Licensing (LVL) | Android-Plugin für Godot nötig, Berechtigung `CHECK_LICENSE`, Netzwerk beim Start | gering: clientseitige Prüfung ist leicht zu umgehen, Bibliothek gilt als veraltet | Offline-Start wird eingeschränkt, Datensicherheit/Datenschutz müssen angepasst werden |
| Play Integrity API (Lizenz-Urteil) | Plugin plus eigener Server zum Entschlüsseln/Prüfen der Tokens | mittel, nur mit Serverprüfung wirksam | `INTERNET`-Berechtigung, Gerätedaten gehen an Google, Datensicherheit „Daten werden erhoben“, Betrieb eines Servers, Offline-Spiel nicht mehr voll offline |
| Play „Automatischer Schutz“ (App-Integrität) | ein Schalter in der Play Console, setzt Play App Signing voraus | schützt vor einfachem Weiterverteilen der APK | vorher testen, ob der Offline-Start betroffen ist und ob sich die Datensicherheitsangaben ändern |

**Empfehlung:** Für ein kleines Offline-Spiel zum Einmalpreis keine eigene Lizenzprüfung einbauen. Sie kostet Offline-Fähigkeit, Datenschutz-Einfachheit („keine Daten erhoben“) und Wartung, ohne Raubkopien wirksam zu verhindern. Optional nach dem ersten Release den „Automatischen Schutz“ testen.

## 9. Nach der Veröffentlichung

- Android Vitals (Abstürze, ANRs) und Rezensionen beobachten.
- **Jährliche Ziel-API:** Google hebt die Pflicht jedes Jahr zum 31. August an (2027 voraussichtlich API 37). Dafür Godot aktualisieren und `gradle_build/target_sdk` anpassen.
- Bekannte Einschränkung: Ein laufender Kampf wird nicht dauerhaft gespeichert. Beendet Android die App im Hintergrund, startet der Kampf neu; Weltkarte, Forschung und Einstellungen bleiben erhalten.
- Bei neuen Berechtigungen, SDKs oder Netzwerkfunktionen: `data-safety.md`, Datenschutzerklärung und Content-Einstufung aktualisieren.

## Quellen

- Ziel-API-Anforderungen: https://developer.android.com/google/play/requirements/target-sdk
- 16-KB-Speicherseiten: https://developer.android.com/guide/practices/page-sizes
- Godot – Export für Android: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- Godot-Vorlage (minSdk 24, targetSdk 36, NDK r29, AGP 8.6.1): https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/app/config.gradle
- Datensicherheit: https://support.google.com/googleplay/android-developer/answer/10787469
- Testtracks (Kauf bei kostenpflichtigen Apps): https://support.google.com/googleplay/android-developer/answer/9845334
- Testanforderungen für neue private Konten: https://support.google.com/googleplay/android-developer/answer/14151465
- Android-Entwicklerverifizierung: https://developer.android.com/developer-verification/guides
