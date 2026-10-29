# Energy Wars – Features

Tower-Defense-/Eroberungsspiel für Android (Godot 4.7, Hochformat). Auf einer Weltkarte erobert man Gebiet für Gebiet. In jedem Gebiet landet ein Soldat per Fallschirm auf einer großen, vernebelten Karte und sucht einen Bauplatz. Dort baut man den Kern, mauert sich mit Bollwerken ein und baut ein Energienetz aus Solarpanels, Verteilern und Speichern. Damit versorgt man Türme über sichtbare Energiestrahlen und erobert die Karte, bis alle feindlichen Strukturen zerstört sind.

## Projektspezifische Ausnahmen von globalen Regeln

- **Übersetzungen:** Statt `strings.xml` wird – wie beim Referenzprojekt `../department` – Godots CSV-Übersetzung genutzt: `i18n/translations.csv` mit den Spalten `keys,en,de`. Englisch ist der Fallback.
- **Testabdeckung:** GUT misst keine Coverage. Abgedeckt sind alle Logikklassen (`src/core`) und die UI-Logik bzw. die Szenen (`src/ui`) über Unit- und Szenentests.
- **Grafik und Sound** werden vollständig prozedural zur Laufzeit erzeugt. Es gibt keine fremden Bild- oder Audiodateien.
  - Fonts: Geist (SIL OFL 1.1, `assets/fonts/OFL.txt`) und Material Icons (Apache 2.0, `assets/fonts/MaterialIcons-LICENSE.txt`).
  - Das App-Icon (`assets/icon.svg`) ist eine Eigenkreation.

## Spielablauf

1. **Weltkarte** (Hauptmenü): siehe Abschnitt „Weltkarte und Kampagne“. Von dort startet man eine Eroberung (Kampagne) oder – in eroberten Gebieten – den Survival-Modus.
2. **Erkundung:**
   - Ein Soldat schwebt am Fallschirm herab und landet. Während der Erkundung läuft keine Zeit und es kommen keine Gegner.
   - Der Soldat wird direkt gesteuert: Man zieht mit dem Finger **irgendwo auf der Karte** (schwebender Joystick, der unter dem Finger erscheint und ihm folgt), am Desktop alternativ mit Pfeiltasten/WASD. Einen festen Joystick gibt es nicht. Er läuft 195 px/s, sieht 460 px weit, gleitet an Klippen, Schluchten, Teichen, Wald und Felsen entlang und deckt dabei den Nebel auf. Die Kamera folgt ihm.
   - Tippt man auf einen Baum oder Felsen in seiner Nähe (goldener Ring, Reichweite ca. 2 Felder diagonal bzw. 2,9 Felder gerade), beseitigt er ihn: Bäume fällt er mit einem Schlag sofort, Felsen brauchen ca. 1,1 s. Läuft er während eines Felsens weg, bricht das Roden ab.
   - Tippt man einen weiter entfernten Baum oder Felsen an, läuft der Soldat per Wegsuche dorthin (gestrichelte Route, Fadenkreuz am Ziel) und rodet, sobald er nah genug ist. Tippen auf freien Boden schickt ihn ebenfalls dorthin (Ring am Zielpunkt). Ziehen zum Steuern bricht die Route ab. Ist ein Ziel nicht erreichbar, erscheint „Da kommt der Soldat nicht hin.“; auf Wasser, Klippen oder Gebäude zu tippen bewirkt nichts.
   - Während der Erkundung gibt es noch keine feindlichen Strukturen.
   - Mit „Basis“ in der Bauleiste setzt man den Kern: nur in der Nähe des Soldaten (420 px), auf erkundetem, freiem Boden. Ist der Ort zu weit weg, läuft der Soldat dorthin („Der Soldat läuft hin – tippe erneut, sobald er nah genug ist.“), der Baumodus bleibt aktiv. Danach beginnt die erste Planungsphase.
   - **Feindliche Basen erscheinen erst, wenn der Kern steht** – an zufälligen Stellen weit weg vom Kern (siehe „Platzierung feindlicher Strukturen“). Ein Hinweis meldet „N feindliche Bauten sind aufgetaucht“ und der Karten-Button hüpft.
   - Sobald der Kern steht, setzt sich der Soldat hinein und ist nicht mehr steuerbar. Von dort schießt er mit seinem Gewehr (ohne Energie, Reichweite 250) auf den nächsten Gegner.
3. **Planungsphase** (ohne Zeitlimit):
   - Man kann bauen, upgraden, verbinden, versetzen und verkaufen.
   - Es gibt keine Gegner, die Zeit steht still und alle Energie ist eingefroren: Generatoren und Exporteure produzieren nichts, Türme schießen nicht, Heiltürme heilen nicht, mobile Türme fahren nicht.
   - Versetzen ist kostenlos. Nur was in **dieser** Planungsphase investiert wurde (Bau und Upgrades), bekommt man beim Verkaufen voll zurück; Gebäude aus früheren Runden oder aus dem Kampf geben nur den normalen Anteil. Der Verkaufen-Button zeigt „volle Erstattung“ bzw. den Verlust, im Statusmodus markiert ein goldenes Symbol die voll erstattbaren Gebäude.
   - In einem großen Umkreis (650 px) um feindliche Strukturen darf nicht gebaut werden. Feindbasen besiegt man nur mit mobilen Türmen oder mit Gebäuden, die man während des Kampfes näher heranbaut (dann gilt nur der kleine Mindestabstand von 150 px).
   - Eine Karte oben zeigt „Planung · Tag N“, die Buttons „Rückgängig“ und „Zurücksetzen“ sowie „▶ Tag N starten“.
   - **Rückgängig** nimmt den letzten Planungsschritt zurück: Bauen, Upgraden, Verkaufen, Versetzen, Verbinden, Kappen, Zielpriorität, Fokus, Brennstoff markieren und Lampenhelligkeit. Ein Zug am Helligkeitsregler und ein Wischer, der mehrere Strahlen kappt, zählen jeweils als ein Schritt; jedes Bollwerk ist ein eigener Schritt. Gebäude, Energie, Strahlen und Geld kehren zum Stand vor dem Schritt zurück.
   - **Zurücksetzen** stellt nach einer Rückfrage den Zustand zu Beginn dieser Planungsphase wieder her. Einnahmen, die währenddessen eingingen, bleiben erhalten.
   - Beide Buttons sind ausgegraut, solange es nichts zurückzunehmen gibt. Mit dem Start des Tages endet die Historie.
