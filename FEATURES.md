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
   - Der Soldat wird mit einem virtuellen Joystick (links unten; am Desktop auch Pfeiltasten/WASD) direkt gesteuert. Er gleitet an Klippen, Schluchten, Wald, Felsen und feindlichen Strukturen entlang und deckt dabei den Nebel auf. Die Kamera folgt ihm.
   - Tippt man auf einen Baum oder Felsen in seiner Nähe (goldener Ring), beseitigt er ihn (Baum ca. 1,6 s, Fels ca. 3,2 s). Läuft er weg, bricht das Roden ab.
   - Mit „Basis“ in der Bauleiste setzt man den Kern: nur in der Nähe des Soldaten, auf erkundetem, freiem Boden und mit großem Abstand zu feindlichen Strukturen. Danach beginnt die erste Planungsphase.
   - Sobald der Kern steht, setzt sich der Soldat hinein und ist nicht mehr steuerbar. Von dort schießt er mit seinem Gewehr (ohne Energie, Reichweite 250) auf den nächsten Gegner.
3. **Planungsphase** (ohne Zeitlimit):
   - Man kann bauen, upgraden, verbinden, versetzen und verkaufen.
   - Es gibt keine Gegner, die Zeit steht still und alle Energie ist eingefroren: Generatoren und Exporteure produzieren nichts, Türme schießen nicht, Heiltürme heilen nicht, mobile Türme fahren nicht.
   - Versetzen ist kostenlos. Was in dieser Planungsphase investiert wurde (Bau und Upgrades), bekommt man beim Verkaufen voll zurück.
   - In einem großen Umkreis (650 px) um feindliche Strukturen darf nicht gebaut werden. Feindbasen besiegt man nur mit mobilen Türmen oder mit Gebäuden, die man während des Kampfes näher heranbaut (dann gilt nur der kleine Mindestabstand von 150 px).
   - Eine Karte oben zeigt „Planung · Tag N“, die Buttons „Rückgängig“ und „Zurücksetzen“ sowie „▶ Tag N starten“.
   - **Rückgängig** nimmt den letzten Planungsschritt zurück: Bauen, Upgraden, Verkaufen, Versetzen, Verbinden, Kappen, Zielpriorität und Fokus. Eine gezogene Mauerlinie und ein Wischer, der mehrere Strahlen kappt, zählen jeweils als ein Schritt. Gebäude, Energie, Strahlen und Geld kehren zum Stand vor dem Schritt zurück.
   - **Zurücksetzen** stellt nach einer Rückfrage den Zustand zu Beginn dieser Planungsphase wieder her. Einnahmen, die währenddessen eingingen, bleiben erhalten.
   - Beide Buttons sind ausgegraut, solange es nichts zurückzunehmen gibt. Mit dem Start des Tages endet die Historie.
4. **Kampf (Tag und Nacht):**
   - „Tag N starten“ beginnt den Tag. Die erste Welle kommt nach 3 s, danach alle 9 s eine weitere (Zähler „Tag N · Welle x/y“).
   - Jeder Spawner (Nest, Lager) schickt pro Welle mindestens einen Gegner; die Wellen werden im Laufe des Tages größer (bis zum 2,5-Fachen). Die Gegner einer Welle laufen kurz nacheinander (alle 0,3 s) aus einer gemeinsamen Richtung los.
   - Die Nacht bringt größere Wellen (×1,6) mit stärkeren Gegnern (HP ×1,35, Schaden und Kopfgeld ×1,2, eine Gegnerstufe höher). Jede Nachtwelle wird mit Hinweis und Grollen angekündigt.
   - Ist die Nacht vorbei, kommen keine neuen Gegner mehr („Morgengrauen – noch N Gegner“). Ist der letzte Gegner besiegt, gibt es ein Banner „Tag N überstanden“, alle Münzen werden eingesammelt, und die nächste Planungsphase beginnt.
   - Mit jedem Tag werden die Gegner stärker: HP ×1,16 pro Tag (ohne Deckel), Schaden +8 %, Kopfgeld +12 %, Wellen +35 %, und neue Gegnertypen kommen hinzu. Irgendwann ist die Verteidigung nicht mehr zu halten.
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

