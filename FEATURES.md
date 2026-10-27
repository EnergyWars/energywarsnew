# Energy Wars – Features

Tower-Defense-/Eroberungsspiel für Android (Godot 4.7, Hochformat). Ein Soldat landet per Fallschirm auf einer großen, vernebelten Karte und sucht einen Bauplatz. Dort baut man den Kern, mauert sich mit Bollwerken ein und baut ein Energienetz aus Solarpanels, Verteilern und Speichern. Damit versorgt man Türme über sichtbare Energiestrahlen und erobert die Karte, bis alle feindlichen Strukturen zerstört sind.

## Projektspezifische Ausnahmen von globalen Regeln

- **Übersetzungen:** Statt `strings.xml` wird – wie beim Referenzprojekt `../department` – Godots CSV-Übersetzung genutzt: `i18n/translations.csv` mit den Spalten `keys,en,de`. Englisch ist der Fallback.
- **Testabdeckung:** GUT misst keine Coverage. Abgedeckt sind alle Logikklassen (`src/core`) und die UI-Logik bzw. die Szenen (`src/ui`) über Unit- und Szenentests.
- **Grafik und Sound** werden vollständig prozedural zur Laufzeit erzeugt. Es gibt keine fremden Bild- oder Audiodateien.
  - Fonts: Geist (SIL OFL 1.1, `assets/fonts/OFL.txt`) und Material Icons (Apache 2.0, `assets/fonts/MaterialIcons-LICENSE.txt`).
  - Das App-Icon (`assets/icon.svg`) ist eine Eigenkreation.

## Spielablauf

1. **Levelauswahl:** 8 Level, die nacheinander freigeschaltet werden. Pro Level gibt es 0–3 Sterne. Angezeigt werden Gesamtsterne, Kills und die beste Combo.
2. **Erkundung:**
   - Ein Soldat schwebt am Fallschirm herab und landet. Während der Erkundung läuft keine Zeit und es kommen keine Gegner.
   - Man tippt auf die Karte, damit der Soldat dorthin läuft (Pfadsuche um Gelände). Dabei deckt er den Nebel auf.
   - Tippt man auf einen Baum oder Felsen, läuft der Soldat hin und beseitigt ihn (Baum ca. 1,6 s, Fels ca. 3,2 s).
   - Mit „Basis“ in der Bauleiste setzt man den Kern: nur in der Nähe des Soldaten, auf erkundetem, freiem Boden und mit großem Abstand zu feindlichen Strukturen. Danach beginnt die Vorbereitung.
   - Der Soldat bleibt auch danach steuerbar (Button links unten oder Antippen) und kann weiter erkunden und roden.
3. **Vorbereitung:** Countdown, in dem man in Ruhe bauen kann. Mit „Angriff!“ lässt sich die Vorbereitung vorzeitig beenden; jede gesparte Sekunde bringt 1 Geld Bonus.
4. **Kampf:**
   - Es gibt keine festen Wellen. Feindliche Spawner (Nest, Lager) schicken Gegner fortlaufend in Rudeln, die aus einer gemeinsamen Richtung kommen. Ein Rudel hat anfangs 3 Gegner und wächst alle 2 Angriffszyklen um 1 (max. 10).
   - Jeder Angriffszyklus (ca. 2 Minuten) beginnt ruhig und verdichtet sich gegen Ende. Ab 75 % kündigt ein Hinweis mit Grollen „Die Angriffe werden heftiger“ an; danach ebbt es wieder ab.
   - Mit jedem Zyklus kommen mehr und stärkere Gegner, nachts zusätzlich mehr.
   - Feindliche Geschütztürme verteidigen sich selbst.
5. **Sieg:** Alle feindlichen Strukturen sind zerstört. Verbleibende Gegner werden vernichtet und alle Münzen eingesammelt.
6. **Niederlage:** Der Kern wird zerstört.
7. **Sterne:**
   - 3 Sterne: Kern ≥ 80 % und höchstens 2 verlorene Gebäude.
   - 2 Sterne: Kern ≥ 40 %.
   - Sonst 1 Stern.
8. **Ergebnis:** Sterne erscheinen nacheinander mit Konfetti. Dazu Statistiken (Kills, beste Combo, verdientes Geld, Verluste, Zeit) und die Buttons Weiter, Nochmal und Menü.

## Gelände und Nebel