4. **Kampf (Tag und Nacht):**
   - „Tag N starten“ beginnt den Tag. Die erste Welle kommt nach 3 s, danach alle 9 s eine weitere (Zähler „Tag N · Welle x/y“).
   - Jeder Spawner (Nest, Lager) schickt pro Welle mindestens einen Gegner; die Wellen werden im Laufe des Tages größer (bis zum 2,5-Fachen). Die Gegner einer Welle laufen kurz nacheinander (alle 0,3 s) aus einer gemeinsamen Richtung los. Bodenwellen sind um 35 % größer, Bodengegner richten 30 % mehr Schaden an.
   - Luftgegner gehören nicht zu den regulären Wellen. Ab Tag 4 kann bei jeder Welle mit 14 % Wahrscheinlichkeit (mindestens 4 Wellen Abstand) ein Luftangriff aus dem Nichts kommen: 3–5 Flieger (wächst langsam, höchstens 9) erscheinen gebündelt an einer zufälligen Stelle am Kartenrand, ohne Vorwarnung. In den ersten drei Tagen gibt es keine Flieger.
   - **Tagmonster:** Nach der Planungsphase ist es noch Tag. Dann kommen nur Tagmonster (Krabbler, Speier, Stachler, Käfer, Soldaten, Drohnen) – eher schwach.
   - **Nachtmonster:** Sobald die Nacht beginnt, schicken die Spawner nur noch Nachtmonster (Pirscher, Nachtschwinge, Plünderer, Phantomdrohne, Saboteur sowie die Bosse Koloss und Panzer). Sie sind deutlich stärker; Nachtwellen sind zusätzlich 1,2-mal so groß. Jede Nachtwelle wird mit Hinweis und Grollen angekündigt. Jedes Level hat dafür eine eigene Tag- und Nachtliste.
   - **Tagesanbruch:** Ist die Nacht vorbei, kommen keine neuen Gegner mehr. Alle Nachtmonster gehen in Flammen auf und verbrennen innerhalb von 0,6–2,4 s (Banner „Morgengrauen – N Nachtmonster gehen in Flammen auf“, Flammen und Funken). Verbrannte Monster bringen kein Kopfgeld und zählen nicht als Kill. Übrige Tagmonster muss man selbst besiegen („noch N Gegner“). Ist der letzte Gegner weg, gibt es ein Banner „Tag N überstanden“, alle Münzen werden eingesammelt, und die nächste Planungsphase beginnt.
   - Mit jedem Tag werden die Gegner stärker: HP ×1,22 pro Tag (ohne Deckel), Schaden +8 %, Kopfgeld +12 %, Wellen +40 %, und neue Gegnertypen kommen hinzu. Irgendwann ist die Verteidigung nicht mehr zu halten.
   - **Balance-Ziel:** Ein einzelner Turm reicht nur für die ersten ein, zwei Tage. Ab Tag 3 braucht man mehrere Türme, um Tag 5 drei bis vier ausgebaute, um Tag 8 sechs bis acht und ab Tag 10 zehn oder mehr mit passender Energieversorgung. Gegner haben dafür deutlich mehr HP, bringen aber weniger Kopfgeld; Upgrades werden pro Stufe um 18 % teurer. Man muss also Geld klug zwischen neuen Türmen, Upgrades, Energie und Mauern aufteilen.
   - Feindliche Geschütztürme verteidigen sich selbst.
   - **Wächter:** Im Kampf erscheinen zusätzlich Wächter rund um jedes Nest (Käfer mit 4-fachen HP) und jedes Lager (Soldaten mit 12-fachen HP). Ab 2 s nach Tagesstart kommen sie nacheinander (alle 0,8 s), bis 2 Wächter je Basis stehen (alle zwei Tage einer mehr, höchstens 5). Gefallene Wächter werden nach 30 s ersetzt, aber nur bis zum Ende der Nacht. Sie laufen langsam (55 %) auf einem Ring um ihre Basis Patrouille, greifen nie an und bringen 1,5-faches Kopfgeld. Sie halten das Rundenende nicht auf. Beginnt die Planungsphase oder fällt ihre Basis, gehen sie in Flammen auf und verbrennen ohne Kopfgeld. Wächter tragen einen gelben Markierungsring; wählt man eine Feindbasis aus, zeigt ein gestrichelter Ring ihre Patrouillenroute.
5. **Sieg (Kampagne):** Alle feindlichen Strukturen sind zerstört. Verbleibende Gegner werden vernichtet und alle Münzen eingesammelt. Das Gebiet gilt als erobert.
6. **Sieg (Survival):** Die gewählte Zahl an Tagen ist überstanden. Im Endlos-Modus gibt es keinen Sieg.
7. **Niederlage:** Der Kern wird zerstört.
   - **Checkpoint:** Bei jedem „Tag N starten“ merkt sich das Spiel den kompletten Stand direkt vor dem Start: Gelände inklusive gefällter oder verbrannter Bäume und Felsen, Nebel, beschädigte Hindernisse, alle Gebäude mit Upgrades, Energie, Namen, Zielprioritäten, Fokus, markiertem Brennstoff und Lampenradius, Strahlen, Geld, Tag, Kills, Verluste und Spielzeit.
   - Nach einer Niederlage bietet das Ergebnis „Ab letztem Start nochmal“ an (hervorgehoben vor „Nochmal spielen“). Damit beginnt man wieder in der Planungsphase genau dieses Tages, ohne Tutorial. Gegner, die bei Tagesbeginn schon verbrannten, und liegende Münzen werden nicht übernommen. Der Checkpoint lässt sich beliebig oft wiederholen.
8. **Ergebnis:** Titel je nach Modus („Erobert!“, „Überlebt!“, „Das Ende“ mit überlebten Tagen, „Kern zerstört“). Im Survival erscheinen die Sterne nacheinander mit Konfetti; bei neuem Sterne- bzw. Endlos-Rekord steht „Neuer Rekord!“. Darunter alle Herausforderungen des Gebiets mit Häkchen, neu geschaffte mit „+N SP“. Dazu Statistiken (überlebte Tage, Kills, beste Combo, verdientes Geld, Verluste, Zeit) und die Buttons „Weltkarte“, „Nochmal spielen“ und – nach einer Niederlage mit Checkpoint – „Ab letztem Start nochmal“.

## Weltkarte und Kampagne

- Die Weltkarte ist das Hauptmenü: eine Inselwelt mit 8 Gebieten, verbunden durch Wege. Oben stehen Titel, Gesamtsterne, verfügbare Skillpunkte und Kills; unten das Gebietspanel, der Forschungs-Button und Sound/Vibration/Sprache.
- Der eigene Soldat steht auf der Karte und **geht** über die Wege: Tippt man ein Gebiet an, läuft er auf dem kürzesten Weg dorthin – nur durch eroberte Gebiete. Während er läuft, sind die Start-Buttons gesperrt; tippt man unterwegs ein anderes Ziel an, läuft er vom nächsten Wegpunkt aus weiter. Sein Standort wird gespeichert.
- **Gebietszustände:** erobert (Energie-Flagge, Sterne darunter), Feindgebiet (pulsierender roter Ring, Nest- oder Lager-Symbol der Feinde, angreifbar), unbekannt (Schloss). Ein Gebiet wird angreifbar, sobald ein Nachbargebiet erobert ist; das erste Gebiet ist immer offen. Wege zwischen eroberten Gebieten leuchten, Wege zu Feindgebieten sind goldfarben gestrichelt, alle anderen grau.
- **Gebietspanel:** Name, Zustand, Beschreibung, alle Herausforderungen mit Häkchen und Skillpunkten. Buttons „Erobern“ bzw. „Erneut erobern“ (Kampagne, z. B. für offene Herausforderungen) und – in eroberten Gebieten – „Survival“.
- Gebiete und Wege: Erstes Licht → Käferhügel / Schwarmnacht → Grenzposten / Sabotage → Panzerfront / Koloss → Endschlacht (mit Querwegen, mehrere Routen möglich).

## Survival-Modus