- Ein Kampftag besteht aus Tag (75–90 s) und Nacht (60–75 s), je nach Level. In der Planungsphase ist es hell, die Uhr steht.
- Solarpanels liefern Energie proportional zum Licht. Die Abenddämmerung (12 s) ist ein weicher Übergang, nachts liefern sie nichts. Nach der Nacht wird es in 8 s wieder hell.
- Nachts wird die Karte abgedunkelt und Gegneraugen leuchten. Man muss tagsüber genug Überschuss in die Speicher laden.
- Die HUD-Uhr zeigt eine Flagge mit „Planung“, Sonne oder Mond mit der Zeit bis zum nächsten Wechsel, dazu den aktuellen Tag und die Welle.

## Gebäude

Jedes Gebäude hat Kosten, Lebenspunkte und eigene Upgrade-Pfade; die meisten haben einen Energiespeicher. Kern, Nest und Lager belegen 2×2 Zellen, alle anderen 1×1. Platziert wird am Raster.

| Gebäude | Funktion | Upgrades |
|---|---|---|
| Kern (Basis) | Wird nach der Erkundung gesetzt, erzeugt etwas Energie, hat 3 Strahlen und verteidigt sich selbst mit Blitzen. Der Soldat sitzt darin und schießt zusätzlich. | Rate, Reichweite, Strahlen, Kraft, Tempo, Leistung, Kapazität, Hülle |
| Solarpanel | Erzeugt tagsüber Energie, kann nur senden. Die Transferrate entspricht immer der Leistung und verteilt sich auf die verbundenen Strahlen – so fließt stets die gesamte Leistung ab. | Leistung, Reichweite, Strahlen, Kapazität, Hülle |
| Verteiler | Leitet Energie weiter (3 Strahlen, große Reichweite) | Rate, Reichweite, Strahlen, Kapazität, Hülle |
| Speicher | Großer Energiespeicher | Kapazität, Rate, Reichweite, Strahlen, Hülle |
| Energieexporteur | Verkauft empfangene Energie für Geld (4 Energie = 1 Geld, Auszahlung in 5er-Paketen) | Exportrate, Kapazität, Hülle |
| Blitzturm | Schneller Einzelziel-Blitz (Boden + Luft) | Kraft, Tempo, Reichweite, Kritische Treffer, Effizienz, Kapazität, Hülle |
| Laserturm | Dauerstrahl, verbraucht Energie kontinuierlich | Kraft, Reichweite, Effizienz, Kapazität, Hülle |
| Teslaturm | Kettenblitz über bis zu 5 Ziele mit Abschwächung | Kraft, Tempo, Reichweite, Kettenziele, Kritische Treffer, Effizienz, Kapazität, Hülle |
| Plasmawerfer | Artillerie mit Flächenschaden, große Reichweite und Mindestreichweite, nur Bodenziele (auch Strukturen) | Kraft, Tempo, Reichweite, Explosionsradius, Kritische Treffer, Effizienz, Kapazität, Hülle |
| Schildgenerator | Absorbiert Schaden an Gebäuden im Radius mit eigener Energie | Stärke, Radius, Kapazität, Hülle |
| Heilturm | Repariert beschädigte Gebäude in Reichweite und verbraucht dafür Energie. Wählt das Ziel automatisch: am stärksten beschädigt, gerade unter Beschuss, Kern bevorzugt, plus etwas Zufall. Kein Überheilen, ohne Ziel kein Verbrauch. | Heilkraft, Heiltempo, Heilreichweite, Effizienz, Kapazität, Hülle |
| Mobiler Turm | Fahrbarer Blitzturm (Boden + Luft). Wird ausgewählt und per Joystick gesteuert (nur im Kampf); Fahren kostet viel Energie (ca. 6,7 pro Feld). Ohne Energie bleibt er stehen. Erweitert den Bauradius nicht und kann nicht versetzt werden. | Kraft, Tempo, Reichweite, Kritische Treffer, Fahreffizienz, Kapazität, Hülle |
| Bollwerk | Mauerblock mit sehr viel HP (2000, Türme nur 90–120). Blockiert Bodengegner, braucht keine Energie und erweitert den Bauradius nicht. Anfangs sehr günstig (4 Geld), alle 6 Bollwerke wird es 1 teurer. Im Baumodus kann man eine Mauerlinie ziehen; der Baumodus bleibt aktiv. | Hülle |