- **Große Karten** im Raster (Zelle 56 px), je nach Level 52×64 bis 76×96 Zellen. Sie werden pro Level deterministisch aus einem Seed erzeugt.
- **Plateaus** (Hochebenen) sind von Klippen umgeben und nur über Rampen erreichbar. Gebäude auf einem Plateau haben +20 % Reichweite und Sicht (Rampen zählen nicht).
- **Schluchten** sind unpassierbar und haben gelegentliche Brücken. **Wälder** und **Felsen** blockieren Weg und Bauplatz.
- **Vorteils-Spots:** Jedes Level hat feste Plätze, die an einigen Seiten durch Plateaus, Wald oder Felsen geschützt sind. Dort muss man weniger Bollwerke bauen.
- Alle begehbaren Bereiche sind verbunden. Nur der Spieler kann Bäume und Felsen entfernen, Gegner nicht.
- **Nebel des Krieges:** Unerkundetes ist schwarz, Erkundetes abgedunkelt, sichtbar ist nur, was Soldat oder eigene Gebäude sehen. Gegner sind nur im sichtbaren Bereich zu sehen. Gebaut werden darf nur auf erkundetem Boden.

## Tag und Nacht

- Tag und Nacht wechseln sich ab und sind lang (Tag ca. 3–3,5 min, Nacht ca. 2–2,5 min, je nach Level). Energiesparen für die Nacht ist deshalb wichtig.
- Solarpanels liefern Energie proportional zum Licht. Die Dämmerung ist ein weicher Übergang, nachts liefern sie nichts.
- Nachts wird die Karte abgedunkelt, Gegneraugen leuchten und es kommen mehr Gegner. Man muss tagsüber genug Überschuss in die Speicher laden.
- Die HUD-Uhr zeigt Sonne oder Mond, die Zeit bis zum nächsten Wechsel und den aktuellen Tag.

## Gebäude

Jedes Gebäude hat Kosten, Lebenspunkte und eigene Upgrade-Pfade; die meisten haben einen Energiespeicher. Kern, Nest und Lager belegen 2×2 Zellen, alle anderen 1×1. Platziert wird am Raster.

| Gebäude | Funktion | Upgrades |
|---|---|---|
| Kern (Basis) | Wird nach der Erkundung gesetzt, erzeugt etwas Energie, hat 3 Strahlen und verteidigt sich selbst mit Blitzen | Rate, Reichweite, Strahlen, Kraft |
| Solarpanel | Erzeugt tagsüber Energie, kann nur senden | Leistung, Rate, Reichweite, Strahlen |
| Verteiler | Leitet Energie weiter (3 Strahlen, große Reichweite) | Rate, Reichweite, Strahlen |
| Speicher | Großer Energiespeicher | Kapazität, Rate, Reichweite, Strahlen |
| Energieexporteur | Verkauft empfangene Energie für Geld (4 Energie = 1 Geld, Auszahlung in 5er-Paketen) | Exportrate, Kapazität |
| Blitzturm | Schneller Einzelziel-Blitz (Boden + Luft) | Kraft, Tempo, Reichweite |
| Laserturm | Dauerstrahl, verbraucht Energie kontinuierlich | Kraft, Reichweite |
| Teslaturm | Kettenblitz über bis zu 5 Ziele mit Abschwächung | Kraft, Tempo, Reichweite |
| Plasmawerfer | Artillerie mit Flächenschaden, große Reichweite und Mindestreichweite, nur Bodenziele (auch Strukturen) | Kraft, Tempo, Reichweite |
| Schildgenerator | Absorbiert Schaden an Gebäuden im Radius mit eigener Energie | Stärke, Radius |
| Heilturm | Repariert beschädigte Gebäude in Reichweite und verbraucht dafür Energie. Wählt das Ziel automatisch: am stärksten beschädigt, gerade unter Beschuss, Kern bevorzugt, plus etwas Zufall. Kein Überheilen, ohne Ziel kein Verbrauch. | Heilkraft, Heiltempo, Heilreichweite |
| Bollwerk | Mauerblock mit sehr viel HP (2000, Türme nur 90–120). Blockiert Bodengegner, braucht keine Energie und erweitert den Bauradius nicht. Anfangs sehr günstig (4 Geld), alle 6 Bollwerke wird es 1 teurer. Im Baumodus kann man eine Mauerlinie ziehen; der Baumodus bleibt aktiv. | Hülle (+50 % HP je Stufe) |