- Nur in eroberten Gebieten. Ablauf wie in der Kampagne (Erkundung, Kern, Planung, Tag/Nacht), aber die Spawner (Nest, Lager) sind unverwundbar (violetter Schutzring): Türme greifen sie nicht an, Fokus ist nicht möglich. Feindliche Geschütztürme bleiben zerstörbar.
- Im Gebietspanel wählt man die Dauer: 5 Tage (★), 10 Tage (★★), 15 Tage (★★★) oder Endlos. Standard ist das nächste noch nicht erreichte Sternziel.
- Übersteht man alle Tage, ist das Survival gewonnen und bringt die Sterne der gewählten Dauer (pro Gebiet zählt das Maximum, insgesamt 24 Sterne).
- **Endlos:** Man kann nicht gewinnen; es zählt der Rekord an überlebten Tagen pro Gebiet („Endlos-Rekord: N Tage“).
- Die HUD-Uhr zeigt „Tag N/M“ (bzw. „Tag N“ im Endlos-Modus).

## Herausforderungen und Skillpunkte

- Jedes Gebiet hat drei Herausforderungen. Jede bringt einmalig Skillpunkte (SP):
  - „Erobere das Gebiet“ (2 SP).
  - Eine Kampagnen-Herausforderung (1 SP), z. B. Kern ≥ X %, höchstens N verlorene Gebäude, Eroberung bis Tag N oder eine ×N-Combo. Gilt nur bei einem Kampagnensieg.
  - „Überlebe N Tage im Survival“ (1 SP), gilt in jedem Survival-Lauf (auch bei Niederlage oder endlos), sobald N Tage überstanden sind.
- Insgesamt gibt es 32 SP – weniger, als der ganze Forschungsbaum kostet (52 SP). Man muss also wählen.

## Forschung (Tech-Baum)

- Button „Forschung · N SP“ auf der Weltkarte. Drei Zweige; jede Forschung kostet SP und setzt teils andere voraus (wie ein StarCraft-Techbaum). Gekaufte Forschung gilt für jeden Kampf (Kampagne und Survival).
- Zu Beginn verfügbar: Bollwerk, Solar, Verteiler, Speicher, Exporteur, Lampe, Blitzturm. Wasserrad, Feuerstelle und alle weiteren Türme werden erforscht.

| Zweig | Forschung (Kosten, Voraussetzung) |
|---|---|
| Waffen | Überladene Blitze (1): Blitzturm +20 % Schaden · Laserturm (2) · Mobiler Turm (2, Überladene Blitze) · Tesla-Spule (3, Überladene Blitze) · Plasmawerfer (3, Laserturm) · Fokuslinse (2, Laser): Laser +20 % Schaden · Bogenverstärker (2, Tesla): +1 Kettenziel · Instabiles Plasma (2, Plasma): +25 % Explosionsradius · Waffensysteme I (2, Laser) und II (3): alle Türme je +10 % Schaden · Zieloptik (2, Waffensysteme I): alle Türme +8 % Reichweite |
| Verteidigung | Verstärkte Mauern (1): Bollwerk +25 % HP · Heilturm (2) · Nanoreparatur (2, Heilturm): +25 % Heilkraft · Schildgenerator (3, Heilturm) · Panzerung I (2, Verstärkte Mauern) und II (3): alle Gebäude inkl. Kern je +15 % HP |
| Wirtschaft | Wasserrad (1) · Feuerstelle (1) · Bessere Zellen (1) und Perfekte Zellen (2): Solar je +15 % Leistung · Supraleiter (2, Bessere Zellen): alle Strahlen +25 % Übertragung, also 20 % weniger Strahlverlust · Dichte Speicher (1): Speicher +30 % Kapazität · Handelswege (2, Dichte Speicher): Exporteur +25 % Exportrate · Kriegskasse I (1) und II (2): +60 bzw. +120 Startgeld |

- Jede Zeile zeigt Symbol, Name, Wirkung, fehlende Voraussetzungen und den Kauf-Button (ausgegraut, wenn SP oder Voraussetzungen fehlen; „Erforscht“ bei Besitz).
- „Forschung zurücksetzen“ erstattet nach Rückfrage alle SP.
- Boni wirken auf die Grundwerte und stapeln sich mit den Upgrades im Kampf; das Gebäudepanel zeigt die erhöhten Werte.

## Gelände und Nebel

- **Große Karten** im Raster (Zelle 56 px), je nach Level 52×64 bis 76×96 Zellen. Sie werden pro Level deterministisch aus einem Seed erzeugt.
- **Plateaus** (Hochebenen) sind von Klippen umgeben und nur über Rampen erreichbar. Gebäude auf einem Plateau haben +20 % Reichweite und Sicht (Rampen zählen nicht).
- **Schluchten** sind unpassierbar und haben gelegentliche Brücken. **Teiche** (blaues Wasser mit Sandufer) sind unpassierbar, nicht bebaubar und nicht rodbar; Flieger überfliegen sie. **Wälder** und **Felsen** blockieren Weg und Bauplatz.
- **Häufigkeit je Level:** 3–6 Teiche, 11–20 kleine Wälder (Radius 2–5 Felder) und 12–20 Felsgruppen. Dazu 1–2 seltene **große Wälder** (Radius 7–10 Felder, Kern ohne Lücken), in die man sich mit dem Soldaten ein Loch für die Basis schlagen kann.
- **Vorteils-Spots:** Jedes Level hat feste Plätze, die an einigen Seiten durch Plateaus, Wald oder Felsen geschützt sind. Dort muss man weniger Bollwerke bauen.
- Alle begehbaren Bereiche sind verbunden (notfalls wird eine Furt durch Wasser oder eine Schneise durch Wald geschlagen). Nur der Spieler kann Bäume und Felsen entfernen, Gegner nicht.
- **Platzierung feindlicher Strukturen:** Beim Setzen des Kerns werden Nester und Lager zufällig (abhängig von Level und Kernposition) auf freiem, ebenem, vom Kern aus erreichbarem Boden mit 2 Feldern Freiraum platziert – mindestens 60 % der größten möglichen Entfernung vom Kern und nie näher als 900 px. Spawner halten 14 Felder Abstand zueinander (sofern möglich). Feindliche Geschütztürme stehen als Wache 5–9 Felder um einen Spawner. Findet sich kein Platz, wird die feste Ausweichposition des Levels genutzt.
- **Karte (Minimap):** Der runde Karten-Button rechts unten (über dem Modus- bzw. Soldaten-Button) öffnet oben eine Übersicht des ganzen Gebiets. Gelände wird im Nebel-Stil gezeigt (unerkundet dunkel, erkundet abgedunkelt). Feindliche Basen (rot) und Geschütztürme (orange) sind immer eingezeichnet, sobald sie existieren – auch im Nebel. Dazu der eigene Kern, eigene Gebäude, während der Erkundung der Soldat (gold) und der aktuelle Bildausschnitt als Rahmen. Die Kopfzeile nennt die Zahl der markierten Bauten (vor dem Kern: „Feindliche Basen erscheinen, sobald dein Kern steht.“). Tippen auf die Karte springt mit der Kamera dorthin und schließt sie. Karte und Energie-Statistik schließen sich gegenseitig; die Zurück-Taste schließt die Karte.
- **Nebel des Krieges:** Unerkundetes ist schwarz, Erkundetes abgedunkelt, sichtbar ist nur, was Soldat oder eigene Gebäude sehen. Gegner sind nur im sichtbaren Bereich zu sehen. Gebaut werden darf nur auf erkundetem Boden.