- **Energiewerte pro Gebäude:** Türme, Kern, mobiler Turm und Heilturm zeigen im Panel zusätzlich den Verbrauch pro Sekunde bei Dauerfeuer (beim Laser „Energie/s“), wie lange der eigene Speicher dabei reicht und wie viele Schüsse bzw. Heilungen eine volle Ladung ergibt. Ändert ein Upgrade den Verbrauch (Tempo, Effizienz), zeigt die Upgrade-Zeile zusätzlich „⚡ alt → neu/s“. Nach einem Upgrade hüpfen alle geänderten Werte kurz auf.
- **Upgrades:** viele kleine Stufen je Pfad, z. B. Kraft 40 Stufen à +10 %, Tempo 25 à +6 %, Rate 25 à +12 %, Reichweite 15 à +4 %, Leistung 30 à +10 %, Kapazität 25 à +20 %, Hülle 30 à +15 %, Effizienz 20 à +5 % (weniger Energie pro Schuss, Heilung oder Fahrt), Kritische Treffer 20 à +1 % Chance, Explosionsradius 15 à +5 %, Strahlen und Kettenziele je 5 Stufen à +1. Die Kosten wachsen pro Stufe um 12 % (Strahlen und Kette steiler). Das Panel zeigt „St. x/max“, aktuellen und nächsten Wert sowie die Kosten; die Liste ist scrollbar.
- **Verkaufen:** Investitionen aus der aktuellen Planungsphase werden voll erstattet, ältere Investitionen zu 50 %. Dieser Anteil sinkt mit dem Gesundheitszustand (z. B. bei 40 % HP nur 40 % davon).
- **Versetzen** (Button im Panel): in der Planungsphase kostenlos, im Kampf 20 % von Kaufpreis plus allen Upgrades (mindestens 1). Es gelten die normalen Bauregeln, das Gebäude selbst zählt dabei nicht für den Bauradius. Strahlen, die danach zu lang sind, werden gekappt. Kern und mobiler Turm lassen sich nicht versetzen.
- **Bauregeln:**
  - Nur innerhalb des Bauradius eigener Gebäude (Bollwerke zählen nicht).
  - Nur auf erkundetem, freiem Boden: nicht auf Klippen, Schluchten, Bäumen, Felsen, anderen Gebäuden oder Bodengegnern.
  - Abstand zu feindlichen Strukturen: in der Planungsphase 650 px (Hinweis „Zu nah an der Feindbasis – das geht nur während des Angriffs.“), im Kampf 150 px. Die Sperrzone wird im Baumodus um erkundete Feindstrukturen angezeigt.
  - Geld muss reichen und das Gebäude freigeschaltet sein.
- **Freischaltung je Level:**
  - Level 1: Solar, Verteiler, Speicher, Exporteur, Blitz, Bollwerk
  - Level 2: Laser, Heilturm, mobiler Turm
  - Level 3: Schild
  - Level 4: Tesla
  - Level 5: Plasma

## Energienetz

- Im Verbinden-Modus zieht man per Drag & Drop von einem sendenden Gebäude zu einem Ziel. Dabei entsteht ein elektrischer Energiestrahl in der Luft.
- Alternativ ohne Drag & Drop: Gebäude auswählen, im Panel „Verbinden“ tippen – Reichweite und alle gültigen Ziele (grüne Ringe) werden angezeigt – und dann das Ziel antippen. Tippen ins Leere bricht ab.
- Ist ein Gebäude ausgewählt, werden alle seine ein- und ausgehenden Verbindungen mit Richtungspfeil und die verbundenen Gebäude hervorgehoben (rot: Ziel gerade außer Reichweite).
  - Die Vorschau zeigt, ob die Verbindung gültig ist.
  - Fehlergründe erscheinen als Hinweis: zu weit, voll, existiert bereits, Ziel kann nicht empfangen usw.