- **Upgrade-Kosten** wachsen exponentiell; jeder Pfad hat eine Maximalstufe.
- **Verkaufen** erstattet 50 % aller Investitionen.
- **Bauregeln:**
  - Nur innerhalb des Bauradius eigener Gebäude (Bollwerke zählen nicht).
  - Nur auf erkundetem, freiem Boden: nicht auf Klippen, Schluchten, Bäumen, Felsen, anderen Gebäuden oder Bodengegnern und nicht zu nah an feindlichen Strukturen.
  - Geld muss reichen und das Gebäude freigeschaltet sein.
- **Freischaltung je Level:**
  - Level 1: Solar, Verteiler, Speicher, Exporteur, Blitz, Bollwerk
  - Level 2: Laser, Heilturm
  - Level 3: Schild
  - Level 4: Tesla
  - Level 5: Plasma

## Energienetz

- Im Verbinden-Modus zieht man per Drag & Drop von einem sendenden Gebäude zu einem Ziel. Dabei entsteht ein elektrischer Energiestrahl in der Luft.
  - Die Vorschau zeigt, ob die Verbindung gültig ist.
  - Fehlergründe erscheinen als Hinweis: zu weit, voll, existiert bereits, Ziel kann nicht empfangen usw.
- Wischt man im Verbinden-Modus über Strahlen (Start im leeren Raum oder auf einem nicht sendenden Gebäude), werden sie durchgeschnitten.
- **Sichtbarkeit:** Strahlen sind nur sichtbar, solange gerade Energie fließt, und blenden weich ein und aus. Im Verbinden-Modus werden zusätzlich alle Verbindungen gestrichelt angezeigt, damit man sie findet und kappen kann.
- **Energiefluss:**
  - Jede Quelle verteilt ihre Transferrate gleichmäßig auf ihre Strahlen.
  - Begrenzt wird durch den freien Speicher des Ziels.
  - Die Dicke und das Leuchten eines Strahls zeigen den aktuellen Fluss; Energiepakete wandern sichtbar entlang.
- Türme ohne Energie feuern nicht und zeigen ein blinkendes Blitzsymbol.

## Gegner

Es gibt drei Klassen: Nahkampf, Fernkampf und Luft.

| Gegner | Klasse | Eigenschaften |
|---|---|---|
| Krabbler | Nahkampf | Schnell, schwach, Schwarm |
| Käfer | Nahkampf | Gepanzert, langsam |
| Speier | Fernkampf | Säurespucker aus dem Nest |
| Wespe | Luft | Schnell, schwach (Plasma trifft nicht) |
| Behemoth | Nahkampf | Boss, sehr viel HP |
| Soldat | Fernkampf | Schießt aus Distanz |
| Saboteur | Nahkampf | Läuft zum nächsten erreichbaren Strahl (freie Zelle direkt am Strahl) und schneidet ihn durch |
| Drohne | Luft | Fliegt und schießt aus kurzer Distanz |
| Panzer | Fernkampf | Boss mit großer Reichweite |

- Nester schicken Tiere, Lager schicken Menschen und Maschinen. Jede Fraktion hat alle drei Klassen. Feindliche Geschütztürme schießen auf nahe Gebäude.
- **Pfadsuche:** Bodengegner laufen per A* um Klippen, Schluchten, Wald, Felsen und Gebäude herum. Neue Mauern lösen eine Neuplanung aus.
- **Zielpriorität:** Exporteur > Heiler > Türme (inkl. Schild) > Bollwerke > Verteiler und Speicher > Kern. Gebäude, die mangels Energie gerade nichts tun, rutschen auf die niedrigste Stufe direkt über dem Kern. Bei gleicher Stufe gewinnt das nächste Ziel.
- **Erreichbarkeit:** Bodengegner (Nah- und Fernkampf) greifen nur Gebäude an, zu denen ein Weg führt. Ist die Basis eingemauert, greifen sie zuerst die Bollwerke an. Fernkämpfer schießen auch dann nicht über Mauern, wenn das Ziel in Reichweite ist. Luftgegner ignorieren das.
- Gegner zerstören Türme sehr schnell; nur Bollwerke halten lange stand. Man muss sich also einmauern. Mauern wirken am besten dicht an den Türmen: Fernkämpfer (Reichweite 110–120) bleiben dann in Turmreichweite, nur der Panzer schießt von weiter weg.
- HP und Kopfgeld steigen mit jedem Angriffszyklus; die HP sind ab Zyklus 8 gedeckelt.