## Tag und Nacht

- Ein Kampftag besteht aus Tag (75–90 s) und Nacht (60–75 s), je nach Level. In der Planungsphase ist es hell, die Uhr steht.
- Solarpanels liefern Energie proportional zum Licht. Die Abenddämmerung (12 s) ist ein weicher Übergang, nachts liefern sie nichts. Nach der Nacht wird es in 8 s wieder hell.
- Nachts ist alles Unbeleuchtete so schwarz wie der Nebel des Krieges: Auch der Spieler sieht dort keine Gegner, Gegneraugen, Lebensbalken oder feindlichen Schäden. Man muss tagsüber genug Überschuss in die Speicher laden. Das Wasserrad liefert Tag und Nacht gleich viel.
- **Sicht bei Nacht:** Nachts sehen Türme, Kern und der Soldat im Kern nur, was beleuchtet ist. Der Kern leuchtet etwa 3 Felder in jede Richtung (ab seinem Rand), eingeschaltete Lampen in ihrem eingestellten Radius, verkleinert um den Anteil fehlender Ladung (halb voll = halber Radius). Jedes eigene Gebäude mit Energie (ab 0,5) glimmt zusätzlich schwach einen halben Block in jede Richtung um seine Grundfläche; auch das zählt als beleuchtet. Gegner und feindliche Strukturen außerhalb des Lichts werden nicht angegriffen, auch nicht per Fokus; Kettenblitze springen nicht ins Dunkle, Laser lassen Ziele fallen, die das Licht verlassen. Tagsüber und in der Planung gilt das nicht.
- Die Dunkelheit wird per Shader in der Nebelfarbe gezeichnet: Beleuchtete Bereiche sind mit weichem Rand aufgehellt (bis zu 32 Lichtquellen gleichzeitig), das Glimmen der Gebäude kommt als weiche Feldmaske dazu und hellt nur gedämpft auf.
- Die HUD-Uhr zeigt eine Flagge mit „Planung“, Sonne oder Mond mit der Zeit bis zum nächsten Wechsel, dazu den aktuellen Tag und die Welle.

## Gebäude

Jedes Gebäude hat Kosten, Lebenspunkte und eigene Upgrade-Pfade; die meisten haben einen Energiespeicher. Kern, Nest und Lager belegen 2×2 Zellen, alle anderen 1×1. Platziert wird am Raster.

| Gebäude | Funktion | Upgrades |
|---|---|---|
| Kern (Basis) | Wird nach der Erkundung gesetzt, erzeugt etwas Energie, hat 3 Strahlen und verteidigt sich selbst mit Blitzen. Der Soldat sitzt darin und schießt zusätzlich. | Rate, Reichweite, Strahlen, Strahlübertragung, Kraft, Tempo, Leistung, Kapazität, Hülle |
| Solarpanel | Erzeugt tagsüber Energie, kann nur senden. Die Transferrate entspricht immer der Leistung und verteilt sich auf die verbundenen Strahlen – so fließt stets die gesamte Leistung ab. | Leistung, Reichweite, Strahlen, Strahlübertragung, Kapazität, Hülle |
| Verteiler | Leitet Energie weiter (3 Strahlen, große Reichweite) | Rate, Reichweite, Strahlen, Strahlübertragung, Kapazität, Hülle |
| Speicher | Großer Energiespeicher | Kapazität, Rate, Reichweite, Strahlen, Strahlübertragung, Hülle |
| Energieexporteur | Verkauft empfangene Energie für Geld (8 Energie = 1 Geld). Ein Exportvorgang dauert mindestens 5 s: Pro Sekunde verbraucht er genau seine Exportrate, und der deutlich sichtbare blaue Ring um das Gebäude schließt sich dabei. Kommt nicht genug Energie für den nächsten Schritt an, verbraucht er nichts und der Ring bleibt stehen. Ist der Ring geschlossen (Exportrate × 5 s), ploppt die Auszahlung auf (Geld/s × 5, Bruchteile werden mitgenommen). Daher zahlen Exporteure unabhängig voneinander zu unterschiedlichen Zeiten aus. Das Panel zeigt zusätzlich den Fortschritt des aktuellen Zyklus in Prozent. Das Panel zeigt Verbrauch/s, Erlös/s, Kurs, Auszahlung („+5 alle 5 s“), Erlös pro Tag bei voller Versorgung und den realen Ertrag laut Netzdiagnose (Tag/Nacht). | Exportrate, Kapazität, Strahlübertragung, Hülle |
| Blitzturm | Schneller Einzelziel-Blitz (Boden + Luft) | Kraft, Tempo, Überladung, Reichweite, Kritische Treffer, Effizienz, Kapazität, Hülle |
| Laserturm | Dauerstrahl, verbraucht Energie kontinuierlich | Kraft, Überladung, Reichweite, Effizienz, Kapazität, Hülle |
| Teslaturm | Kettenblitz über bis zu 5 Ziele mit Abschwächung | Kraft, Tempo, Überladung, Reichweite, Kettenziele, Kritische Treffer, Effizienz, Kapazität, Hülle |
| Plasmawerfer | Artillerie mit Flächenschaden, große Reichweite und Mindestreichweite, nur Bodenziele (auch Strukturen) | Kraft, Tempo, Überladung, Reichweite, Explosionsradius, Kritische Treffer, Effizienz, Kapazität, Hülle |
| Schildgenerator | Absorbiert Schaden an Gebäuden im Radius mit eigener Energie | Stärke, Radius, Kapazität, Hülle |
| Heilturm | Repariert beschädigte Gebäude in Reichweite und verbraucht dafür Energie. Wählt das Ziel automatisch: am stärksten beschädigt, gerade unter Beschuss, Kern bevorzugt, plus etwas Zufall. Kein Überheilen, ohne Ziel kein Verbrauch. | Heilkraft, Heiltempo, Heilreichweite, Effizienz, Kapazität, Hülle |
| Bollwerk-Turm | Robuster Flugabwehrturm (nur Luft, 900 HP). Luftgegner greifen immer zuerst den nächsten Bollwerk-Turm an, Bodengegner ignorieren diese Sonderrolle. Wird im Verteidigungs-Zweig freigeschaltet (Tech „Bollwerk-Turm“, 2 Punkte, benötigt Rumpfpanzerung). | Kraft, Tempo, Reichweite, Kritische Treffer, Effizienz, Kapazität, Hülle |
| Mobiler Turm | Fahrbarer Blitzturm (Boden + Luft). Wird ausgewählt und durch Ziehen irgendwo auf der Karte gesteuert (nur im Kampf); Fahren kostet viel Energie (ca. 6,7 pro Feld). Ohne Energie bleibt er stehen. Erweitert den Bauradius nicht und kann nicht versetzt werden. | Kraft, Tempo, Überladung, Reichweite, Kritische Treffer, Fahreffizienz, Kapazität, Hülle |
| Bollwerk | Mauerblock mit sehr viel HP (2000, Türme nur 90–120). Blockiert Bodengegner, braucht keine Energie und erweitert den Bauradius nicht. Anfangs sehr günstig (4 Geld), alle 6 Bollwerke wird es 1 teurer. Wird wie jedes andere Gebäude einzeln platziert (für mehrere: „Mehrfach platzieren“). | Hülle |
| Wasserrad | Erzeugt wenig Energie (3/s), dafür Tag und Nacht gleich, unabhängig von der Sonne. Sendet nur, Transferrate = Leistung (wie Solar). Kosten 50, wird erforscht. | Leistung, Reichweite, Strahlen, Strahlübertragung, Kapazität, Hülle |
| Feuerstelle | Kostet sehr wenig (15) und liefert sehr viel (30/s, Tag und Nacht), aber nur, solange markierte Bäume brennen. Über „Bäume markieren (N)“ im Panel tippt man Bäume im Umkreis von 3,5 Feldern an (erkundet, nur Bäume; erneutes Tippen hebt die Markierung auf, Tippen ins Leere beendet). Ohne Markierung tut sie nichts. Im Kampf brennt sie die markierten Bäume nacheinander ab (je 15 s, Flammen und Fortschrittsbalken am Baum); danach ist das Feld frei begehbar – Bäume sind endlich und verbrannter Wald kann die Basis für Gegner öffnen. Fällt ein markierter Baum anders weg, verschwindet er aus der Liste; ist alles verbrannt, meldet ein Hinweis „Eine Feuerstelle hat alle Bäume verbrannt“. Das Panel zeigt markierte Bäume und die restliche Brenndauer. Wird erforscht. | Leistung, Reichweite, Strahlen, Strahlübertragung, Kapazität, Hülle |
| Lampe | Beleuchtet nachts ihren Umkreis, damit Türme dort Gegner sehen (von Anfang an verfügbar, Kosten 25). Empfängt Energie und verbraucht sie nur nachts, solange sie leuchtet; reicht die Energie nicht, geht sie aus. Der Helligkeitsregler im Panel stellt den Radius von 1,5 bis 7 Felder ein (Schritte à 0,5, Standard 3). Der Verbrauch steigt überproportional: 1,2/s bei 2 Feldern × (Radius ÷ 2)^2,5, doppelter Radius kostet also etwa 5,7-mal so viel. Effizienz-Upgrades („Lichteffizienz“) senken den Verbrauch. Das Panel zeigt Radius, Verbrauch nachts und ob sie gerade leuchtet („An · 2,0 Felder“ mit dem wirksamen Radius). Je leerer die Lampe, desto kleiner der Leuchtradius. Der Helligkeitsregler bleibt auch bei minimiertem Panel sichtbar. | Lichteffizienz, Kapazität, Strahlübertragung, Hülle |