- Wischt man im Verbinden-Modus über Strahlen (Start im leeren Raum oder auf einem nicht sendenden Gebäude), werden sie durchgeschnitten.
- **Sichtbarkeit:** Strahlen sind nur sichtbar, solange gerade Energie fließt, und blenden weich ein und aus. Im Verbinden-Modus werden zusätzlich alle Verbindungen gestrichelt angezeigt, damit man sie findet und kappen kann.
- **Energiefluss:**
  - Jeder Strahl überträgt bis zur Transferrate der Quelle; der Vorrat der Quelle wird gleichmäßig auf ihre Strahlen verteilt. Beim Solarpanel ist die Transferrate die Leistung, aufgeteilt auf die verbundenen Strahlen.
  - Strahlen, deren Ziel außer Reichweite ist (mobiler Turm ist weggefahren), bleiben bestehen, übertragen aber nichts, bis das Ziel wieder in Reichweite ist.
  - Begrenzt wird durch den freien Speicher des Ziels.
  - Die Dicke und das Leuchten eines Strahls zeigen den aktuellen Fluss; Energiepakete wandern sichtbar entlang.
- Türme ohne Energie feuern nicht und zeigen ein blinkendes Blitzsymbol.
- **Energiebilanz** (Diagramm-Button in der oberen Leiste, ab dem Setzen des Kerns): Ein Panel unter der Planungskarte zeigt live
  - Produktion pro Sekunde bei Tag und bei Nacht (Solar zählt nur am Tag),
  - Gesamtspeicher aller Gebäude, davon gespeichert (mit Prozent),
  - wie lange eine volle Ladung aller Speicher dauert (Tagproduktion minus Exporteure; „voll“ bzw. „nie“),
  - den Verbrauch aller Türme, des Kerns, mobiler Türme und Heiltürme bei Dauerfeuer sowie den Verbrauch der Exporteure,
  - die Bilanz bei Dauerfeuer am Tag und in der Nacht,
  - wie lange die aktuelle Reserve bei Dauerfeuer am Tag und in der Nacht reicht und wie lange volle Speicher nachts reichen („unbegrenzt“, wenn die Produktion reicht).
  - Eine farbige Spalte zeigt die Änderung seit Beginn der aktuellen Planungsphase (grün besser, rot schlechter, grau neutral; bei „unbegrenzt“/„voll“ steht „vorher …“). Nach Bauen, Upgraden, Verkaufen, Versetzen, Verbinden, Kappen oder Rückgängig hüpfen die geänderten Werte kurz auf.
  - Schilde fließen nicht ein (Verbrauch nur bei Treffern), Strahl-Transferlimits werden nicht berücksichtigt. Schließen über ✕, erneutes Tippen auf den Button oder die Zurück-Taste.

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
- HP, Schaden und Kopfgeld steigen mit jedem Tag und sind nachts zusätzlich erhöht (siehe Kampf).

## Belohnungen und „Juice“

- Getötete Gegner droppen Münzen. Diese fliegen nach kurzer Verzögerung sichtbar zur Geldanzeige, und der Zähler rollt hoch.
- **Combo-System:** Kills in schneller Folge erhöhen die Combo.
  - Meilensteine (5, 10, 20, 35, 50, 75, 100) zahlen Bonusgeld und lösen Banner, Konfetti und Sound aus.
  - Die Tonhöhe der Kill-Sounds steigt mit der Combo.
- **Kritische Treffer:** 12 % Grundchance auf doppelten Schaden (per Upgrade steigerbar), mit großer Schadenszahl und Effekt.
- Wird eine feindliche Struktur zerstört, gibt es Zeitlupe, Bildschirmwackeln, eine Explosion, einen Münzregen und ein Banner.
- Partikel, Ringe, Schadenszahlen, Vibration (abschaltbar) und synthetisierte Soundeffekte.
- Banner für Tagesstart, Nacht, Ende der Nacht und „Tag N überstanden“ (mit Fanfare und Konfetti), Nachtwellen-Hinweis, Exporteur-Einnahmen-Effekt, grüne Heilstrahlen mit „+N“, Landungs- und Basis-Banner, Rodungs-Effekte.

## Bedienung

- **Bauen:** Gebäude in der Bauleiste antippen. Ein Geist (Rasterfeld) zeigt Gültigkeit und Reichweite; Platzieren per Tippen oder Loslassen.
  - Energie-Abdeckung im Platzierungsmodus (nicht bei Bollwerk und Kern): Bebaubare Felder werden eingefärbt, je nachdem wie viele sendende Gebäude mit freiem Strahl sie erreichen – rot = 1, gelb = 2, grün = 3 oder mehr. Blau = nur von Gebäuden erreichbar, deren Strahlen alle belegt sind. Danach endet der Baumodus, außer bei Bollwerken: Hier zieht man Mauerlinien und baut weiter, bis das Geld fehlt. Die Kosten in der Bauleiste sind aktuell (Bollwerke werden teurer).