## Belohnungen und „Juice“

- Getötete Gegner droppen Münzen. Diese fliegen nach kurzer Verzögerung sichtbar zur Geldanzeige, und der Zähler rollt hoch.
- **Combo-System:** Kills in schneller Folge erhöhen die Combo.
  - Meilensteine (5, 10, 20, 35, 50, 75, 100) zahlen Bonusgeld und lösen Banner, Konfetti und Sound aus.
  - Die Tonhöhe der Kill-Sounds steigt mit der Combo.
- **Kritische Treffer:** 12 % Chance auf doppelten Schaden, mit großer Schadenszahl und Effekt.
- Wird eine feindliche Struktur zerstört, gibt es Zeitlupe, Bildschirmwackeln, eine Explosion, einen Münzregen und ein Banner.
- Partikel, Ringe, Schadenszahlen, Vibration (abschaltbar) und synthetisierte Soundeffekte.
- Nacht- und Morgen-Banner, Ansturm-Hinweis, Exporteur-Einnahmen-Effekt, grüne Heilstrahlen mit „+N“, Landungs- und Basis-Banner, Rodungs-Effekte.

## Bedienung

- **Bauen:** Gebäude in der Bauleiste antippen. Ein Geist (Rasterfeld) zeigt Gültigkeit und Reichweite; Platzieren per Tippen oder Loslassen. Danach endet der Baumodus, außer bei Bollwerken: Hier zieht man Mauerlinien und baut weiter, bis das Geld fehlt. Die Kosten in der Bauleiste sind aktuell (Bollwerke werden teurer).
- **Soldat:** Antippen wählt ihn aus (Hinweis-Chip oben). Tippen auf die Karte schickt ihn los, Tippen auf Baum oder Fels rodet. Der Button links unten springt zum Soldaten.
- **Modus-Umschalter** (Button unten rechts):
  - „Verschieben“ (Standard): Ein Finger bewegt die Karte, Tippen wählt aus.
  - „Verbinden“: Ziehen verbindet, Wischen kappt. Doppeltippen und gedrückt halten verschiebt die Karte; bis zum Loslassen wird nicht verbunden. Die Zurück-Taste wechselt zurück zu Verschieben.
- **Auswahl:** Gebäude antippen öffnet ein Panel mit Werten, Upgrades (aktueller und nächster Wert, Kosten) und Verkaufen. Reichweitenkreise werden angezeigt.
- **Zielpriorität pro Turm:** Im Panel jedes Turms (und des Kerns) zeigt eine Zeile die Reihenfolge Luft → Fernkampf → Nahkampf (Standard). Tippen auf eine Klasse deaktiviert oder aktiviert sie (z. B. Turm nur gegen Luft); die Pfeil-Buttons tauschen benachbarte Klassen. Klassen, die ein Turm nicht treffen kann (Plasma gegen Luft), sind ausgegraut. Strukturen greift ein Turm nur an, wenn Nah- oder Fernkampf aktiv ist.
- **Kamera:**
  - Ein Finger verschiebt im Verschieben-Modus.
  - Zwei Finger zoomen und verschieben in beiden Modi. Solange zwei Finger aufliegen, wird nicht verbunden oder geschnitten.
  - Im Verbinden-Modus: Doppeltippen und halten verschiebt.
  - Am Desktop: Mausrad sowie rechte oder mittlere Maustaste.
- **HUD:** Geld, Energiebalken mit Erzeugung pro Sekunde, Tag/Nacht-Uhr mit Tageszähler, Spielgeschwindigkeit 1×/2×/3× und Pause.
- **Pause-Menü:** Weiter, Neustart, Menü, Sound und Vibration.
- **Zurück-Taste:** schließt nacheinander Baumodus, Soldatenauswahl, Gebäudeauswahl und Verbinden-Modus, dann öffnet sie die Pause; nach Spielende geht sie zum Menü.
- **Tutorial** im ersten Level: Soldat laufen lassen → Basis setzen → Solar bauen → verbinden → Turm bauen → Turm versorgen → Bollwerke bauen → Kamera → Speicher → Strahl schneiden.

## Einstellungen und Fortschritt

- Sound, Vibration und Sprache (Deutsch/Englisch, Standard ist die Systemsprache) werden lokal gespeichert.
- Der Fortschritt (Sterne je Level, Gesamtkills, beste Combo) liegt als JSON in `user://progress.json`. Beschädigte Daten werden robust bereinigt.