- **Energiewerte pro Gebäude:** Türme, Kern, mobiler Turm und Heilturm zeigen im Panel zusätzlich den Verbrauch pro Sekunde bei Dauerfeuer (beim Laser „Energie/s“), wie lange der eigene Speicher dabei reicht und wie viele Schüsse bzw. Heilungen eine volle Ladung ergibt. Ändert ein Upgrade den Verbrauch (Tempo, Effizienz), zeigt die Upgrade-Zeile zusätzlich „⚡ alt → neu/s“. Nach einem Upgrade hüpfen alle geänderten Werte kurz auf.
- **Upgrades:** viele kleine Stufen je Pfad, z. B. Kraft 40 Stufen à +10 %, Tempo 25 à +6 %, Rate 25 à +12 %, Reichweite 15 à +4 %, Leistung 30 à +10 %, Kapazität 25 à +20 %, Hülle 30 à +15 %, Effizienz 20 à +5 % (weniger Energie pro Schuss, Heilung oder Fahrt), Kritische Treffer 20 à +1 % Chance, Explosionsradius 15 à +5 %, Strahlübertragung 10 à −10 % Strahlverlust (auf Stufe 10 verlustfrei), Strahlen und Kettenziele je 5 Stufen à +1.
- **Überladung (Fehl-Upgrade möglich):** 12 Stufen à +20 % Schaden, aber jede Stufe braucht ×1,25 Energie pro Schuss. Braucht ein Schuss mehr Energie, als der Turm speichern kann, ist er **überladen** und feuert gar nicht mehr (Blitzturm ab Stufe 11, Tesla ab 8, Plasma ab 6 ohne Kapazitäts-Upgrades). Man darf das bewusst oder versehentlich ausbauen. Die Upgrade-Zeile warnt vorher (Warnsymbol „Schuss > Speicher: feuert nicht mehr“), Kapazität bzw. Effizienz zeigen mit Häkchen „feuert wieder“, wenn sie die Überladung beheben, nach dem Upgrade erscheint ein Hinweis, und der Statusmodus markiert den Turm rot. Die Kosten wachsen pro Stufe um 18 % (Strahlen und Kette steiler). Das Panel zeigt „St. x/max“, aktuellen und nächsten Wert sowie die Kosten; die Liste ist scrollbar.
- **Verkaufen:** Investitionen aus der aktuellen Planungsphase werden voll erstattet, ältere Investitionen (auch alles, was im Kampf gebaut wurde) zu 50 %. Dieser Anteil sinkt mit dem Gesundheitszustand (z. B. bei 40 % HP nur 40 % davon). Der Button zeigt „+N (volle Erstattung)“ oder „+N (−M Verlust)“.
- **Versetzen** (Button im Panel): in der Planungsphase kostenlos, im Kampf 20 % von Kaufpreis plus allen Upgrades (mindestens 1). Es gelten die normalen Bauregeln, das Gebäude selbst zählt dabei nicht für den Bauradius. Strahlen, die danach zu lang sind, werden gekappt. Kern und mobiler Turm lassen sich nicht versetzen.
- **Bauregeln:**
  - Nur innerhalb des Bauradius eigener Gebäude (Bollwerke zählen nicht).
  - Nur auf erkundetem, freiem Boden: nicht auf Klippen, Schluchten, Teichen, Bäumen, Felsen, anderen Gebäuden oder Bodengegnern.
  - Abstand zu feindlichen Strukturen: in der Planungsphase 650 px (Hinweis „Zu nah an der Feindbasis – das geht nur während des Angriffs.“), im Kampf 150 px. Die Sperrzone wird im Baumodus um erkundete Feindstrukturen angezeigt.
  - Geld muss reichen und das Gebäude freigeschaltet sein.
- **Freischaltung:** über die Forschung (siehe „Forschung“), unabhängig vom Gebiet.

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
  - **Strahlverlust:** Jeder Strahl verliert 2,5 % pro Feld Lücke zwischen den Gebäuden (höchstens 60 %). Direkt benachbarte und diagonal angrenzende Gebäude (auch am 2×2-Kern) sind verlustfrei verbunden. Das Ziel erhält nur den Rest, die Quelle zahlt den vollen Betrag. Das Upgrade „Strahlübertragung“ gibt es an jedem Gebäude, das Energie sendet oder empfängt: Jede Stufe senkt den Verlust um 10 % des Grundwerts, auf Stufe 10 ist das Gebäude verlustfrei. Sender- und Empfängerstufe wirken beide (multiplikativ), die Forschung „Supraleiter“ teilt den Verlust zusätzlich. Ist das Ziel fast voll, wird nur so viel gesendet, wie ankommen kann, sodass nichts verschwendet wird. Das Panel zeigt pro Sender den „Verlust bei voller Weite“ und in der Upgrade-Zeile den Verlust pro Feld.
  - Die Dicke und das Leuchten eines Strahls zeigen den aktuellen Fluss; Energiepakete wandern sichtbar entlang.