- **Soldat (nur während der Erkundung):** Joystick links unten, Hinweis-Chip darüber. Tippen auf nahe Bäume oder Felsen rodet. Der Button rechts unten springt zum Soldaten.
- **Mobiler Turm:** Auswählen zeigt den Joystick. Solange er ausgewählt ist, zeigt der Boden die Reichweite aller mit ihm verbundenen Sender (rot/gelb/grün = 1/2/3+), damit man sieht, wie weit er fahren kann. Abwählen hält ihn an.
- **Modus-Umschalter** (Button unten rechts):
  - „Verschieben“ (Standard): Ein Finger bewegt die Karte, Tippen wählt aus.
  - „Verbinden“: Ziehen verbindet, Wischen kappt. Doppeltippen und gedrückt halten verschiebt die Karte; bis zum Loslassen wird nicht verbunden. Die Zurück-Taste wechselt zurück zu Verschieben.
- **Auswahl:** Gebäude antippen öffnet ein Panel mit Werten, Upgrades (aktueller und nächster Wert, Kosten), Aktionen und Verkaufen. Reichweitenkreise und Verbindungen werden angezeigt.
  - Aktionen: „Verbinden x/y“ (Sender), „Angreifen“ (Türme, Kern, mobiler Turm) und „Versetzen −Kosten“.
- **Angriffsziel (Fokus):** „Angreifen“ tippen, dann einen sichtbaren Gegner, eine feindliche Struktur oder einen Baum/Felsen antippen. Der Turm schießt bevorzugt darauf, sobald es in Reichweite ist, sonst wie gewohnt nach Priorität. Strukturen und Hindernisse müssen in Reichweite sein. Fokus wird mit Fadenkreuz angezeigt und per „Ziel lösen“ aufgehoben. So lassen sich nach der Erkundung Bäume (140 HP) und Felsen (320 HP) mit Türmen zerstören; Plasma trifft sie mit dem Geschoss.
- **Zielpriorität pro Turm:** Im Panel jedes Turms (und des Kerns) zeigt eine Zeile die Reihenfolge Luft → Fernkampf → Nahkampf (Standard). Tippen auf eine Klasse deaktiviert oder aktiviert sie (z. B. Turm nur gegen Luft); die Pfeil-Buttons tauschen benachbarte Klassen. Klassen, die ein Turm nicht treffen kann (Plasma gegen Luft), sind ausgegraut. Strukturen greift ein Turm nur an, wenn Nah- oder Fernkampf aktiv ist.
- **Kamera:**
  - Ein Finger verschiebt im Verschieben-Modus.
  - Zwei Finger zoomen und verschieben in beiden Modi. Solange zwei Finger aufliegen, wird nicht verbunden oder geschnitten.
  - Im Verbinden-Modus: Doppeltippen und halten verschiebt.
  - Am Desktop: Mausrad sowie rechte oder mittlere Maustaste.
- **HUD:** Geld, Energiebalken mit Erzeugung pro Sekunde, Button für die Energiebilanz, Uhr (Planung/Tag/Nacht) mit Tages- und Wellenzähler, Planungskarte mit Rückgängig, Zurücksetzen und „Tag N starten“, Spielgeschwindigkeit 1×/2×/3× und Pause.
- **Pause-Menü:** Weiter, Neustart, Menü, Sound und Vibration.
- **Zurück-Taste:** schließt nacheinander Zielauswahl (Verbinden/Angreifen), Bau- oder Versetzen-Modus, Gebäudeauswahl, Energiebilanz und Verbinden-Modus, dann öffnet sie die Pause; nach Spielende geht sie zum Menü.
- **Tutorial** im ersten Level: Soldat mit Joystick laufen lassen → Basis setzen → Solar bauen → verbinden → Turm bauen → Turm versorgen → Bollwerke bauen → Kamera → Tag starten → Speicher → Strahl schneiden.

## Einstellungen und Fortschritt

- Sound, Vibration und Sprache (Deutsch/Englisch, Standard ist die Systemsprache) werden lokal gespeichert.
- Der Fortschritt (Sterne je Level, Gesamtkills, beste Combo) liegt als JSON in `user://progress.json`. Beschädigte Daten werden robust bereinigt.