- Türme ohne Energie feuern nicht und zeigen ein blinkendes Blitzsymbol.
- **Energiebilanz** (Diagramm-Button in der oberen Leiste, ab dem Setzen des Kerns): Ein Panel unter der Planungskarte zeigt live
  - Produktion pro Sekunde bei Tag und bei Nacht (Solar zählt nur am Tag, das Wasserrad immer, die Feuerstelle nur mit markierten Bäumen),
  - Gesamtspeicher aller Gebäude, davon gespeichert (mit Prozent),
  - wie lange eine volle Ladung aller Speicher dauert (Tagproduktion minus Exporteure; „voll“ bzw. „nie“),
  - den Verbrauch aller Türme, des Kerns, mobiler Türme, Heiltürme und Lampen bei Dauerfeuer bzw. voller Helligkeit sowie den Verbrauch der Exporteure,
  - die Bilanz bei Dauerfeuer am Tag und in der Nacht,
  - wie lange die aktuelle Reserve bei Dauerfeuer am Tag und in der Nacht reicht und wie lange volle Speicher nachts reichen („unbegrenzt“, wenn die Produktion reicht).
  - Eine farbige Spalte zeigt die Änderung seit Beginn der aktuellen Planungsphase (grün besser, rot schlechter, grau neutral; bei „unbegrenzt“/„voll“ steht „vorher …“). Nach Bauen, Upgraden, Verkaufen, Versetzen, Verbinden, Kappen oder Rückgängig hüpfen die geänderten Werte kurz auf.
  - Zusätzlich: Exporterlös (Geld/s, nach Strahlverlust), Strahlverlust am Tag (Energie/s), Strahleffizienz (ankommender Anteil) und wie viel Prozent des Bedarfs am Tag und in der Nacht gedeckt sind. Die Bilanzen ziehen den Strahlverlust ab.
  - Schilde fließen nicht ein (Verbrauch nur bei Treffern). Schließen über ✕, erneutes Tippen auf den Button oder die Zurück-Taste.
- **Statusmodus** (Netz-Button neben der Energiebilanz, ab dem Setzen des Kerns, in Planung und Kampf):
  - Eine Diagnose rechnet den Energiefluss im ganzen Netz und prüft für jedes Gebäude, ob im Dauerbetrieb genug Energie ankommen kann. Gerechnet wird ein Tag- und ein Nacht-Szenario, mit Transferraten, Strahlverlusten und fairer Aufteilung auf mehrere Strahlen (auch bei Kreisen im Netz). Nachts liefert Solar nichts; Speicher, Verteiler und Kern geben dafür ihren Speicherinhalt verteilt über die ganze Nacht ab (Kapazität ÷ Nachtlänge pro Sekunde).
  - **Bedarf:** Verbraucher brauchen ihren Verbrauch bei Dauerfeuer bzw. ihre Exportrate. Verteiler und Speicher brauchen so viel, wie sie weitergeben müssen (Bedarf der Ziele geteilt durch die Ankunftsquote der Strahlen, begrenzt durch die Transferrate). Überladene Türme brauchen nichts.
  - **Urteil nur ein Kettenglied weit:** Ob ein Gebäude unterversorgt ist, hängt nur von seinen direkten Lieferanten ab. Angenommen wird, dass diese selbst voll versorgt sind; Erzeuger zählen mit ihrer echten Leistung. Ein Engpass weiter vorne markiert so nur das Gebäude direkt dahinter, nicht die ganze nachgelagerte Kette. Auch „außer Reichweite“ und „keine Quelle“ betreffen nur das Gebäude am kaputten Strahl bzw. am Anfang einer Kette ohne Erzeuger.
  - In der Planung zeigt die Diagnose für jedes Gebäude die schlechtere Tageszeit, im Kampf die aktuelle (Tag oder Nacht).
  - **Abzeichen:** Erzeuger (Kern, Solar, Wasserrad, Feuerstelle) haben keines. Lampen zählen mit ihrem Nachtverbrauch als Bedarf. Alle anderen zeigen ein grünes Häkchen mit grünem Ring („Versorgt“), ein gelbes Warndreieck mit gelbem Ring („Unterversorgt“) oder ein rotes Fehlersymbol („Überladen“). Bei Unterversorgung wird der Ring anteilig rot, je nachdem, wie viel zur vollen Versorgung fehlt (Strahlverluste sind eingerechnet). Ohne Verbindung zu einem Erzeuger ist der Ring ganz rot. Prozentwerte werden auf der Karte nicht angezeigt.
  - Darunter steht der Verbrauch: Türme „Energie/Schuss · Energie/s“, Laser „Energie/s“, Heiltürme pro Heilung, Exporteure „Energie/s → Geld/s“, Erzeuger ihre Leistung, Verteiler den Durchsatz.
  - Die Karte zeigt im Statusmodus **keinen Text**, nur die Abzeichen (grünes Häkchen, gelbes Warndreieck mit Ring, rotes Fehlersymbol). Ohne Auswahl sind auch keine Strahlen sichtbar.
  - Wählt man ein Gebäude aus, erscheinen genau dessen direkte Strahlen (ein- und ausgehend) mit ihrer Rate. Vor- und nachgelagerte Ketten, Schuldigen-Puls und Verkaufs-Symbole gibt es nicht. Das Panel nennt Status (z. B. „Unterversorgt nachts · 2,4/s fehlen“), Bedarf, was tagsüber und nachts ankommt (mit Häkchen bzw. Warnsymbol), wie lange der eigene Speicher nachts reicht, Strahlen rein/raus und die Ursache mit Lösungsvorschlag: keine Quelle, außer Reichweite, Strahl am Limit, starker Strahlverlust, zu wenig Erzeugung, Nacht ohne Speicher oder zu kleiner Speicher („Der Speicher von Energiespeicher hält nachts bei Dauerfeuer nur 0:44 …“).
  - Eine Legende erklärt die Abzeichen.
- **Strahl-Beschriftung:** Ist ein eigenes Gebäude ausgewählt (auch im Statusmodus), werden nur die Strahlen direkt an diesem Gebäude hervorgehoben und beschriftet – keine anderen und keine, die nur über die Kette damit verbunden sind. Eingehende Strahlen zeigen nur, was ankommt („12,0/s“), ausgehende zusätzlich ihren Verlust („12,0/s (−5 %)“, bei Nachbarn „(−0 %)“), Strahlen außer Reichweite „außer Reichweite“. Dieselben Texte stehen in der Verbindungsliste des Panels. Die Farbe zeigt: Energie normal, gelb am Transferlimit, orange bei starkem Verlust (ab 15 %), rot außer Reichweite.

## Gegner

Es gibt drei Klassen: Nahkampf, Fernkampf und Luft.

| Gegner | Klasse | Zeit | Eigenschaften |
|---|---|---|---|
| Krabbler | Nahkampf | Tag | Schnell, schwach, Schwarm |
| Käfer | Nahkampf | Tag | Gepanzert, langsam |
| Speier | Fernkampf | Tag | Säurespucker aus dem Nest |
| Stachler | Luft | Tag | Schnell, schwach (Plasma trifft nicht) |
| Soldat | Fernkampf | Tag | Schießt aus Distanz |
| Drohne | Luft | Tag | Fliegt und schießt aus kurzer Distanz |
| Pirscher | Nahkampf | Nacht | Schnelles, kräftiges Raubtier aus dem Nest |
| Nachtschwinge | Luft | Nacht | Fledermausartiger Flieger |
| Koloss | Nahkampf | Nacht | Boss, sehr viel HP |
| Plünderer | Fernkampf | Nacht | Stärkerer Schütze mit Nachtsichtvisier |
| Phantomdrohne | Luft | Nacht | Stärkere, violett leuchtende Drohne |
| Saboteur | Nahkampf | Nacht | Läuft zum nächsten erreichbaren Strahl (freie Zelle direkt am Strahl) und schneidet ihn durch |
| Panzer | Fernkampf | Nacht | Boss mit großer Reichweite |

- Nachtmonster verbrennen bei Tagesanbruch (siehe Kampf).

- Nester schicken Tiere, Lager schicken Menschen und Maschinen. Jede Fraktion hat alle drei Klassen. Feindliche Geschütztürme schießen auf nahe Gebäude.
- **Pfadsuche:** Bodengegner laufen per A* um Klippen, Schluchten, Teiche, Wald, Felsen und Gebäude herum. Neue Mauern lösen eine Neuplanung aus.
- **Zielpriorität:** Exporteur > Heiler > Türme (inkl. Schild) > Bollwerke > Verteiler und Speicher > Kern. Gebäude, die mangels Energie gerade nichts tun, rutschen auf die niedrigste Stufe direkt über dem Kern. Bei gleicher Stufe gewinnt das nächste Ziel.
- **Erreichbarkeit:** Bodengegner (Nah- und Fernkampf) greifen nur Gebäude an, zu denen ein Weg führt. Ist die Basis eingemauert, greifen sie zuerst die Bollwerke an. Fernkämpfer schießen auch dann nicht über Mauern, wenn das Ziel in Reichweite ist. Luftgegner ignorieren das.
- Gegner zerstören Türme sehr schnell; nur Bollwerke halten lange stand. Man muss sich also einmauern. Mauern wirken am besten dicht an den Türmen: Fernkämpfer (Reichweite 110–120) bleiben dann in Turmreichweite, nur der Panzer schießt von weiter weg.
- HP, Schaden und Kopfgeld steigen mit jedem Tag (siehe Kampf).

## Belohnungen und „Juice“

- Getötete Gegner droppen Münzen. Diese fliegen nach kurzer Verzögerung sichtbar zur Geldanzeige, und der Zähler rollt hoch.
- **Combo-System:** Kills in schneller Folge erhöhen die Combo.
  - Meilensteine (5, 10, 20, 35, 50, 75, 100) zahlen Bonusgeld und lösen Banner, Konfetti und Sound aus.
  - Die Tonhöhe der Kill-Sounds steigt mit der Combo.
- **Kritische Treffer:** 12 % Grundchance auf doppelten Schaden (per Upgrade steigerbar), mit großer Schadenszahl und Effekt.
- Wird eine feindliche Struktur zerstört, gibt es Zeitlupe, Bildschirmwackeln, eine Explosion, einen Münzregen und ein Banner.
- Partikel, Ringe, Schadenszahlen, Vibration (abschaltbar) und synthetisierte Soundeffekte.
- Erscheinende Wächter blitzen gelb auf (einmaliger Hinweis), beim Start der Planungsphase meldet ein Hinweis „N Wächter gehen in Flammen auf“. Wächter brennen mit stärkeren Flammen.
- Verbrennende Nachtmonster flackern in Flammen und zerfallen mit Funkenregen; ein verbrannter Boss löst Bildschirmwackeln und den Hinweis „Boss verbrannt“ aus. Unverwundbare Survival-Spawner tragen einen pulsierenden violetten Schutzring.
- Banner für Tagesstart, Nacht, Ende der Nacht und „Tag N überstanden“ (mit Fanfare und Konfetti), Nachtwellen-Hinweis, Exporteur-Einnahmen-Effekt, grüne Heilstrahlen mit „+N“, Landungs- und Basis-Banner, Rodungs-Effekte. Verbrennt eine Feuerstelle einen Baum, sprühen Flammen und Funken; markierte Bäume, leuchtende Lampen und brennende Feuerstellen glühen.

## Bedienung

- **Bauen:** Nach dem Setzen des Kerns ist die Bauleiste eingeklappt und zeigt nur den großen Button „Bauen“. Antippen klappt sie auf: oben die Wahl „1× platzieren“ (Standard) oder „Mehrfach platzieren“ sowie ein Einklappen-Pfeil, darunter die Gebäudekarten. Gebäude antippen wählt es aus; nach dem Platzieren oder Abbrechen ist die Leiste wieder aufgeklappt, bis man sie über den Pfeil oder die Zurück-Taste einklappt. Während der Erkundung zeigt die Leiste direkt die Karte „Basis“.
  - Ein Geist (Rasterfeld) zeigt Gültigkeit und Reichweite; Platzieren per Tippen oder Loslassen. Alle Gebäude, auch Bollwerke, werden einzeln platziert.
  - Solange ein Gebäude zum Bauen oder Versetzen ausgewählt ist, steht anstelle der Leiste ein großer roter Button „Abbrechen: <Gebäude>“. Er beendet den Baumodus; beim Versetzen bleibt das Gebäude ausgewählt.
  - „1× platzieren“ beendet den Baumodus nach jedem gesetzten Gebäude. „Mehrfach platzieren“ behält das Gebäude ausgewählt, bis man abbricht oder das Geld für das nächste fehlt.
  - Energie-Abdeckung im Platzierungsmodus (nicht bei Bollwerk und Kern): Bebaubare Felder werden eingefärbt, je nachdem wie viele sendende Gebäude mit freiem Strahl sie erreichen – rot = 1, gelb = 2, grün = 3 oder mehr. Blau = nur von Gebäuden erreichbar, deren Strahlen alle belegt sind. Die Kosten in der Bauleiste sind aktuell (Bollwerke werden teurer).
- **Soldat (nur während der Erkundung):** Ziehen irgendwo auf der Karte (schwebender Joystick mit Totzone, der Ursprung wandert mit dem Finger mit), Hinweis-Chip unten mittig. Kurzes Tippen wählt weiterhin aus, rodet nahe Bäume oder Felsen oder schickt den Soldaten zum angetippten Ort bzw. zum entfernten Hindernis (siehe Erkundung). Der Button rechts unten springt zum Soldaten.
- **Mobiler Turm:** Im Kampf lenkt Ziehen irgendwo auf der Karte (im Verschieben-Modus ohne aktiven Bau- oder Zielmodus), am Desktop auch Pfeiltasten/WASD, solange er ausgewählt ist. Solange er ausgewählt ist, zeigt der Boden die Reichweite aller mit ihm verbundenen Sender (rot/gelb/grün = 1/2/3+), damit man sieht, wie weit er fahren kann. Abwählen hält ihn an.
- **Modus-Umschalter** (Button unten rechts):
  - „Verbinden“ (Standard ab dem Setzen des Kerns, auch nach einem Checkpoint-Neustart): Ziehen verbindet, Wischen kappt. Doppeltippen und gedrückt halten verschiebt die Karte; bis zum Loslassen wird nicht verbunden.
  - „Verschieben“: Ein Finger bewegt die Karte, Tippen wählt aus. Während der Erkundung ist immer Verschieben aktiv. Der Modus wechselt nur über den Button.
- **Auswahl:** Gebäude antippen öffnet ein Panel mit Werten, Upgrades (aktueller und nächster Wert, Kosten), Aktionen und Verkaufen. Reichweitenkreise und Verbindungen werden angezeigt.
- **Panel-Größe:** Das Gebäudepanel ist so hoch wie sein Inhalt, damit man nicht scrollen muss, und reicht höchstens bis direkt unter die Planungskarte (darüber scrollt der Inhalt).
- **Panel minimieren:** Der Pfeil-Button im Panelkopf klappt das Panel auf eine einzige Button-Höhe zusammen (nur Titel, Minimieren, Schließen). Der Titel zeigt dann Gebäudeart und Freitext-Name in einer Zeile und kürzt lange Namen mit „…“, damit die Höhe gleich bleibt. Bei Lampen bleibt darunter der Helligkeitsregler sichtbar. Panel und Bauleiste sind immer genau so hoch wie ihr Inhalt. Das Gebäude bleibt ausgewählt, Reichweiten, markierte Strahlen und Strahl-Beschriftungen bleiben auf der Karte sichtbar. Der Zustand bleibt beim Wechsel zu einem anderen Gebäude erhalten. „Verbinden“, „Versetzen“ und „Bäume markieren“ minimieren das Panel automatisch.
- **Verbindungen im Panel:** Eigene Gebäude mit Strahlen zeigen eine Liste aller ein- und ausgehenden Verbindungen (Pfeilrichtung, Gebäude samt Name; eingehend die ankommende Rate, ausgehend Rate und Verlust). Tippen auf den Eintrag wählt das Gegenstück aus und zentriert die Kamera, das ✕ kappt den einzelnen Strahl. „Alle eingehenden entfernen“ und „Alle ausgehenden entfernen“ kappen jeweils alle Strahlen der Richtung. Alles ist in der Planung rückgängig machbar.
- **Freitext-Name:** Eigene Gebäude haben im Panel ein Namensfeld (max. 24 Zeichen) unter dem Gebäudenamen. Der Name erscheint nur im Panel (minimiert im Titel) und in der Verbindungsliste, nicht auf der Karte.
  - Aktionen: „Verbinden x/y“ (Sender), „Angreifen“ (Türme, Kern, mobiler Turm), „Bäume markieren (N)“ (Feuerstelle) und „Versetzen −Kosten“. Lampen haben zusätzlich den Helligkeitsregler mit Radius und Verbrauch.
  - Ausgewählte Lampen und Feuerstellen zeigen ihren Licht- bzw. Brennstoff-Radius gestrichelt; beim Markieren sind alle markierbaren Bäume grün umringt, markierte Bäume orange.
- **Angriffsziel (Fokus):** „Angreifen“ tippen, dann einen sichtbaren Gegner, eine feindliche Struktur oder einen Baum/Felsen antippen. Der Turm schießt bevorzugt darauf, sobald es in Reichweite ist, sonst wie gewohnt nach Priorität. Strukturen und Hindernisse müssen in Reichweite sein. Fokus wird mit Fadenkreuz angezeigt und per „Ziel lösen“ aufgehoben. So lassen sich nach der Erkundung Bäume (140 HP) und Felsen (320 HP) mit Türmen zerstören; Plasma trifft sie mit dem Geschoss.
- **Zielpriorität pro Turm:** Im Panel jedes Turms (und des Kerns) zeigt eine Zeile die Reihenfolge Luft → Fernkampf → Nahkampf (Standard). Tippen auf eine Klasse deaktiviert oder aktiviert sie (z. B. Turm nur gegen Luft); die Pfeil-Buttons tauschen benachbarte Klassen. Klassen, die ein Turm nicht treffen kann (Plasma gegen Luft), sind ausgegraut. Strukturen greift ein Turm nur an, wenn Nah- oder Fernkampf aktiv ist.
- **Kamera:**
  - Ein Finger verschiebt im Verschieben-Modus.
  - Zwei Finger zoomen und verschieben in beiden Modi. Solange zwei Finger aufliegen, wird nicht verbunden oder geschnitten.
  - Im Verbinden-Modus: Doppeltippen und halten verschiebt.
  - Am Desktop: Mausrad sowie rechte oder mittlere Maustaste.
- **HUD:** Geld, Energiebalken mit Erzeugung pro Sekunde, Buttons für die Energiebilanz und den Statusmodus, Uhr (Planung/Tag/Nacht) mit Tages- und Wellenzähler, Planungskarte mit Rückgängig, Zurücksetzen und „Tag N starten“, Spielgeschwindigkeit 1×/2×/3× und Pause.
- **Pause-Menü:** Weiter, Neustart, Weltkarte, Sound und Vibration.
- **Aktive und hervorgehobene Buttons** (Hauptaktionen, gewählte Optionen, aktiver Statusmodus) sind dunkelblau mit hellblauer Schrift und Rand, nicht hellblau gefüllt.
- **Zurück-Taste:** schließt nacheinander Zielauswahl (Verbinden/Angreifen/Bäume markieren), Bau- oder Versetzen-Modus, Gebäudeauswahl, die aufgeklappte Bauleiste, Energiebilanz, Karte und Statusmodus, dann öffnet sie die Pause; nach Spielende geht sie zur Weltkarte. Auf der Weltkarte schließt sie die Rückfrage bzw. die Forschung, sonst beendet sie die App.
- **Tutorial** in der ersten Kampagne von „Erstes Licht“ (solange es nicht erobert ist): Soldat laufen lassen → Basis setzen → Solar bauen → verbinden → Turm bauen → Turm versorgen → Bollwerke bauen → Kamera → Tag starten → Speicher → Strahl schneiden.

## Einstellungen und Fortschritt

- Sound, Vibration und Sprache (Deutsch/Englisch, Standard ist die Systemsprache) werden lokal gespeichert.
- Der Fortschritt liegt als JSON (Version 2) in `user://progress.json`: pro Gebiet erobert, Survival-Sterne, Endlos-Rekord und geschaffte Herausforderungen; dazu gekaufte Forschung, Standort auf der Weltkarte, Gesamtkills und beste Combo. Beschädigte Daten werden robust bereinigt (unbekannte Gebiete, Herausforderungen und Forschungen fallen weg; wurde mehr ausgegeben als verdient, wird die Forschung zurückgesetzt).
- **Migration:** Ein alter Spielstand (Version 1, Sterne je Level) wird beim Laden übernommen: Jedes Level mit mindestens einem Stern gilt als erobert (inkl. „Erobere das Gebiet“), der Standort ist das letzte eroberte Gebiet. Andere Versionen werden verworfen.

## Spielstand zurücksetzen
- Auf der Weltkarte gibt es unten neben Ton, Vibration und Sprache einen Zurücksetzen-Button. Nach einer Sicherheitsabfrage („Spielstand zurücksetzen?“) werden eroberte Regionen, Sterne, Forschung, Position und Statistiken gelöscht (auch die Speicherdatei). Einstellungen bleiben erhalten. Danach startet die Weltkarte neu.
