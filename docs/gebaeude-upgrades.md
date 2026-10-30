# Gebäude und Upgrades

Alle Spielergebäude mit allen Upgrade-Pfaden, Kosten je Stufe, Gesamtkosten der Reihe und Kosten-Nutzen-Verhältnis. Berechnet aus `src/core/game_config.gd` und `src/core/formulas.gd` (Stand 30.10.2026). Ändert sich die Balance, ist die Datei neu zu erzeugen.

## Annahmen

- Grundwerte ohne Forschungsboni und auf ebenem Gelände (keine Höhenstufe). Forschung verändert die Grundwerte, nicht die Upgrade-Kosten.
- Jeder Upgrade-Pfad wird für sich betrachtet, alle anderen Pfade stehen auf Stufe 0.
- DPS sind Durchschnittswerte inklusive 12 % Grund-Kritchance (doppelter Schaden). Der Laser kann nicht kritisch treffen.
- Reichweiten in Feldern (1 Feld = 56 px), Energie in E, Energieraten in E/s.
- Leben (HP) und Panzerung sind getrennt: Leben ist die Trefferpunktzahl, Panzerung senkt jeden Treffer um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Den Pfad Panzerung haben alle Türme (Blitzturm, Laserturm, Tesla-Spule, Plasmawerfer, Bollwerk-Turm, Heilturm, Mobiler Turm).

## So liest du die Tabellen

| Spalte | Bedeutung |
|---|---|
| Stufe | Zielstufe des Upgrades (1 = erstes Upgrade) |
| Kosten | Preis genau dieser Stufe: `round(Upgrade-Basis × Preisfaktor × Wachstum^(Stufe − 1))`, mindestens 1. Upgrade-Basis = Baukosten (Kern 120, Bollwerk 40) |
| Summe | Kosten aller Stufen dieses Pfads bis einschließlich dieser |
| Veränderung | Der Spielwert, den das Upgrade verändert: vorher → nachher |
| Nutzen | Relativer Zuwachs der Nutzgröße gegenüber der vorigen Stufe |
| Münzen je % | Kosten ÷ Nutzen in Prozent – wie viele Münzen 1 % Verbesserung kostet. **Kleiner = lohnender**. Vergleichbar zwischen Pfaden desselben Gebäudes |
| Münzen je Einheit | Kosten ÷ absoluter Zuwachs (z. B. Münzen je HP, je DPS, je E/s). Vergleichbar zwischen Gebäuden und mit einem Neubau |
| Nutzen gesamt | Zuwachs der Nutzgröße gegenüber Stufe 0 |

„Neubau zum Vergleich“ nennt, was dieselbe Einheit kostet, wenn man stattdessen ein weiteres Gebäude baut (Baukosten ÷ Grundwert).

## Upgrade-Pfade im Überblick

| Pfad | Verändert | je Stufe | max. Stufen | Preisfaktor | Preiswachstum |
|---|---|---|---|---|---|
| Transferrate | Transferrate je Strahl (Exporteur: Exportrate) | +12 % des Grundwerts | 25 | 0,22 | ×1,18 |
| Reichweite | Strahl-, Angriffs-, Schild- oder Heilreichweite | +4 % des Grundwerts | 15 | 0,30 | ×1,18 |
| Strahlen | maximale ausgehende Strahlen | +1 Strahl | 5 | 0,80 | ×1,60 |
| Leistung | Energieerzeugung | +10 % des Grundwerts | 30 | 0,25 | ×1,18 |
| Kapazität | Energiespeicher | +20 % des Grundwerts | 25 | 0,18 | ×1,18 |
| Schaden | Schaden (Schild: Schildstärke, Heilturm: Heilkraft) | +10 % des Grundwerts | 40 | 0,22 | ×1,18 |
| Feuerrate | Feuerrate bzw. Heiltempo (Abklingzeit ÷ Multiplikator) | +6 % Tempo | 25 | 0,25 | ×1,18 |
| Leben | maximale HP (Lebenspunkte) | +15 % des Grundwerts | 30 | 0,18 | ×1,18 |
| Panzerung | Panzerung (Schadensreduktion), nur Türme | +15 % des Grundwerts | 20 | 0,15 | ×1,18 |
| Effizienz | Energie je Schuss/Heilung/Licht/Fahrt ÷ Multiplikator | +5 % Effizienz | 20 | 0,20 | ×1,18 |
| Kritische Treffer | Krit-Chance (Grund 12 %, Schaden ×2) | +1 Prozentpunkt | 20 | 0,25 | ×1,18 |
| Kettenziele | Kettenziele der Tesla-Spule | +1 Ziel | 5 | 0,70 | ×1,50 |
| Explosionsradius | Explosionsradius des Plasmawerfers | +5 % des Grundwerts | 15 | 0,25 | ×1,18 |
| Überladung | Schaden, aber auch Energie je Schuss | +20 % Schaden, ×1,25 Energie | 12 | 0,15 | ×1,18 |
| Strahlübertragung | Strahlverlust | −10 % des Verlusts | 10 | 0,20 | ×1,18 |
| Leben (Bollwerk) | maximale HP, eigene Kurve | ×3 bis ×37,5 | 8 | 0,125 | ×1,75 |

## Gebäude im Überblick

| Gebäude | Gruppe | Freischaltung | Baukosten | Upgrade-Basis | Pfade | Stufen gesamt | Alle Pfade maximal |
|---|---|---|---|---|---|---|---|
| [Kern](#kern) | Basis | immer vorhanden (wird beim Landen gesetzt) | – | 120 | 9 | 205 | 181.703 |
| [Solarpanel](#solarpanel) | Energie | von Anfang an | 40 | 40 | 6 | 115 | 17.489 |
| [Wasserrad](#wasserrad) | Energie | Forschung „Wasserrad“ (1 SP) | 50 | 50 | 6 | 115 | 21.875 |
| [Feuerstelle](#feuerstelle) | Energie | Forschung „Feuerstelle“ (1 SP) | 15 | 15 | 6 | 115 | 6.561 |
| [Verteiler](#verteiler) | Energie | von Anfang an | 30 | 30 | 6 | 110 | 9.449 |
| [Energiespeicher](#energiespeicher) | Energie | von Anfang an | 80 | 80 | 6 | 110 | 25.199 |
| [Energieexporteur](#energieexporteur) | Energie | von Anfang an | 120 | 120 | 4 | 90 | 34.084 |
| [Blitzturm](#blitzturm) | Türme | von Anfang an | 70 | 70 | 10 | 217 | 92.532 |
| [Laserturm](#laserturm) | Türme | Forschung „Laserturm“ (2 SP) | 120 | 120 | 7 | 160 | 143.297 |
| [Tesla-Spule](#tesla-spule) | Türme | Forschung „Tesla-Spule“ (3 SP) | 160 | 160 | 11 | 222 | 212.970 |
| [Plasmawerfer](#plasmawerfer) | Türme | Forschung „Plasmawerfer“ (3 SP) | 200 | 200 | 11 | 232 | 267.406 |
| [Bollwerk](#bollwerk) | Verteidigung | von Anfang an | 4 (+1 je 6 gebaute) | 40 | 1 | 8 | 580 |
| [Bollwerk-Turm](#bollwerk-turm) | Verteidigung | Forschung „Bollwerk-Turm“ (2 SP) | 130 | 130 | 9 | 205 | 171.149 |
| [Schildgenerator](#schildgenerator) | Verteidigung | Forschung „Schildgenerator“ (3 SP) | 140 | 140 | 5 | 120 | 160.014 |
| [Heilturm](#heilturm) | Verteidigung | Forschung „Heilturm“ (2 SP) | 110 | 110 | 8 | 185 | 140.789 |
| [Lampe](#lampe) | Extras | von Anfang an | 25 | 25 | 4 | 85 | 5.953 |
| [Mobiler Turm](#mobiler-turm) | Extras | Forschung „Mobiler Turm“ (2 SP) | 150 | 150 | 10 | 217 | 198.275 |

## Basis

### Kern

- **Freischaltung:** immer vorhanden (wird beim Landen gesetzt)
- **Baukosten:** – · **Upgrade-Basis:** 120
- **Grundwerte:** 1.500 HP · Panzerung 20 · Kapazität 300 · Leistung 3 E/s · 3 Strahlen à 5,00 Felder · Transferrate 40 E/s · 12 Schaden alle 0,70 s, 3 Energie/Schuss, Reichweite 3,93 Felder · DPS 19,2 (Ø inkl. 12 % Krit)

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Transferrate | 25 | 26 | 1.402 | 9.041 | +300 % | 2,17 → 453 |
| Reichweite | 15 | 36 | 365 | 2.193 | +60 % | 9,00 → 142 |
| Strahlen | 5 | 96 | 629 | 1.518 | +167 % | 2,88 → 44,0 |
| Strahlübertragung | 10 | 24 | 106 | 563 | +11 % | 21,6 → 105 |
| Schaden | 40 | 26 | 16.788 | 109.904 | +400 % | 2,60 → 8.226 |
| Feuerrate | 25 | 30 | 1.593 | 10.277 | +150 % | 5,00 → 648 |
| Leistung | 30 | 30 | 3.645 | 23.727 | +300 % | 3,00 → 1.422 |
| Kapazität | 25 | 22 | 1.147 | 7.398 | +500 % | 1,10 → 333 |
| Leben | 30 | 22 | 2.624 | 17.082 | +450 % | 1,47 → 936 |

#### Kern – Transferrate

**Verändert:** Transferrate je ausgehendem Strahl (Energie pro Sekunde, die ein Strahl höchstens weitergibt). **Je Stufe:** +12 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 26 | 26 | 40,0 → 44,8 E/s je Strahl | +12,00 % | 2,17 | 5,42 | +12,0 % |
| 2 | 31 | 57 | 44,8 → 49,6 E/s je Strahl | +10,71 % | 2,89 | 6,46 | +24,0 % |
| 3 | 37 | 94 | 49,6 → 54,4 E/s je Strahl | +9,68 % | 3,82 | 7,71 | +36,0 % |
| 4 | 43 | 137 | 54,4 → 59,2 E/s je Strahl | +8,82 % | 4,87 | 8,96 | +48,0 % |
| 5 | 51 | 188 | 59,2 → 64,0 E/s je Strahl | +8,11 % | 6,29 | 10,6 | +60,0 % |
| 6 | 60 | 248 | 64,0 → 68,8 E/s je Strahl | +7,50 % | 8,00 | 12,5 | +72,0 % |
| 7 | 71 | 319 | 68,8 → 73,6 E/s je Strahl | +6,98 % | 10,2 | 14,8 | +84,0 % |
| 8 | 84 | 403 | 73,6 → 78,4 E/s je Strahl | +6,52 % | 12,9 | 17,5 | +96,0 % |
| 9 | 99 | 502 | 78,4 → 83,2 E/s je Strahl | +6,12 % | 16,2 | 20,6 | +108,0 % |
| 10 | 117 | 619 | 83,2 → 88,0 E/s je Strahl | +5,77 % | 20,3 | 24,4 | +120,0 % |
| 11 | 138 | 757 | 88,0 → 92,8 E/s je Strahl | +5,45 % | 25,3 | 28,8 | +132,0 % |
| 12 | 163 | 920 | 92,8 → 97,6 E/s je Strahl | +5,17 % | 31,5 | 34,0 | +144,0 % |
| 13 | 192 | 1.112 | 97,6 → 102,4 E/s je Strahl | +4,92 % | 39,0 | 40,0 | +156,0 % |
| 14 | 227 | 1.339 | 102,4 → 107,2 E/s je Strahl | +4,69 % | 48,4 | 47,3 | +168,0 % |
| 15 | 268 | 1.607 | 107,2 → 112,0 E/s je Strahl | +4,48 % | 59,9 | 55,8 | +180,0 % |
| 16 | 316 | 1.923 | 112,0 → 116,8 E/s je Strahl | +4,29 % | 73,7 | 65,8 | +192,0 % |
| 17 | 373 | 2.296 | 116,8 → 121,6 E/s je Strahl | +4,11 % | 90,8 | 77,7 | +204,0 % |
| 18 | 440 | 2.736 | 121,6 → 126,4 E/s je Strahl | +3,95 % | 111 | 91,7 | +216,0 % |
| 19 | 519 | 3.255 | 126,4 → 131,2 E/s je Strahl | +3,80 % | 137 | 108 | +228,0 % |
| 20 | 613 | 3.868 | 131,2 → 136,0 E/s je Strahl | +3,66 % | 168 | 128 | +240,0 % |
| 21 | 723 | 4.591 | 136,0 → 140,8 E/s je Strahl | +3,53 % | 205 | 151 | +252,0 % |
| 22 | 853 | 5.444 | 140,8 → 145,6 E/s je Strahl | +3,41 % | 250 | 178 | +264,0 % |
| 23 | 1.007 | 6.451 | 145,6 → 150,4 E/s je Strahl | +3,30 % | 305 | 210 | +276,0 % |
| 24 | 1.188 | 7.639 | 150,4 → 155,2 E/s je Strahl | +3,19 % | 372 | 247 | +288,0 % |
| 25 | 1.402 | 9.041 | 155,2 → 160,0 E/s je Strahl | +3,09 % | 453 | 292 | +300,0 % |

#### Kern – Reichweite

**Verändert:** Strahlreichweite und Angriffsreichweite (und damit Sichtweite). Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. „Münzen je Feld“ bezieht sich auf die Strahlreichweite. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 36 | 36 | Strahl 5,00 → 5,20 · Angriff 3,93 → 4,09 Felder | +4,00 % | 9,00 | 180 | +4,0 % |
| 2 | 42 | 78 | Strahl 5,20 → 5,40 · Angriff 4,09 → 4,24 Felder | +3,85 % | 10,9 | 210 | +8,0 % |
| 3 | 50 | 128 | Strahl 5,40 → 5,60 · Angriff 4,24 → 4,40 Felder | +3,70 % | 13,5 | 250 | +12,0 % |
| 4 | 59 | 187 | Strahl 5,60 → 5,80 · Angriff 4,40 → 4,56 Felder | +3,57 % | 16,5 | 295 | +16,0 % |
| 5 | 70 | 257 | Strahl 5,80 → 6,00 · Angriff 4,56 → 4,71 Felder | +3,45 % | 20,3 | 350 | +20,0 % |
| 6 | 82 | 339 | Strahl 6,00 → 6,20 · Angriff 4,71 → 4,87 Felder | +3,33 % | 24,6 | 410 | +24,0 % |
| 7 | 97 | 436 | Strahl 6,20 → 6,40 · Angriff 4,87 → 5,03 Felder | +3,23 % | 30,1 | 485 | +28,0 % |
| 8 | 115 | 551 | Strahl 6,40 → 6,60 · Angriff 5,03 → 5,19 Felder | +3,12 % | 36,8 | 575 | +32,0 % |
| 9 | 135 | 686 | Strahl 6,60 → 6,80 · Angriff 5,19 → 5,34 Felder | +3,03 % | 44,6 | 675 | +36,0 % |
| 10 | 160 | 846 | Strahl 6,80 → 7,00 · Angriff 5,34 → 5,50 Felder | +2,94 % | 54,4 | 800 | +40,0 % |
| 11 | 188 | 1.034 | Strahl 7,00 → 7,20 · Angriff 5,50 → 5,66 Felder | +2,86 % | 65,8 | 940 | +44,0 % |
| 12 | 222 | 1.256 | Strahl 7,20 → 7,40 · Angriff 5,66 → 5,81 Felder | +2,78 % | 79,9 | 1.110 | +48,0 % |
| 13 | 262 | 1.518 | Strahl 7,40 → 7,60 · Angriff 5,81 → 5,97 Felder | +2,70 % | 96,9 | 1.310 | +52,0 % |
| 14 | 310 | 1.828 | Strahl 7,60 → 7,80 · Angriff 5,97 → 6,13 Felder | +2,63 % | 118 | 1.550 | +56,0 % |
| 15 | 365 | 2.193 | Strahl 7,80 → 8,00 · Angriff 6,13 → 6,29 Felder | +2,56 % | 142 | 1.825 | +60,0 % |

#### Kern – Strahlen

**Verändert:** Maximale Zahl ausgehender Strahlen. Jeder Strahl hat die volle Transferrate, der mögliche Gesamtdurchsatz steigt also um einen Strahl. **Je Stufe:** +1 Strahl.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Strahl | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 96 | 96 | 3 → 4 Strahlen | +33,33 % | 2,88 | 96 | +33,3 % |
| 2 | 154 | 250 | 4 → 5 Strahlen | +25,00 % | 6,16 | 154 | +66,7 % |
| 3 | 246 | 496 | 5 → 6 Strahlen | +20,00 % | 12,3 | 246 | +100,0 % |
| 4 | 393 | 889 | 6 → 7 Strahlen | +16,67 % | 23,6 | 393 | +133,3 % |
| 5 | 629 | 1.518 | 7 → 8 Strahlen | +14,29 % | 44,0 | 629 | +166,7 % |

#### Kern – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf ein- und ausgehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 24 | 24 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 21,6 | +1,1 % |
| 2 | 28 | 52 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 25,5 | +2,2 % |
| 3 | 33 | 85 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 30,4 | +3,3 % |
| 4 | 39 | 124 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 36,3 | +4,4 % |
| 5 | 47 | 171 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 44,2 | +5,6 % |
| 6 | 55 | 226 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 52,2 | +6,7 % |
| 7 | 65 | 291 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 62,4 | +7,8 % |
| 8 | 76 | 367 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 73,7 | +8,9 % |
| 9 | 90 | 457 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 88,2 | +10,0 % |
| 10 | 106 | 563 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 105 | +11,1 % |

#### Kern – Schaden

**Verändert:** Schaden je Schuss (Laser: je Sekunde). **Je Stufe:** +10 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 26 | 26 | Schaden/Schuss 12,0 → 13,2 | +10,00 % | 2,60 | 13,5 | +10,0 % |
| 2 | 31 | 57 | Schaden/Schuss 13,2 → 14,4 | +9,09 % | 3,41 | 16,1 | +20,0 % |
| 3 | 37 | 94 | Schaden/Schuss 14,4 → 15,6 | +8,33 % | 4,44 | 19,3 | +30,0 % |
| 4 | 43 | 137 | Schaden/Schuss 15,6 → 16,8 | +7,69 % | 5,59 | 22,4 | +40,0 % |
| 5 | 51 | 188 | Schaden/Schuss 16,8 → 18,0 | +7,14 % | 7,14 | 26,6 | +50,0 % |
| 6 | 60 | 248 | Schaden/Schuss 18,0 → 19,2 | +6,67 % | 9,00 | 31,2 | +60,0 % |
| 7 | 71 | 319 | Schaden/Schuss 19,2 → 20,4 | +6,25 % | 11,4 | 37,0 | +70,0 % |
| 8 | 84 | 403 | Schaden/Schuss 20,4 → 21,6 | +5,88 % | 14,3 | 43,7 | +80,0 % |
| 9 | 99 | 502 | Schaden/Schuss 21,6 → 22,8 | +5,56 % | 17,8 | 51,6 | +90,0 % |
| 10 | 117 | 619 | Schaden/Schuss 22,8 → 24,0 | +5,26 % | 22,2 | 60,9 | +100,0 % |
| 11 | 138 | 757 | Schaden/Schuss 24,0 → 25,2 | +5,00 % | 27,6 | 71,9 | +110,0 % |
| 12 | 163 | 920 | Schaden/Schuss 25,2 → 26,4 | +4,76 % | 34,2 | 84,9 | +120,0 % |
| 13 | 192 | 1.112 | Schaden/Schuss 26,4 → 27,6 | +4,55 % | 42,2 | 100 | +130,0 % |
| 14 | 227 | 1.339 | Schaden/Schuss 27,6 → 28,8 | +4,35 % | 52,2 | 118 | +140,0 % |
| 15 | 268 | 1.607 | Schaden/Schuss 28,8 → 30,0 | +4,17 % | 64,3 | 140 | +150,0 % |
| 16 | 316 | 1.923 | Schaden/Schuss 30,0 → 31,2 | +4,00 % | 79,0 | 165 | +160,0 % |
| 17 | 373 | 2.296 | Schaden/Schuss 31,2 → 32,4 | +3,85 % | 97,0 | 194 | +170,0 % |
| 18 | 440 | 2.736 | Schaden/Schuss 32,4 → 33,6 | +3,70 % | 119 | 229 | +180,0 % |
| 19 | 519 | 3.255 | Schaden/Schuss 33,6 → 34,8 | +3,57 % | 145 | 270 | +190,0 % |
| 20 | 613 | 3.868 | Schaden/Schuss 34,8 → 36,0 | +3,45 % | 178 | 319 | +200,0 % |
| 21 | 723 | 4.591 | Schaden/Schuss 36,0 → 37,2 | +3,33 % | 217 | 377 | +210,0 % |
| 22 | 853 | 5.444 | Schaden/Schuss 37,2 → 38,4 | +3,23 % | 264 | 444 | +220,0 % |
| 23 | 1.007 | 6.451 | Schaden/Schuss 38,4 → 39,6 | +3,12 % | 322 | 524 | +230,0 % |
| 24 | 1.188 | 7.639 | Schaden/Schuss 39,6 → 40,8 | +3,03 % | 392 | 619 | +240,0 % |
| 25 | 1.402 | 9.041 | Schaden/Schuss 40,8 → 42,0 | +2,94 % | 477 | 730 | +250,0 % |
| 26 | 1.654 | 10.695 | Schaden/Schuss 42,0 → 43,2 | +2,86 % | 579 | 861 | +260,0 % |
| 27 | 1.952 | 12.647 | Schaden/Schuss 43,2 → 44,4 | +2,78 % | 703 | 1.017 | +270,0 % |
| 28 | 2.304 | 14.951 | Schaden/Schuss 44,4 → 45,6 | +2,70 % | 852 | 1.200 | +280,0 % |
| 29 | 2.718 | 17.669 | Schaden/Schuss 45,6 → 46,8 | +2,63 % | 1.033 | 1.416 | +290,0 % |
| 30 | 3.208 | 20.877 | Schaden/Schuss 46,8 → 48,0 | +2,56 % | 1.251 | 1.671 | +300,0 % |
| 31 | 3.785 | 24.662 | Schaden/Schuss 48,0 → 49,2 | +2,50 % | 1.514 | 1.971 | +310,0 % |
| 32 | 4.466 | 29.128 | Schaden/Schuss 49,2 → 50,4 | +2,44 % | 1.831 | 2.326 | +320,0 % |
| 33 | 5.270 | 34.398 | Schaden/Schuss 50,4 → 51,6 | +2,38 % | 2.213 | 2.745 | +330,0 % |
| 34 | 6.219 | 40.617 | Schaden/Schuss 51,6 → 52,8 | +2,33 % | 2.674 | 3.239 | +340,0 % |
| 35 | 7.338 | 47.955 | Schaden/Schuss 52,8 → 54,0 | +2,27 % | 3.229 | 3.822 | +350,0 % |
| 36 | 8.659 | 56.614 | Schaden/Schuss 54,0 → 55,2 | +2,22 % | 3.897 | 4.510 | +360,0 % |
| 37 | 10.218 | 66.832 | Schaden/Schuss 55,2 → 56,4 | +2,17 % | 4.700 | 5.322 | +370,0 % |
| 38 | 12.057 | 78.889 | Schaden/Schuss 56,4 → 57,6 | +2,13 % | 5.667 | 6.280 | +380,0 % |
| 39 | 14.227 | 93.116 | Schaden/Schuss 57,6 → 58,8 | +2,08 % | 6.829 | 7.410 | +390,0 % |
| 40 | 16.788 | 109.904 | Schaden/Schuss 58,8 → 60,0 | +2,04 % | 8.226 | 8.744 | +400,0 % |

#### Kern – Feuerrate

**Verändert:** Abklingzeit zwischen zwei Schüssen (Feuerrate = 1 ÷ Abklingzeit). Mehr Schüsse brauchen entsprechend mehr Energie pro Sekunde. **Je Stufe:** +6 % Feuerrate.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 30 | 30 | 0,700 → 0,660 s (1,51 Schüsse/s) | +6,00 % | 5,00 | 26,0 | +6,0 % |
| 2 | 35 | 65 | 0,660 → 0,625 s (1,60 Schüsse/s) | +5,66 % | 6,18 | 30,4 | +12,0 % |
| 3 | 42 | 107 | 0,625 → 0,593 s (1,69 Schüsse/s) | +5,36 % | 7,84 | 36,5 | +18,0 % |
| 4 | 49 | 156 | 0,593 → 0,565 s (1,77 Schüsse/s) | +5,08 % | 9,64 | 42,5 | +24,0 % |
| 5 | 58 | 214 | 0,565 → 0,538 s (1,86 Schüsse/s) | +4,84 % | 12,0 | 50,3 | +30,0 % |
| 6 | 69 | 283 | 0,538 → 0,515 s (1,94 Schüsse/s) | +4,62 % | 15,0 | 59,9 | +36,0 % |
| 7 | 81 | 364 | 0,515 → 0,493 s (2,03 Schüsse/s) | +4,41 % | 18,4 | 70,3 | +42,0 % |
| 8 | 96 | 460 | 0,493 → 0,473 s (2,11 Schüsse/s) | +4,23 % | 22,7 | 83,3 | +48,0 % |
| 9 | 113 | 573 | 0,473 → 0,455 s (2,20 Schüsse/s) | +4,05 % | 27,9 | 98,1 | +54,0 % |
| 10 | 133 | 706 | 0,455 → 0,437 s (2,29 Schüsse/s) | +3,90 % | 34,1 | 115 | +60,0 % |
| 11 | 157 | 863 | 0,437 → 0,422 s (2,37 Schüsse/s) | +3,75 % | 41,9 | 136 | +66,0 % |
| 12 | 185 | 1.048 | 0,422 → 0,407 s (2,46 Schüsse/s) | +3,61 % | 51,2 | 161 | +72,0 % |
| 13 | 219 | 1.267 | 0,407 → 0,393 s (2,54 Schüsse/s) | +3,49 % | 62,8 | 190 | +78,0 % |
| 14 | 258 | 1.525 | 0,393 → 0,380 s (2,63 Schüsse/s) | +3,37 % | 76,5 | 224 | +84,0 % |
| 15 | 304 | 1.829 | 0,380 → 0,368 s (2,71 Schüsse/s) | +3,26 % | 93,2 | 264 | +90,0 % |
| 16 | 359 | 2.188 | 0,368 → 0,357 s (2,80 Schüsse/s) | +3,16 % | 114 | 312 | +96,0 % |
| 17 | 424 | 2.612 | 0,357 → 0,347 s (2,89 Schüsse/s) | +3,06 % | 139 | 368 | +102,0 % |
| 18 | 500 | 3.112 | 0,347 → 0,337 s (2,97 Schüsse/s) | +2,97 % | 168 | 434 | +108,0 % |
| 19 | 590 | 3.702 | 0,337 → 0,327 s (3,06 Schüsse/s) | +2,88 % | 205 | 512 | +114,0 % |
| 20 | 696 | 4.398 | 0,327 → 0,318 s (3,14 Schüsse/s) | +2,80 % | 248 | 604 | +120,0 % |
| 21 | 822 | 5.220 | 0,318 → 0,310 s (3,23 Schüsse/s) | +2,73 % | 301 | 714 | +126,0 % |
| 22 | 970 | 6.190 | 0,310 → 0,302 s (3,31 Schüsse/s) | +2,65 % | 365 | 842 | +132,0 % |
| 23 | 1.144 | 7.334 | 0,302 → 0,294 s (3,40 Schüsse/s) | +2,59 % | 442 | 993 | +138,0 % |
| 24 | 1.350 | 8.684 | 0,294 → 0,287 s (3,49 Schüsse/s) | +2,52 % | 535 | 1.172 | +144,0 % |
| 25 | 1.593 | 10.277 | 0,287 → 0,280 s (3,57 Schüsse/s) | +2,46 % | 648 | 1.383 | +150,0 % |

#### Kern – Leistung

**Verändert:** Energieerzeugung pro Sekunde. **Je Stufe:** +10 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 30 | 30 | 3,00 → 3,30 E/s | +10,00 % | 3,00 | 100,0 | +10,0 % |
| 2 | 35 | 65 | 3,30 → 3,60 E/s | +9,09 % | 3,85 | 117 | +20,0 % |
| 3 | 42 | 107 | 3,60 → 3,90 E/s | +8,33 % | 5,04 | 140 | +30,0 % |
| 4 | 49 | 156 | 3,90 → 4,20 E/s | +7,69 % | 6,37 | 163 | +40,0 % |
| 5 | 58 | 214 | 4,20 → 4,50 E/s | +7,14 % | 8,12 | 193 | +50,0 % |
| 6 | 69 | 283 | 4,50 → 4,80 E/s | +6,67 % | 10,3 | 230 | +60,0 % |
| 7 | 81 | 364 | 4,80 → 5,10 E/s | +6,25 % | 13,0 | 270 | +70,0 % |
| 8 | 96 | 460 | 5,10 → 5,40 E/s | +5,88 % | 16,3 | 320 | +80,0 % |
| 9 | 113 | 573 | 5,40 → 5,70 E/s | +5,56 % | 20,3 | 377 | +90,0 % |
| 10 | 133 | 706 | 5,70 → 6,00 E/s | +5,26 % | 25,3 | 443 | +100,0 % |
| 11 | 157 | 863 | 6,00 → 6,30 E/s | +5,00 % | 31,4 | 523 | +110,0 % |
| 12 | 185 | 1.048 | 6,30 → 6,60 E/s | +4,76 % | 38,8 | 617 | +120,0 % |
| 13 | 219 | 1.267 | 6,60 → 6,90 E/s | +4,55 % | 48,2 | 730 | +130,0 % |
| 14 | 258 | 1.525 | 6,90 → 7,20 E/s | +4,35 % | 59,3 | 860 | +140,0 % |
| 15 | 304 | 1.829 | 7,20 → 7,50 E/s | +4,17 % | 73,0 | 1.013 | +150,0 % |
| 16 | 359 | 2.188 | 7,50 → 7,80 E/s | +4,00 % | 89,7 | 1.197 | +160,0 % |
| 17 | 424 | 2.612 | 7,80 → 8,10 E/s | +3,85 % | 110 | 1.413 | +170,0 % |
| 18 | 500 | 3.112 | 8,10 → 8,40 E/s | +3,70 % | 135 | 1.667 | +180,0 % |
| 19 | 590 | 3.702 | 8,40 → 8,70 E/s | +3,57 % | 165 | 1.967 | +190,0 % |
| 20 | 696 | 4.398 | 8,70 → 9,00 E/s | +3,45 % | 202 | 2.320 | +200,0 % |
| 21 | 822 | 5.220 | 9,00 → 9,30 E/s | +3,33 % | 247 | 2.740 | +210,0 % |
| 22 | 970 | 6.190 | 9,30 → 9,60 E/s | +3,23 % | 301 | 3.233 | +220,0 % |
| 23 | 1.144 | 7.334 | 9,60 → 9,90 E/s | +3,12 % | 366 | 3.813 | +230,0 % |
| 24 | 1.350 | 8.684 | 9,90 → 10,20 E/s | +3,03 % | 446 | 4.500 | +240,0 % |
| 25 | 1.593 | 10.277 | 10,20 → 10,50 E/s | +2,94 % | 542 | 5.310 | +250,0 % |
| 26 | 1.880 | 12.157 | 10,50 → 10,80 E/s | +2,86 % | 658 | 6.267 | +260,0 % |
| 27 | 2.218 | 14.375 | 10,80 → 11,10 E/s | +2,78 % | 798 | 7.393 | +270,0 % |
| 28 | 2.618 | 16.993 | 11,10 → 11,40 E/s | +2,70 % | 969 | 8.727 | +280,0 % |
| 29 | 3.089 | 20.082 | 11,40 → 11,70 E/s | +2,63 % | 1.174 | 10.297 | +290,0 % |
| 30 | 3.645 | 23.727 | 11,70 → 12,00 E/s | +2,56 % | 1.422 | 12.150 | +300,0 % |

#### Kern – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). Hebt die Grenze, ab der eine Überladung den Turm stilllegt. **Je Stufe:** +20 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 22 | 22 | 300,0 → 360,0 Energie | +20,00 % | 1,10 | 0,37 | +20,0 % |
| 2 | 25 | 47 | 360,0 → 420,0 Energie | +16,67 % | 1,50 | 0,42 | +40,0 % |
| 3 | 30 | 77 | 420,0 → 480,0 Energie | +14,29 % | 2,10 | 0,50 | +60,0 % |
| 4 | 35 | 112 | 480,0 → 540,0 Energie | +12,50 % | 2,80 | 0,58 | +80,0 % |
| 5 | 42 | 154 | 540,0 → 600,0 Energie | +11,11 % | 3,78 | 0,70 | +100,0 % |
| 6 | 49 | 203 | 600,0 → 660,0 Energie | +10,00 % | 4,90 | 0,82 | +120,0 % |
| 7 | 58 | 261 | 660,0 → 720,0 Energie | +9,09 % | 6,38 | 0,97 | +140,0 % |
| 8 | 69 | 330 | 720,0 → 780,0 Energie | +8,33 % | 8,28 | 1,15 | +160,0 % |
| 9 | 81 | 411 | 780,0 → 840,0 Energie | +7,69 % | 10,5 | 1,35 | +180,0 % |
| 10 | 96 | 507 | 840,0 → 900,0 Energie | +7,14 % | 13,4 | 1,60 | +200,0 % |
| 11 | 113 | 620 | 900,0 → 960,0 Energie | +6,67 % | 17,0 | 1,88 | +220,0 % |
| 12 | 133 | 753 | 960,0 → 1.020,0 Energie | +6,25 % | 21,3 | 2,22 | +240,0 % |
| 13 | 157 | 910 | 1.020,0 → 1.080,0 Energie | +5,88 % | 26,7 | 2,62 | +260,0 % |
| 14 | 186 | 1.096 | 1.080,0 → 1.140,0 Energie | +5,56 % | 33,5 | 3,10 | +280,0 % |
| 15 | 219 | 1.315 | 1.140,0 → 1.200,0 Energie | +5,26 % | 41,6 | 3,65 | +300,0 % |
| 16 | 259 | 1.574 | 1.200,0 → 1.260,0 Energie | +5,00 % | 51,8 | 4,32 | +320,0 % |
| 17 | 305 | 1.879 | 1.260,0 → 1.320,0 Energie | +4,76 % | 64,0 | 5,08 | +340,0 % |
| 18 | 360 | 2.239 | 1.320,0 → 1.380,0 Energie | +4,55 % | 79,2 | 6,00 | +360,0 % |
| 19 | 425 | 2.664 | 1.380,0 → 1.440,0 Energie | +4,35 % | 97,7 | 7,08 | +380,0 % |
| 20 | 501 | 3.165 | 1.440,0 → 1.500,0 Energie | +4,17 % | 120 | 8,35 | +400,0 % |
| 21 | 592 | 3.757 | 1.500,0 → 1.560,0 Energie | +4,00 % | 148 | 9,87 | +420,0 % |
| 22 | 698 | 4.455 | 1.560,0 → 1.620,0 Energie | +3,85 % | 181 | 11,6 | +440,0 % |
| 23 | 824 | 5.279 | 1.620,0 → 1.680,0 Energie | +3,70 % | 222 | 13,7 | +460,0 % |
| 24 | 972 | 6.251 | 1.680,0 → 1.740,0 Energie | +3,57 % | 272 | 16,2 | +480,0 % |
| 25 | 1.147 | 7.398 | 1.740,0 → 1.800,0 Energie | +3,45 % | 333 | 19,1 | +500,0 % |

#### Kern – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 22 | 22 | 1.500,0 → 1.725,0 HP | +15,00 % | 1,47 | 0,098 | +15,0 % |
| 2 | 25 | 47 | 1.725,0 → 1.950,0 HP | +13,04 % | 1,92 | 0,111 | +30,0 % |
| 3 | 30 | 77 | 1.950,0 → 2.175,0 HP | +11,54 % | 2,60 | 0,133 | +45,0 % |
| 4 | 35 | 112 | 2.175,0 → 2.400,0 HP | +10,34 % | 3,38 | 0,156 | +60,0 % |
| 5 | 42 | 154 | 2.400,0 → 2.625,0 HP | +9,38 % | 4,48 | 0,187 | +75,0 % |
| 6 | 49 | 203 | 2.625,0 → 2.850,0 HP | +8,57 % | 5,72 | 0,218 | +90,0 % |
| 7 | 58 | 261 | 2.850,0 → 3.075,0 HP | +7,89 % | 7,35 | 0,258 | +105,0 % |
| 8 | 69 | 330 | 3.075,0 → 3.300,0 HP | +7,32 % | 9,43 | 0,307 | +120,0 % |
| 9 | 81 | 411 | 3.300,0 → 3.525,0 HP | +6,82 % | 11,9 | 0,360 | +135,0 % |
| 10 | 96 | 507 | 3.525,0 → 3.750,0 HP | +6,38 % | 15,0 | 0,427 | +150,0 % |
| 11 | 113 | 620 | 3.750,0 → 3.975,0 HP | +6,00 % | 18,8 | 0,502 | +165,0 % |
| 12 | 133 | 753 | 3.975,0 → 4.200,0 HP | +5,66 % | 23,5 | 0,591 | +180,0 % |
| 13 | 157 | 910 | 4.200,0 → 4.425,0 HP | +5,36 % | 29,3 | 0,698 | +195,0 % |
| 14 | 186 | 1.096 | 4.425,0 → 4.650,0 HP | +5,08 % | 36,6 | 0,827 | +210,0 % |
| 15 | 219 | 1.315 | 4.650,0 → 4.875,0 HP | +4,84 % | 45,3 | 0,973 | +225,0 % |
| 16 | 259 | 1.574 | 4.875,0 → 5.100,0 HP | +4,62 % | 56,1 | 1,151 | +240,0 % |
| 17 | 305 | 1.879 | 5.100,0 → 5.325,0 HP | +4,41 % | 69,1 | 1,356 | +255,0 % |
| 18 | 360 | 2.239 | 5.325,0 → 5.550,0 HP | +4,23 % | 85,2 | 1,600 | +270,0 % |
| 19 | 425 | 2.664 | 5.550,0 → 5.775,0 HP | +4,05 % | 105 | 1,889 | +285,0 % |
| 20 | 501 | 3.165 | 5.775,0 → 6.000,0 HP | +3,90 % | 129 | 2,227 | +300,0 % |
| 21 | 592 | 3.757 | 6.000,0 → 6.225,0 HP | +3,75 % | 158 | 2,631 | +315,0 % |
| 22 | 698 | 4.455 | 6.225,0 → 6.450,0 HP | +3,61 % | 193 | 3,102 | +330,0 % |
| 23 | 824 | 5.279 | 6.450,0 → 6.675,0 HP | +3,49 % | 236 | 3,662 | +345,0 % |
| 24 | 972 | 6.251 | 6.675,0 → 6.900,0 HP | +3,37 % | 288 | 4,320 | +360,0 % |
| 25 | 1.147 | 7.398 | 6.900,0 → 7.125,0 HP | +3,26 % | 352 | 5,098 | +375,0 % |
| 26 | 1.354 | 8.752 | 7.125,0 → 7.350,0 HP | +3,16 % | 429 | 6,018 | +390,0 % |
| 27 | 1.597 | 10.349 | 7.350,0 → 7.575,0 HP | +3,06 % | 522 | 7,098 | +405,0 % |
| 28 | 1.885 | 12.234 | 7.575,0 → 7.800,0 HP | +2,97 % | 635 | 8,378 | +420,0 % |
| 29 | 2.224 | 14.458 | 7.800,0 → 8.025,0 HP | +2,88 % | 771 | 9,884 | +435,0 % |
| 30 | 2.624 | 17.082 | 8.025,0 → 8.250,0 HP | +2,80 % | 936 | 11,662 | +450,0 % |

## Energie

### Solarpanel

- **Freischaltung:** von Anfang an
- **Baukosten:** 40 · **Upgrade-Basis:** 40
- **Grundwerte:** 70 HP · Panzerung 0 · Kapazität 30 · Leistung 8 E/s · 1 Strahl à 4,29 Felder

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Leistung | 30 | 10 | 1.215 | 7.909 | +300 % | 1,00 → 474 |
| Reichweite | 15 | 12 | 122 | 730 | +60 % | 3,00 → 47,6 |
| Strahlen | 5 | 32 | 210 | 506 | ±0 % | – |
| Strahlübertragung | 10 | 8 | 35 | 187 | +11 % | 7,20 → 34,6 |
| Kapazität | 25 | 7 | 382 | 2.465 | +500 % | 0,35 → 111 |
| Leben | 30 | 7 | 875 | 5.692 | +450 % | 0,47 → 312 |

#### Solarpanel – Leistung

**Verändert:** Energieerzeugung pro Sekunde. Nur bei Tageslicht. Bei Solar, Wasserrad und Feuerstelle ist die Strahlrate gleich der Leistung. **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 5,00 Münzen je E/s.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 10 | 10 | 8,00 → 8,80 E/s | +10,00 % | 1,00 | 12,5 | +10,0 % |
| 2 | 12 | 22 | 8,80 → 9,60 E/s | +9,09 % | 1,32 | 15,0 | +20,0 % |
| 3 | 14 | 36 | 9,60 → 10,40 E/s | +8,33 % | 1,68 | 17,5 | +30,0 % |
| 4 | 16 | 52 | 10,40 → 11,20 E/s | +7,69 % | 2,08 | 20,0 | +40,0 % |
| 5 | 19 | 71 | 11,20 → 12,00 E/s | +7,14 % | 2,66 | 23,7 | +50,0 % |
| 6 | 23 | 94 | 12,00 → 12,80 E/s | +6,67 % | 3,45 | 28,7 | +60,0 % |
| 7 | 27 | 121 | 12,80 → 13,60 E/s | +6,25 % | 4,32 | 33,7 | +70,0 % |
| 8 | 32 | 153 | 13,60 → 14,40 E/s | +5,88 % | 5,44 | 40,0 | +80,0 % |
| 9 | 38 | 191 | 14,40 → 15,20 E/s | +5,56 % | 6,84 | 47,5 | +90,0 % |
| 10 | 44 | 235 | 15,20 → 16,00 E/s | +5,26 % | 8,36 | 55,0 | +100,0 % |
| 11 | 52 | 287 | 16,00 → 16,80 E/s | +5,00 % | 10,4 | 65,0 | +110,0 % |
| 12 | 62 | 349 | 16,80 → 17,60 E/s | +4,76 % | 13,0 | 77,5 | +120,0 % |
| 13 | 73 | 422 | 17,60 → 18,40 E/s | +4,55 % | 16,1 | 91,3 | +130,0 % |
| 14 | 86 | 508 | 18,40 → 19,20 E/s | +4,35 % | 19,8 | 107 | +140,0 % |
| 15 | 101 | 609 | 19,20 → 20,00 E/s | +4,17 % | 24,2 | 126 | +150,0 % |
| 16 | 120 | 729 | 20,00 → 20,80 E/s | +4,00 % | 30,0 | 150 | +160,0 % |
| 17 | 141 | 870 | 20,80 → 21,60 E/s | +3,85 % | 36,7 | 176 | +170,0 % |
| 18 | 167 | 1.037 | 21,60 → 22,40 E/s | +3,70 % | 45,1 | 209 | +180,0 % |
| 19 | 197 | 1.234 | 22,40 → 23,20 E/s | +3,57 % | 55,2 | 246 | +190,0 % |
| 20 | 232 | 1.466 | 23,20 → 24,00 E/s | +3,45 % | 67,3 | 290 | +200,0 % |
| 21 | 274 | 1.740 | 24,00 → 24,80 E/s | +3,33 % | 82,2 | 342 | +210,0 % |
| 22 | 323 | 2.063 | 24,80 → 25,60 E/s | +3,23 % | 100 | 404 | +220,0 % |
| 23 | 381 | 2.444 | 25,60 → 26,40 E/s | +3,12 % | 122 | 476 | +230,0 % |
| 24 | 450 | 2.894 | 26,40 → 27,20 E/s | +3,03 % | 149 | 562 | +240,0 % |
| 25 | 531 | 3.425 | 27,20 → 28,00 E/s | +2,94 % | 181 | 664 | +250,0 % |
| 26 | 627 | 4.052 | 28,00 → 28,80 E/s | +2,86 % | 219 | 784 | +260,0 % |
| 27 | 739 | 4.791 | 28,80 → 29,60 E/s | +2,78 % | 266 | 924 | +270,0 % |
| 28 | 873 | 5.664 | 29,60 → 30,40 E/s | +2,70 % | 323 | 1.091 | +280,0 % |
| 29 | 1.030 | 6.694 | 30,40 → 31,20 E/s | +2,63 % | 391 | 1.287 | +290,0 % |
| 30 | 1.215 | 7.909 | 31,20 → 32,00 E/s | +2,56 % | 474 | 1.519 | +300,0 % |

#### Solarpanel – Reichweite

**Verändert:** Strahlreichweite. Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 12 | 12 | 4,29 → 4,46 Felder | +4,00 % | 3,00 | 70,0 | +4,0 % |
| 2 | 14 | 26 | 4,46 → 4,63 Felder | +3,85 % | 3,64 | 81,7 | +8,0 % |
| 3 | 17 | 43 | 4,63 → 4,80 Felder | +3,70 % | 4,59 | 99,2 | +12,0 % |
| 4 | 20 | 63 | 4,80 → 4,97 Felder | +3,57 % | 5,60 | 117 | +16,0 % |
| 5 | 23 | 86 | 4,97 → 5,14 Felder | +3,45 % | 6,67 | 134 | +20,0 % |
| 6 | 27 | 113 | 5,14 → 5,31 Felder | +3,33 % | 8,10 | 157 | +24,0 % |
| 7 | 32 | 145 | 5,31 → 5,49 Felder | +3,23 % | 9,92 | 187 | +28,0 % |
| 8 | 38 | 183 | 5,49 → 5,66 Felder | +3,12 % | 12,2 | 222 | +32,0 % |
| 9 | 45 | 228 | 5,66 → 5,83 Felder | +3,03 % | 14,9 | 263 | +36,0 % |
| 10 | 53 | 281 | 5,83 → 6,00 Felder | +2,94 % | 18,0 | 309 | +40,0 % |
| 11 | 63 | 344 | 6,00 → 6,17 Felder | +2,86 % | 22,0 | 368 | +44,0 % |
| 12 | 74 | 418 | 6,17 → 6,34 Felder | +2,78 % | 26,6 | 432 | +48,0 % |
| 13 | 87 | 505 | 6,34 → 6,51 Felder | +2,70 % | 32,2 | 507 | +52,0 % |
| 14 | 103 | 608 | 6,51 → 6,69 Felder | +2,63 % | 39,1 | 601 | +56,0 % |
| 15 | 122 | 730 | 6,69 → 6,86 Felder | +2,56 % | 47,6 | 712 | +60,0 % |

#### Solarpanel – Strahlen

**Verändert:** Maximale Zahl ausgehender Strahlen. Die Leistung wird auf alle Strahlen aufgeteilt, die Gesamtmenge steigt nicht – das Upgrade bringt nur Verteilung. **Je Stufe:** +1 Strahl.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Strahl | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 32 | 32 | 1 → 2 Strahlen | ±0 % | – | 32 | ±0 % |
| 2 | 51 | 83 | 2 → 3 Strahlen | ±0 % | – | 51 | ±0 % |
| 3 | 82 | 165 | 3 → 4 Strahlen | ±0 % | – | 82 | ±0 % |
| 4 | 131 | 296 | 4 → 5 Strahlen | ±0 % | – | 131 | ±0 % |
| 5 | 210 | 506 | 5 → 6 Strahlen | ±0 % | – | 210 | ±0 % |

#### Solarpanel – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf ein- und ausgehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 8 | 8 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 7,20 | +1,1 % |
| 2 | 9 | 17 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 8,19 | +2,2 % |
| 3 | 11 | 28 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 10,1 | +3,3 % |
| 4 | 13 | 41 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 12,1 | +4,4 % |
| 5 | 16 | 57 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 15,0 | +5,6 % |
| 6 | 18 | 75 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 17,1 | +6,7 % |
| 7 | 22 | 97 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 21,1 | +7,8 % |
| 8 | 25 | 122 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 24,3 | +8,9 % |
| 9 | 30 | 152 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 29,4 | +10,0 % |
| 10 | 35 | 187 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 34,6 | +11,1 % |

#### Solarpanel – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,33 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 7 | 7 | 30,0 → 36,0 Energie | +20,00 % | 0,35 | 1,17 | +20,0 % |
| 2 | 8 | 15 | 36,0 → 42,0 Energie | +16,67 % | 0,48 | 1,33 | +40,0 % |
| 3 | 10 | 25 | 42,0 → 48,0 Energie | +14,29 % | 0,70 | 1,67 | +60,0 % |
| 4 | 12 | 37 | 48,0 → 54,0 Energie | +12,50 % | 0,96 | 2,00 | +80,0 % |
| 5 | 14 | 51 | 54,0 → 60,0 Energie | +11,11 % | 1,26 | 2,33 | +100,0 % |
| 6 | 16 | 67 | 60,0 → 66,0 Energie | +10,00 % | 1,60 | 2,67 | +120,0 % |
| 7 | 19 | 86 | 66,0 → 72,0 Energie | +9,09 % | 2,09 | 3,17 | +140,0 % |
| 8 | 23 | 109 | 72,0 → 78,0 Energie | +8,33 % | 2,76 | 3,83 | +160,0 % |
| 9 | 27 | 136 | 78,0 → 84,0 Energie | +7,69 % | 3,51 | 4,50 | +180,0 % |
| 10 | 32 | 168 | 84,0 → 90,0 Energie | +7,14 % | 4,48 | 5,33 | +200,0 % |
| 11 | 38 | 206 | 90,0 → 96,0 Energie | +6,67 % | 5,70 | 6,33 | +220,0 % |
| 12 | 44 | 250 | 96,0 → 102,0 Energie | +6,25 % | 7,04 | 7,33 | +240,0 % |
| 13 | 52 | 302 | 102,0 → 108,0 Energie | +5,88 % | 8,84 | 8,67 | +260,0 % |
| 14 | 62 | 364 | 108,0 → 114,0 Energie | +5,56 % | 11,2 | 10,3 | +280,0 % |
| 15 | 73 | 437 | 114,0 → 120,0 Energie | +5,26 % | 13,9 | 12,2 | +300,0 % |
| 16 | 86 | 523 | 120,0 → 126,0 Energie | +5,00 % | 17,2 | 14,3 | +320,0 % |
| 17 | 102 | 625 | 126,0 → 132,0 Energie | +4,76 % | 21,4 | 17,0 | +340,0 % |
| 18 | 120 | 745 | 132,0 → 138,0 Energie | +4,55 % | 26,4 | 20,0 | +360,0 % |
| 19 | 142 | 887 | 138,0 → 144,0 Energie | +4,35 % | 32,7 | 23,7 | +380,0 % |
| 20 | 167 | 1.054 | 144,0 → 150,0 Energie | +4,17 % | 40,1 | 27,8 | +400,0 % |
| 21 | 197 | 1.251 | 150,0 → 156,0 Energie | +4,00 % | 49,2 | 32,8 | +420,0 % |
| 22 | 233 | 1.484 | 156,0 → 162,0 Energie | +3,85 % | 60,6 | 38,8 | +440,0 % |
| 23 | 275 | 1.759 | 162,0 → 168,0 Energie | +3,70 % | 74,2 | 45,8 | +460,0 % |
| 24 | 324 | 2.083 | 168,0 → 174,0 Energie | +3,57 % | 90,7 | 54,0 | +480,0 % |
| 25 | 382 | 2.465 | 174,0 → 180,0 Energie | +3,45 % | 111 | 63,7 | +500,0 % |

#### Solarpanel – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,571 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 7 | 7 | 70,0 → 80,5 HP | +15,00 % | 0,47 | 0,667 | +15,0 % |
| 2 | 8 | 15 | 80,5 → 91,0 HP | +13,04 % | 0,61 | 0,762 | +30,0 % |
| 3 | 10 | 25 | 91,0 → 101,5 HP | +11,54 % | 0,87 | 0,952 | +45,0 % |
| 4 | 12 | 37 | 101,5 → 112,0 HP | +10,34 % | 1,16 | 1,143 | +60,0 % |
| 5 | 14 | 51 | 112,0 → 122,5 HP | +9,38 % | 1,49 | 1,333 | +75,0 % |
| 6 | 16 | 67 | 122,5 → 133,0 HP | +8,57 % | 1,87 | 1,524 | +90,0 % |
| 7 | 19 | 86 | 133,0 → 143,5 HP | +7,89 % | 2,41 | 1,810 | +105,0 % |
| 8 | 23 | 109 | 143,5 → 154,0 HP | +7,32 % | 3,14 | 2,190 | +120,0 % |
| 9 | 27 | 136 | 154,0 → 164,5 HP | +6,82 % | 3,96 | 2,571 | +135,0 % |
| 10 | 32 | 168 | 164,5 → 175,0 HP | +6,38 % | 5,01 | 3,048 | +150,0 % |
| 11 | 38 | 206 | 175,0 → 185,5 HP | +6,00 % | 6,33 | 3,619 | +165,0 % |
| 12 | 44 | 250 | 185,5 → 196,0 HP | +5,66 % | 7,77 | 4,190 | +180,0 % |
| 13 | 52 | 302 | 196,0 → 206,5 HP | +5,36 % | 9,71 | 4,952 | +195,0 % |
| 14 | 62 | 364 | 206,5 → 217,0 HP | +5,08 % | 12,2 | 5,905 | +210,0 % |
| 15 | 73 | 437 | 217,0 → 227,5 HP | +4,84 % | 15,1 | 6,952 | +225,0 % |
| 16 | 86 | 523 | 227,5 → 238,0 HP | +4,62 % | 18,6 | 8,190 | +240,0 % |
| 17 | 102 | 625 | 238,0 → 248,5 HP | +4,41 % | 23,1 | 9,714 | +255,0 % |
| 18 | 120 | 745 | 248,5 → 259,0 HP | +4,23 % | 28,4 | 11,429 | +270,0 % |
| 19 | 142 | 887 | 259,0 → 269,5 HP | +4,05 % | 35,0 | 13,524 | +285,0 % |
| 20 | 167 | 1.054 | 269,5 → 280,0 HP | +3,90 % | 42,9 | 15,905 | +300,0 % |
| 21 | 197 | 1.251 | 280,0 → 290,5 HP | +3,75 % | 52,5 | 18,762 | +315,0 % |
| 22 | 233 | 1.484 | 290,5 → 301,0 HP | +3,61 % | 64,5 | 22,190 | +330,0 % |
| 23 | 275 | 1.759 | 301,0 → 311,5 HP | +3,49 % | 78,8 | 26,190 | +345,0 % |
| 24 | 324 | 2.083 | 311,5 → 322,0 HP | +3,37 % | 96,1 | 30,857 | +360,0 % |
| 25 | 382 | 2.465 | 322,0 → 332,5 HP | +3,26 % | 117 | 36,381 | +375,0 % |
| 26 | 451 | 2.916 | 332,5 → 343,0 HP | +3,16 % | 143 | 42,952 | +390,0 % |
| 27 | 532 | 3.448 | 343,0 → 353,5 HP | +3,06 % | 174 | 50,667 | +405,0 % |
| 28 | 628 | 4.076 | 353,5 → 364,0 HP | +2,97 % | 211 | 59,810 | +420,0 % |
| 29 | 741 | 4.817 | 364,0 → 374,5 HP | +2,88 % | 257 | 70,571 | +435,0 % |
| 30 | 875 | 5.692 | 374,5 → 385,0 HP | +2,80 % | 312 | 83,333 | +450,0 % |

### Wasserrad

- **Freischaltung:** Forschung „Wasserrad“ (1 SP)
- **Baukosten:** 50 · **Upgrade-Basis:** 50
- **Grundwerte:** 90 HP · Panzerung 2 · Kapazität 30 · Leistung 3 E/s · 1 Strahl à 4,29 Felder

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Leistung | 30 | 13 | 1.519 | 9.887 | +300 % | 1,30 → 592 |
| Reichweite | 15 | 15 | 152 | 915 | +60 % | 3,75 → 59,3 |
| Strahlen | 5 | 40 | 262 | 632 | ±0 % | – |
| Strahlübertragung | 10 | 10 | 44 | 235 | +11 % | 9,00 → 43,6 |
| Kapazität | 25 | 9 | 478 | 3.085 | +500 % | 0,45 → 139 |
| Leben | 30 | 9 | 1.094 | 7.121 | +450 % | 0,60 → 390 |

#### Wasserrad – Leistung

**Verändert:** Energieerzeugung pro Sekunde. Bei Solar, Wasserrad und Feuerstelle ist die Strahlrate gleich der Leistung. **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 16,7 Münzen je E/s.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 13 | 13 | 3,00 → 3,30 E/s | +10,00 % | 1,30 | 43,3 | +10,0 % |
| 2 | 15 | 28 | 3,30 → 3,60 E/s | +9,09 % | 1,65 | 50,0 | +20,0 % |
| 3 | 17 | 45 | 3,60 → 3,90 E/s | +8,33 % | 2,04 | 56,7 | +30,0 % |
| 4 | 21 | 66 | 3,90 → 4,20 E/s | +7,69 % | 2,73 | 70,0 | +40,0 % |
| 5 | 24 | 90 | 4,20 → 4,50 E/s | +7,14 % | 3,36 | 80,0 | +50,0 % |
| 6 | 29 | 119 | 4,50 → 4,80 E/s | +6,67 % | 4,35 | 96,7 | +60,0 % |
| 7 | 34 | 153 | 4,80 → 5,10 E/s | +6,25 % | 5,44 | 113 | +70,0 % |
| 8 | 40 | 193 | 5,10 → 5,40 E/s | +5,88 % | 6,80 | 133 | +80,0 % |
| 9 | 47 | 240 | 5,40 → 5,70 E/s | +5,56 % | 8,46 | 157 | +90,0 % |
| 10 | 55 | 295 | 5,70 → 6,00 E/s | +5,26 % | 10,4 | 183 | +100,0 % |
| 11 | 65 | 360 | 6,00 → 6,30 E/s | +5,00 % | 13,0 | 217 | +110,0 % |
| 12 | 77 | 437 | 6,30 → 6,60 E/s | +4,76 % | 16,2 | 257 | +120,0 % |
| 13 | 91 | 528 | 6,60 → 6,90 E/s | +4,55 % | 20,0 | 303 | +130,0 % |
| 14 | 107 | 635 | 6,90 → 7,20 E/s | +4,35 % | 24,6 | 357 | +140,0 % |
| 15 | 127 | 762 | 7,20 → 7,50 E/s | +4,17 % | 30,5 | 423 | +150,0 % |
| 16 | 150 | 912 | 7,50 → 7,80 E/s | +4,00 % | 37,5 | 500 | +160,0 % |
| 17 | 177 | 1.089 | 7,80 → 8,10 E/s | +3,85 % | 46,0 | 590 | +170,0 % |
| 18 | 208 | 1.297 | 8,10 → 8,40 E/s | +3,70 % | 56,2 | 693 | +180,0 % |
| 19 | 246 | 1.543 | 8,40 → 8,70 E/s | +3,57 % | 68,9 | 820 | +190,0 % |
| 20 | 290 | 1.833 | 8,70 → 9,00 E/s | +3,45 % | 84,1 | 967 | +200,0 % |
| 21 | 342 | 2.175 | 9,00 → 9,30 E/s | +3,33 % | 103 | 1.140 | +210,0 % |
| 22 | 404 | 2.579 | 9,30 → 9,60 E/s | +3,23 % | 125 | 1.347 | +220,0 % |
| 23 | 477 | 3.056 | 9,60 → 9,90 E/s | +3,12 % | 153 | 1.590 | +230,0 % |
| 24 | 563 | 3.619 | 9,90 → 10,20 E/s | +3,03 % | 186 | 1.877 | +240,0 % |
| 25 | 664 | 4.283 | 10,20 → 10,50 E/s | +2,94 % | 226 | 2.213 | +250,0 % |
| 26 | 783 | 5.066 | 10,50 → 10,80 E/s | +2,86 % | 274 | 2.610 | +260,0 % |
| 27 | 924 | 5.990 | 10,80 → 11,10 E/s | +2,78 % | 333 | 3.080 | +270,0 % |
| 28 | 1.091 | 7.081 | 11,10 → 11,40 E/s | +2,70 % | 404 | 3.637 | +280,0 % |
| 29 | 1.287 | 8.368 | 11,40 → 11,70 E/s | +2,63 % | 489 | 4.290 | +290,0 % |
| 30 | 1.519 | 9.887 | 11,70 → 12,00 E/s | +2,56 % | 592 | 5.063 | +300,0 % |

#### Wasserrad – Reichweite

**Verändert:** Strahlreichweite. Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 15 | 15 | 4,29 → 4,46 Felder | +4,00 % | 3,75 | 87,5 | +4,0 % |
| 2 | 18 | 33 | 4,46 → 4,63 Felder | +3,85 % | 4,68 | 105 | +8,0 % |
| 3 | 21 | 54 | 4,63 → 4,80 Felder | +3,70 % | 5,67 | 123 | +12,0 % |
| 4 | 25 | 79 | 4,80 → 4,97 Felder | +3,57 % | 7,00 | 146 | +16,0 % |
| 5 | 29 | 108 | 4,97 → 5,14 Felder | +3,45 % | 8,41 | 169 | +20,0 % |
| 6 | 34 | 142 | 5,14 → 5,31 Felder | +3,33 % | 10,2 | 198 | +24,0 % |
| 7 | 40 | 182 | 5,31 → 5,49 Felder | +3,23 % | 12,4 | 233 | +28,0 % |
| 8 | 48 | 230 | 5,49 → 5,66 Felder | +3,12 % | 15,4 | 280 | +32,0 % |
| 9 | 56 | 286 | 5,66 → 5,83 Felder | +3,03 % | 18,5 | 327 | +36,0 % |
| 10 | 67 | 353 | 5,83 → 6,00 Felder | +2,94 % | 22,8 | 391 | +40,0 % |
| 11 | 79 | 432 | 6,00 → 6,17 Felder | +2,86 % | 27,6 | 461 | +44,0 % |
| 12 | 93 | 525 | 6,17 → 6,34 Felder | +2,78 % | 33,5 | 542 | +48,0 % |
| 13 | 109 | 634 | 6,34 → 6,51 Felder | +2,70 % | 40,3 | 636 | +52,0 % |
| 14 | 129 | 763 | 6,51 → 6,69 Felder | +2,63 % | 49,0 | 752 | +56,0 % |
| 15 | 152 | 915 | 6,69 → 6,86 Felder | +2,56 % | 59,3 | 887 | +60,0 % |

#### Wasserrad – Strahlen

**Verändert:** Maximale Zahl ausgehender Strahlen. Die Leistung wird auf alle Strahlen aufgeteilt, die Gesamtmenge steigt nicht – das Upgrade bringt nur Verteilung. **Je Stufe:** +1 Strahl.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Strahl | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 40 | 40 | 1 → 2 Strahlen | ±0 % | – | 40 | ±0 % |
| 2 | 64 | 104 | 2 → 3 Strahlen | ±0 % | – | 64 | ±0 % |
| 3 | 102 | 206 | 3 → 4 Strahlen | ±0 % | – | 102 | ±0 % |
| 4 | 164 | 370 | 4 → 5 Strahlen | ±0 % | – | 164 | ±0 % |
| 5 | 262 | 632 | 5 → 6 Strahlen | ±0 % | – | 262 | ±0 % |

#### Wasserrad – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf ein- und ausgehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 10 | 10 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 9,00 | +1,1 % |
| 2 | 12 | 22 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 10,9 | +2,2 % |
| 3 | 14 | 36 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 12,9 | +3,3 % |
| 4 | 16 | 52 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 14,9 | +4,4 % |
| 5 | 19 | 71 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 17,9 | +5,6 % |
| 6 | 23 | 94 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 21,8 | +6,7 % |
| 7 | 27 | 121 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 25,9 | +7,8 % |
| 8 | 32 | 153 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 31,0 | +8,9 % |
| 9 | 38 | 191 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 37,2 | +10,0 % |
| 10 | 44 | 235 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 43,6 | +11,1 % |

#### Wasserrad – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,67 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 9 | 9 | 30,0 → 36,0 Energie | +20,00 % | 0,45 | 1,50 | +20,0 % |
| 2 | 11 | 20 | 36,0 → 42,0 Energie | +16,67 % | 0,66 | 1,83 | +40,0 % |
| 3 | 13 | 33 | 42,0 → 48,0 Energie | +14,29 % | 0,91 | 2,17 | +60,0 % |
| 4 | 15 | 48 | 48,0 → 54,0 Energie | +12,50 % | 1,20 | 2,50 | +80,0 % |
| 5 | 17 | 65 | 54,0 → 60,0 Energie | +11,11 % | 1,53 | 2,83 | +100,0 % |
| 6 | 21 | 86 | 60,0 → 66,0 Energie | +10,00 % | 2,10 | 3,50 | +120,0 % |
| 7 | 24 | 110 | 66,0 → 72,0 Energie | +9,09 % | 2,64 | 4,00 | +140,0 % |
| 8 | 29 | 139 | 72,0 → 78,0 Energie | +8,33 % | 3,48 | 4,83 | +160,0 % |
| 9 | 34 | 173 | 78,0 → 84,0 Energie | +7,69 % | 4,42 | 5,67 | +180,0 % |
| 10 | 40 | 213 | 84,0 → 90,0 Energie | +7,14 % | 5,60 | 6,67 | +200,0 % |
| 11 | 47 | 260 | 90,0 → 96,0 Energie | +6,67 % | 7,05 | 7,83 | +220,0 % |
| 12 | 56 | 316 | 96,0 → 102,0 Energie | +6,25 % | 8,96 | 9,33 | +240,0 % |
| 13 | 66 | 382 | 102,0 → 108,0 Energie | +5,88 % | 11,2 | 11,0 | +260,0 % |
| 14 | 77 | 459 | 108,0 → 114,0 Energie | +5,56 % | 13,9 | 12,8 | +280,0 % |
| 15 | 91 | 550 | 114,0 → 120,0 Energie | +5,26 % | 17,3 | 15,2 | +300,0 % |
| 16 | 108 | 658 | 120,0 → 126,0 Energie | +5,00 % | 21,6 | 18,0 | +320,0 % |
| 17 | 127 | 785 | 126,0 → 132,0 Energie | +4,76 % | 26,7 | 21,2 | +340,0 % |
| 18 | 150 | 935 | 132,0 → 138,0 Energie | +4,55 % | 33,0 | 25,0 | +360,0 % |
| 19 | 177 | 1.112 | 138,0 → 144,0 Energie | +4,35 % | 40,7 | 29,5 | +380,0 % |
| 20 | 209 | 1.321 | 144,0 → 150,0 Energie | +4,17 % | 50,2 | 34,8 | +400,0 % |
| 21 | 247 | 1.568 | 150,0 → 156,0 Energie | +4,00 % | 61,7 | 41,2 | +420,0 % |
| 22 | 291 | 1.859 | 156,0 → 162,0 Energie | +3,85 % | 75,7 | 48,5 | +440,0 % |
| 23 | 343 | 2.202 | 162,0 → 168,0 Energie | +3,70 % | 92,6 | 57,2 | +460,0 % |
| 24 | 405 | 2.607 | 168,0 → 174,0 Energie | +3,57 % | 113 | 67,5 | +480,0 % |
| 25 | 478 | 3.085 | 174,0 → 180,0 Energie | +3,45 % | 139 | 79,7 | +500,0 % |

#### Wasserrad – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,556 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 9 | 9 | 90,0 → 103,5 HP | +15,00 % | 0,60 | 0,667 | +15,0 % |
| 2 | 11 | 20 | 103,5 → 117,0 HP | +13,04 % | 0,84 | 0,815 | +30,0 % |
| 3 | 13 | 33 | 117,0 → 130,5 HP | +11,54 % | 1,13 | 0,963 | +45,0 % |
| 4 | 15 | 48 | 130,5 → 144,0 HP | +10,34 % | 1,45 | 1,111 | +60,0 % |
| 5 | 17 | 65 | 144,0 → 157,5 HP | +9,38 % | 1,81 | 1,259 | +75,0 % |
| 6 | 21 | 86 | 157,5 → 171,0 HP | +8,57 % | 2,45 | 1,556 | +90,0 % |
| 7 | 24 | 110 | 171,0 → 184,5 HP | +7,89 % | 3,04 | 1,778 | +105,0 % |
| 8 | 29 | 139 | 184,5 → 198,0 HP | +7,32 % | 3,96 | 2,148 | +120,0 % |
| 9 | 34 | 173 | 198,0 → 211,5 HP | +6,82 % | 4,99 | 2,519 | +135,0 % |
| 10 | 40 | 213 | 211,5 → 225,0 HP | +6,38 % | 6,27 | 2,963 | +150,0 % |
| 11 | 47 | 260 | 225,0 → 238,5 HP | +6,00 % | 7,83 | 3,481 | +165,0 % |
| 12 | 56 | 316 | 238,5 → 252,0 HP | +5,66 % | 9,89 | 4,148 | +180,0 % |
| 13 | 66 | 382 | 252,0 → 265,5 HP | +5,36 % | 12,3 | 4,889 | +195,0 % |
| 14 | 77 | 459 | 265,5 → 279,0 HP | +5,08 % | 15,1 | 5,704 | +210,0 % |
| 15 | 91 | 550 | 279,0 → 292,5 HP | +4,84 % | 18,8 | 6,741 | +225,0 % |
| 16 | 108 | 658 | 292,5 → 306,0 HP | +4,62 % | 23,4 | 8,000 | +240,0 % |
| 17 | 127 | 785 | 306,0 → 319,5 HP | +4,41 % | 28,8 | 9,407 | +255,0 % |
| 18 | 150 | 935 | 319,5 → 333,0 HP | +4,23 % | 35,5 | 11,111 | +270,0 % |
| 19 | 177 | 1.112 | 333,0 → 346,5 HP | +4,05 % | 43,7 | 13,111 | +285,0 % |
| 20 | 209 | 1.321 | 346,5 → 360,0 HP | +3,90 % | 53,6 | 15,481 | +300,0 % |
| 21 | 247 | 1.568 | 360,0 → 373,5 HP | +3,75 % | 65,9 | 18,296 | +315,0 % |
| 22 | 291 | 1.859 | 373,5 → 387,0 HP | +3,61 % | 80,5 | 21,556 | +330,0 % |
| 23 | 343 | 2.202 | 387,0 → 400,5 HP | +3,49 % | 98,3 | 25,407 | +345,0 % |
| 24 | 405 | 2.607 | 400,5 → 414,0 HP | +3,37 % | 120 | 30,000 | +360,0 % |
| 25 | 478 | 3.085 | 414,0 → 427,5 HP | +3,26 % | 147 | 35,407 | +375,0 % |
| 26 | 564 | 3.649 | 427,5 → 441,0 HP | +3,16 % | 179 | 41,778 | +390,0 % |
| 27 | 666 | 4.315 | 441,0 → 454,5 HP | +3,06 % | 218 | 49,333 | +405,0 % |
| 28 | 785 | 5.100 | 454,5 → 468,0 HP | +2,97 % | 264 | 58,148 | +420,0 % |
| 29 | 927 | 6.027 | 468,0 → 481,5 HP | +2,88 % | 321 | 68,667 | +435,0 % |
| 30 | 1.094 | 7.121 | 481,5 → 495,0 HP | +2,80 % | 390 | 81,037 | +450,0 % |

### Feuerstelle

- **Freischaltung:** Forschung „Feuerstelle“ (1 SP)
- **Baukosten:** 15 · **Upgrade-Basis:** 15
- **Grundwerte:** 60 HP · Panzerung 0 · Kapazität 40 · Leistung 30 E/s · 1 Strahl à 4,29 Felder

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Leistung | 30 | 4 | 456 | 2.966 | +300 % | 0,40 → 178 |
| Reichweite | 15 | 5 | 46 | 275 | +60 % | 1,25 → 17,9 |
| Strahlen | 5 | 12 | 79 | 190 | ±0 % | – |
| Strahlübertragung | 10 | 3 | 13 | 71 | +11 % | 2,70 → 12,9 |
| Kapazität | 25 | 3 | 143 | 924 | +500 % | 0,15 → 41,5 |
| Leben | 30 | 3 | 328 | 2.135 | +450 % | 0,20 → 117 |

#### Feuerstelle – Leistung

**Verändert:** Energieerzeugung pro Sekunde. Nur solange markierte Bäume brennen. Bei Solar, Wasserrad und Feuerstelle ist die Strahlrate gleich der Leistung. **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 0,50 Münzen je E/s.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 4 | 4 | 30,00 → 33,00 E/s | +10,00 % | 0,40 | 1,33 | +10,0 % |
| 2 | 4 | 8 | 33,00 → 36,00 E/s | +9,09 % | 0,44 | 1,33 | +20,0 % |
| 3 | 5 | 13 | 36,00 → 39,00 E/s | +8,33 % | 0,60 | 1,67 | +30,0 % |
| 4 | 6 | 19 | 39,00 → 42,00 E/s | +7,69 % | 0,78 | 2,00 | +40,0 % |
| 5 | 7 | 26 | 42,00 → 45,00 E/s | +7,14 % | 0,98 | 2,33 | +50,0 % |
| 6 | 9 | 35 | 45,00 → 48,00 E/s | +6,67 % | 1,35 | 3,00 | +60,0 % |
| 7 | 10 | 45 | 48,00 → 51,00 E/s | +6,25 % | 1,60 | 3,33 | +70,0 % |
| 8 | 12 | 57 | 51,00 → 54,00 E/s | +5,88 % | 2,04 | 4,00 | +80,0 % |
| 9 | 14 | 71 | 54,00 → 57,00 E/s | +5,56 % | 2,52 | 4,67 | +90,0 % |
| 10 | 17 | 88 | 57,00 → 60,00 E/s | +5,26 % | 3,23 | 5,67 | +100,0 % |
| 11 | 20 | 108 | 60,00 → 63,00 E/s | +5,00 % | 4,00 | 6,67 | +110,0 % |
| 12 | 23 | 131 | 63,00 → 66,00 E/s | +4,76 % | 4,83 | 7,67 | +120,0 % |
| 13 | 27 | 158 | 66,00 → 69,00 E/s | +4,55 % | 5,94 | 9,00 | +130,0 % |
| 14 | 32 | 190 | 69,00 → 72,00 E/s | +4,35 % | 7,36 | 10,7 | +140,0 % |
| 15 | 38 | 228 | 72,00 → 75,00 E/s | +4,17 % | 9,12 | 12,7 | +150,0 % |
| 16 | 45 | 273 | 75,00 → 78,00 E/s | +4,00 % | 11,2 | 15,0 | +160,0 % |
| 17 | 53 | 326 | 78,00 → 81,00 E/s | +3,85 % | 13,8 | 17,7 | +170,0 % |
| 18 | 63 | 389 | 81,00 → 84,00 E/s | +3,70 % | 17,0 | 21,0 | +180,0 % |
| 19 | 74 | 463 | 84,00 → 87,00 E/s | +3,57 % | 20,7 | 24,7 | +190,0 % |
| 20 | 87 | 550 | 87,00 → 90,00 E/s | +3,45 % | 25,2 | 29,0 | +200,0 % |
| 21 | 103 | 653 | 90,00 → 93,00 E/s | +3,33 % | 30,9 | 34,3 | +210,0 % |
| 22 | 121 | 774 | 93,00 → 96,00 E/s | +3,23 % | 37,5 | 40,3 | +220,0 % |
| 23 | 143 | 917 | 96,00 → 99,00 E/s | +3,13 % | 45,8 | 47,7 | +230,0 % |
| 24 | 169 | 1.086 | 99,00 → 102,00 E/s | +3,03 % | 55,8 | 56,3 | +240,0 % |
| 25 | 199 | 1.285 | 102,00 → 105,00 E/s | +2,94 % | 67,7 | 66,3 | +250,0 % |
| 26 | 235 | 1.520 | 105,00 → 108,00 E/s | +2,86 % | 82,3 | 78,3 | +260,0 % |
| 27 | 277 | 1.797 | 108,00 → 111,00 E/s | +2,78 % | 99,7 | 92,3 | +270,0 % |
| 28 | 327 | 2.124 | 111,00 → 114,00 E/s | +2,70 % | 121 | 109 | +280,0 % |
| 29 | 386 | 2.510 | 114,00 → 117,00 E/s | +2,63 % | 147 | 129 | +290,0 % |
| 30 | 456 | 2.966 | 117,00 → 120,00 E/s | +2,56 % | 178 | 152 | +300,0 % |

#### Feuerstelle – Reichweite

**Verändert:** Strahlreichweite. Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 4,29 → 4,46 Felder | +4,00 % | 1,25 | 29,2 | +4,0 % |
| 2 | 5 | 10 | 4,46 → 4,63 Felder | +3,85 % | 1,30 | 29,2 | +8,0 % |
| 3 | 6 | 16 | 4,63 → 4,80 Felder | +3,70 % | 1,62 | 35,0 | +12,0 % |
| 4 | 7 | 23 | 4,80 → 4,97 Felder | +3,57 % | 1,96 | 40,8 | +16,0 % |
| 5 | 9 | 32 | 4,97 → 5,14 Felder | +3,45 % | 2,61 | 52,5 | +20,0 % |
| 6 | 10 | 42 | 5,14 → 5,31 Felder | +3,33 % | 3,00 | 58,3 | +24,0 % |
| 7 | 12 | 54 | 5,31 → 5,49 Felder | +3,23 % | 3,72 | 70,0 | +28,0 % |
| 8 | 14 | 68 | 5,49 → 5,66 Felder | +3,12 % | 4,48 | 81,7 | +32,0 % |
| 9 | 17 | 85 | 5,66 → 5,83 Felder | +3,03 % | 5,61 | 99,2 | +36,0 % |
| 10 | 20 | 105 | 5,83 → 6,00 Felder | +2,94 % | 6,80 | 117 | +40,0 % |
| 11 | 24 | 129 | 6,00 → 6,17 Felder | +2,86 % | 8,40 | 140 | +44,0 % |
| 12 | 28 | 157 | 6,17 → 6,34 Felder | +2,78 % | 10,1 | 163 | +48,0 % |
| 13 | 33 | 190 | 6,34 → 6,51 Felder | +2,70 % | 12,2 | 192 | +52,0 % |
| 14 | 39 | 229 | 6,51 → 6,69 Felder | +2,63 % | 14,8 | 227 | +56,0 % |
| 15 | 46 | 275 | 6,69 → 6,86 Felder | +2,56 % | 17,9 | 268 | +60,0 % |

#### Feuerstelle – Strahlen

**Verändert:** Maximale Zahl ausgehender Strahlen. Die Leistung wird auf alle Strahlen aufgeteilt, die Gesamtmenge steigt nicht – das Upgrade bringt nur Verteilung. **Je Stufe:** +1 Strahl.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Strahl | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 12 | 12 | 1 → 2 Strahlen | ±0 % | – | 12 | ±0 % |
| 2 | 19 | 31 | 2 → 3 Strahlen | ±0 % | – | 19 | ±0 % |
| 3 | 31 | 62 | 3 → 4 Strahlen | ±0 % | – | 31 | ±0 % |
| 4 | 49 | 111 | 4 → 5 Strahlen | ±0 % | – | 49 | ±0 % |
| 5 | 79 | 190 | 5 → 6 Strahlen | ±0 % | – | 79 | ±0 % |

#### Feuerstelle – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf ein- und ausgehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 3 | 3 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 2,70 | +1,1 % |
| 2 | 4 | 7 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 3,64 | +2,2 % |
| 3 | 4 | 11 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 3,68 | +3,3 % |
| 4 | 5 | 16 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 4,65 | +4,4 % |
| 5 | 6 | 22 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 5,64 | +5,6 % |
| 6 | 7 | 29 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 6,65 | +6,7 % |
| 7 | 8 | 37 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 7,68 | +7,8 % |
| 8 | 10 | 47 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 9,70 | +8,9 % |
| 9 | 11 | 58 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 10,8 | +10,0 % |
| 10 | 13 | 71 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 12,9 | +11,1 % |

#### Feuerstelle – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 0,38 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 3 | 3 | 40,0 → 48,0 Energie | +20,00 % | 0,15 | 0,38 | +20,0 % |
| 2 | 3 | 6 | 48,0 → 56,0 Energie | +16,67 % | 0,18 | 0,38 | +40,0 % |
| 3 | 4 | 10 | 56,0 → 64,0 Energie | +14,29 % | 0,28 | 0,50 | +60,0 % |
| 4 | 4 | 14 | 64,0 → 72,0 Energie | +12,50 % | 0,32 | 0,50 | +80,0 % |
| 5 | 5 | 19 | 72,0 → 80,0 Energie | +11,11 % | 0,45 | 0,62 | +100,0 % |
| 6 | 6 | 25 | 80,0 → 88,0 Energie | +10,00 % | 0,60 | 0,75 | +120,0 % |
| 7 | 7 | 32 | 88,0 → 96,0 Energie | +9,09 % | 0,77 | 0,87 | +140,0 % |
| 8 | 9 | 41 | 96,0 → 104,0 Energie | +8,33 % | 1,08 | 1,13 | +160,0 % |
| 9 | 10 | 51 | 104,0 → 112,0 Energie | +7,69 % | 1,30 | 1,25 | +180,0 % |
| 10 | 12 | 63 | 112,0 → 120,0 Energie | +7,14 % | 1,68 | 1,50 | +200,0 % |
| 11 | 14 | 77 | 120,0 → 128,0 Energie | +6,67 % | 2,10 | 1,75 | +220,0 % |
| 12 | 17 | 94 | 128,0 → 136,0 Energie | +6,25 % | 2,72 | 2,12 | +240,0 % |
| 13 | 20 | 114 | 136,0 → 144,0 Energie | +5,88 % | 3,40 | 2,50 | +260,0 % |
| 14 | 23 | 137 | 144,0 → 152,0 Energie | +5,56 % | 4,14 | 2,88 | +280,0 % |
| 15 | 27 | 164 | 152,0 → 160,0 Energie | +5,26 % | 5,13 | 3,38 | +300,0 % |
| 16 | 32 | 196 | 160,0 → 168,0 Energie | +5,00 % | 6,40 | 4,00 | +320,0 % |
| 17 | 38 | 234 | 168,0 → 176,0 Energie | +4,76 % | 7,98 | 4,75 | +340,0 % |
| 18 | 45 | 279 | 176,0 → 184,0 Energie | +4,55 % | 9,90 | 5,62 | +360,0 % |
| 19 | 53 | 332 | 184,0 → 192,0 Energie | +4,35 % | 12,2 | 6,62 | +380,0 % |
| 20 | 63 | 395 | 192,0 → 200,0 Energie | +4,17 % | 15,1 | 7,88 | +400,0 % |
| 21 | 74 | 469 | 200,0 → 208,0 Energie | +4,00 % | 18,5 | 9,25 | +420,0 % |
| 22 | 87 | 556 | 208,0 → 216,0 Energie | +3,85 % | 22,6 | 10,9 | +440,0 % |
| 23 | 103 | 659 | 216,0 → 224,0 Energie | +3,70 % | 27,8 | 12,9 | +460,0 % |
| 24 | 122 | 781 | 224,0 → 232,0 Energie | +3,57 % | 34,2 | 15,2 | +480,0 % |
| 25 | 143 | 924 | 232,0 → 240,0 Energie | +3,45 % | 41,5 | 17,9 | +500,0 % |

#### Feuerstelle – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,250 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 3 | 3 | 60,0 → 69,0 HP | +15,00 % | 0,20 | 0,333 | +15,0 % |
| 2 | 3 | 6 | 69,0 → 78,0 HP | +13,04 % | 0,23 | 0,333 | +30,0 % |
| 3 | 4 | 10 | 78,0 → 87,0 HP | +11,54 % | 0,35 | 0,444 | +45,0 % |
| 4 | 4 | 14 | 87,0 → 96,0 HP | +10,34 % | 0,39 | 0,444 | +60,0 % |
| 5 | 5 | 19 | 96,0 → 105,0 HP | +9,38 % | 0,53 | 0,556 | +75,0 % |
| 6 | 6 | 25 | 105,0 → 114,0 HP | +8,57 % | 0,70 | 0,667 | +90,0 % |
| 7 | 7 | 32 | 114,0 → 123,0 HP | +7,89 % | 0,89 | 0,778 | +105,0 % |
| 8 | 9 | 41 | 123,0 → 132,0 HP | +7,32 % | 1,23 | 1,000 | +120,0 % |
| 9 | 10 | 51 | 132,0 → 141,0 HP | +6,82 % | 1,47 | 1,111 | +135,0 % |
| 10 | 12 | 63 | 141,0 → 150,0 HP | +6,38 % | 1,88 | 1,333 | +150,0 % |
| 11 | 14 | 77 | 150,0 → 159,0 HP | +6,00 % | 2,33 | 1,556 | +165,0 % |
| 12 | 17 | 94 | 159,0 → 168,0 HP | +5,66 % | 3,00 | 1,889 | +180,0 % |
| 13 | 20 | 114 | 168,0 → 177,0 HP | +5,36 % | 3,73 | 2,222 | +195,0 % |
| 14 | 23 | 137 | 177,0 → 186,0 HP | +5,08 % | 4,52 | 2,556 | +210,0 % |
| 15 | 27 | 164 | 186,0 → 195,0 HP | +4,84 % | 5,58 | 3,000 | +225,0 % |
| 16 | 32 | 196 | 195,0 → 204,0 HP | +4,62 % | 6,93 | 3,556 | +240,0 % |
| 17 | 38 | 234 | 204,0 → 213,0 HP | +4,41 % | 8,61 | 4,222 | +255,0 % |
| 18 | 45 | 279 | 213,0 → 222,0 HP | +4,23 % | 10,7 | 5,000 | +270,0 % |
| 19 | 53 | 332 | 222,0 → 231,0 HP | +4,05 % | 13,1 | 5,889 | +285,0 % |
| 20 | 63 | 395 | 231,0 → 240,0 HP | +3,90 % | 16,2 | 7,000 | +300,0 % |
| 21 | 74 | 469 | 240,0 → 249,0 HP | +3,75 % | 19,7 | 8,222 | +315,0 % |
| 22 | 87 | 556 | 249,0 → 258,0 HP | +3,61 % | 24,1 | 9,667 | +330,0 % |
| 23 | 103 | 659 | 258,0 → 267,0 HP | +3,49 % | 29,5 | 11,444 | +345,0 % |
| 24 | 122 | 781 | 267,0 → 276,0 HP | +3,37 % | 36,2 | 13,556 | +360,0 % |
| 25 | 143 | 924 | 276,0 → 285,0 HP | +3,26 % | 43,9 | 15,889 | +375,0 % |
| 26 | 169 | 1.093 | 285,0 → 294,0 HP | +3,16 % | 53,5 | 18,778 | +390,0 % |
| 27 | 200 | 1.293 | 294,0 → 303,0 HP | +3,06 % | 65,3 | 22,222 | +405,0 % |
| 28 | 236 | 1.529 | 303,0 → 312,0 HP | +2,97 % | 79,5 | 26,222 | +420,0 % |
| 29 | 278 | 1.807 | 312,0 → 321,0 HP | +2,88 % | 96,4 | 30,889 | +435,0 % |
| 30 | 328 | 2.135 | 321,0 → 330,0 HP | +2,80 % | 117 | 36,444 | +450,0 % |

### Verteiler

- **Freischaltung:** von Anfang an
- **Baukosten:** 30 · **Upgrade-Basis:** 30
- **Grundwerte:** 90 HP · Panzerung 4 · Kapazität 20 · 3 Strahlen à 5,89 Felder · Transferrate 30 E/s

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Transferrate | 25 | 7 | 351 | 2.263 | +300 % | 0,58 → 113 |
| Reichweite | 15 | 9 | 91 | 550 | +60 % | 2,25 → 35,5 |
| Strahlen | 5 | 24 | 157 | 378 | +167 % | 0,72 → 11,0 |
| Strahlübertragung | 10 | 6 | 27 | 142 | +11 % | 5,40 → 26,7 |
| Kapazität | 25 | 5 | 287 | 1.848 | +500 % | 0,25 → 83,2 |
| Leben | 30 | 5 | 656 | 4.268 | +450 % | 0,33 → 234 |

#### Verteiler – Transferrate

**Verändert:** Transferrate je ausgehendem Strahl (Energie pro Sekunde, die ein Strahl höchstens weitergibt). **Je Stufe:** +12 % des Grundwerts.

Neubau zum Vergleich: 1,00 Münzen je E/s.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 7 | 7 | 30,0 → 33,6 E/s je Strahl | +12,00 % | 0,58 | 1,94 | +12,0 % |
| 2 | 8 | 15 | 33,6 → 37,2 E/s je Strahl | +10,71 % | 0,75 | 2,22 | +24,0 % |
| 3 | 9 | 24 | 37,2 → 40,8 E/s je Strahl | +9,68 % | 0,93 | 2,50 | +36,0 % |
| 4 | 11 | 35 | 40,8 → 44,4 E/s je Strahl | +8,82 % | 1,25 | 3,06 | +48,0 % |
| 5 | 13 | 48 | 44,4 → 48,0 E/s je Strahl | +8,11 % | 1,60 | 3,61 | +60,0 % |
| 6 | 15 | 63 | 48,0 → 51,6 E/s je Strahl | +7,50 % | 2,00 | 4,17 | +72,0 % |
| 7 | 18 | 81 | 51,6 → 55,2 E/s je Strahl | +6,98 % | 2,58 | 5,00 | +84,0 % |
| 8 | 21 | 102 | 55,2 → 58,8 E/s je Strahl | +6,52 % | 3,22 | 5,83 | +96,0 % |
| 9 | 25 | 127 | 58,8 → 62,4 E/s je Strahl | +6,12 % | 4,08 | 6,94 | +108,0 % |
| 10 | 29 | 156 | 62,4 → 66,0 E/s je Strahl | +5,77 % | 5,03 | 8,06 | +120,0 % |
| 11 | 35 | 191 | 66,0 → 69,6 E/s je Strahl | +5,45 % | 6,42 | 9,72 | +132,0 % |
| 12 | 41 | 232 | 69,6 → 73,2 E/s je Strahl | +5,17 % | 7,93 | 11,4 | +144,0 % |
| 13 | 48 | 280 | 73,2 → 76,8 E/s je Strahl | +4,92 % | 9,76 | 13,3 | +156,0 % |
| 14 | 57 | 337 | 76,8 → 80,4 E/s je Strahl | +4,69 % | 12,2 | 15,8 | +168,0 % |
| 15 | 67 | 404 | 80,4 → 84,0 E/s je Strahl | +4,48 % | 15,0 | 18,6 | +180,0 % |
| 16 | 79 | 483 | 84,0 → 87,6 E/s je Strahl | +4,29 % | 18,4 | 21,9 | +192,0 % |
| 17 | 93 | 576 | 87,6 → 91,2 E/s je Strahl | +4,11 % | 22,6 | 25,8 | +204,0 % |
| 18 | 110 | 686 | 91,2 → 94,8 E/s je Strahl | +3,95 % | 27,9 | 30,6 | +216,0 % |
| 19 | 130 | 816 | 94,8 → 98,4 E/s je Strahl | +3,80 % | 34,2 | 36,1 | +228,0 % |
| 20 | 153 | 969 | 98,4 → 102,0 E/s je Strahl | +3,66 % | 41,8 | 42,5 | +240,0 % |
| 21 | 181 | 1.150 | 102,0 → 105,6 E/s je Strahl | +3,53 % | 51,3 | 50,3 | +252,0 % |
| 22 | 213 | 1.363 | 105,6 → 109,2 E/s je Strahl | +3,41 % | 62,5 | 59,2 | +264,0 % |
| 23 | 252 | 1.615 | 109,2 → 112,8 E/s je Strahl | +3,30 % | 76,4 | 70,0 | +276,0 % |
| 24 | 297 | 1.912 | 112,8 → 116,4 E/s je Strahl | +3,19 % | 93,1 | 82,5 | +288,0 % |
| 25 | 351 | 2.263 | 116,4 → 120,0 E/s je Strahl | +3,09 % | 113 | 97,5 | +300,0 % |

#### Verteiler – Reichweite

**Verändert:** Strahlreichweite. Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 9 | 9 | 5,89 → 6,13 Felder | +4,00 % | 2,25 | 38,2 | +4,0 % |
| 2 | 11 | 20 | 6,13 → 6,36 Felder | +3,85 % | 2,86 | 46,7 | +8,0 % |
| 3 | 13 | 33 | 6,36 → 6,60 Felder | +3,70 % | 3,51 | 55,2 | +12,0 % |
| 4 | 15 | 48 | 6,60 → 6,84 Felder | +3,57 % | 4,20 | 63,6 | +16,0 % |
| 5 | 17 | 65 | 6,84 → 7,07 Felder | +3,45 % | 4,93 | 72,1 | +20,0 % |
| 6 | 21 | 86 | 7,07 → 7,31 Felder | +3,33 % | 6,30 | 89,1 | +24,0 % |
| 7 | 24 | 110 | 7,31 → 7,54 Felder | +3,23 % | 7,44 | 102 | +28,0 % |
| 8 | 29 | 139 | 7,54 → 7,78 Felder | +3,12 % | 9,28 | 123 | +32,0 % |
| 9 | 34 | 173 | 7,78 → 8,01 Felder | +3,03 % | 11,2 | 144 | +36,0 % |
| 10 | 40 | 213 | 8,01 → 8,25 Felder | +2,94 % | 13,6 | 170 | +40,0 % |
| 11 | 47 | 260 | 8,25 → 8,49 Felder | +2,86 % | 16,4 | 199 | +44,0 % |
| 12 | 56 | 316 | 8,49 → 8,72 Felder | +2,78 % | 20,2 | 238 | +48,0 % |
| 13 | 66 | 382 | 8,72 → 8,96 Felder | +2,70 % | 24,4 | 280 | +52,0 % |
| 14 | 77 | 459 | 8,96 → 9,19 Felder | +2,63 % | 29,3 | 327 | +56,0 % |
| 15 | 91 | 550 | 9,19 → 9,43 Felder | +2,56 % | 35,5 | 386 | +60,0 % |

#### Verteiler – Strahlen

**Verändert:** Maximale Zahl ausgehender Strahlen. Jeder Strahl hat die volle Transferrate, der mögliche Gesamtdurchsatz steigt also um einen Strahl. **Je Stufe:** +1 Strahl.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Strahl | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 24 | 24 | 3 → 4 Strahlen | +33,33 % | 0,72 | 24 | +33,3 % |
| 2 | 38 | 62 | 4 → 5 Strahlen | +25,00 % | 1,52 | 38 | +66,7 % |
| 3 | 61 | 123 | 5 → 6 Strahlen | +20,00 % | 3,05 | 61 | +100,0 % |
| 4 | 98 | 221 | 6 → 7 Strahlen | +16,67 % | 5,88 | 98 | +133,3 % |
| 5 | 157 | 378 | 7 → 8 Strahlen | +14,29 % | 11,0 | 157 | +166,7 % |

#### Verteiler – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf ein- und ausgehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 6 | 6 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 5,40 | +1,1 % |
| 2 | 7 | 13 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 6,37 | +2,2 % |
| 3 | 8 | 21 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 7,36 | +3,3 % |
| 4 | 10 | 31 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 9,30 | +4,4 % |
| 5 | 12 | 43 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 11,3 | +5,6 % |
| 6 | 14 | 57 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 13,3 | +6,7 % |
| 7 | 16 | 73 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 15,4 | +7,8 % |
| 8 | 19 | 92 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 18,4 | +8,9 % |
| 9 | 23 | 115 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 22,5 | +10,0 % |
| 10 | 27 | 142 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 26,7 | +11,1 % |

#### Verteiler – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,50 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 20,0 → 24,0 Energie | +20,00 % | 0,25 | 1,25 | +20,0 % |
| 2 | 6 | 11 | 24,0 → 28,0 Energie | +16,67 % | 0,36 | 1,50 | +40,0 % |
| 3 | 8 | 19 | 28,0 → 32,0 Energie | +14,29 % | 0,56 | 2,00 | +60,0 % |
| 4 | 9 | 28 | 32,0 → 36,0 Energie | +12,50 % | 0,72 | 2,25 | +80,0 % |
| 5 | 10 | 38 | 36,0 → 40,0 Energie | +11,11 % | 0,90 | 2,50 | +100,0 % |
| 6 | 12 | 50 | 40,0 → 44,0 Energie | +10,00 % | 1,20 | 3,00 | +120,0 % |
| 7 | 15 | 65 | 44,0 → 48,0 Energie | +9,09 % | 1,65 | 3,75 | +140,0 % |
| 8 | 17 | 82 | 48,0 → 52,0 Energie | +8,33 % | 2,04 | 4,25 | +160,0 % |
| 9 | 20 | 102 | 52,0 → 56,0 Energie | +7,69 % | 2,60 | 5,00 | +180,0 % |
| 10 | 24 | 126 | 56,0 → 60,0 Energie | +7,14 % | 3,36 | 6,00 | +200,0 % |
| 11 | 28 | 154 | 60,0 → 64,0 Energie | +6,67 % | 4,20 | 7,00 | +220,0 % |
| 12 | 33 | 187 | 64,0 → 68,0 Energie | +6,25 % | 5,28 | 8,25 | +240,0 % |
| 13 | 39 | 226 | 68,0 → 72,0 Energie | +5,88 % | 6,63 | 9,75 | +260,0 % |
| 14 | 46 | 272 | 72,0 → 76,0 Energie | +5,56 % | 8,28 | 11,5 | +280,0 % |
| 15 | 55 | 327 | 76,0 → 80,0 Energie | +5,26 % | 10,5 | 13,8 | +300,0 % |
| 16 | 65 | 392 | 80,0 → 84,0 Energie | +5,00 % | 13,0 | 16,2 | +320,0 % |
| 17 | 76 | 468 | 84,0 → 88,0 Energie | +4,76 % | 16,0 | 19,0 | +340,0 % |
| 18 | 90 | 558 | 88,0 → 92,0 Energie | +4,55 % | 19,8 | 22,5 | +360,0 % |
| 19 | 106 | 664 | 92,0 → 96,0 Energie | +4,35 % | 24,4 | 26,5 | +380,0 % |
| 20 | 125 | 789 | 96,0 → 100,0 Energie | +4,17 % | 30,0 | 31,3 | +400,0 % |
| 21 | 148 | 937 | 100,0 → 104,0 Energie | +4,00 % | 37,0 | 37,0 | +420,0 % |
| 22 | 175 | 1.112 | 104,0 → 108,0 Energie | +3,85 % | 45,5 | 43,8 | +440,0 % |
| 23 | 206 | 1.318 | 108,0 → 112,0 Energie | +3,70 % | 55,6 | 51,5 | +460,0 % |
| 24 | 243 | 1.561 | 112,0 → 116,0 Energie | +3,57 % | 68,0 | 60,8 | +480,0 % |
| 25 | 287 | 1.848 | 116,0 → 120,0 Energie | +3,45 % | 83,2 | 71,8 | +500,0 % |

#### Verteiler – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,333 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 90,0 → 103,5 HP | +15,00 % | 0,33 | 0,370 | +15,0 % |
| 2 | 6 | 11 | 103,5 → 117,0 HP | +13,04 % | 0,46 | 0,444 | +30,0 % |
| 3 | 8 | 19 | 117,0 → 130,5 HP | +11,54 % | 0,69 | 0,593 | +45,0 % |
| 4 | 9 | 28 | 130,5 → 144,0 HP | +10,34 % | 0,87 | 0,667 | +60,0 % |
| 5 | 10 | 38 | 144,0 → 157,5 HP | +9,38 % | 1,07 | 0,741 | +75,0 % |
| 6 | 12 | 50 | 157,5 → 171,0 HP | +8,57 % | 1,40 | 0,889 | +90,0 % |
| 7 | 15 | 65 | 171,0 → 184,5 HP | +7,89 % | 1,90 | 1,111 | +105,0 % |
| 8 | 17 | 82 | 184,5 → 198,0 HP | +7,32 % | 2,32 | 1,259 | +120,0 % |
| 9 | 20 | 102 | 198,0 → 211,5 HP | +6,82 % | 2,93 | 1,481 | +135,0 % |
| 10 | 24 | 126 | 211,5 → 225,0 HP | +6,38 % | 3,76 | 1,778 | +150,0 % |
| 11 | 28 | 154 | 225,0 → 238,5 HP | +6,00 % | 4,67 | 2,074 | +165,0 % |
| 12 | 33 | 187 | 238,5 → 252,0 HP | +5,66 % | 5,83 | 2,444 | +180,0 % |
| 13 | 39 | 226 | 252,0 → 265,5 HP | +5,36 % | 7,28 | 2,889 | +195,0 % |
| 14 | 46 | 272 | 265,5 → 279,0 HP | +5,08 % | 9,05 | 3,407 | +210,0 % |
| 15 | 55 | 327 | 279,0 → 292,5 HP | +4,84 % | 11,4 | 4,074 | +225,0 % |
| 16 | 65 | 392 | 292,5 → 306,0 HP | +4,62 % | 14,1 | 4,815 | +240,0 % |
| 17 | 76 | 468 | 306,0 → 319,5 HP | +4,41 % | 17,2 | 5,630 | +255,0 % |
| 18 | 90 | 558 | 319,5 → 333,0 HP | +4,23 % | 21,3 | 6,667 | +270,0 % |
| 19 | 106 | 664 | 333,0 → 346,5 HP | +4,05 % | 26,1 | 7,852 | +285,0 % |
| 20 | 125 | 789 | 346,5 → 360,0 HP | +3,90 % | 32,1 | 9,259 | +300,0 % |
| 21 | 148 | 937 | 360,0 → 373,5 HP | +3,75 % | 39,5 | 10,963 | +315,0 % |
| 22 | 175 | 1.112 | 373,5 → 387,0 HP | +3,61 % | 48,4 | 12,963 | +330,0 % |
| 23 | 206 | 1.318 | 387,0 → 400,5 HP | +3,49 % | 59,1 | 15,259 | +345,0 % |
| 24 | 243 | 1.561 | 400,5 → 414,0 HP | +3,37 % | 72,1 | 18,000 | +360,0 % |
| 25 | 287 | 1.848 | 414,0 → 427,5 HP | +3,26 % | 88,0 | 21,259 | +375,0 % |
| 26 | 338 | 2.186 | 427,5 → 441,0 HP | +3,16 % | 107 | 25,037 | +390,0 % |
| 27 | 399 | 2.585 | 441,0 → 454,5 HP | +3,06 % | 130 | 29,556 | +405,0 % |
| 28 | 471 | 3.056 | 454,5 → 468,0 HP | +2,97 % | 159 | 34,889 | +420,0 % |
| 29 | 556 | 3.612 | 468,0 → 481,5 HP | +2,88 % | 193 | 41,185 | +435,0 % |
| 30 | 656 | 4.268 | 481,5 → 495,0 HP | +2,80 % | 234 | 48,593 | +450,0 % |

### Energiespeicher

- **Freischaltung:** von Anfang an
- **Baukosten:** 80 · **Upgrade-Basis:** 80
- **Grundwerte:** 140 HP · Panzerung 8 · Kapazität 400 · 2 Strahlen à 3,93 Felder · Transferrate 30 E/s

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Kapazität | 25 | 14 | 765 | 4.931 | +500 % | 0,70 → 222 |
| Transferrate | 25 | 18 | 935 | 6.031 | +300 % | 1,50 → 302 |
| Reichweite | 15 | 24 | 244 | 1.462 | +60 % | 6,00 → 95,2 |
| Strahlen | 5 | 64 | 419 | 1.011 | +250 % | 1,28 → 25,1 |
| Strahlübertragung | 10 | 16 | 71 | 376 | +11 % | 14,4 → 70,3 |
| Leben | 30 | 14 | 1.750 | 11.388 | +450 % | 0,93 → 624 |

#### Energiespeicher – Kapazität

**Verändert:** Speicherkapazität (Nachtreserve). **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 0,20 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 14 | 14 | 400,0 → 480,0 Energie | +20,00 % | 0,70 | 0,17 | +20,0 % |
| 2 | 17 | 31 | 480,0 → 560,0 Energie | +16,67 % | 1,02 | 0,21 | +40,0 % |
| 3 | 20 | 51 | 560,0 → 640,0 Energie | +14,29 % | 1,40 | 0,25 | +60,0 % |
| 4 | 24 | 75 | 640,0 → 720,0 Energie | +12,50 % | 1,92 | 0,30 | +80,0 % |
| 5 | 28 | 103 | 720,0 → 800,0 Energie | +11,11 % | 2,52 | 0,35 | +100,0 % |
| 6 | 33 | 136 | 800,0 → 880,0 Energie | +10,00 % | 3,30 | 0,41 | +120,0 % |
| 7 | 39 | 175 | 880,0 → 960,0 Energie | +9,09 % | 4,29 | 0,49 | +140,0 % |
| 8 | 46 | 221 | 960,0 → 1.040,0 Energie | +8,33 % | 5,52 | 0,58 | +160,0 % |
| 9 | 54 | 275 | 1.040,0 → 1.120,0 Energie | +7,69 % | 7,02 | 0,68 | +180,0 % |
| 10 | 64 | 339 | 1.120,0 → 1.200,0 Energie | +7,14 % | 8,96 | 0,80 | +200,0 % |
| 11 | 75 | 414 | 1.200,0 → 1.280,0 Energie | +6,67 % | 11,3 | 0,94 | +220,0 % |
| 12 | 89 | 503 | 1.280,0 → 1.360,0 Energie | +6,25 % | 14,2 | 1,11 | +240,0 % |
| 13 | 105 | 608 | 1.360,0 → 1.440,0 Energie | +5,88 % | 17,9 | 1,31 | +260,0 % |
| 14 | 124 | 732 | 1.440,0 → 1.520,0 Energie | +5,56 % | 22,3 | 1,55 | +280,0 % |
| 15 | 146 | 878 | 1.520,0 → 1.600,0 Energie | +5,26 % | 27,7 | 1,82 | +300,0 % |
| 16 | 172 | 1.050 | 1.600,0 → 1.680,0 Energie | +5,00 % | 34,4 | 2,15 | +320,0 % |
| 17 | 203 | 1.253 | 1.680,0 → 1.760,0 Energie | +4,76 % | 42,6 | 2,54 | +340,0 % |
| 18 | 240 | 1.493 | 1.760,0 → 1.840,0 Energie | +4,55 % | 52,8 | 3,00 | +360,0 % |
| 19 | 283 | 1.776 | 1.840,0 → 1.920,0 Energie | +4,35 % | 65,1 | 3,54 | +380,0 % |
| 20 | 334 | 2.110 | 1.920,0 → 2.000,0 Energie | +4,17 % | 80,2 | 4,18 | +400,0 % |
| 21 | 394 | 2.504 | 2.000,0 → 2.080,0 Energie | +4,00 % | 98,5 | 4,92 | +420,0 % |
| 22 | 465 | 2.969 | 2.080,0 → 2.160,0 Energie | +3,85 % | 121 | 5,81 | +440,0 % |
| 23 | 549 | 3.518 | 2.160,0 → 2.240,0 Energie | +3,70 % | 148 | 6,86 | +460,0 % |
| 24 | 648 | 4.166 | 2.240,0 → 2.320,0 Energie | +3,57 % | 181 | 8,10 | +480,0 % |
| 25 | 765 | 4.931 | 2.320,0 → 2.400,0 Energie | +3,45 % | 222 | 9,56 | +500,0 % |

#### Energiespeicher – Transferrate

**Verändert:** Transferrate je ausgehendem Strahl (Energie pro Sekunde, die ein Strahl höchstens weitergibt). **Je Stufe:** +12 % des Grundwerts.

Neubau zum Vergleich: 2,67 Münzen je E/s.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 18 | 18 | 30,0 → 33,6 E/s je Strahl | +12,00 % | 1,50 | 5,00 | +12,0 % |
| 2 | 21 | 39 | 33,6 → 37,2 E/s je Strahl | +10,71 % | 1,96 | 5,83 | +24,0 % |
| 3 | 25 | 64 | 37,2 → 40,8 E/s je Strahl | +9,68 % | 2,58 | 6,94 | +36,0 % |
| 4 | 29 | 93 | 40,8 → 44,4 E/s je Strahl | +8,82 % | 3,29 | 8,06 | +48,0 % |
| 5 | 34 | 127 | 44,4 → 48,0 E/s je Strahl | +8,11 % | 4,19 | 9,44 | +60,0 % |
| 6 | 40 | 167 | 48,0 → 51,6 E/s je Strahl | +7,50 % | 5,33 | 11,1 | +72,0 % |
| 7 | 48 | 215 | 51,6 → 55,2 E/s je Strahl | +6,98 % | 6,88 | 13,3 | +84,0 % |
| 8 | 56 | 271 | 55,2 → 58,8 E/s je Strahl | +6,52 % | 8,59 | 15,6 | +96,0 % |
| 9 | 66 | 337 | 58,8 → 62,4 E/s je Strahl | +6,12 % | 10,8 | 18,3 | +108,0 % |
| 10 | 78 | 415 | 62,4 → 66,0 E/s je Strahl | +5,77 % | 13,5 | 21,7 | +120,0 % |
| 11 | 92 | 507 | 66,0 → 69,6 E/s je Strahl | +5,45 % | 16,9 | 25,6 | +132,0 % |
| 12 | 109 | 616 | 69,6 → 73,2 E/s je Strahl | +5,17 % | 21,1 | 30,3 | +144,0 % |
| 13 | 128 | 744 | 73,2 → 76,8 E/s je Strahl | +4,92 % | 26,0 | 35,6 | +156,0 % |
| 14 | 151 | 895 | 76,8 → 80,4 E/s je Strahl | +4,69 % | 32,2 | 41,9 | +168,0 % |
| 15 | 179 | 1.074 | 80,4 → 84,0 E/s je Strahl | +4,48 % | 40,0 | 49,7 | +180,0 % |
| 16 | 211 | 1.285 | 84,0 → 87,6 E/s je Strahl | +4,29 % | 49,2 | 58,6 | +192,0 % |
| 17 | 249 | 1.534 | 87,6 → 91,2 E/s je Strahl | +4,11 % | 60,6 | 69,2 | +204,0 % |
| 18 | 293 | 1.827 | 91,2 → 94,8 E/s je Strahl | +3,95 % | 74,2 | 81,4 | +216,0 % |
| 19 | 346 | 2.173 | 94,8 → 98,4 E/s je Strahl | +3,80 % | 91,1 | 96,1 | +228,0 % |
| 20 | 409 | 2.582 | 98,4 → 102,0 E/s je Strahl | +3,66 % | 112 | 114 | +240,0 % |
| 21 | 482 | 3.064 | 102,0 → 105,6 E/s je Strahl | +3,53 % | 137 | 134 | +252,0 % |
| 22 | 569 | 3.633 | 105,6 → 109,2 E/s je Strahl | +3,41 % | 167 | 158 | +264,0 % |
| 23 | 671 | 4.304 | 109,2 → 112,8 E/s je Strahl | +3,30 % | 204 | 186 | +276,0 % |
| 24 | 792 | 5.096 | 112,8 → 116,4 E/s je Strahl | +3,19 % | 248 | 220 | +288,0 % |
| 25 | 935 | 6.031 | 116,4 → 120,0 E/s je Strahl | +3,09 % | 302 | 260 | +300,0 % |

#### Energiespeicher – Reichweite

**Verändert:** Strahlreichweite. Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 24 | 24 | 3,93 → 4,09 Felder | +4,00 % | 6,00 | 153 | +4,0 % |
| 2 | 28 | 52 | 4,09 → 4,24 Felder | +3,85 % | 7,28 | 178 | +8,0 % |
| 3 | 33 | 85 | 4,24 → 4,40 Felder | +3,70 % | 8,91 | 210 | +12,0 % |
| 4 | 39 | 124 | 4,40 → 4,56 Felder | +3,57 % | 10,9 | 248 | +16,0 % |
| 5 | 47 | 171 | 4,56 → 4,71 Felder | +3,45 % | 13,6 | 299 | +20,0 % |
| 6 | 55 | 226 | 4,71 → 4,87 Felder | +3,33 % | 16,5 | 350 | +24,0 % |
| 7 | 65 | 291 | 4,87 → 5,03 Felder | +3,23 % | 20,2 | 414 | +28,0 % |
| 8 | 76 | 367 | 5,03 → 5,19 Felder | +3,12 % | 24,3 | 484 | +32,0 % |
| 9 | 90 | 457 | 5,19 → 5,34 Felder | +3,03 % | 29,7 | 573 | +36,0 % |
| 10 | 106 | 563 | 5,34 → 5,50 Felder | +2,94 % | 36,0 | 675 | +40,0 % |
| 11 | 126 | 689 | 5,50 → 5,66 Felder | +2,86 % | 44,1 | 802 | +44,0 % |
| 12 | 148 | 837 | 5,66 → 5,81 Felder | +2,78 % | 53,3 | 942 | +48,0 % |
| 13 | 175 | 1.012 | 5,81 → 5,97 Felder | +2,70 % | 64,8 | 1.114 | +52,0 % |
| 14 | 206 | 1.218 | 5,97 → 6,13 Felder | +2,63 % | 78,3 | 1.311 | +56,0 % |
| 15 | 244 | 1.462 | 6,13 → 6,29 Felder | +2,56 % | 95,2 | 1.553 | +60,0 % |

#### Energiespeicher – Strahlen

**Verändert:** Maximale Zahl ausgehender Strahlen. Jeder Strahl hat die volle Transferrate, der mögliche Gesamtdurchsatz steigt also um einen Strahl. **Je Stufe:** +1 Strahl.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Strahl | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 64 | 64 | 2 → 3 Strahlen | +50,00 % | 1,28 | 64 | +50,0 % |
| 2 | 102 | 166 | 3 → 4 Strahlen | +33,33 % | 3,06 | 102 | +100,0 % |
| 3 | 164 | 330 | 4 → 5 Strahlen | +25,00 % | 6,56 | 164 | +150,0 % |
| 4 | 262 | 592 | 5 → 6 Strahlen | +20,00 % | 13,1 | 262 | +200,0 % |
| 5 | 419 | 1.011 | 6 → 7 Strahlen | +16,67 % | 25,1 | 419 | +250,0 % |

#### Energiespeicher – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf ein- und ausgehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 16 | 16 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 14,4 | +1,1 % |
| 2 | 19 | 35 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 17,3 | +2,2 % |
| 3 | 22 | 57 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 20,2 | +3,3 % |
| 4 | 26 | 83 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 24,2 | +4,4 % |
| 5 | 31 | 114 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 29,1 | +5,6 % |
| 6 | 37 | 151 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 35,1 | +6,7 % |
| 7 | 43 | 194 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 41,3 | +7,8 % |
| 8 | 51 | 245 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 49,5 | +8,9 % |
| 9 | 60 | 305 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 58,8 | +10,0 % |
| 10 | 71 | 376 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 70,3 | +11,1 % |

#### Energiespeicher – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,571 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 14 | 14 | 140,0 → 161,0 HP | +15,00 % | 0,93 | 0,667 | +15,0 % |
| 2 | 17 | 31 | 161,0 → 182,0 HP | +13,04 % | 1,30 | 0,810 | +30,0 % |
| 3 | 20 | 51 | 182,0 → 203,0 HP | +11,54 % | 1,73 | 0,952 | +45,0 % |
| 4 | 24 | 75 | 203,0 → 224,0 HP | +10,34 % | 2,32 | 1,143 | +60,0 % |
| 5 | 28 | 103 | 224,0 → 245,0 HP | +9,38 % | 2,99 | 1,333 | +75,0 % |
| 6 | 33 | 136 | 245,0 → 266,0 HP | +8,57 % | 3,85 | 1,571 | +90,0 % |
| 7 | 39 | 175 | 266,0 → 287,0 HP | +7,89 % | 4,94 | 1,857 | +105,0 % |
| 8 | 46 | 221 | 287,0 → 308,0 HP | +7,32 % | 6,29 | 2,190 | +120,0 % |
| 9 | 54 | 275 | 308,0 → 329,0 HP | +6,82 % | 7,92 | 2,571 | +135,0 % |
| 10 | 64 | 339 | 329,0 → 350,0 HP | +6,38 % | 10,0 | 3,048 | +150,0 % |
| 11 | 75 | 414 | 350,0 → 371,0 HP | +6,00 % | 12,5 | 3,571 | +165,0 % |
| 12 | 89 | 503 | 371,0 → 392,0 HP | +5,66 % | 15,7 | 4,238 | +180,0 % |
| 13 | 105 | 608 | 392,0 → 413,0 HP | +5,36 % | 19,6 | 5,000 | +195,0 % |
| 14 | 124 | 732 | 413,0 → 434,0 HP | +5,08 % | 24,4 | 5,905 | +210,0 % |
| 15 | 146 | 878 | 434,0 → 455,0 HP | +4,84 % | 30,2 | 6,952 | +225,0 % |
| 16 | 172 | 1.050 | 455,0 → 476,0 HP | +4,62 % | 37,3 | 8,190 | +240,0 % |
| 17 | 203 | 1.253 | 476,0 → 497,0 HP | +4,41 % | 46,0 | 9,667 | +255,0 % |
| 18 | 240 | 1.493 | 497,0 → 518,0 HP | +4,23 % | 56,8 | 11,429 | +270,0 % |
| 19 | 283 | 1.776 | 518,0 → 539,0 HP | +4,05 % | 69,8 | 13,476 | +285,0 % |
| 20 | 334 | 2.110 | 539,0 → 560,0 HP | +3,90 % | 85,7 | 15,905 | +300,0 % |
| 21 | 394 | 2.504 | 560,0 → 581,0 HP | +3,75 % | 105 | 18,762 | +315,0 % |
| 22 | 465 | 2.969 | 581,0 → 602,0 HP | +3,61 % | 129 | 22,143 | +330,0 % |
| 23 | 549 | 3.518 | 602,0 → 623,0 HP | +3,49 % | 157 | 26,143 | +345,0 % |
| 24 | 648 | 4.166 | 623,0 → 644,0 HP | +3,37 % | 192 | 30,857 | +360,0 % |
| 25 | 765 | 4.931 | 644,0 → 665,0 HP | +3,26 % | 235 | 36,429 | +375,0 % |
| 26 | 902 | 5.833 | 665,0 → 686,0 HP | +3,16 % | 286 | 42,952 | +390,0 % |
| 27 | 1.065 | 6.898 | 686,0 → 707,0 HP | +3,06 % | 348 | 50,714 | +405,0 % |
| 28 | 1.257 | 8.155 | 707,0 → 728,0 HP | +2,97 % | 423 | 59,857 | +420,0 % |
| 29 | 1.483 | 9.638 | 728,0 → 749,0 HP | +2,88 % | 514 | 70,619 | +435,0 % |
| 30 | 1.750 | 11.388 | 749,0 → 770,0 HP | +2,80 % | 624 | 83,333 | +450,0 % |

### Energieexporteur

- **Freischaltung:** von Anfang an
- **Baukosten:** 120 · **Upgrade-Basis:** 120
- **Grundwerte:** 80 HP · Panzerung 4 · Kapazität 80 · Export 8 E/s = 1,00 Münzen/s

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Exportrate | 25 | 26 | 1.402 | 9.041 | +300 % | 2,17 → 453 |
| Kapazität | 25 | 22 | 1.147 | 7.398 | +500 % | 1,10 → 333 |
| Strahlübertragung | 10 | 24 | 106 | 563 | +11 % | 21,6 → 105 |
| Leben | 30 | 22 | 2.624 | 17.082 | +450 % | 1,47 → 936 |

#### Energieexporteur – Exportrate

**Verändert:** Exportrate (verkaufte Energie pro Sekunde). Erlös = Rate ÷ 8 Münzen/s, ausgezahlt alle 5 s. **Je Stufe:** +12 % des Grundwerts.

Neubau zum Vergleich: amortisiert sich in 120 s Exportzeit (bei voller Versorgung, ohne Energiekosten).

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Amortisation | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 26 | 26 | 8,00 → 8,96 E/s (1,00 → 1,12 Münzen/s) | +12,00 % | 2,17 | 217 s | +12,0 % |
| 2 | 31 | 57 | 8,96 → 9,92 E/s (1,12 → 1,24 Münzen/s) | +10,71 % | 2,89 | 258 s | +24,0 % |
| 3 | 37 | 94 | 9,92 → 10,88 E/s (1,24 → 1,36 Münzen/s) | +9,68 % | 3,82 | 308 s | +36,0 % |
| 4 | 43 | 137 | 10,88 → 11,84 E/s (1,36 → 1,48 Münzen/s) | +8,82 % | 4,87 | 358 s | +48,0 % |
| 5 | 51 | 188 | 11,84 → 12,80 E/s (1,48 → 1,60 Münzen/s) | +8,11 % | 6,29 | 425 s | +60,0 % |
| 6 | 60 | 248 | 12,80 → 13,76 E/s (1,60 → 1,72 Münzen/s) | +7,50 % | 8,00 | 500 s | +72,0 % |
| 7 | 71 | 319 | 13,76 → 14,72 E/s (1,72 → 1,84 Münzen/s) | +6,98 % | 10,2 | 592 s | +84,0 % |
| 8 | 84 | 403 | 14,72 → 15,68 E/s (1,84 → 1,96 Münzen/s) | +6,52 % | 12,9 | 700 s | +96,0 % |
| 9 | 99 | 502 | 15,68 → 16,64 E/s (1,96 → 2,08 Münzen/s) | +6,12 % | 16,2 | 825 s | +108,0 % |
| 10 | 117 | 619 | 16,64 → 17,60 E/s (2,08 → 2,20 Münzen/s) | +5,77 % | 20,3 | 975 s | +120,0 % |
| 11 | 138 | 757 | 17,60 → 18,56 E/s (2,20 → 2,32 Münzen/s) | +5,45 % | 25,3 | 1.150 s | +132,0 % |
| 12 | 163 | 920 | 18,56 → 19,52 E/s (2,32 → 2,44 Münzen/s) | +5,17 % | 31,5 | 1.358 s | +144,0 % |
| 13 | 192 | 1.112 | 19,52 → 20,48 E/s (2,44 → 2,56 Münzen/s) | +4,92 % | 39,0 | 1.600 s | +156,0 % |
| 14 | 227 | 1.339 | 20,48 → 21,44 E/s (2,56 → 2,68 Münzen/s) | +4,69 % | 48,4 | 1.892 s | +168,0 % |
| 15 | 268 | 1.607 | 21,44 → 22,40 E/s (2,68 → 2,80 Münzen/s) | +4,48 % | 59,9 | 2.233 s | +180,0 % |
| 16 | 316 | 1.923 | 22,40 → 23,36 E/s (2,80 → 2,92 Münzen/s) | +4,29 % | 73,7 | 2.633 s | +192,0 % |
| 17 | 373 | 2.296 | 23,36 → 24,32 E/s (2,92 → 3,04 Münzen/s) | +4,11 % | 90,8 | 3.108 s | +204,0 % |
| 18 | 440 | 2.736 | 24,32 → 25,28 E/s (3,04 → 3,16 Münzen/s) | +3,95 % | 111 | 3.667 s | +216,0 % |
| 19 | 519 | 3.255 | 25,28 → 26,24 E/s (3,16 → 3,28 Münzen/s) | +3,80 % | 137 | 4.325 s | +228,0 % |
| 20 | 613 | 3.868 | 26,24 → 27,20 E/s (3,28 → 3,40 Münzen/s) | +3,66 % | 168 | 5.108 s | +240,0 % |
| 21 | 723 | 4.591 | 27,20 → 28,16 E/s (3,40 → 3,52 Münzen/s) | +3,53 % | 205 | 6.025 s | +252,0 % |
| 22 | 853 | 5.444 | 28,16 → 29,12 E/s (3,52 → 3,64 Münzen/s) | +3,41 % | 250 | 7.108 s | +264,0 % |
| 23 | 1.007 | 6.451 | 29,12 → 30,08 E/s (3,64 → 3,76 Münzen/s) | +3,30 % | 305 | 8.392 s | +276,0 % |
| 24 | 1.188 | 7.639 | 30,08 → 31,04 E/s (3,76 → 3,88 Münzen/s) | +3,19 % | 372 | 9.900 s | +288,0 % |
| 25 | 1.402 | 9.041 | 31,04 → 32,00 E/s (3,88 → 4,00 Münzen/s) | +3,09 % | 453 | 11.683 s | +300,0 % |

#### Energieexporteur – Kapazität

**Verändert:** Puffer vor dem Verkauf. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,50 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 22 | 22 | 80,0 → 96,0 Energie | +20,00 % | 1,10 | 1,38 | +20,0 % |
| 2 | 25 | 47 | 96,0 → 112,0 Energie | +16,67 % | 1,50 | 1,56 | +40,0 % |
| 3 | 30 | 77 | 112,0 → 128,0 Energie | +14,29 % | 2,10 | 1,88 | +60,0 % |
| 4 | 35 | 112 | 128,0 → 144,0 Energie | +12,50 % | 2,80 | 2,19 | +80,0 % |
| 5 | 42 | 154 | 144,0 → 160,0 Energie | +11,11 % | 3,78 | 2,62 | +100,0 % |
| 6 | 49 | 203 | 160,0 → 176,0 Energie | +10,00 % | 4,90 | 3,06 | +120,0 % |
| 7 | 58 | 261 | 176,0 → 192,0 Energie | +9,09 % | 6,38 | 3,62 | +140,0 % |
| 8 | 69 | 330 | 192,0 → 208,0 Energie | +8,33 % | 8,28 | 4,31 | +160,0 % |
| 9 | 81 | 411 | 208,0 → 224,0 Energie | +7,69 % | 10,5 | 5,06 | +180,0 % |
| 10 | 96 | 507 | 224,0 → 240,0 Energie | +7,14 % | 13,4 | 6,00 | +200,0 % |
| 11 | 113 | 620 | 240,0 → 256,0 Energie | +6,67 % | 17,0 | 7,06 | +220,0 % |
| 12 | 133 | 753 | 256,0 → 272,0 Energie | +6,25 % | 21,3 | 8,31 | +240,0 % |
| 13 | 157 | 910 | 272,0 → 288,0 Energie | +5,88 % | 26,7 | 9,81 | +260,0 % |
| 14 | 186 | 1.096 | 288,0 → 304,0 Energie | +5,56 % | 33,5 | 11,6 | +280,0 % |
| 15 | 219 | 1.315 | 304,0 → 320,0 Energie | +5,26 % | 41,6 | 13,7 | +300,0 % |
| 16 | 259 | 1.574 | 320,0 → 336,0 Energie | +5,00 % | 51,8 | 16,2 | +320,0 % |
| 17 | 305 | 1.879 | 336,0 → 352,0 Energie | +4,76 % | 64,0 | 19,1 | +340,0 % |
| 18 | 360 | 2.239 | 352,0 → 368,0 Energie | +4,55 % | 79,2 | 22,5 | +360,0 % |
| 19 | 425 | 2.664 | 368,0 → 384,0 Energie | +4,35 % | 97,7 | 26,6 | +380,0 % |
| 20 | 501 | 3.165 | 384,0 → 400,0 Energie | +4,17 % | 120 | 31,3 | +400,0 % |
| 21 | 592 | 3.757 | 400,0 → 416,0 Energie | +4,00 % | 148 | 37,0 | +420,0 % |
| 22 | 698 | 4.455 | 416,0 → 432,0 Energie | +3,85 % | 181 | 43,6 | +440,0 % |
| 23 | 824 | 5.279 | 432,0 → 448,0 Energie | +3,70 % | 222 | 51,5 | +460,0 % |
| 24 | 972 | 6.251 | 448,0 → 464,0 Energie | +3,57 % | 272 | 60,8 | +480,0 % |
| 25 | 1.147 | 7.398 | 464,0 → 480,0 Energie | +3,45 % | 333 | 71,7 | +500,0 % |

#### Energieexporteur – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 24 | 24 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 21,6 | +1,1 % |
| 2 | 28 | 52 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 25,5 | +2,2 % |
| 3 | 33 | 85 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 30,4 | +3,3 % |
| 4 | 39 | 124 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 36,3 | +4,4 % |
| 5 | 47 | 171 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 44,2 | +5,6 % |
| 6 | 55 | 226 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 52,2 | +6,7 % |
| 7 | 65 | 291 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 62,4 | +7,8 % |
| 8 | 76 | 367 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 73,7 | +8,9 % |
| 9 | 90 | 457 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 88,2 | +10,0 % |
| 10 | 106 | 563 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 105 | +11,1 % |

#### Energieexporteur – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,500 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 22 | 22 | 80,0 → 92,0 HP | +15,00 % | 1,47 | 1,833 | +15,0 % |
| 2 | 25 | 47 | 92,0 → 104,0 HP | +13,04 % | 1,92 | 2,083 | +30,0 % |
| 3 | 30 | 77 | 104,0 → 116,0 HP | +11,54 % | 2,60 | 2,500 | +45,0 % |
| 4 | 35 | 112 | 116,0 → 128,0 HP | +10,34 % | 3,38 | 2,917 | +60,0 % |
| 5 | 42 | 154 | 128,0 → 140,0 HP | +9,38 % | 4,48 | 3,500 | +75,0 % |
| 6 | 49 | 203 | 140,0 → 152,0 HP | +8,57 % | 5,72 | 4,083 | +90,0 % |
| 7 | 58 | 261 | 152,0 → 164,0 HP | +7,89 % | 7,35 | 4,833 | +105,0 % |
| 8 | 69 | 330 | 164,0 → 176,0 HP | +7,32 % | 9,43 | 5,750 | +120,0 % |
| 9 | 81 | 411 | 176,0 → 188,0 HP | +6,82 % | 11,9 | 6,750 | +135,0 % |
| 10 | 96 | 507 | 188,0 → 200,0 HP | +6,38 % | 15,0 | 8,000 | +150,0 % |
| 11 | 113 | 620 | 200,0 → 212,0 HP | +6,00 % | 18,8 | 9,417 | +165,0 % |
| 12 | 133 | 753 | 212,0 → 224,0 HP | +5,66 % | 23,5 | 11,083 | +180,0 % |
| 13 | 157 | 910 | 224,0 → 236,0 HP | +5,36 % | 29,3 | 13,083 | +195,0 % |
| 14 | 186 | 1.096 | 236,0 → 248,0 HP | +5,08 % | 36,6 | 15,500 | +210,0 % |
| 15 | 219 | 1.315 | 248,0 → 260,0 HP | +4,84 % | 45,3 | 18,250 | +225,0 % |
| 16 | 259 | 1.574 | 260,0 → 272,0 HP | +4,62 % | 56,1 | 21,583 | +240,0 % |
| 17 | 305 | 1.879 | 272,0 → 284,0 HP | +4,41 % | 69,1 | 25,417 | +255,0 % |
| 18 | 360 | 2.239 | 284,0 → 296,0 HP | +4,23 % | 85,2 | 30,000 | +270,0 % |
| 19 | 425 | 2.664 | 296,0 → 308,0 HP | +4,05 % | 105 | 35,417 | +285,0 % |
| 20 | 501 | 3.165 | 308,0 → 320,0 HP | +3,90 % | 129 | 41,750 | +300,0 % |
| 21 | 592 | 3.757 | 320,0 → 332,0 HP | +3,75 % | 158 | 49,333 | +315,0 % |
| 22 | 698 | 4.455 | 332,0 → 344,0 HP | +3,61 % | 193 | 58,167 | +330,0 % |
| 23 | 824 | 5.279 | 344,0 → 356,0 HP | +3,49 % | 236 | 68,667 | +345,0 % |
| 24 | 972 | 6.251 | 356,0 → 368,0 HP | +3,37 % | 288 | 81,000 | +360,0 % |
| 25 | 1.147 | 7.398 | 368,0 → 380,0 HP | +3,26 % | 352 | 95,583 | +375,0 % |
| 26 | 1.354 | 8.752 | 380,0 → 392,0 HP | +3,16 % | 429 | 112,833 | +390,0 % |
| 27 | 1.597 | 10.349 | 392,0 → 404,0 HP | +3,06 % | 522 | 133,083 | +405,0 % |
| 28 | 1.885 | 12.234 | 404,0 → 416,0 HP | +2,97 % | 635 | 157,083 | +420,0 % |
| 29 | 2.224 | 14.458 | 416,0 → 428,0 HP | +2,88 % | 771 | 185,333 | +435,0 % |
| 30 | 2.624 | 17.082 | 428,0 → 440,0 HP | +2,80 % | 936 | 218,667 | +450,0 % |

## Türme

### Blitzturm

- **Freischaltung:** von Anfang an
- **Baukosten:** 70 · **Upgrade-Basis:** 70
- **Grundwerte:** 90 HP · Panzerung 6 · Kapazität 40 · 26 Schaden alle 0,45 s, 4 Energie/Schuss, Reichweite 4,11 Felder · DPS 64,7 (Ø inkl. 12 % Krit)

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Schaden | 40 | 15 | 9.793 | 64.112 | +400 % | 1,50 → 4.799 |
| Feuerrate | 25 | 18 | 929 | 5.997 | +150 % | 3,00 → 378 |
| Überladung | 12 | 11 | 65 | 366 | +240 % | 0,55 → 10,4 |
| Reichweite | 15 | 21 | 213 | 1.282 | +60 % | 5,25 → 83,1 |
| Kritische Treffer | 20 | 18 | 406 | 2.568 | +18 % | 20,2 → 532 |
| Effizienz | 20 | 14 | 325 | 2.052 | +100 % | 2,80 → 127 |
| Kapazität | 25 | 13 | 669 | 4.318 | +500 % | 0,65 → 194 |
| Strahlübertragung | 10 | 14 | 62 | 330 | +11 % | 12,6 → 61,4 |
| Leben | 30 | 13 | 1.531 | 9.967 | +450 % | 0,87 → 546 |
| Panzerung | 20 | 11 | 244 | 1.540 | +17 % | 13,0 → 334 |

#### Blitzturm – Schaden

**Verändert:** Schaden je Schuss (Laser: je Sekunde). **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 1,08 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 15 | 15 | Schaden/Schuss 26,0 → 28,6 | +10,00 % | 1,50 | 2,32 | +10,0 % |
| 2 | 18 | 33 | Schaden/Schuss 28,6 → 31,2 | +9,09 % | 1,98 | 2,78 | +20,0 % |
| 3 | 21 | 54 | Schaden/Schuss 31,2 → 33,8 | +8,33 % | 2,52 | 3,25 | +30,0 % |
| 4 | 25 | 79 | Schaden/Schuss 33,8 → 36,4 | +7,69 % | 3,25 | 3,86 | +40,0 % |
| 5 | 30 | 109 | Schaden/Schuss 36,4 → 39,0 | +7,14 % | 4,20 | 4,64 | +50,0 % |
| 6 | 35 | 144 | Schaden/Schuss 39,0 → 41,6 | +6,67 % | 5,25 | 5,41 | +60,0 % |
| 7 | 42 | 186 | Schaden/Schuss 41,6 → 44,2 | +6,25 % | 6,72 | 6,49 | +70,0 % |
| 8 | 49 | 235 | Schaden/Schuss 44,2 → 46,8 | +5,88 % | 8,33 | 7,57 | +80,0 % |
| 9 | 58 | 293 | Schaden/Schuss 46,8 → 49,4 | +5,56 % | 10,4 | 8,96 | +90,0 % |
| 10 | 68 | 361 | Schaden/Schuss 49,4 → 52,0 | +5,26 % | 12,9 | 10,5 | +100,0 % |
| 11 | 81 | 442 | Schaden/Schuss 52,0 → 54,6 | +5,00 % | 16,2 | 12,5 | +110,0 % |
| 12 | 95 | 537 | Schaden/Schuss 54,6 → 57,2 | +4,76 % | 19,9 | 14,7 | +120,0 % |
| 13 | 112 | 649 | Schaden/Schuss 57,2 → 59,8 | +4,55 % | 24,6 | 17,3 | +130,0 % |
| 14 | 132 | 781 | Schaden/Schuss 59,8 → 62,4 | +4,35 % | 30,4 | 20,4 | +140,0 % |
| 15 | 156 | 937 | Schaden/Schuss 62,4 → 65,0 | +4,17 % | 37,4 | 24,1 | +150,0 % |
| 16 | 184 | 1.121 | Schaden/Schuss 65,0 → 67,6 | +4,00 % | 46,0 | 28,4 | +160,0 % |
| 17 | 218 | 1.339 | Schaden/Schuss 67,6 → 70,2 | +3,85 % | 56,7 | 33,7 | +170,0 % |
| 18 | 257 | 1.596 | Schaden/Schuss 70,2 → 72,8 | +3,70 % | 69,4 | 39,7 | +180,0 % |
| 19 | 303 | 1.899 | Schaden/Schuss 72,8 → 75,4 | +3,57 % | 84,8 | 46,8 | +190,0 % |
| 20 | 358 | 2.257 | Schaden/Schuss 75,4 → 78,0 | +3,45 % | 104 | 55,3 | +200,0 % |
| 21 | 422 | 2.679 | Schaden/Schuss 78,0 → 80,6 | +3,33 % | 127 | 65,2 | +210,0 % |
| 22 | 498 | 3.177 | Schaden/Schuss 80,6 → 83,2 | +3,23 % | 154 | 77,0 | +220,0 % |
| 23 | 587 | 3.764 | Schaden/Schuss 83,2 → 85,8 | +3,12 % | 188 | 90,7 | +230,0 % |
| 24 | 693 | 4.457 | Schaden/Schuss 85,8 → 88,4 | +3,03 % | 229 | 107 | +240,0 % |
| 25 | 818 | 5.275 | Schaden/Schuss 88,4 → 91,0 | +2,94 % | 278 | 126 | +250,0 % |
| 26 | 965 | 6.240 | Schaden/Schuss 91,0 → 93,6 | +2,86 % | 338 | 149 | +260,0 % |
| 27 | 1.139 | 7.379 | Schaden/Schuss 93,6 → 96,2 | +2,78 % | 410 | 176 | +270,0 % |
| 28 | 1.344 | 8.723 | Schaden/Schuss 96,2 → 98,8 | +2,70 % | 497 | 208 | +280,0 % |
| 29 | 1.586 | 10.309 | Schaden/Schuss 98,8 → 101,4 | +2,63 % | 603 | 245 | +290,0 % |
| 30 | 1.871 | 12.180 | Schaden/Schuss 101,4 → 104,0 | +2,56 % | 730 | 289 | +300,0 % |
| 31 | 2.208 | 14.388 | Schaden/Schuss 104,0 → 106,6 | +2,50 % | 883 | 341 | +310,0 % |
| 32 | 2.605 | 16.993 | Schaden/Schuss 106,6 → 109,2 | +2,44 % | 1.068 | 403 | +320,0 % |
| 33 | 3.074 | 20.067 | Schaden/Schuss 109,2 → 111,8 | +2,38 % | 1.291 | 475 | +330,0 % |
| 34 | 3.628 | 23.695 | Schaden/Schuss 111,8 → 114,4 | +2,33 % | 1.560 | 561 | +340,0 % |
| 35 | 4.281 | 27.976 | Schaden/Schuss 114,4 → 117,0 | +2,27 % | 1.884 | 662 | +350,0 % |
| 36 | 5.051 | 33.027 | Schaden/Schuss 117,0 → 119,6 | +2,22 % | 2.273 | 781 | +360,0 % |
| 37 | 5.960 | 38.987 | Schaden/Schuss 119,6 → 122,2 | +2,17 % | 2.742 | 921 | +370,0 % |
| 38 | 7.033 | 46.020 | Schaden/Schuss 122,2 → 124,8 | +2,13 % | 3.306 | 1.087 | +380,0 % |
| 39 | 8.299 | 54.319 | Schaden/Schuss 124,8 → 127,4 | +2,08 % | 3.984 | 1.282 | +390,0 % |
| 40 | 9.793 | 64.112 | Schaden/Schuss 127,4 → 130,0 | +2,04 % | 4.799 | 1.513 | +400,0 % |

#### Blitzturm – Feuerrate

**Verändert:** Abklingzeit zwischen zwei Schüssen (Feuerrate = 1 ÷ Abklingzeit). Mehr Schüsse brauchen entsprechend mehr Energie pro Sekunde. **Je Stufe:** +6 % Feuerrate.

Neubau zum Vergleich: 1,08 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 18 | 18 | 0,450 → 0,425 s (2,36 Schüsse/s) | +6,00 % | 3,00 | 4,64 | +6,0 % |
| 2 | 21 | 39 | 0,425 → 0,402 s (2,49 Schüsse/s) | +5,66 % | 3,71 | 5,41 | +12,0 % |
| 3 | 24 | 63 | 0,402 → 0,381 s (2,62 Schüsse/s) | +5,36 % | 4,48 | 6,18 | +18,0 % |
| 4 | 29 | 92 | 0,381 → 0,363 s (2,76 Schüsse/s) | +5,08 % | 5,70 | 7,47 | +24,0 % |
| 5 | 34 | 126 | 0,363 → 0,346 s (2,89 Schüsse/s) | +4,84 % | 7,03 | 8,76 | +30,0 % |
| 6 | 40 | 166 | 0,346 → 0,331 s (3,02 Schüsse/s) | +4,62 % | 8,67 | 10,3 | +36,0 % |
| 7 | 47 | 213 | 0,331 → 0,317 s (3,16 Schüsse/s) | +4,41 % | 10,7 | 12,1 | +42,0 % |
| 8 | 56 | 269 | 0,317 → 0,304 s (3,29 Schüsse/s) | +4,23 % | 13,3 | 14,4 | +48,0 % |
| 9 | 66 | 335 | 0,304 → 0,292 s (3,42 Schüsse/s) | +4,05 % | 16,3 | 17,0 | +54,0 % |
| 10 | 78 | 413 | 0,292 → 0,281 s (3,56 Schüsse/s) | +3,90 % | 20,0 | 20,1 | +60,0 % |
| 11 | 92 | 505 | 0,281 → 0,271 s (3,69 Schüsse/s) | +3,75 % | 24,5 | 23,7 | +66,0 % |
| 12 | 108 | 613 | 0,271 → 0,262 s (3,82 Schüsse/s) | +3,61 % | 29,9 | 27,8 | +72,0 % |
| 13 | 128 | 741 | 0,262 → 0,253 s (3,96 Schüsse/s) | +3,49 % | 36,7 | 33,0 | +78,0 % |
| 14 | 150 | 891 | 0,253 → 0,245 s (4,09 Schüsse/s) | +3,37 % | 44,5 | 38,6 | +84,0 % |
| 15 | 178 | 1.069 | 0,245 → 0,237 s (4,22 Schüsse/s) | +3,26 % | 54,6 | 45,8 | +90,0 % |
| 16 | 210 | 1.279 | 0,237 → 0,230 s (4,36 Schüsse/s) | +3,16 % | 66,5 | 54,1 | +96,0 % |
| 17 | 247 | 1.526 | 0,230 → 0,223 s (4,49 Schüsse/s) | +3,06 % | 80,7 | 63,6 | +102,0 % |
| 18 | 292 | 1.818 | 0,223 → 0,216 s (4,62 Schüsse/s) | +2,97 % | 98,3 | 75,2 | +108,0 % |
| 19 | 344 | 2.162 | 0,216 → 0,210 s (4,76 Schüsse/s) | +2,88 % | 119 | 88,6 | +114,0 % |
| 20 | 406 | 2.568 | 0,210 → 0,205 s (4,89 Schüsse/s) | +2,80 % | 145 | 105 | +120,0 % |
| 21 | 479 | 3.047 | 0,205 → 0,199 s (5,02 Schüsse/s) | +2,73 % | 176 | 123 | +126,0 % |
| 22 | 566 | 3.613 | 0,199 → 0,194 s (5,16 Schüsse/s) | +2,65 % | 213 | 146 | +132,0 % |
| 23 | 667 | 4.280 | 0,194 → 0,189 s (5,29 Schüsse/s) | +2,59 % | 258 | 172 | +138,0 % |
| 24 | 788 | 5.068 | 0,189 → 0,184 s (5,42 Schüsse/s) | +2,52 % | 313 | 203 | +144,0 % |
| 25 | 929 | 5.997 | 0,184 → 0,180 s (5,56 Schüsse/s) | +2,46 % | 378 | 239 | +150,0 % |

#### Blitzturm – Überladung

**Verändert:** Schaden ×(1 + 0,2 × Stufe), aber Energie je Schuss ×1,25 je Stufe. Braucht ein Schuss mehr Energie als der Speicher fasst, feuert der Turm nicht mehr (Überladung, Grenze ohne Kapazitäts- und Effizienz-Upgrades). **Je Stufe:** +20 % Schaden, ×1,25 Energie.

Neubau zum Vergleich: 1,08 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt | Nebenwirkung |
|---|---|---|---|---|---|---|---|---|
| 1 | 11 | 11 | Schaden 26,0 → 31,2 · Energie/Schuss 4,00 → 5,00 | +20,00 % | 0,55 | 0,85 | +20,0 % | Schaden je Energie −4,0 % |
| 2 | 12 | 23 | Schaden 31,2 → 36,4 · Energie/Schuss 5,00 → 6,25 | +16,67 % | 0,72 | 0,93 | +40,0 % | Schaden je Energie −6,7 % |
| 3 | 15 | 38 | Schaden 36,4 → 41,6 · Energie/Schuss 6,25 → 7,81 | +14,29 % | 1,05 | 1,16 | +60,0 % | Schaden je Energie −8,6 % |
| 4 | 17 | 55 | Schaden 41,6 → 46,8 · Energie/Schuss 7,81 → 9,77 | +12,50 % | 1,36 | 1,31 | +80,0 % | Schaden je Energie −10,0 % |
| 5 | 20 | 75 | Schaden 46,8 → 52,0 · Energie/Schuss 9,77 → 12,21 | +11,11 % | 1,80 | 1,55 | +100,0 % | Schaden je Energie −11,1 % |
| 6 | 24 | 99 | Schaden 52,0 → 57,2 · Energie/Schuss 12,21 → 15,26 | +10,00 % | 2,40 | 1,85 | +120,0 % | Schaden je Energie −12,0 % |
| 7 | 28 | 127 | Schaden 57,2 → 62,4 · Energie/Schuss 15,26 → 19,07 | +9,09 % | 3,08 | 2,16 | +140,0 % | Schaden je Energie −12,7 % |
| 8 | 33 | 160 | Schaden 62,4 → 67,6 · Energie/Schuss 19,07 → 23,84 | +8,33 % | 3,96 | 2,55 | +160,0 % | Schaden je Energie −13,3 % |
| 9 | 39 | 199 | Schaden 67,6 → 72,8 · Energie/Schuss 23,84 → 29,80 | +7,69 % | 5,07 | 3,01 | +180,0 % | Schaden je Energie −13,8 % |
| 10 | 47 | 246 | Schaden 72,8 → 78,0 · Energie/Schuss 29,80 → 37,25 | +7,14 % | 6,58 | 3,63 | +200,0 % | Schaden je Energie −14,3 % |
| 11 | 55 | 301 | Schaden 78,0 → 83,2 · Energie/Schuss 37,25 → 46,57 | +6,67 % | 8,25 | 4,25 | +220,0 % | Schaden je Energie −14,7 % · ⚠ ab hier überladen (Schuss 46,6 > Speicher 40) |
| 12 | 65 | 366 | Schaden 83,2 → 88,4 · Energie/Schuss 46,57 → 58,21 | +6,25 % | 10,4 | 5,02 | +240,0 % | Schaden je Energie −15,0 % · ⚠ überladen |

#### Blitzturm – Reichweite

**Verändert:** Angriffsreichweite (und damit Sichtweite). Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 21 | 21 | 4,11 → 4,27 Felder | +4,00 % | 5,25 | 128 | +4,0 % |
| 2 | 25 | 46 | 4,27 → 4,44 Felder | +3,85 % | 6,50 | 152 | +8,0 % |
| 3 | 29 | 75 | 4,44 → 4,60 Felder | +3,70 % | 7,83 | 177 | +12,0 % |
| 4 | 35 | 110 | 4,60 → 4,76 Felder | +3,57 % | 9,80 | 213 | +16,0 % |
| 5 | 41 | 151 | 4,76 → 4,93 Felder | +3,45 % | 11,9 | 250 | +20,0 % |
| 6 | 48 | 199 | 4,93 → 5,09 Felder | +3,33 % | 14,4 | 292 | +24,0 % |
| 7 | 57 | 256 | 5,09 → 5,26 Felder | +3,23 % | 17,7 | 347 | +28,0 % |
| 8 | 67 | 323 | 5,26 → 5,42 Felder | +3,12 % | 21,4 | 408 | +32,0 % |
| 9 | 79 | 402 | 5,42 → 5,59 Felder | +3,03 % | 26,1 | 481 | +36,0 % |
| 10 | 93 | 495 | 5,59 → 5,75 Felder | +2,94 % | 31,6 | 566 | +40,0 % |
| 11 | 110 | 605 | 5,75 → 5,91 Felder | +2,86 % | 38,5 | 670 | +44,0 % |
| 12 | 130 | 735 | 5,91 → 6,08 Felder | +2,78 % | 46,8 | 791 | +48,0 % |
| 13 | 153 | 888 | 6,08 → 6,24 Felder | +2,70 % | 56,6 | 931 | +52,0 % |
| 14 | 181 | 1.069 | 6,24 → 6,41 Felder | +2,63 % | 68,8 | 1.102 | +56,0 % |
| 15 | 213 | 1.282 | 6,41 → 6,57 Felder | +2,56 % | 83,1 | 1.297 | +60,0 % |

#### Blitzturm – Kritische Treffer

**Verändert:** Chance auf einen kritischen Treffer (doppelter Schaden). Nutzen = Anstieg des durchschnittlichen Schadens (1 + Krit-Chance). **Je Stufe:** +1 Prozentpunkt.

Neubau zum Vergleich: 1,08 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 18 | 18 | Krit-Chance 12 % → 13 % | +0,89 % | 20,2 | 31,2 | +0,9 % |
| 2 | 21 | 39 | Krit-Chance 13 % → 14 % | +0,88 % | 23,7 | 36,3 | +1,8 % |
| 3 | 24 | 63 | Krit-Chance 14 % → 15 % | +0,88 % | 27,4 | 41,5 | +2,7 % |
| 4 | 29 | 92 | Krit-Chance 15 % → 16 % | +0,87 % | 33,4 | 50,2 | +3,6 % |
| 5 | 34 | 126 | Krit-Chance 16 % → 17 % | +0,86 % | 39,4 | 58,8 | +4,5 % |
| 6 | 40 | 166 | Krit-Chance 17 % → 18 % | +0,85 % | 46,8 | 69,2 | +5,4 % |
| 7 | 47 | 213 | Krit-Chance 18 % → 19 % | +0,85 % | 55,5 | 81,3 | +6,2 % |
| 8 | 56 | 269 | Krit-Chance 19 % → 20 % | +0,84 % | 66,6 | 96,9 | +7,1 % |
| 9 | 66 | 335 | Krit-Chance 20 % → 21 % | +0,83 % | 79,2 | 114 | +8,0 % |
| 10 | 78 | 413 | Krit-Chance 21 % → 22 % | +0,83 % | 94,4 | 135 | +8,9 % |
| 11 | 92 | 505 | Krit-Chance 22 % → 23 % | +0,82 % | 112 | 159 | +9,8 % |
| 12 | 108 | 613 | Krit-Chance 23 % → 24 % | +0,81 % | 133 | 187 | +10,7 % |
| 13 | 128 | 741 | Krit-Chance 24 % → 25 % | +0,81 % | 159 | 222 | +11,6 % |
| 14 | 150 | 891 | Krit-Chance 25 % → 26 % | +0,80 % | 187 | 260 | +12,5 % |
| 15 | 178 | 1.069 | Krit-Chance 26 % → 27 % | +0,79 % | 224 | 308 | +13,4 % |
| 16 | 210 | 1.279 | Krit-Chance 27 % → 28 % | +0,79 % | 267 | 363 | +14,3 % |
| 17 | 247 | 1.526 | Krit-Chance 28 % → 29 % | +0,78 % | 316 | 428 | +15,2 % |
| 18 | 292 | 1.818 | Krit-Chance 29 % → 30 % | +0,78 % | 377 | 505 | +16,1 % |
| 19 | 344 | 2.162 | Krit-Chance 30 % → 31 % | +0,77 % | 447 | 595 | +17,0 % |
| 20 | 406 | 2.568 | Krit-Chance 31 % → 32 % | +0,76 % | 532 | 703 | +17,9 % |

#### Blitzturm – Effizienz

**Verändert:** Senkt die Energie je Schuss (Energie ÷ Effizienz). Verschiebt die Überladungsgrenze nach oben. **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je (Schaden/Energie) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 14 | 14 | Energie/Schuss 4,00 → 3,81 | +5,00 % | 2,80 | 38,5 | +5,0 % |
| 2 | 17 | 31 | Energie/Schuss 3,81 → 3,64 | +4,76 % | 3,57 | 46,7 | +10,0 % |
| 3 | 19 | 50 | Energie/Schuss 3,64 → 3,48 | +4,55 % | 4,18 | 52,2 | +15,0 % |
| 4 | 23 | 73 | Energie/Schuss 3,48 → 3,33 | +4,35 % | 5,29 | 63,2 | +20,0 % |
| 5 | 27 | 100 | Energie/Schuss 3,33 → 3,20 | +4,17 % | 6,48 | 74,2 | +25,0 % |
| 6 | 32 | 132 | Energie/Schuss 3,20 → 3,08 | +4,00 % | 8,00 | 87,9 | +30,0 % |
| 7 | 38 | 170 | Energie/Schuss 3,08 → 2,96 | +3,85 % | 9,88 | 104 | +35,0 % |
| 8 | 45 | 215 | Energie/Schuss 2,96 → 2,86 | +3,70 % | 12,2 | 124 | +40,0 % |
| 9 | 53 | 268 | Energie/Schuss 2,86 → 2,76 | +3,57 % | 14,8 | 146 | +45,0 % |
| 10 | 62 | 330 | Energie/Schuss 2,76 → 2,67 | +3,45 % | 18,0 | 170 | +50,0 % |
| 11 | 73 | 403 | Energie/Schuss 2,67 → 2,58 | +3,33 % | 21,9 | 201 | +55,0 % |
| 12 | 86 | 489 | Energie/Schuss 2,58 → 2,50 | +3,23 % | 26,7 | 236 | +60,0 % |
| 13 | 102 | 591 | Energie/Schuss 2,50 → 2,42 | +3,12 % | 32,6 | 280 | +65,0 % |
| 14 | 120 | 711 | Energie/Schuss 2,42 → 2,35 | +3,03 % | 39,6 | 330 | +70,0 % |
| 15 | 142 | 853 | Energie/Schuss 2,35 → 2,29 | +2,94 % | 48,3 | 390 | +75,0 % |
| 16 | 168 | 1.021 | Energie/Schuss 2,29 → 2,22 | +2,86 % | 58,8 | 462 | +80,0 % |
| 17 | 198 | 1.219 | Energie/Schuss 2,22 → 2,16 | +2,78 % | 71,3 | 544 | +85,0 % |
| 18 | 233 | 1.452 | Energie/Schuss 2,16 → 2,11 | +2,70 % | 86,2 | 640 | +90,0 % |
| 19 | 275 | 1.727 | Energie/Schuss 2,11 → 2,05 | +2,63 % | 104 | 755 | +95,0 % |
| 20 | 325 | 2.052 | Energie/Schuss 2,05 → 2,00 | +2,56 % | 127 | 893 | +100,0 % |

#### Blitzturm – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). Hebt die Grenze, ab der eine Überladung den Turm stilllegt. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,75 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 13 | 13 | 40,0 → 48,0 Energie | +20,00 % | 0,65 | 1,62 | +20,0 % |
| 2 | 15 | 28 | 48,0 → 56,0 Energie | +16,67 % | 0,90 | 1,88 | +40,0 % |
| 3 | 18 | 46 | 56,0 → 64,0 Energie | +14,29 % | 1,26 | 2,25 | +60,0 % |
| 4 | 21 | 67 | 64,0 → 72,0 Energie | +12,50 % | 1,68 | 2,62 | +80,0 % |
| 5 | 24 | 91 | 72,0 → 80,0 Energie | +11,11 % | 2,16 | 3,00 | +100,0 % |
| 6 | 29 | 120 | 80,0 → 88,0 Energie | +10,00 % | 2,90 | 3,62 | +120,0 % |
| 7 | 34 | 154 | 88,0 → 96,0 Energie | +9,09 % | 3,74 | 4,25 | +140,0 % |
| 8 | 40 | 194 | 96,0 → 104,0 Energie | +8,33 % | 4,80 | 5,00 | +160,0 % |
| 9 | 47 | 241 | 104,0 → 112,0 Energie | +7,69 % | 6,11 | 5,88 | +180,0 % |
| 10 | 56 | 297 | 112,0 → 120,0 Energie | +7,14 % | 7,84 | 7,00 | +200,0 % |
| 11 | 66 | 363 | 120,0 → 128,0 Energie | +6,67 % | 9,90 | 8,25 | +220,0 % |
| 12 | 78 | 441 | 128,0 → 136,0 Energie | +6,25 % | 12,5 | 9,75 | +240,0 % |
| 13 | 92 | 533 | 136,0 → 144,0 Energie | +5,88 % | 15,6 | 11,5 | +260,0 % |
| 14 | 108 | 641 | 144,0 → 152,0 Energie | +5,56 % | 19,4 | 13,5 | +280,0 % |
| 15 | 128 | 769 | 152,0 → 160,0 Energie | +5,26 % | 24,3 | 16,0 | +300,0 % |
| 16 | 151 | 920 | 160,0 → 168,0 Energie | +5,00 % | 30,2 | 18,9 | +320,0 % |
| 17 | 178 | 1.098 | 168,0 → 176,0 Energie | +4,76 % | 37,4 | 22,2 | +340,0 % |
| 18 | 210 | 1.308 | 176,0 → 184,0 Energie | +4,55 % | 46,2 | 26,2 | +360,0 % |
| 19 | 248 | 1.556 | 184,0 → 192,0 Energie | +4,35 % | 57,0 | 31,0 | +380,0 % |
| 20 | 293 | 1.849 | 192,0 → 200,0 Energie | +4,17 % | 70,3 | 36,6 | +400,0 % |
| 21 | 345 | 2.194 | 200,0 → 208,0 Energie | +4,00 % | 86,2 | 43,1 | +420,0 % |
| 22 | 407 | 2.601 | 208,0 → 216,0 Energie | +3,85 % | 106 | 50,9 | +440,0 % |
| 23 | 481 | 3.082 | 216,0 → 224,0 Energie | +3,70 % | 130 | 60,1 | +460,0 % |
| 24 | 567 | 3.649 | 224,0 → 232,0 Energie | +3,57 % | 159 | 70,9 | +480,0 % |
| 25 | 669 | 4.318 | 232,0 → 240,0 Energie | +3,45 % | 194 | 83,6 | +500,0 % |

#### Blitzturm – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 14 | 14 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 12,6 | +1,1 % |
| 2 | 17 | 31 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 15,5 | +2,2 % |
| 3 | 19 | 50 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 17,5 | +3,3 % |
| 4 | 23 | 73 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 21,4 | +4,4 % |
| 5 | 27 | 100 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 25,4 | +5,6 % |
| 6 | 32 | 132 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 30,4 | +6,7 % |
| 7 | 38 | 170 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 36,5 | +7,8 % |
| 8 | 45 | 215 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 43,7 | +8,9 % |
| 9 | 53 | 268 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 51,9 | +10,0 % |
| 10 | 62 | 330 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 61,4 | +11,1 % |

#### Blitzturm – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,778 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 13 | 13 | 90,0 → 103,5 HP | +15,00 % | 0,87 | 0,963 | +15,0 % |
| 2 | 15 | 28 | 103,5 → 117,0 HP | +13,04 % | 1,15 | 1,111 | +30,0 % |
| 3 | 18 | 46 | 117,0 → 130,5 HP | +11,54 % | 1,56 | 1,333 | +45,0 % |
| 4 | 21 | 67 | 130,5 → 144,0 HP | +10,34 % | 2,03 | 1,556 | +60,0 % |
| 5 | 24 | 91 | 144,0 → 157,5 HP | +9,38 % | 2,56 | 1,778 | +75,0 % |
| 6 | 29 | 120 | 157,5 → 171,0 HP | +8,57 % | 3,38 | 2,148 | +90,0 % |
| 7 | 34 | 154 | 171,0 → 184,5 HP | +7,89 % | 4,31 | 2,519 | +105,0 % |
| 8 | 40 | 194 | 184,5 → 198,0 HP | +7,32 % | 5,47 | 2,963 | +120,0 % |
| 9 | 47 | 241 | 198,0 → 211,5 HP | +6,82 % | 6,89 | 3,481 | +135,0 % |
| 10 | 56 | 297 | 211,5 → 225,0 HP | +6,38 % | 8,77 | 4,148 | +150,0 % |
| 11 | 66 | 363 | 225,0 → 238,5 HP | +6,00 % | 11,0 | 4,889 | +165,0 % |
| 12 | 78 | 441 | 238,5 → 252,0 HP | +5,66 % | 13,8 | 5,778 | +180,0 % |
| 13 | 92 | 533 | 252,0 → 265,5 HP | +5,36 % | 17,2 | 6,815 | +195,0 % |
| 14 | 108 | 641 | 265,5 → 279,0 HP | +5,08 % | 21,2 | 8,000 | +210,0 % |
| 15 | 128 | 769 | 279,0 → 292,5 HP | +4,84 % | 26,5 | 9,481 | +225,0 % |
| 16 | 151 | 920 | 292,5 → 306,0 HP | +4,62 % | 32,7 | 11,185 | +240,0 % |
| 17 | 178 | 1.098 | 306,0 → 319,5 HP | +4,41 % | 40,3 | 13,185 | +255,0 % |
| 18 | 210 | 1.308 | 319,5 → 333,0 HP | +4,23 % | 49,7 | 15,556 | +270,0 % |
| 19 | 248 | 1.556 | 333,0 → 346,5 HP | +4,05 % | 61,2 | 18,370 | +285,0 % |
| 20 | 293 | 1.849 | 346,5 → 360,0 HP | +3,90 % | 75,2 | 21,704 | +300,0 % |
| 21 | 345 | 2.194 | 360,0 → 373,5 HP | +3,75 % | 92,0 | 25,556 | +315,0 % |
| 22 | 407 | 2.601 | 373,5 → 387,0 HP | +3,61 % | 113 | 30,148 | +330,0 % |
| 23 | 481 | 3.082 | 387,0 → 400,5 HP | +3,49 % | 138 | 35,630 | +345,0 % |
| 24 | 567 | 3.649 | 400,5 → 414,0 HP | +3,37 % | 168 | 42,000 | +360,0 % |
| 25 | 669 | 4.318 | 414,0 → 427,5 HP | +3,26 % | 205 | 49,556 | +375,0 % |
| 26 | 790 | 5.108 | 427,5 → 441,0 HP | +3,16 % | 250 | 58,519 | +390,0 % |
| 27 | 932 | 6.040 | 441,0 → 454,5 HP | +3,06 % | 304 | 69,037 | +405,0 % |
| 28 | 1.099 | 7.139 | 454,5 → 468,0 HP | +2,97 % | 370 | 81,407 | +420,0 % |
| 29 | 1.297 | 8.436 | 468,0 → 481,5 HP | +2,88 % | 450 | 96,074 | +435,0 % |
| 30 | 1.531 | 9.967 | 481,5 → 495,0 HP | +2,80 % | 546 | 113,407 | +450,0 % |

#### Blitzturm – Panzerung

**Verändert:** Panzerung. Jeder erlittene Treffer sinkt um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Nutzen gemessen an den effektiven Lebenspunkten (Leben ÷ (1 − Reduktion)) mit Grund-Leben, ohne Mindestschaden. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,73 Münzen je eff. HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eff. HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 11 | 11 | Panzerung 6,0 → 6,9 (−5,7 % → −6,5 %) | +0,85 % | 13,0 | 13,6 | +0,8 % |
| 2 | 12 | 23 | Panzerung 6,9 → 7,8 (−6,5 % → −7,2 %) | +0,84 % | 14,3 | 14,8 | +1,7 % |
| 3 | 15 | 38 | Panzerung 7,8 → 8,7 (−7,2 % → −8,0 %) | +0,83 % | 18,0 | 18,5 | +2,5 % |
| 4 | 17 | 55 | Panzerung 8,7 → 9,6 (−8,0 % → −8,8 %) | +0,83 % | 20,5 | 21,0 | +3,4 % |
| 5 | 20 | 75 | Panzerung 9,6 → 10,5 (−8,8 % → −9,5 %) | +0,82 % | 24,4 | 24,7 | +4,2 % |
| 6 | 24 | 99 | Panzerung 10,5 → 11,4 (−9,5 % → −10,2 %) | +0,81 % | 29,5 | 29,6 | +5,1 % |
| 7 | 28 | 127 | Panzerung 11,4 → 12,3 (−10,2 % → −11,0 %) | +0,81 % | 34,7 | 34,6 | +5,9 % |
| 8 | 33 | 160 | Panzerung 12,3 → 13,2 (−11,0 % → −11,7 %) | +0,80 % | 41,2 | 40,7 | +6,8 % |
| 9 | 39 | 199 | Panzerung 13,2 → 14,1 (−11,7 % → −12,4 %) | +0,80 % | 49,1 | 48,1 | +7,6 % |
| 10 | 47 | 246 | Panzerung 14,1 → 15,0 (−12,4 % → −13,0 %) | +0,79 % | 59,6 | 58,0 | +8,5 % |
| 11 | 55 | 301 | Panzerung 15,0 → 15,9 (−13,0 % → −13,7 %) | +0,78 % | 70,3 | 67,9 | +9,3 % |
| 12 | 65 | 366 | Panzerung 15,9 → 16,8 (−13,7 % → −14,4 %) | +0,78 % | 83,7 | 80,2 | +10,2 % |
| 13 | 77 | 443 | Panzerung 16,8 → 17,7 (−14,4 % → −15,0 %) | +0,77 % | 99,9 | 95,1 | +11,0 % |
| 14 | 90 | 533 | Panzerung 17,7 → 18,6 (−15,0 % → −15,7 %) | +0,76 % | 118 | 111 | +11,9 % |
| 15 | 107 | 640 | Panzerung 18,6 → 19,5 (−15,7 % → −16,3 %) | +0,76 % | 141 | 132 | +12,7 % |
| 16 | 126 | 766 | Panzerung 19,5 → 20,4 (−16,3 % → −16,9 %) | +0,75 % | 167 | 156 | +13,6 % |
| 17 | 148 | 914 | Panzerung 20,4 → 21,3 (−16,9 % → −17,6 %) | +0,75 % | 198 | 183 | +14,4 % |
| 18 | 175 | 1.089 | Panzerung 21,3 → 22,2 (−17,6 % → −18,2 %) | +0,74 % | 236 | 216 | +15,3 % |
| 19 | 207 | 1.296 | Panzerung 22,2 → 23,1 (−18,2 % → −18,8 %) | +0,74 % | 281 | 256 | +16,1 % |
| 20 | 244 | 1.540 | Panzerung 23,1 → 24,0 (−18,8 % → −19,4 %) | +0,73 % | 334 | 301 | +17,0 % |

### Laserturm

- **Freischaltung:** Forschung „Laserturm“ (2 SP)
- **Baukosten:** 120 · **Upgrade-Basis:** 120
- **Grundwerte:** 110 HP · Panzerung 8 · Kapazität 60 · Laser 30 Schaden/s, 10 Energie/s, Reichweite 4,82 Felder · DPS 30,0

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Schaden | 40 | 26 | 16.788 | 109.904 | +400 % | 2,60 → 8.226 |
| Reichweite | 15 | 36 | 365 | 2.193 | +60 % | 9,00 → 142 |
| Effizienz | 20 | 24 | 557 | 3.517 | +100 % | 4,80 → 217 |
| Kapazität | 25 | 22 | 1.147 | 7.398 | +500 % | 1,10 → 333 |
| Strahlübertragung | 10 | 24 | 106 | 563 | +11 % | 21,6 → 105 |
| Leben | 30 | 22 | 2.624 | 17.082 | +450 % | 1,47 → 936 |
| Panzerung | 20 | 18 | 418 | 2.640 | +22 % | 16,2 → 456 |

#### Laserturm – Schaden

**Verändert:** Schaden je Schuss (Laser: je Sekunde). **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 4,00 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 26 | 26 | Schaden/s 30,0 → 33,0 | +10,00 % | 2,60 | 8,67 | +10,0 % |
| 2 | 31 | 57 | Schaden/s 33,0 → 36,0 | +9,09 % | 3,41 | 10,3 | +20,0 % |
| 3 | 37 | 94 | Schaden/s 36,0 → 39,0 | +8,33 % | 4,44 | 12,3 | +30,0 % |
| 4 | 43 | 137 | Schaden/s 39,0 → 42,0 | +7,69 % | 5,59 | 14,3 | +40,0 % |
| 5 | 51 | 188 | Schaden/s 42,0 → 45,0 | +7,14 % | 7,14 | 17,0 | +50,0 % |
| 6 | 60 | 248 | Schaden/s 45,0 → 48,0 | +6,67 % | 9,00 | 20,0 | +60,0 % |
| 7 | 71 | 319 | Schaden/s 48,0 → 51,0 | +6,25 % | 11,4 | 23,7 | +70,0 % |
| 8 | 84 | 403 | Schaden/s 51,0 → 54,0 | +5,88 % | 14,3 | 28,0 | +80,0 % |
| 9 | 99 | 502 | Schaden/s 54,0 → 57,0 | +5,56 % | 17,8 | 33,0 | +90,0 % |
| 10 | 117 | 619 | Schaden/s 57,0 → 60,0 | +5,26 % | 22,2 | 39,0 | +100,0 % |
| 11 | 138 | 757 | Schaden/s 60,0 → 63,0 | +5,00 % | 27,6 | 46,0 | +110,0 % |
| 12 | 163 | 920 | Schaden/s 63,0 → 66,0 | +4,76 % | 34,2 | 54,3 | +120,0 % |
| 13 | 192 | 1.112 | Schaden/s 66,0 → 69,0 | +4,55 % | 42,2 | 64,0 | +130,0 % |
| 14 | 227 | 1.339 | Schaden/s 69,0 → 72,0 | +4,35 % | 52,2 | 75,7 | +140,0 % |
| 15 | 268 | 1.607 | Schaden/s 72,0 → 75,0 | +4,17 % | 64,3 | 89,3 | +150,0 % |
| 16 | 316 | 1.923 | Schaden/s 75,0 → 78,0 | +4,00 % | 79,0 | 105 | +160,0 % |
| 17 | 373 | 2.296 | Schaden/s 78,0 → 81,0 | +3,85 % | 97,0 | 124 | +170,0 % |
| 18 | 440 | 2.736 | Schaden/s 81,0 → 84,0 | +3,70 % | 119 | 147 | +180,0 % |
| 19 | 519 | 3.255 | Schaden/s 84,0 → 87,0 | +3,57 % | 145 | 173 | +190,0 % |
| 20 | 613 | 3.868 | Schaden/s 87,0 → 90,0 | +3,45 % | 178 | 204 | +200,0 % |
| 21 | 723 | 4.591 | Schaden/s 90,0 → 93,0 | +3,33 % | 217 | 241 | +210,0 % |
| 22 | 853 | 5.444 | Schaden/s 93,0 → 96,0 | +3,23 % | 264 | 284 | +220,0 % |
| 23 | 1.007 | 6.451 | Schaden/s 96,0 → 99,0 | +3,13 % | 322 | 336 | +230,0 % |
| 24 | 1.188 | 7.639 | Schaden/s 99,0 → 102,0 | +3,03 % | 392 | 396 | +240,0 % |
| 25 | 1.402 | 9.041 | Schaden/s 102,0 → 105,0 | +2,94 % | 477 | 467 | +250,0 % |
| 26 | 1.654 | 10.695 | Schaden/s 105,0 → 108,0 | +2,86 % | 579 | 551 | +260,0 % |
| 27 | 1.952 | 12.647 | Schaden/s 108,0 → 111,0 | +2,78 % | 703 | 651 | +270,0 % |
| 28 | 2.304 | 14.951 | Schaden/s 111,0 → 114,0 | +2,70 % | 852 | 768 | +280,0 % |
| 29 | 2.718 | 17.669 | Schaden/s 114,0 → 117,0 | +2,63 % | 1.033 | 906 | +290,0 % |
| 30 | 3.208 | 20.877 | Schaden/s 117,0 → 120,0 | +2,56 % | 1.251 | 1.069 | +300,0 % |
| 31 | 3.785 | 24.662 | Schaden/s 120,0 → 123,0 | +2,50 % | 1.514 | 1.262 | +310,0 % |
| 32 | 4.466 | 29.128 | Schaden/s 123,0 → 126,0 | +2,44 % | 1.831 | 1.489 | +320,0 % |
| 33 | 5.270 | 34.398 | Schaden/s 126,0 → 129,0 | +2,38 % | 2.213 | 1.757 | +330,0 % |
| 34 | 6.219 | 40.617 | Schaden/s 129,0 → 132,0 | +2,33 % | 2.674 | 2.073 | +340,0 % |
| 35 | 7.338 | 47.955 | Schaden/s 132,0 → 135,0 | +2,27 % | 3.229 | 2.446 | +350,0 % |
| 36 | 8.659 | 56.614 | Schaden/s 135,0 → 138,0 | +2,22 % | 3.897 | 2.886 | +360,0 % |
| 37 | 10.218 | 66.832 | Schaden/s 138,0 → 141,0 | +2,17 % | 4.700 | 3.406 | +370,0 % |
| 38 | 12.057 | 78.889 | Schaden/s 141,0 → 144,0 | +2,13 % | 5.667 | 4.019 | +380,0 % |
| 39 | 14.227 | 93.116 | Schaden/s 144,0 → 147,0 | +2,08 % | 6.829 | 4.742 | +390,0 % |
| 40 | 16.788 | 109.904 | Schaden/s 147,0 → 150,0 | +2,04 % | 8.226 | 5.596 | +400,0 % |

#### Laserturm – Reichweite

**Verändert:** Angriffsreichweite (und damit Sichtweite). Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 36 | 36 | 4,82 → 5,01 Felder | +4,00 % | 9,00 | 187 | +4,0 % |
| 2 | 42 | 78 | 5,01 → 5,21 Felder | +3,85 % | 10,9 | 218 | +8,0 % |
| 3 | 50 | 128 | 5,21 → 5,40 Felder | +3,70 % | 13,5 | 259 | +12,0 % |
| 4 | 59 | 187 | 5,40 → 5,59 Felder | +3,57 % | 16,5 | 306 | +16,0 % |
| 5 | 70 | 257 | 5,59 → 5,79 Felder | +3,45 % | 20,3 | 363 | +20,0 % |
| 6 | 82 | 339 | 5,79 → 5,98 Felder | +3,33 % | 24,6 | 425 | +24,0 % |
| 7 | 97 | 436 | 5,98 → 6,17 Felder | +3,23 % | 30,1 | 503 | +28,0 % |
| 8 | 115 | 551 | 6,17 → 6,36 Felder | +3,12 % | 36,8 | 596 | +32,0 % |
| 9 | 135 | 686 | 6,36 → 6,56 Felder | +3,03 % | 44,6 | 700 | +36,0 % |
| 10 | 160 | 846 | 6,56 → 6,75 Felder | +2,94 % | 54,4 | 830 | +40,0 % |
| 11 | 188 | 1.034 | 6,75 → 6,94 Felder | +2,86 % | 65,8 | 975 | +44,0 % |
| 12 | 222 | 1.256 | 6,94 → 7,14 Felder | +2,78 % | 79,9 | 1.151 | +48,0 % |
| 13 | 262 | 1.518 | 7,14 → 7,33 Felder | +2,70 % | 96,9 | 1.359 | +52,0 % |
| 14 | 310 | 1.828 | 7,33 → 7,52 Felder | +2,63 % | 118 | 1.607 | +56,0 % |
| 15 | 365 | 2.193 | 7,52 → 7,71 Felder | +2,56 % | 142 | 1.893 | +60,0 % |

#### Laserturm – Effizienz

**Verändert:** Senkt die Energie je Schuss (Energie ÷ Effizienz). **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je (Schaden/Energie) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 24 | 24 | Energie/s 10,00 → 9,52 | +5,00 % | 4,80 | 160 | +5,0 % |
| 2 | 28 | 52 | Energie/s 9,52 → 9,09 | +4,76 % | 5,88 | 187 | +10,0 % |
| 3 | 33 | 85 | Energie/s 9,09 → 8,70 | +4,55 % | 7,26 | 220 | +15,0 % |
| 4 | 39 | 124 | Energie/s 8,70 → 8,33 | +4,35 % | 8,97 | 260 | +20,0 % |
| 5 | 47 | 171 | Energie/s 8,33 → 8,00 | +4,17 % | 11,3 | 313 | +25,0 % |
| 6 | 55 | 226 | Energie/s 8,00 → 7,69 | +4,00 % | 13,7 | 367 | +30,0 % |
| 7 | 65 | 291 | Energie/s 7,69 → 7,41 | +3,85 % | 16,9 | 433 | +35,0 % |
| 8 | 76 | 367 | Energie/s 7,41 → 7,14 | +3,70 % | 20,5 | 507 | +40,0 % |
| 9 | 90 | 457 | Energie/s 7,14 → 6,90 | +3,57 % | 25,2 | 600 | +45,0 % |
| 10 | 106 | 563 | Energie/s 6,90 → 6,67 | +3,45 % | 30,7 | 707 | +50,0 % |
| 11 | 126 | 689 | Energie/s 6,67 → 6,45 | +3,33 % | 37,8 | 840 | +55,0 % |
| 12 | 148 | 837 | Energie/s 6,45 → 6,25 | +3,23 % | 45,9 | 987 | +60,0 % |
| 13 | 175 | 1.012 | Energie/s 6,25 → 6,06 | +3,12 % | 56,0 | 1.167 | +65,0 % |
| 14 | 206 | 1.218 | Energie/s 6,06 → 5,88 | +3,03 % | 68,0 | 1.373 | +70,0 % |
| 15 | 244 | 1.462 | Energie/s 5,88 → 5,71 | +2,94 % | 83,0 | 1.627 | +75,0 % |
| 16 | 287 | 1.749 | Energie/s 5,71 → 5,56 | +2,86 % | 100 | 1.913 | +80,0 % |
| 17 | 339 | 2.088 | Energie/s 5,56 → 5,41 | +2,78 % | 122 | 2.260 | +85,0 % |
| 18 | 400 | 2.488 | Energie/s 5,41 → 5,26 | +2,70 % | 148 | 2.667 | +90,0 % |
| 19 | 472 | 2.960 | Energie/s 5,26 → 5,13 | +2,63 % | 179 | 3.147 | +95,0 % |
| 20 | 557 | 3.517 | Energie/s 5,13 → 5,00 | +2,56 % | 217 | 3.713 | +100,0 % |

#### Laserturm – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). Hebt die Grenze, ab der eine Überladung den Turm stilllegt. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 2,00 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 22 | 22 | 60,0 → 72,0 Energie | +20,00 % | 1,10 | 1,83 | +20,0 % |
| 2 | 25 | 47 | 72,0 → 84,0 Energie | +16,67 % | 1,50 | 2,08 | +40,0 % |
| 3 | 30 | 77 | 84,0 → 96,0 Energie | +14,29 % | 2,10 | 2,50 | +60,0 % |
| 4 | 35 | 112 | 96,0 → 108,0 Energie | +12,50 % | 2,80 | 2,92 | +80,0 % |
| 5 | 42 | 154 | 108,0 → 120,0 Energie | +11,11 % | 3,78 | 3,50 | +100,0 % |
| 6 | 49 | 203 | 120,0 → 132,0 Energie | +10,00 % | 4,90 | 4,08 | +120,0 % |
| 7 | 58 | 261 | 132,0 → 144,0 Energie | +9,09 % | 6,38 | 4,83 | +140,0 % |
| 8 | 69 | 330 | 144,0 → 156,0 Energie | +8,33 % | 8,28 | 5,75 | +160,0 % |
| 9 | 81 | 411 | 156,0 → 168,0 Energie | +7,69 % | 10,5 | 6,75 | +180,0 % |
| 10 | 96 | 507 | 168,0 → 180,0 Energie | +7,14 % | 13,4 | 8,00 | +200,0 % |
| 11 | 113 | 620 | 180,0 → 192,0 Energie | +6,67 % | 17,0 | 9,42 | +220,0 % |
| 12 | 133 | 753 | 192,0 → 204,0 Energie | +6,25 % | 21,3 | 11,1 | +240,0 % |
| 13 | 157 | 910 | 204,0 → 216,0 Energie | +5,88 % | 26,7 | 13,1 | +260,0 % |
| 14 | 186 | 1.096 | 216,0 → 228,0 Energie | +5,56 % | 33,5 | 15,5 | +280,0 % |
| 15 | 219 | 1.315 | 228,0 → 240,0 Energie | +5,26 % | 41,6 | 18,3 | +300,0 % |
| 16 | 259 | 1.574 | 240,0 → 252,0 Energie | +5,00 % | 51,8 | 21,6 | +320,0 % |
| 17 | 305 | 1.879 | 252,0 → 264,0 Energie | +4,76 % | 64,0 | 25,4 | +340,0 % |
| 18 | 360 | 2.239 | 264,0 → 276,0 Energie | +4,55 % | 79,2 | 30,0 | +360,0 % |
| 19 | 425 | 2.664 | 276,0 → 288,0 Energie | +4,35 % | 97,7 | 35,4 | +380,0 % |
| 20 | 501 | 3.165 | 288,0 → 300,0 Energie | +4,17 % | 120 | 41,8 | +400,0 % |
| 21 | 592 | 3.757 | 300,0 → 312,0 Energie | +4,00 % | 148 | 49,3 | +420,0 % |
| 22 | 698 | 4.455 | 312,0 → 324,0 Energie | +3,85 % | 181 | 58,2 | +440,0 % |
| 23 | 824 | 5.279 | 324,0 → 336,0 Energie | +3,70 % | 222 | 68,7 | +460,0 % |
| 24 | 972 | 6.251 | 336,0 → 348,0 Energie | +3,57 % | 272 | 81,0 | +480,0 % |
| 25 | 1.147 | 7.398 | 348,0 → 360,0 Energie | +3,45 % | 333 | 95,6 | +500,0 % |

#### Laserturm – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 24 | 24 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 21,6 | +1,1 % |
| 2 | 28 | 52 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 25,5 | +2,2 % |
| 3 | 33 | 85 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 30,4 | +3,3 % |
| 4 | 39 | 124 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 36,3 | +4,4 % |
| 5 | 47 | 171 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 44,2 | +5,6 % |
| 6 | 55 | 226 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 52,2 | +6,7 % |
| 7 | 65 | 291 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 62,4 | +7,8 % |
| 8 | 76 | 367 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 73,7 | +8,9 % |
| 9 | 90 | 457 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 88,2 | +10,0 % |
| 10 | 106 | 563 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 105 | +11,1 % |

#### Laserturm – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,091 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 22 | 22 | 110,0 → 126,5 HP | +15,00 % | 1,47 | 1,333 | +15,0 % |
| 2 | 25 | 47 | 126,5 → 143,0 HP | +13,04 % | 1,92 | 1,515 | +30,0 % |
| 3 | 30 | 77 | 143,0 → 159,5 HP | +11,54 % | 2,60 | 1,818 | +45,0 % |
| 4 | 35 | 112 | 159,5 → 176,0 HP | +10,34 % | 3,38 | 2,121 | +60,0 % |
| 5 | 42 | 154 | 176,0 → 192,5 HP | +9,38 % | 4,48 | 2,545 | +75,0 % |
| 6 | 49 | 203 | 192,5 → 209,0 HP | +8,57 % | 5,72 | 2,970 | +90,0 % |
| 7 | 58 | 261 | 209,0 → 225,5 HP | +7,89 % | 7,35 | 3,515 | +105,0 % |
| 8 | 69 | 330 | 225,5 → 242,0 HP | +7,32 % | 9,43 | 4,182 | +120,0 % |
| 9 | 81 | 411 | 242,0 → 258,5 HP | +6,82 % | 11,9 | 4,909 | +135,0 % |
| 10 | 96 | 507 | 258,5 → 275,0 HP | +6,38 % | 15,0 | 5,818 | +150,0 % |
| 11 | 113 | 620 | 275,0 → 291,5 HP | +6,00 % | 18,8 | 6,848 | +165,0 % |
| 12 | 133 | 753 | 291,5 → 308,0 HP | +5,66 % | 23,5 | 8,061 | +180,0 % |
| 13 | 157 | 910 | 308,0 → 324,5 HP | +5,36 % | 29,3 | 9,515 | +195,0 % |
| 14 | 186 | 1.096 | 324,5 → 341,0 HP | +5,08 % | 36,6 | 11,273 | +210,0 % |
| 15 | 219 | 1.315 | 341,0 → 357,5 HP | +4,84 % | 45,3 | 13,273 | +225,0 % |
| 16 | 259 | 1.574 | 357,5 → 374,0 HP | +4,62 % | 56,1 | 15,697 | +240,0 % |
| 17 | 305 | 1.879 | 374,0 → 390,5 HP | +4,41 % | 69,1 | 18,485 | +255,0 % |
| 18 | 360 | 2.239 | 390,5 → 407,0 HP | +4,23 % | 85,2 | 21,818 | +270,0 % |
| 19 | 425 | 2.664 | 407,0 → 423,5 HP | +4,05 % | 105 | 25,758 | +285,0 % |
| 20 | 501 | 3.165 | 423,5 → 440,0 HP | +3,90 % | 129 | 30,364 | +300,0 % |
| 21 | 592 | 3.757 | 440,0 → 456,5 HP | +3,75 % | 158 | 35,879 | +315,0 % |
| 22 | 698 | 4.455 | 456,5 → 473,0 HP | +3,61 % | 193 | 42,303 | +330,0 % |
| 23 | 824 | 5.279 | 473,0 → 489,5 HP | +3,49 % | 236 | 49,939 | +345,0 % |
| 24 | 972 | 6.251 | 489,5 → 506,0 HP | +3,37 % | 288 | 58,909 | +360,0 % |
| 25 | 1.147 | 7.398 | 506,0 → 522,5 HP | +3,26 % | 352 | 69,515 | +375,0 % |
| 26 | 1.354 | 8.752 | 522,5 → 539,0 HP | +3,16 % | 429 | 82,061 | +390,0 % |
| 27 | 1.597 | 10.349 | 539,0 → 555,5 HP | +3,06 % | 522 | 96,788 | +405,0 % |
| 28 | 1.885 | 12.234 | 555,5 → 572,0 HP | +2,97 % | 635 | 114,242 | +420,0 % |
| 29 | 2.224 | 14.458 | 572,0 → 588,5 HP | +2,88 % | 771 | 134,788 | +435,0 % |
| 30 | 2.624 | 17.082 | 588,5 → 605,0 HP | +2,80 % | 936 | 159,030 | +450,0 % |

#### Laserturm – Panzerung

**Verändert:** Panzerung. Jeder erlittene Treffer sinkt um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Nutzen gemessen an den effektiven Lebenspunkten (Leben ÷ (1 − Reduktion)) mit Grund-Leben, ohne Mindestschaden. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,01 Münzen je eff. HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eff. HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 18 | 18 | Panzerung 8,0 → 9,2 (−7,4 % → −8,4 %) | +1,11 % | 16,2 | 13,6 | +1,1 % |
| 2 | 21 | 39 | Panzerung 9,2 → 10,4 (−8,4 % → −9,4 %) | +1,10 % | 19,1 | 15,9 | +2,2 % |
| 3 | 25 | 64 | Panzerung 10,4 → 11,6 (−9,4 % → −10,4 %) | +1,09 % | 23,0 | 18,9 | +3,3 % |
| 4 | 30 | 94 | Panzerung 11,6 → 12,8 (−10,4 % → −11,3 %) | +1,08 % | 27,9 | 22,7 | +4,4 % |
| 5 | 35 | 129 | Panzerung 12,8 → 14,0 (−11,3 % → −12,3 %) | +1,06 % | 32,9 | 26,5 | +5,6 % |
| 6 | 41 | 170 | Panzerung 14,0 → 15,2 (−12,3 % → −13,2 %) | +1,05 % | 38,9 | 31,1 | +6,7 % |
| 7 | 49 | 219 | Panzerung 15,2 → 16,4 (−13,2 % → −14,1 %) | +1,04 % | 47,0 | 37,1 | +7,8 % |
| 8 | 57 | 276 | Panzerung 16,4 → 17,6 (−14,1 % → −15,0 %) | +1,03 % | 55,3 | 43,2 | +8,9 % |
| 9 | 68 | 344 | Panzerung 17,6 → 18,8 (−15,0 % → −15,8 %) | +1,02 % | 66,6 | 51,5 | +10,0 % |
| 10 | 80 | 424 | Panzerung 18,8 → 20,0 (−15,8 % → −16,7 %) | +1,01 % | 79,2 | 60,6 | +11,1 % |
| 11 | 94 | 518 | Panzerung 20,0 → 21,2 (−16,7 % → −17,5 %) | +1,00 % | 94,0 | 71,2 | +12,2 % |
| 12 | 111 | 629 | Panzerung 21,2 → 22,4 (−17,5 % → −18,3 %) | +0,99 % | 112 | 84,1 | +13,3 % |
| 13 | 131 | 760 | Panzerung 22,4 → 23,6 (−18,3 % → −19,1 %) | +0,98 % | 134 | 99,2 | +14,4 % |
| 14 | 155 | 915 | Panzerung 23,6 → 24,8 (−19,1 % → −19,9 %) | +0,97 % | 160 | 117 | +15,6 % |
| 15 | 183 | 1.098 | Panzerung 24,8 → 26,0 (−19,9 % → −20,6 %) | +0,96 % | 190 | 139 | +16,7 % |
| 16 | 216 | 1.314 | Panzerung 26,0 → 27,2 (−20,6 % → −21,4 %) | +0,95 % | 227 | 164 | +17,8 % |
| 17 | 254 | 1.568 | Panzerung 27,2 → 28,4 (−21,4 % → −22,1 %) | +0,94 % | 269 | 192 | +18,9 % |
| 18 | 300 | 1.868 | Panzerung 28,4 → 29,6 (−22,1 % → −22,8 %) | +0,93 % | 321 | 227 | +20,0 % |
| 19 | 354 | 2.222 | Panzerung 29,6 → 30,8 (−22,8 % → −23,5 %) | +0,93 % | 382 | 268 | +21,1 % |
| 20 | 418 | 2.640 | Panzerung 30,8 → 32,0 (−23,5 % → −24,2 %) | +0,92 % | 456 | 317 | +22,2 % |

### Tesla-Spule

- **Freischaltung:** Forschung „Tesla-Spule“ (3 SP)
- **Baukosten:** 160 · **Upgrade-Basis:** 160
- **Grundwerte:** 120 HP · Panzerung 8 · Kapazität 80 · 30 Schaden alle 1,00 s, 14 Energie/Schuss, Reichweite 3,93 Felder, Kette 5 Ziele · DPS (volle Kette) 112,9 (Ø inkl. 12 % Krit)

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Schaden | 40 | 35 | 22.384 | 146.545 | +400 % | 3,50 → 10.968 |
| Feuerrate | 25 | 40 | 2.124 | 13.705 | +150 % | 6,67 → 864 |
| Überladung | 12 | 24 | 148 | 837 | +240 % | 1,20 → 23,7 |
| Reichweite | 15 | 48 | 487 | 2.927 | +60 % | 12,0 → 190 |
| Kettenziele | 5 | 112 | 567 | 1.477 | +33 % | 11,5 → 183 |
| Kritische Treffer | 20 | 40 | 929 | 5.866 | +18 % | 44,8 → 1.217 |
| Effizienz | 20 | 32 | 743 | 4.693 | +100 % | 6,40 → 290 |
| Kapazität | 25 | 29 | 1.530 | 9.869 | +500 % | 1,45 → 444 |
| Strahlübertragung | 10 | 32 | 142 | 753 | +11 % | 28,8 → 141 |
| Leben | 30 | 29 | 3.499 | 22.781 | +450 % | 1,93 → 1.248 |
| Panzerung | 20 | 24 | 557 | 3.517 | +22 % | 21,6 → 607 |

#### Tesla-Spule – Schaden

**Verändert:** Schaden je Schuss (Laser: je Sekunde). Die Kette schwächt sich je Sprung auf 80 % ab. **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 1,42 Münzen je DPS (volle Kette).

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS (volle Kette) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 35 | 35 | Schaden erster Treffer 30,0 → 33,0 | +10,00 % | 3,50 | 3,10 | +10,0 % |
| 2 | 42 | 77 | Schaden erster Treffer 33,0 → 36,0 | +9,09 % | 4,62 | 3,72 | +20,0 % |
| 3 | 49 | 126 | Schaden erster Treffer 36,0 → 39,0 | +8,33 % | 5,88 | 4,34 | +30,0 % |
| 4 | 58 | 184 | Schaden erster Treffer 39,0 → 42,0 | +7,69 % | 7,54 | 5,14 | +40,0 % |
| 5 | 68 | 252 | Schaden erster Treffer 42,0 → 45,0 | +7,14 % | 9,52 | 6,02 | +50,0 % |
| 6 | 81 | 333 | Schaden erster Treffer 45,0 → 48,0 | +6,67 % | 12,2 | 7,17 | +60,0 % |
| 7 | 95 | 428 | Schaden erster Treffer 48,0 → 51,0 | +6,25 % | 15,2 | 8,41 | +70,0 % |
| 8 | 112 | 540 | Schaden erster Treffer 51,0 → 54,0 | +5,88 % | 19,0 | 9,92 | +80,0 % |
| 9 | 132 | 672 | Schaden erster Treffer 54,0 → 57,0 | +5,56 % | 23,8 | 11,7 | +90,0 % |
| 10 | 156 | 828 | Schaden erster Treffer 57,0 → 60,0 | +5,26 % | 29,6 | 13,8 | +100,0 % |
| 11 | 184 | 1.012 | Schaden erster Treffer 60,0 → 63,0 | +5,00 % | 36,8 | 16,3 | +110,0 % |
| 12 | 217 | 1.229 | Schaden erster Treffer 63,0 → 66,0 | +4,76 % | 45,6 | 19,2 | +120,0 % |
| 13 | 257 | 1.486 | Schaden erster Treffer 66,0 → 69,0 | +4,55 % | 56,5 | 22,8 | +130,0 % |
| 14 | 303 | 1.789 | Schaden erster Treffer 69,0 → 72,0 | +4,35 % | 69,7 | 26,8 | +140,0 % |
| 15 | 357 | 2.146 | Schaden erster Treffer 72,0 → 75,0 | +4,17 % | 85,7 | 31,6 | +150,0 % |
| 16 | 421 | 2.567 | Schaden erster Treffer 75,0 → 78,0 | +4,00 % | 105 | 37,3 | +160,0 % |
| 17 | 497 | 3.064 | Schaden erster Treffer 78,0 → 81,0 | +3,85 % | 129 | 44,0 | +170,0 % |
| 18 | 587 | 3.651 | Schaden erster Treffer 81,0 → 84,0 | +3,70 % | 158 | 52,0 | +180,0 % |
| 19 | 692 | 4.343 | Schaden erster Treffer 84,0 → 87,0 | +3,57 % | 194 | 61,3 | +190,0 % |
| 20 | 817 | 5.160 | Schaden erster Treffer 87,0 → 90,0 | +3,45 % | 237 | 72,3 | +200,0 % |
| 21 | 964 | 6.124 | Schaden erster Treffer 90,0 → 93,0 | +3,33 % | 289 | 85,3 | +210,0 % |
| 22 | 1.138 | 7.262 | Schaden erster Treffer 93,0 → 96,0 | +3,23 % | 353 | 101 | +220,0 % |
| 23 | 1.343 | 8.605 | Schaden erster Treffer 96,0 → 99,0 | +3,13 % | 430 | 119 | +230,0 % |
| 24 | 1.584 | 10.189 | Schaden erster Treffer 99,0 → 102,0 | +3,03 % | 523 | 140 | +240,0 % |
| 25 | 1.869 | 12.058 | Schaden erster Treffer 102,0 → 105,0 | +2,94 % | 635 | 165 | +250,0 % |
| 26 | 2.206 | 14.264 | Schaden erster Treffer 105,0 → 108,0 | +2,86 % | 772 | 195 | +260,0 % |
| 27 | 2.603 | 16.867 | Schaden erster Treffer 108,0 → 111,0 | +2,78 % | 937 | 230 | +270,0 % |
| 28 | 3.072 | 19.939 | Schaden erster Treffer 111,0 → 114,0 | +2,70 % | 1.137 | 272 | +280,0 % |
| 29 | 3.624 | 23.563 | Schaden erster Treffer 114,0 → 117,0 | +2,63 % | 1.377 | 321 | +290,0 % |
| 30 | 4.277 | 27.840 | Schaden erster Treffer 117,0 → 120,0 | +2,56 % | 1.668 | 379 | +300,0 % |
| 31 | 5.047 | 32.887 | Schaden erster Treffer 120,0 → 123,0 | +2,50 % | 2.019 | 447 | +310,0 % |
| 32 | 5.955 | 38.842 | Schaden erster Treffer 123,0 → 126,0 | +2,44 % | 2.442 | 527 | +320,0 % |
| 33 | 7.027 | 45.869 | Schaden erster Treffer 126,0 → 129,0 | +2,38 % | 2.951 | 622 | +330,0 % |
| 34 | 8.292 | 54.161 | Schaden erster Treffer 129,0 → 132,0 | +2,33 % | 3.566 | 734 | +340,0 % |
| 35 | 9.784 | 63.945 | Schaden erster Treffer 132,0 → 135,0 | +2,27 % | 4.305 | 866 | +350,0 % |
| 36 | 11.546 | 75.491 | Schaden erster Treffer 135,0 → 138,0 | +2,22 % | 5.196 | 1.022 | +360,0 % |
| 37 | 13.624 | 89.115 | Schaden erster Treffer 138,0 → 141,0 | +2,17 % | 6.267 | 1.206 | +370,0 % |
| 38 | 16.076 | 105.191 | Schaden erster Treffer 141,0 → 144,0 | +2,13 % | 7.556 | 1.423 | +380,0 % |
| 39 | 18.970 | 124.161 | Schaden erster Treffer 144,0 → 147,0 | +2,08 % | 9.106 | 1.680 | +390,0 % |
| 40 | 22.384 | 146.545 | Schaden erster Treffer 147,0 → 150,0 | +2,04 % | 10.968 | 1.982 | +400,0 % |

#### Tesla-Spule – Feuerrate

**Verändert:** Abklingzeit zwischen zwei Schüssen (Feuerrate = 1 ÷ Abklingzeit). Mehr Schüsse brauchen entsprechend mehr Energie pro Sekunde. **Je Stufe:** +6 % Feuerrate.

Neubau zum Vergleich: 1,42 Münzen je DPS (volle Kette).

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS (volle Kette) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 40 | 40 | 1,000 → 0,943 s (1,06 Schüsse/s) | +6,00 % | 6,67 | 5,90 | +6,0 % |
| 2 | 47 | 87 | 0,943 → 0,893 s (1,12 Schüsse/s) | +5,66 % | 8,30 | 6,94 | +12,0 % |
| 3 | 56 | 143 | 0,893 → 0,847 s (1,18 Schüsse/s) | +5,36 % | 10,5 | 8,26 | +18,0 % |
| 4 | 66 | 209 | 0,847 → 0,806 s (1,24 Schüsse/s) | +5,08 % | 13,0 | 9,74 | +24,0 % |
| 5 | 78 | 287 | 0,806 → 0,769 s (1,30 Schüsse/s) | +4,84 % | 16,1 | 11,5 | +30,0 % |
| 6 | 92 | 379 | 0,769 → 0,735 s (1,36 Schüsse/s) | +4,62 % | 19,9 | 13,6 | +36,0 % |
| 7 | 108 | 487 | 0,735 → 0,704 s (1,42 Schüsse/s) | +4,41 % | 24,5 | 15,9 | +42,0 % |
| 8 | 127 | 614 | 0,704 → 0,676 s (1,48 Schüsse/s) | +4,23 % | 30,1 | 18,7 | +48,0 % |
| 9 | 150 | 764 | 0,676 → 0,649 s (1,54 Schüsse/s) | +4,05 % | 37,0 | 22,1 | +54,0 % |
| 10 | 177 | 941 | 0,649 → 0,625 s (1,60 Schüsse/s) | +3,90 % | 45,4 | 26,1 | +60,0 % |
| 11 | 209 | 1.150 | 0,625 → 0,602 s (1,66 Schüsse/s) | +3,75 % | 55,7 | 30,8 | +66,0 % |
| 12 | 247 | 1.397 | 0,602 → 0,581 s (1,72 Schüsse/s) | +3,61 % | 68,3 | 36,4 | +72,0 % |
| 13 | 292 | 1.689 | 0,581 → 0,562 s (1,78 Schüsse/s) | +3,49 % | 83,7 | 43,1 | +78,0 % |
| 14 | 344 | 2.033 | 0,562 → 0,543 s (1,84 Schüsse/s) | +3,37 % | 102 | 50,8 | +84,0 % |
| 15 | 406 | 2.439 | 0,543 → 0,526 s (1,90 Schüsse/s) | +3,26 % | 125 | 59,9 | +90,0 % |
| 16 | 479 | 2.918 | 0,526 → 0,510 s (1,96 Schüsse/s) | +3,16 % | 152 | 70,7 | +96,0 % |
| 17 | 565 | 3.483 | 0,510 → 0,495 s (2,02 Schüsse/s) | +3,06 % | 185 | 83,4 | +102,0 % |
| 18 | 667 | 4.150 | 0,495 → 0,481 s (2,08 Schüsse/s) | +2,97 % | 225 | 98,4 | +108,0 % |
| 19 | 787 | 4.937 | 0,481 → 0,467 s (2,14 Schüsse/s) | +2,88 % | 273 | 116 | +114,0 % |
| 20 | 929 | 5.866 | 0,467 → 0,455 s (2,20 Schüsse/s) | +2,80 % | 331 | 137 | +120,0 % |
| 21 | 1.096 | 6.962 | 0,455 → 0,442 s (2,26 Schüsse/s) | +2,73 % | 402 | 162 | +126,0 % |
| 22 | 1.293 | 8.255 | 0,442 → 0,431 s (2,32 Schüsse/s) | +2,65 % | 487 | 191 | +132,0 % |
| 23 | 1.526 | 9.781 | 0,431 → 0,420 s (2,38 Schüsse/s) | +2,59 % | 590 | 225 | +138,0 % |
| 24 | 1.800 | 11.581 | 0,420 → 0,410 s (2,44 Schüsse/s) | +2,52 % | 714 | 266 | +144,0 % |
| 25 | 2.124 | 13.705 | 0,410 → 0,400 s (2,50 Schüsse/s) | +2,46 % | 864 | 313 | +150,0 % |

#### Tesla-Spule – Überladung

**Verändert:** Schaden ×(1 + 0,2 × Stufe), aber Energie je Schuss ×1,25 je Stufe. Braucht ein Schuss mehr Energie als der Speicher fasst, feuert der Turm nicht mehr (Überladung, Grenze ohne Kapazitäts- und Effizienz-Upgrades). **Je Stufe:** +20 % Schaden, ×1,25 Energie.

Neubau zum Vergleich: 1,42 Münzen je DPS (volle Kette).

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS (volle Kette) | Nutzen gesamt | Nebenwirkung |
|---|---|---|---|---|---|---|---|---|
| 1 | 24 | 24 | Schaden 30,0 → 36,0 · Energie/Schuss 14,00 → 17,50 | +20,00 % | 1,20 | 1,06 | +20,0 % | Schaden je Energie −4,0 % |
| 2 | 28 | 52 | Schaden 36,0 → 42,0 · Energie/Schuss 17,50 → 21,88 | +16,67 % | 1,68 | 1,24 | +40,0 % | Schaden je Energie −6,7 % |
| 3 | 33 | 85 | Schaden 42,0 → 48,0 · Energie/Schuss 21,88 → 27,34 | +14,29 % | 2,31 | 1,46 | +60,0 % | Schaden je Energie −8,6 % |
| 4 | 39 | 124 | Schaden 48,0 → 54,0 · Energie/Schuss 27,34 → 34,18 | +12,50 % | 3,12 | 1,73 | +80,0 % | Schaden je Energie −10,0 % |
| 5 | 47 | 171 | Schaden 54,0 → 60,0 · Energie/Schuss 34,18 → 42,72 | +11,11 % | 4,23 | 2,08 | +100,0 % | Schaden je Energie −11,1 % |
| 6 | 55 | 226 | Schaden 60,0 → 66,0 · Energie/Schuss 42,72 → 53,41 | +10,00 % | 5,50 | 2,43 | +120,0 % | Schaden je Energie −12,0 % |
| 7 | 65 | 291 | Schaden 66,0 → 72,0 · Energie/Schuss 53,41 → 66,76 | +9,09 % | 7,15 | 2,88 | +140,0 % | Schaden je Energie −12,7 % |
| 8 | 76 | 367 | Schaden 72,0 → 78,0 · Energie/Schuss 66,76 → 83,45 | +8,33 % | 9,12 | 3,36 | +160,0 % | Schaden je Energie −13,3 % · ⚠ ab hier überladen (Schuss 83,4 > Speicher 80) |
| 9 | 90 | 457 | Schaden 78,0 → 84,0 · Energie/Schuss 83,45 → 104,31 | +7,69 % | 11,7 | 3,98 | +180,0 % | Schaden je Energie −13,8 % · ⚠ überladen |
| 10 | 106 | 563 | Schaden 84,0 → 90,0 · Energie/Schuss 104,31 → 130,39 | +7,14 % | 14,8 | 4,69 | +200,0 % | Schaden je Energie −14,3 % · ⚠ überladen |
| 11 | 126 | 689 | Schaden 90,0 → 96,0 · Energie/Schuss 130,39 → 162,98 | +6,67 % | 18,9 | 5,58 | +220,0 % | Schaden je Energie −14,7 % · ⚠ überladen |
| 12 | 148 | 837 | Schaden 96,0 → 102,0 · Energie/Schuss 162,98 → 203,73 | +6,25 % | 23,7 | 6,55 | +240,0 % | Schaden je Energie −15,0 % · ⚠ überladen |

#### Tesla-Spule – Reichweite

**Verändert:** Angriffsreichweite (und damit Sichtweite). Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 48 | 48 | 3,93 → 4,09 Felder | +4,00 % | 12,0 | 305 | +4,0 % |
| 2 | 57 | 105 | 4,09 → 4,24 Felder | +3,85 % | 14,8 | 363 | +8,0 % |
| 3 | 67 | 172 | 4,24 → 4,40 Felder | +3,70 % | 18,1 | 426 | +12,0 % |
| 4 | 79 | 251 | 4,40 → 4,56 Felder | +3,57 % | 22,1 | 503 | +16,0 % |
| 5 | 93 | 344 | 4,56 → 4,71 Felder | +3,45 % | 27,0 | 592 | +20,0 % |
| 6 | 110 | 454 | 4,71 → 4,87 Felder | +3,33 % | 33,0 | 700 | +24,0 % |
| 7 | 130 | 584 | 4,87 → 5,03 Felder | +3,23 % | 40,3 | 827 | +28,0 % |
| 8 | 153 | 737 | 5,03 → 5,19 Felder | +3,12 % | 49,0 | 974 | +32,0 % |
| 9 | 180 | 917 | 5,19 → 5,34 Felder | +3,03 % | 59,4 | 1.145 | +36,0 % |
| 10 | 213 | 1.130 | 5,34 → 5,50 Felder | +2,94 % | 72,4 | 1.355 | +40,0 % |
| 11 | 251 | 1.381 | 5,50 → 5,66 Felder | +2,86 % | 87,8 | 1.597 | +44,0 % |
| 12 | 296 | 1.677 | 5,66 → 5,81 Felder | +2,78 % | 107 | 1.884 | +48,0 % |
| 13 | 350 | 2.027 | 5,81 → 5,97 Felder | +2,70 % | 130 | 2.227 | +52,0 % |
| 14 | 413 | 2.440 | 5,97 → 6,13 Felder | +2,63 % | 157 | 2.628 | +56,0 % |
| 15 | 487 | 2.927 | 6,13 → 6,29 Felder | +2,56 % | 190 | 3.099 | +60,0 % |

#### Tesla-Spule – Kettenziele

**Verändert:** Zahl der Ziele, über die der Blitz springt (Sprungweite 2,5 Felder, je Sprung 80 % des vorigen Schadens). Nutzen gilt nur, wenn genug Gegner nah beieinander stehen. **Je Stufe:** +1 Ziel.

Neubau zum Vergleich: 1,42 Münzen je DPS (volle Kette).

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS (volle Kette) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 112 | 112 | 5 → 6 Ziele (Kettenschaden 3,36 → 3,69 × Treffer) | +9,75 % | 11,5 | 10,2 | +9,7 % |
| 2 | 168 | 280 | 6 → 7 Ziele (Kettenschaden 3,69 → 3,95 × Treffer) | +7,11 % | 23,6 | 19,1 | +17,5 % |
| 3 | 252 | 532 | 7 → 8 Ziele (Kettenschaden 3,95 → 4,16 × Treffer) | +5,31 % | 47,5 | 35,8 | +23,8 % |
| 4 | 378 | 910 | 8 → 9 Ziele (Kettenschaden 4,16 → 4,33 × Treffer) | +4,03 % | 93,8 | 67,1 | +28,8 % |
| 5 | 567 | 1.477 | 9 → 10 Ziele (Kettenschaden 4,33 → 4,46 × Treffer) | +3,10 % | 183 | 126 | +32,8 % |

#### Tesla-Spule – Kritische Treffer

**Verändert:** Chance auf einen kritischen Treffer (doppelter Schaden). Nutzen = Anstieg des durchschnittlichen Schadens (1 + Krit-Chance). **Je Stufe:** +1 Prozentpunkt.

Neubau zum Vergleich: 1,42 Münzen je DPS (volle Kette).

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS (volle Kette) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 40 | 40 | Krit-Chance 12 % → 13 % | +0,89 % | 44,8 | 39,7 | +0,9 % |
| 2 | 47 | 87 | Krit-Chance 13 % → 14 % | +0,88 % | 53,1 | 46,6 | +1,8 % |
| 3 | 56 | 143 | Krit-Chance 14 % → 15 % | +0,88 % | 63,8 | 55,5 | +2,7 % |
| 4 | 66 | 209 | Krit-Chance 15 % → 16 % | +0,87 % | 75,9 | 65,4 | +3,6 % |
| 5 | 78 | 287 | Krit-Chance 16 % → 17 % | +0,86 % | 90,5 | 77,3 | +4,5 % |
| 6 | 92 | 379 | Krit-Chance 17 % → 18 % | +0,85 % | 108 | 91,2 | +5,4 % |
| 7 | 108 | 487 | Krit-Chance 18 % → 19 % | +0,85 % | 127 | 107 | +6,2 % |
| 8 | 127 | 614 | Krit-Chance 19 % → 20 % | +0,84 % | 151 | 126 | +7,1 % |
| 9 | 150 | 764 | Krit-Chance 20 % → 21 % | +0,83 % | 180 | 149 | +8,0 % |
| 10 | 177 | 941 | Krit-Chance 21 % → 22 % | +0,83 % | 214 | 176 | +8,9 % |
| 11 | 209 | 1.150 | Krit-Chance 22 % → 23 % | +0,82 % | 255 | 207 | +9,8 % |
| 12 | 247 | 1.397 | Krit-Chance 23 % → 24 % | +0,81 % | 304 | 245 | +10,7 % |
| 13 | 292 | 1.689 | Krit-Chance 24 % → 25 % | +0,81 % | 362 | 290 | +11,6 % |
| 14 | 344 | 2.033 | Krit-Chance 25 % → 26 % | +0,80 % | 430 | 341 | +12,5 % |
| 15 | 406 | 2.439 | Krit-Chance 26 % → 27 % | +0,79 % | 512 | 403 | +13,4 % |
| 16 | 479 | 2.918 | Krit-Chance 27 % → 28 % | +0,79 % | 608 | 475 | +14,3 % |
| 17 | 565 | 3.483 | Krit-Chance 28 % → 29 % | +0,78 % | 723 | 560 | +15,2 % |
| 18 | 667 | 4.150 | Krit-Chance 29 % → 30 % | +0,78 % | 860 | 661 | +16,1 % |
| 19 | 787 | 4.937 | Krit-Chance 30 % → 31 % | +0,77 % | 1.023 | 780 | +17,0 % |
| 20 | 929 | 5.866 | Krit-Chance 31 % → 32 % | +0,76 % | 1.217 | 921 | +17,9 % |

#### Tesla-Spule – Effizienz

**Verändert:** Senkt die Energie je Schuss (Energie ÷ Effizienz). Verschiebt die Überladungsgrenze nach oben. **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je (Schaden/Energie) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 32 | 32 | Energie/Schuss 14,00 → 13,33 | +5,00 % | 6,40 | 79,3 | +5,0 % |
| 2 | 38 | 70 | Energie/Schuss 13,33 → 12,73 | +4,76 % | 7,98 | 94,2 | +10,0 % |
| 3 | 45 | 115 | Energie/Schuss 12,73 → 12,17 | +4,55 % | 9,90 | 112 | +15,0 % |
| 4 | 53 | 168 | Energie/Schuss 12,17 → 11,67 | +4,35 % | 12,2 | 131 | +20,0 % |
| 5 | 62 | 230 | Energie/Schuss 11,67 → 11,20 | +4,17 % | 14,9 | 154 | +25,0 % |
| 6 | 73 | 303 | Energie/Schuss 11,20 → 10,77 | +4,00 % | 18,2 | 181 | +30,0 % |
| 7 | 86 | 389 | Energie/Schuss 10,77 → 10,37 | +3,85 % | 22,4 | 213 | +35,0 % |
| 8 | 102 | 491 | Energie/Schuss 10,37 → 10,00 | +3,70 % | 27,5 | 253 | +40,0 % |
| 9 | 120 | 611 | Energie/Schuss 10,00 → 9,66 | +3,57 % | 33,6 | 297 | +45,0 % |
| 10 | 142 | 753 | Energie/Schuss 9,66 → 9,33 | +3,45 % | 41,2 | 352 | +50,0 % |
| 11 | 167 | 920 | Energie/Schuss 9,33 → 9,03 | +3,33 % | 50,1 | 414 | +55,0 % |
| 12 | 198 | 1.118 | Energie/Schuss 9,03 → 8,75 | +3,23 % | 61,4 | 491 | +60,0 % |
| 13 | 233 | 1.351 | Energie/Schuss 8,75 → 8,48 | +3,12 % | 74,6 | 578 | +65,0 % |
| 14 | 275 | 1.626 | Energie/Schuss 8,48 → 8,24 | +3,03 % | 90,7 | 682 | +70,0 % |
| 15 | 325 | 1.951 | Energie/Schuss 8,24 → 8,00 | +2,94 % | 111 | 806 | +75,0 % |
| 16 | 383 | 2.334 | Energie/Schuss 8,00 → 7,78 | +2,86 % | 134 | 949 | +80,0 % |
| 17 | 452 | 2.786 | Energie/Schuss 7,78 → 7,57 | +2,78 % | 163 | 1.120 | +85,0 % |
| 18 | 534 | 3.320 | Energie/Schuss 7,57 → 7,37 | +2,70 % | 198 | 1.324 | +90,0 % |
| 19 | 630 | 3.950 | Energie/Schuss 7,37 → 7,18 | +2,63 % | 239 | 1.562 | +95,0 % |
| 20 | 743 | 4.693 | Energie/Schuss 7,18 → 7,00 | +2,56 % | 290 | 1.842 | +100,0 % |

#### Tesla-Spule – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). Hebt die Grenze, ab der eine Überladung den Turm stilllegt. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 2,00 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 29 | 29 | 80,0 → 96,0 Energie | +20,00 % | 1,45 | 1,81 | +20,0 % |
| 2 | 34 | 63 | 96,0 → 112,0 Energie | +16,67 % | 2,04 | 2,12 | +40,0 % |
| 3 | 40 | 103 | 112,0 → 128,0 Energie | +14,29 % | 2,80 | 2,50 | +60,0 % |
| 4 | 47 | 150 | 128,0 → 144,0 Energie | +12,50 % | 3,76 | 2,94 | +80,0 % |
| 5 | 56 | 206 | 144,0 → 160,0 Energie | +11,11 % | 5,04 | 3,50 | +100,0 % |
| 6 | 66 | 272 | 160,0 → 176,0 Energie | +10,00 % | 6,60 | 4,12 | +120,0 % |
| 7 | 78 | 350 | 176,0 → 192,0 Energie | +9,09 % | 8,58 | 4,87 | +140,0 % |
| 8 | 92 | 442 | 192,0 → 208,0 Energie | +8,33 % | 11,0 | 5,75 | +160,0 % |
| 9 | 108 | 550 | 208,0 → 224,0 Energie | +7,69 % | 14,0 | 6,75 | +180,0 % |
| 10 | 128 | 678 | 224,0 → 240,0 Energie | +7,14 % | 17,9 | 8,00 | +200,0 % |
| 11 | 151 | 829 | 240,0 → 256,0 Energie | +6,67 % | 22,7 | 9,44 | +220,0 % |
| 12 | 178 | 1.007 | 256,0 → 272,0 Energie | +6,25 % | 28,5 | 11,1 | +240,0 % |
| 13 | 210 | 1.217 | 272,0 → 288,0 Energie | +5,88 % | 35,7 | 13,1 | +260,0 % |
| 14 | 248 | 1.465 | 288,0 → 304,0 Energie | +5,56 % | 44,6 | 15,5 | +280,0 % |
| 15 | 292 | 1.757 | 304,0 → 320,0 Energie | +5,26 % | 55,5 | 18,2 | +300,0 % |
| 16 | 345 | 2.102 | 320,0 → 336,0 Energie | +5,00 % | 69,0 | 21,6 | +320,0 % |
| 17 | 407 | 2.509 | 336,0 → 352,0 Energie | +4,76 % | 85,5 | 25,4 | +340,0 % |
| 18 | 480 | 2.989 | 352,0 → 368,0 Energie | +4,55 % | 106 | 30,0 | +360,0 % |
| 19 | 567 | 3.556 | 368,0 → 384,0 Energie | +4,35 % | 130 | 35,4 | +380,0 % |
| 20 | 669 | 4.225 | 384,0 → 400,0 Energie | +4,17 % | 161 | 41,8 | +400,0 % |
| 21 | 789 | 5.014 | 400,0 → 416,0 Energie | +4,00 % | 197 | 49,3 | +420,0 % |
| 22 | 931 | 5.945 | 416,0 → 432,0 Energie | +3,85 % | 242 | 58,2 | +440,0 % |
| 23 | 1.098 | 7.043 | 432,0 → 448,0 Energie | +3,70 % | 296 | 68,6 | +460,0 % |
| 24 | 1.296 | 8.339 | 448,0 → 464,0 Energie | +3,57 % | 363 | 81,0 | +480,0 % |
| 25 | 1.530 | 9.869 | 464,0 → 480,0 Energie | +3,45 % | 444 | 95,6 | +500,0 % |

#### Tesla-Spule – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 32 | 32 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 28,8 | +1,1 % |
| 2 | 38 | 70 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 34,6 | +2,2 % |
| 3 | 45 | 115 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 41,4 | +3,3 % |
| 4 | 53 | 168 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 49,3 | +4,4 % |
| 5 | 62 | 230 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 58,3 | +5,6 % |
| 6 | 73 | 303 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 69,3 | +6,7 % |
| 7 | 86 | 389 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 82,6 | +7,8 % |
| 8 | 102 | 491 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 98,9 | +8,9 % |
| 9 | 120 | 611 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 118 | +10,0 % |
| 10 | 142 | 753 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 141 | +11,1 % |

#### Tesla-Spule – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,333 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 29 | 29 | 120,0 → 138,0 HP | +15,00 % | 1,93 | 1,611 | +15,0 % |
| 2 | 34 | 63 | 138,0 → 156,0 HP | +13,04 % | 2,61 | 1,889 | +30,0 % |
| 3 | 40 | 103 | 156,0 → 174,0 HP | +11,54 % | 3,47 | 2,222 | +45,0 % |
| 4 | 47 | 150 | 174,0 → 192,0 HP | +10,34 % | 4,54 | 2,611 | +60,0 % |
| 5 | 56 | 206 | 192,0 → 210,0 HP | +9,38 % | 5,97 | 3,111 | +75,0 % |
| 6 | 66 | 272 | 210,0 → 228,0 HP | +8,57 % | 7,70 | 3,667 | +90,0 % |
| 7 | 78 | 350 | 228,0 → 246,0 HP | +7,89 % | 9,88 | 4,333 | +105,0 % |
| 8 | 92 | 442 | 246,0 → 264,0 HP | +7,32 % | 12,6 | 5,111 | +120,0 % |
| 9 | 108 | 550 | 264,0 → 282,0 HP | +6,82 % | 15,8 | 6,000 | +135,0 % |
| 10 | 128 | 678 | 282,0 → 300,0 HP | +6,38 % | 20,1 | 7,111 | +150,0 % |
| 11 | 151 | 829 | 300,0 → 318,0 HP | +6,00 % | 25,2 | 8,389 | +165,0 % |
| 12 | 178 | 1.007 | 318,0 → 336,0 HP | +5,66 % | 31,4 | 9,889 | +180,0 % |
| 13 | 210 | 1.217 | 336,0 → 354,0 HP | +5,36 % | 39,2 | 11,667 | +195,0 % |
| 14 | 248 | 1.465 | 354,0 → 372,0 HP | +5,08 % | 48,8 | 13,778 | +210,0 % |
| 15 | 292 | 1.757 | 372,0 → 390,0 HP | +4,84 % | 60,3 | 16,222 | +225,0 % |
| 16 | 345 | 2.102 | 390,0 → 408,0 HP | +4,62 % | 74,7 | 19,167 | +240,0 % |
| 17 | 407 | 2.509 | 408,0 → 426,0 HP | +4,41 % | 92,3 | 22,611 | +255,0 % |
| 18 | 480 | 2.989 | 426,0 → 444,0 HP | +4,23 % | 114 | 26,667 | +270,0 % |
| 19 | 567 | 3.556 | 444,0 → 462,0 HP | +4,05 % | 140 | 31,500 | +285,0 % |
| 20 | 669 | 4.225 | 462,0 → 480,0 HP | +3,90 % | 172 | 37,167 | +300,0 % |
| 21 | 789 | 5.014 | 480,0 → 498,0 HP | +3,75 % | 210 | 43,833 | +315,0 % |
| 22 | 931 | 5.945 | 498,0 → 516,0 HP | +3,61 % | 258 | 51,722 | +330,0 % |
| 23 | 1.098 | 7.043 | 516,0 → 534,0 HP | +3,49 % | 315 | 61,000 | +345,0 % |
| 24 | 1.296 | 8.339 | 534,0 → 552,0 HP | +3,37 % | 384 | 72,000 | +360,0 % |
| 25 | 1.530 | 9.869 | 552,0 → 570,0 HP | +3,26 % | 469 | 85,000 | +375,0 % |
| 26 | 1.805 | 11.674 | 570,0 → 588,0 HP | +3,16 % | 572 | 100,278 | +390,0 % |
| 27 | 2.130 | 13.804 | 588,0 → 606,0 HP | +3,06 % | 696 | 118,333 | +405,0 % |
| 28 | 2.513 | 16.317 | 606,0 → 624,0 HP | +2,97 % | 846 | 139,611 | +420,0 % |
| 29 | 2.965 | 19.282 | 624,0 → 642,0 HP | +2,88 % | 1.028 | 164,722 | +435,0 % |
| 30 | 3.499 | 22.781 | 642,0 → 660,0 HP | +2,80 % | 1.248 | 194,389 | +450,0 % |

#### Tesla-Spule – Panzerung

**Verändert:** Panzerung. Jeder erlittene Treffer sinkt um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Nutzen gemessen an den effektiven Lebenspunkten (Leben ÷ (1 − Reduktion)) mit Grund-Leben, ohne Mindestschaden. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,23 Münzen je eff. HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eff. HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 24 | 24 | Panzerung 8,0 → 9,2 (−7,4 % → −8,4 %) | +1,11 % | 21,6 | 16,7 | +1,1 % |
| 2 | 28 | 52 | Panzerung 9,2 → 10,4 (−8,4 % → −9,4 %) | +1,10 % | 25,5 | 19,4 | +2,2 % |
| 3 | 33 | 85 | Panzerung 10,4 → 11,6 (−9,4 % → −10,4 %) | +1,09 % | 30,4 | 22,9 | +3,3 % |
| 4 | 39 | 124 | Panzerung 11,6 → 12,8 (−10,4 % → −11,3 %) | +1,08 % | 36,3 | 27,1 | +4,4 % |
| 5 | 47 | 171 | Panzerung 12,8 → 14,0 (−11,3 % → −12,3 %) | +1,06 % | 44,2 | 32,6 | +5,6 % |
| 6 | 55 | 226 | Panzerung 14,0 → 15,2 (−12,3 % → −13,2 %) | +1,05 % | 52,2 | 38,2 | +6,7 % |
| 7 | 65 | 291 | Panzerung 15,2 → 16,4 (−13,2 % → −14,1 %) | +1,04 % | 62,4 | 45,1 | +7,8 % |
| 8 | 76 | 367 | Panzerung 16,4 → 17,6 (−14,1 % → −15,0 %) | +1,03 % | 73,7 | 52,8 | +8,9 % |
| 9 | 90 | 457 | Panzerung 17,6 → 18,8 (−15,0 % → −15,8 %) | +1,02 % | 88,2 | 62,5 | +10,0 % |
| 10 | 106 | 563 | Panzerung 18,8 → 20,0 (−15,8 % → −16,7 %) | +1,01 % | 105 | 73,6 | +11,1 % |
| 11 | 126 | 689 | Panzerung 20,0 → 21,2 (−16,7 % → −17,5 %) | +1,00 % | 126 | 87,5 | +12,2 % |
| 12 | 148 | 837 | Panzerung 21,2 → 22,4 (−17,5 % → −18,3 %) | +0,99 % | 149 | 103 | +13,3 % |
| 13 | 175 | 1.012 | Panzerung 22,4 → 23,6 (−18,3 % → −19,1 %) | +0,98 % | 178 | 122 | +14,4 % |
| 14 | 206 | 1.218 | Panzerung 23,6 → 24,8 (−19,1 % → −19,9 %) | +0,97 % | 212 | 143 | +15,6 % |
| 15 | 244 | 1.462 | Panzerung 24,8 → 26,0 (−19,9 % → −20,6 %) | +0,96 % | 254 | 169 | +16,7 % |
| 16 | 287 | 1.749 | Panzerung 26,0 → 27,2 (−20,6 % → −21,4 %) | +0,95 % | 301 | 199 | +17,8 % |
| 17 | 339 | 2.088 | Panzerung 27,2 → 28,4 (−21,4 % → −22,1 %) | +0,94 % | 359 | 235 | +18,9 % |
| 18 | 400 | 2.488 | Panzerung 28,4 → 29,6 (−22,1 % → −22,8 %) | +0,93 % | 428 | 278 | +20,0 % |
| 19 | 472 | 2.960 | Panzerung 29,6 → 30,8 (−22,8 % → −23,5 %) | +0,93 % | 510 | 328 | +21,1 % |
| 20 | 557 | 3.517 | Panzerung 30,8 → 32,0 (−23,5 % → −24,2 %) | +0,92 % | 607 | 387 | +22,2 % |

### Plasmawerfer

- **Freischaltung:** Forschung „Plasmawerfer“ (3 SP)
- **Baukosten:** 200 · **Upgrade-Basis:** 200
- **Grundwerte:** 110 HP · Panzerung 10 · Kapazität 100 · 65 Schaden alle 2,50 s, 28 Energie/Schuss, Reichweite 7,68 Felder, Explosionsradius 1,52 Felder · DPS je getroffenem Ziel 29,1 (Ø inkl. 12 % Krit)

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Schaden | 40 | 44 | 27.980 | 183.180 | +400 % | 4,40 → 13.710 |
| Feuerrate | 25 | 50 | 2.655 | 17.130 | +150 % | 8,33 → 1.080 |
| Überladung | 12 | 30 | 185 | 1.048 | +240 % | 1,50 → 29,6 |
| Reichweite | 15 | 60 | 609 | 3.659 | +60 % | 15,0 → 238 |
| Explosionsradius | 15 | 50 | 507 | 3.048 | +75 % | 10,00 → 172 |
| Kritische Treffer | 20 | 50 | 1.161 | 7.332 | +18 % | 56,0 → 1.521 |
| Effizienz | 20 | 40 | 929 | 5.866 | +100 % | 8,00 → 362 |
| Kapazität | 25 | 36 | 1.912 | 12.332 | +500 % | 1,80 → 554 |
| Strahlübertragung | 10 | 40 | 177 | 941 | +11 % | 36,0 → 175 |
| Leben | 30 | 36 | 4.374 | 28.472 | +450 % | 2,40 → 1.560 |
| Panzerung | 20 | 30 | 696 | 4.398 | +27 % | 22,0 → 643 |

#### Plasmawerfer – Schaden

**Verändert:** Schaden je Schuss (Laser: je Sekunde). **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 6,87 Münzen je DPS je getroffenem Ziel.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS je getroffenem Ziel | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 44 | 44 | Schaden je Treffer 65,0 → 71,5 | +10,00 % | 4,40 | 15,1 | +10,0 % |
| 2 | 52 | 96 | Schaden je Treffer 71,5 → 78,0 | +9,09 % | 5,72 | 17,9 | +20,0 % |
| 3 | 61 | 157 | Schaden je Treffer 78,0 → 84,5 | +8,33 % | 7,32 | 20,9 | +30,0 % |
| 4 | 72 | 229 | Schaden je Treffer 84,5 → 91,0 | +7,69 % | 9,36 | 24,7 | +40,0 % |
| 5 | 85 | 314 | Schaden je Treffer 91,0 → 97,5 | +7,14 % | 11,9 | 29,2 | +50,0 % |
| 6 | 101 | 415 | Schaden je Treffer 97,5 → 104,0 | +6,67 % | 15,2 | 34,7 | +60,0 % |
| 7 | 119 | 534 | Schaden je Treffer 104,0 → 110,5 | +6,25 % | 19,0 | 40,9 | +70,0 % |
| 8 | 140 | 674 | Schaden je Treffer 110,5 → 117,0 | +5,88 % | 23,8 | 48,1 | +80,0 % |
| 9 | 165 | 839 | Schaden je Treffer 117,0 → 123,5 | +5,56 % | 29,7 | 56,7 | +90,0 % |
| 10 | 195 | 1.034 | Schaden je Treffer 123,5 → 130,0 | +5,26 % | 37,1 | 67,0 | +100,0 % |
| 11 | 230 | 1.264 | Schaden je Treffer 130,0 → 136,5 | +5,00 % | 46,0 | 79,0 | +110,0 % |
| 12 | 272 | 1.536 | Schaden je Treffer 136,5 → 143,0 | +4,76 % | 57,1 | 93,4 | +120,0 % |
| 13 | 321 | 1.857 | Schaden je Treffer 143,0 → 149,5 | +4,55 % | 70,6 | 110 | +130,0 % |
| 14 | 378 | 2.235 | Schaden je Treffer 149,5 → 156,0 | +4,35 % | 86,9 | 130 | +140,0 % |
| 15 | 446 | 2.681 | Schaden je Treffer 156,0 → 162,5 | +4,17 % | 107 | 153 | +150,0 % |
| 16 | 527 | 3.208 | Schaden je Treffer 162,5 → 169,0 | +4,00 % | 132 | 181 | +160,0 % |
| 17 | 622 | 3.830 | Schaden je Treffer 169,0 → 175,5 | +3,85 % | 162 | 214 | +170,0 % |
| 18 | 734 | 4.564 | Schaden je Treffer 175,5 → 182,0 | +3,70 % | 198 | 252 | +180,0 % |
| 19 | 866 | 5.430 | Schaden je Treffer 182,0 → 188,5 | +3,57 % | 242 | 297 | +190,0 % |
| 20 | 1.021 | 6.451 | Schaden je Treffer 188,5 → 195,0 | +3,45 % | 296 | 351 | +200,0 % |
| 21 | 1.205 | 7.656 | Schaden je Treffer 195,0 → 201,5 | +3,33 % | 361 | 414 | +210,0 % |
| 22 | 1.422 | 9.078 | Schaden je Treffer 201,5 → 208,0 | +3,23 % | 441 | 488 | +220,0 % |
| 23 | 1.678 | 10.756 | Schaden je Treffer 208,0 → 214,5 | +3,13 % | 537 | 576 | +230,0 % |
| 24 | 1.980 | 12.736 | Schaden je Treffer 214,5 → 221,0 | +3,03 % | 653 | 680 | +240,0 % |
| 25 | 2.337 | 15.073 | Schaden je Treffer 221,0 → 227,5 | +2,94 % | 795 | 803 | +250,0 % |
| 26 | 2.757 | 17.830 | Schaden je Treffer 227,5 → 234,0 | +2,86 % | 965 | 947 | +260,0 % |
| 27 | 3.254 | 21.084 | Schaden je Treffer 234,0 → 240,5 | +2,78 % | 1.171 | 1.117 | +270,0 % |
| 28 | 3.839 | 24.923 | Schaden je Treffer 240,5 → 247,0 | +2,70 % | 1.420 | 1.318 | +280,0 % |
| 29 | 4.531 | 29.454 | Schaden je Treffer 247,0 → 253,5 | +2,63 % | 1.722 | 1.556 | +290,0 % |
| 30 | 5.346 | 34.800 | Schaden je Treffer 253,5 → 260,0 | +2,56 % | 2.085 | 1.836 | +300,0 % |
| 31 | 6.308 | 41.108 | Schaden je Treffer 260,0 → 266,5 | +2,50 % | 2.523 | 2.166 | +310,0 % |
| 32 | 7.444 | 48.552 | Schaden je Treffer 266,5 → 273,0 | +2,44 % | 3.052 | 2.556 | +320,0 % |
| 33 | 8.784 | 57.336 | Schaden je Treffer 273,0 → 279,5 | +2,38 % | 3.689 | 3.016 | +330,0 % |
| 34 | 10.365 | 67.701 | Schaden je Treffer 279,5 → 286,0 | +2,33 % | 4.457 | 3.559 | +340,0 % |
| 35 | 12.230 | 79.931 | Schaden je Treffer 286,0 → 292,5 | +2,27 % | 5.381 | 4.200 | +350,0 % |
| 36 | 14.432 | 94.363 | Schaden je Treffer 292,5 → 299,0 | +2,22 % | 6.494 | 4.956 | +360,0 % |
| 37 | 17.030 | 111.393 | Schaden je Treffer 299,0 → 305,5 | +2,17 % | 7.834 | 5.848 | +370,0 % |
| 38 | 20.095 | 131.488 | Schaden je Treffer 305,5 → 312,0 | +2,13 % | 9.445 | 6.901 | +380,0 % |
| 39 | 23.712 | 155.200 | Schaden je Treffer 312,0 → 318,5 | +2,08 % | 11.382 | 8.143 | +390,0 % |
| 40 | 27.980 | 183.180 | Schaden je Treffer 318,5 → 325,0 | +2,04 % | 13.710 | 9.609 | +400,0 % |

#### Plasmawerfer – Feuerrate

**Verändert:** Abklingzeit zwischen zwei Schüssen (Feuerrate = 1 ÷ Abklingzeit). Mehr Schüsse brauchen entsprechend mehr Energie pro Sekunde. **Je Stufe:** +6 % Feuerrate.

Neubau zum Vergleich: 6,87 Münzen je DPS je getroffenem Ziel.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS je getroffenem Ziel | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 50 | 50 | 2,500 → 2,358 s (0,42 Schüsse/s) | +6,00 % | 8,33 | 28,6 | +6,0 % |
| 2 | 59 | 109 | 2,358 → 2,232 s (0,45 Schüsse/s) | +5,66 % | 10,4 | 33,8 | +12,0 % |
| 3 | 70 | 179 | 2,232 → 2,119 s (0,47 Schüsse/s) | +5,36 % | 13,1 | 40,1 | +18,0 % |
| 4 | 82 | 261 | 2,119 → 2,016 s (0,50 Schüsse/s) | +5,08 % | 16,1 | 46,9 | +24,0 % |
| 5 | 97 | 358 | 2,016 → 1,923 s (0,52 Schüsse/s) | +4,84 % | 20,0 | 55,5 | +30,0 % |
| 6 | 114 | 472 | 1,923 → 1,838 s (0,54 Schüsse/s) | +4,62 % | 24,7 | 65,2 | +36,0 % |
| 7 | 135 | 607 | 1,838 → 1,761 s (0,57 Schüsse/s) | +4,41 % | 30,6 | 77,3 | +42,0 % |
| 8 | 159 | 766 | 1,761 → 1,689 s (0,59 Schüsse/s) | +4,23 % | 37,6 | 91,0 | +48,0 % |
| 9 | 188 | 954 | 1,689 → 1,623 s (0,62 Schüsse/s) | +4,05 % | 46,4 | 108 | +54,0 % |
| 10 | 222 | 1.176 | 1,623 → 1,562 s (0,64 Schüsse/s) | +3,90 % | 57,0 | 127 | +60,0 % |
| 11 | 262 | 1.438 | 1,562 → 1,506 s (0,66 Schüsse/s) | +3,75 % | 69,9 | 150 | +66,0 % |
| 12 | 309 | 1.747 | 1,506 → 1,453 s (0,69 Schüsse/s) | +3,61 % | 85,5 | 177 | +72,0 % |
| 13 | 364 | 2.111 | 1,453 → 1,404 s (0,71 Schüsse/s) | +3,49 % | 104 | 208 | +78,0 % |
| 14 | 430 | 2.541 | 1,404 → 1,359 s (0,74 Schüsse/s) | +3,37 % | 128 | 246 | +84,0 % |
| 15 | 507 | 3.048 | 1,359 → 1,316 s (0,76 Schüsse/s) | +3,26 % | 155 | 290 | +90,0 % |
| 16 | 599 | 3.647 | 1,316 → 1,276 s (0,78 Schüsse/s) | +3,16 % | 190 | 343 | +96,0 % |
| 17 | 706 | 4.353 | 1,276 → 1,238 s (0,81 Schüsse/s) | +3,06 % | 231 | 404 | +102,0 % |
| 18 | 834 | 5.187 | 1,238 → 1,202 s (0,83 Schüsse/s) | +2,97 % | 281 | 477 | +108,0 % |
| 19 | 984 | 6.171 | 1,202 → 1,168 s (0,86 Schüsse/s) | +2,88 % | 341 | 563 | +114,0 % |
| 20 | 1.161 | 7.332 | 1,168 → 1,136 s (0,88 Schüsse/s) | +2,80 % | 414 | 664 | +120,0 % |
| 21 | 1.370 | 8.702 | 1,136 → 1,106 s (0,90 Schüsse/s) | +2,73 % | 502 | 784 | +126,0 % |
| 22 | 1.616 | 10.318 | 1,106 → 1,078 s (0,93 Schüsse/s) | +2,65 % | 609 | 925 | +132,0 % |
| 23 | 1.907 | 12.225 | 1,078 → 1,050 s (0,95 Schüsse/s) | +2,59 % | 737 | 1.091 | +138,0 % |
| 24 | 2.250 | 14.475 | 1,050 → 1,025 s (0,98 Schüsse/s) | +2,52 % | 892 | 1.288 | +144,0 % |
| 25 | 2.655 | 17.130 | 1,025 → 1,000 s (1,00 Schüsse/s) | +2,46 % | 1.080 | 1.520 | +150,0 % |

#### Plasmawerfer – Überladung

**Verändert:** Schaden ×(1 + 0,2 × Stufe), aber Energie je Schuss ×1,25 je Stufe. Braucht ein Schuss mehr Energie als der Speicher fasst, feuert der Turm nicht mehr (Überladung, Grenze ohne Kapazitäts- und Effizienz-Upgrades). **Je Stufe:** +20 % Schaden, ×1,25 Energie.

Neubau zum Vergleich: 6,87 Münzen je DPS je getroffenem Ziel.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS je getroffenem Ziel | Nutzen gesamt | Nebenwirkung |
|---|---|---|---|---|---|---|---|---|
| 1 | 30 | 30 | Schaden 65,0 → 78,0 · Energie/Schuss 28,00 → 35,00 | +20,00 % | 1,50 | 5,15 | +20,0 % | Schaden je Energie −4,0 % |
| 2 | 35 | 65 | Schaden 78,0 → 91,0 · Energie/Schuss 35,00 → 43,75 | +16,67 % | 2,10 | 6,01 | +40,0 % | Schaden je Energie −6,7 % |
| 3 | 42 | 107 | Schaden 91,0 → 104,0 · Energie/Schuss 43,75 → 54,69 | +14,29 % | 2,94 | 7,21 | +60,0 % | Schaden je Energie −8,6 % |
| 4 | 49 | 156 | Schaden 104,0 → 117,0 · Energie/Schuss 54,69 → 68,36 | +12,50 % | 3,92 | 8,41 | +80,0 % | Schaden je Energie −10,0 % |
| 5 | 58 | 214 | Schaden 117,0 → 130,0 · Energie/Schuss 68,36 → 85,45 | +11,11 % | 5,22 | 9,96 | +100,0 % | Schaden je Energie −11,1 % |
| 6 | 69 | 283 | Schaden 130,0 → 143,0 · Energie/Schuss 85,45 → 106,81 | +10,00 % | 6,90 | 11,8 | +120,0 % | Schaden je Energie −12,0 % · ⚠ ab hier überladen (Schuss 106,8 > Speicher 100) |
| 7 | 81 | 364 | Schaden 143,0 → 156,0 · Energie/Schuss 106,81 → 133,51 | +9,09 % | 8,91 | 13,9 | +140,0 % | Schaden je Energie −12,7 % · ⚠ überladen |
| 8 | 96 | 460 | Schaden 156,0 → 169,0 · Energie/Schuss 133,51 → 166,89 | +8,33 % | 11,5 | 16,5 | +160,0 % | Schaden je Energie −13,3 % · ⚠ überladen |
| 9 | 113 | 573 | Schaden 169,0 → 182,0 · Energie/Schuss 166,89 → 208,62 | +7,69 % | 14,7 | 19,4 | +180,0 % | Schaden je Energie −13,8 % · ⚠ überladen |
| 10 | 133 | 706 | Schaden 182,0 → 195,0 · Energie/Schuss 208,62 → 260,77 | +7,14 % | 18,6 | 22,8 | +200,0 % | Schaden je Energie −14,3 % · ⚠ überladen |
| 11 | 157 | 863 | Schaden 195,0 → 208,0 · Energie/Schuss 260,77 → 325,96 | +6,67 % | 23,6 | 27,0 | +220,0 % | Schaden je Energie −14,7 % · ⚠ überladen |
| 12 | 185 | 1.048 | Schaden 208,0 → 221,0 · Energie/Schuss 325,96 → 407,45 | +6,25 % | 29,6 | 31,8 | +240,0 % | Schaden je Energie −15,0 % · ⚠ überladen |

#### Plasmawerfer – Reichweite

**Verändert:** Angriffsreichweite (und damit Sichtweite). Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 60 | 60 | 7,68 → 7,99 Felder | +4,00 % | 15,0 | 195 | +4,0 % |
| 2 | 71 | 131 | 7,99 → 8,29 Felder | +3,85 % | 18,5 | 231 | +8,0 % |
| 3 | 84 | 215 | 8,29 → 8,60 Felder | +3,70 % | 22,7 | 273 | +12,0 % |
| 4 | 99 | 314 | 8,60 → 8,91 Felder | +3,57 % | 27,7 | 322 | +16,0 % |
| 5 | 116 | 430 | 8,91 → 9,21 Felder | +3,45 % | 33,6 | 378 | +20,0 % |
| 6 | 137 | 567 | 9,21 → 9,52 Felder | +3,33 % | 41,1 | 446 | +24,0 % |
| 7 | 162 | 729 | 9,52 → 9,83 Felder | +3,23 % | 50,2 | 527 | +28,0 % |
| 8 | 191 | 920 | 9,83 → 10,14 Felder | +3,12 % | 61,1 | 622 | +32,0 % |
| 9 | 226 | 1.146 | 10,14 → 10,44 Felder | +3,03 % | 74,6 | 736 | +36,0 % |
| 10 | 266 | 1.412 | 10,44 → 10,75 Felder | +2,94 % | 90,4 | 866 | +40,0 % |
| 11 | 314 | 1.726 | 10,75 → 11,06 Felder | +2,86 % | 110 | 1.022 | +44,0 % |
| 12 | 371 | 2.097 | 11,06 → 11,36 Felder | +2,78 % | 134 | 1.208 | +48,0 % |
| 13 | 437 | 2.534 | 11,36 → 11,67 Felder | +2,70 % | 162 | 1.423 | +52,0 % |
| 14 | 516 | 3.050 | 11,67 → 11,98 Felder | +2,63 % | 196 | 1.680 | +56,0 % |
| 15 | 609 | 3.659 | 11,98 → 12,29 Felder | +2,56 % | 238 | 1.983 | +60,0 % |

#### Plasmawerfer – Explosionsradius

**Verändert:** Radius des Flächenschadens beim Einschlag. Die getroffene Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +5 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld Radius | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 50 | 50 | 1,52 → 1,59 Felder | +5,00 % | 10,00 | 659 | +5,0 % |
| 2 | 59 | 109 | 1,59 → 1,67 Felder | +4,76 % | 12,4 | 777 | +10,0 % |
| 3 | 70 | 179 | 1,67 → 1,75 Felder | +4,55 % | 15,4 | 922 | +15,0 % |
| 4 | 82 | 261 | 1,75 → 1,82 Felder | +4,35 % | 18,9 | 1.080 | +20,0 % |
| 5 | 97 | 358 | 1,82 → 1,90 Felder | +4,17 % | 23,3 | 1.278 | +25,0 % |
| 6 | 114 | 472 | 1,90 → 1,97 Felder | +4,00 % | 28,5 | 1.502 | +30,0 % |
| 7 | 135 | 607 | 1,97 → 2,05 Felder | +3,85 % | 35,1 | 1.779 | +35,0 % |
| 8 | 159 | 766 | 2,05 → 2,12 Felder | +3,70 % | 42,9 | 2.095 | +40,0 % |
| 9 | 188 | 954 | 2,12 → 2,20 Felder | +3,57 % | 52,6 | 2.477 | +45,0 % |
| 10 | 222 | 1.176 | 2,20 → 2,28 Felder | +3,45 % | 64,4 | 2.925 | +50,0 % |
| 11 | 262 | 1.438 | 2,28 → 2,35 Felder | +3,33 % | 78,6 | 3.452 | +55,0 % |
| 12 | 309 | 1.747 | 2,35 → 2,43 Felder | +3,23 % | 95,8 | 4.072 | +60,0 % |
| 13 | 364 | 2.111 | 2,43 → 2,50 Felder | +3,12 % | 116 | 4.796 | +65,0 % |
| 14 | 430 | 2.541 | 2,50 → 2,58 Felder | +3,03 % | 142 | 5.666 | +70,0 % |
| 15 | 507 | 3.048 | 2,58 → 2,66 Felder | +2,94 % | 172 | 6.680 | +75,0 % |

#### Plasmawerfer – Kritische Treffer

**Verändert:** Chance auf einen kritischen Treffer (doppelter Schaden). Nutzen = Anstieg des durchschnittlichen Schadens (1 + Krit-Chance). **Je Stufe:** +1 Prozentpunkt.

Neubau zum Vergleich: 6,87 Münzen je DPS je getroffenem Ziel.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS je getroffenem Ziel | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 50 | 50 | Krit-Chance 12 % → 13 % | +0,89 % | 56,0 | 192 | +0,9 % |
| 2 | 59 | 109 | Krit-Chance 13 % → 14 % | +0,88 % | 66,7 | 227 | +1,8 % |
| 3 | 70 | 179 | Krit-Chance 14 % → 15 % | +0,88 % | 79,8 | 269 | +2,7 % |
| 4 | 82 | 261 | Krit-Chance 15 % → 16 % | +0,87 % | 94,3 | 315 | +3,6 % |
| 5 | 97 | 358 | Krit-Chance 16 % → 17 % | +0,86 % | 113 | 373 | +4,5 % |
| 6 | 114 | 472 | Krit-Chance 17 % → 18 % | +0,85 % | 133 | 438 | +5,4 % |
| 7 | 135 | 607 | Krit-Chance 18 % → 19 % | +0,85 % | 159 | 519 | +6,2 % |
| 8 | 159 | 766 | Krit-Chance 19 % → 20 % | +0,84 % | 189 | 612 | +7,1 % |
| 9 | 188 | 954 | Krit-Chance 20 % → 21 % | +0,83 % | 226 | 723 | +8,0 % |
| 10 | 222 | 1.176 | Krit-Chance 21 % → 22 % | +0,83 % | 269 | 854 | +8,9 % |
| 11 | 262 | 1.438 | Krit-Chance 22 % → 23 % | +0,82 % | 320 | 1.008 | +9,8 % |
| 12 | 309 | 1.747 | Krit-Chance 23 % → 24 % | +0,81 % | 380 | 1.188 | +10,7 % |
| 13 | 364 | 2.111 | Krit-Chance 24 % → 25 % | +0,81 % | 451 | 1.400 | +11,6 % |
| 14 | 430 | 2.541 | Krit-Chance 25 % → 26 % | +0,80 % | 537 | 1.654 | +12,5 % |
| 15 | 507 | 3.048 | Krit-Chance 26 % → 27 % | +0,79 % | 639 | 1.950 | +13,4 % |
| 16 | 599 | 3.647 | Krit-Chance 27 % → 28 % | +0,79 % | 761 | 2.304 | +14,3 % |
| 17 | 706 | 4.353 | Krit-Chance 28 % → 29 % | +0,78 % | 904 | 2.715 | +15,2 % |
| 18 | 834 | 5.187 | Krit-Chance 29 % → 30 % | +0,78 % | 1.076 | 3.208 | +16,1 % |
| 19 | 984 | 6.171 | Krit-Chance 30 % → 31 % | +0,77 % | 1.279 | 3.785 | +17,0 % |
| 20 | 1.161 | 7.332 | Krit-Chance 31 % → 32 % | +0,76 % | 1.521 | 4.465 | +17,9 % |

#### Plasmawerfer – Effizienz

**Verändert:** Senkt die Energie je Schuss (Energie ÷ Effizienz). Verschiebt die Überladungsgrenze nach oben. **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je (Schaden/Energie) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 40 | 40 | Energie/Schuss 28,00 → 26,67 | +5,00 % | 8,00 | 308 | +5,0 % |
| 2 | 47 | 87 | Energie/Schuss 26,67 → 25,45 | +4,76 % | 9,87 | 362 | +10,0 % |
| 3 | 56 | 143 | Energie/Schuss 25,45 → 24,35 | +4,55 % | 12,3 | 431 | +15,0 % |
| 4 | 66 | 209 | Energie/Schuss 24,35 → 23,33 | +4,35 % | 15,2 | 508 | +20,0 % |
| 5 | 78 | 287 | Energie/Schuss 23,33 → 22,40 | +4,17 % | 18,7 | 600 | +25,0 % |
| 6 | 92 | 379 | Energie/Schuss 22,40 → 21,54 | +4,00 % | 23,0 | 708 | +30,0 % |
| 7 | 108 | 487 | Energie/Schuss 21,54 → 20,74 | +3,85 % | 28,1 | 831 | +35,0 % |
| 8 | 127 | 614 | Energie/Schuss 20,74 → 20,00 | +3,70 % | 34,3 | 977 | +40,0 % |
| 9 | 150 | 764 | Energie/Schuss 20,00 → 19,31 | +3,57 % | 42,0 | 1.154 | +45,0 % |
| 10 | 177 | 941 | Energie/Schuss 19,31 → 18,67 | +3,45 % | 51,3 | 1.362 | +50,0 % |
| 11 | 209 | 1.150 | Energie/Schuss 18,67 → 18,06 | +3,33 % | 62,7 | 1.608 | +55,0 % |
| 12 | 247 | 1.397 | Energie/Schuss 18,06 → 17,50 | +3,23 % | 76,6 | 1.900 | +60,0 % |
| 13 | 292 | 1.689 | Energie/Schuss 17,50 → 16,97 | +3,12 % | 93,4 | 2.246 | +65,0 % |
| 14 | 344 | 2.033 | Energie/Schuss 16,97 → 16,47 | +3,03 % | 114 | 2.646 | +70,0 % |
| 15 | 406 | 2.439 | Energie/Schuss 16,47 → 16,00 | +2,94 % | 138 | 3.123 | +75,0 % |
| 16 | 479 | 2.918 | Energie/Schuss 16,00 → 15,56 | +2,86 % | 168 | 3.685 | +80,0 % |
| 17 | 565 | 3.483 | Energie/Schuss 15,56 → 15,14 | +2,78 % | 203 | 4.346 | +85,0 % |
| 18 | 667 | 4.150 | Energie/Schuss 15,14 → 14,74 | +2,70 % | 247 | 5.131 | +90,0 % |
| 19 | 787 | 4.937 | Energie/Schuss 14,74 → 14,36 | +2,63 % | 299 | 6.054 | +95,0 % |
| 20 | 929 | 5.866 | Energie/Schuss 14,36 → 14,00 | +2,56 % | 362 | 7.146 | +100,0 % |

#### Plasmawerfer – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). Hebt die Grenze, ab der eine Überladung den Turm stilllegt. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 2,00 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 36 | 36 | 100,0 → 120,0 Energie | +20,00 % | 1,80 | 1,80 | +20,0 % |
| 2 | 42 | 78 | 120,0 → 140,0 Energie | +16,67 % | 2,52 | 2,10 | +40,0 % |
| 3 | 50 | 128 | 140,0 → 160,0 Energie | +14,29 % | 3,50 | 2,50 | +60,0 % |
| 4 | 59 | 187 | 160,0 → 180,0 Energie | +12,50 % | 4,72 | 2,95 | +80,0 % |
| 5 | 70 | 257 | 180,0 → 200,0 Energie | +11,11 % | 6,30 | 3,50 | +100,0 % |
| 6 | 82 | 339 | 200,0 → 220,0 Energie | +10,00 % | 8,20 | 4,10 | +120,0 % |
| 7 | 97 | 436 | 220,0 → 240,0 Energie | +9,09 % | 10,7 | 4,85 | +140,0 % |
| 8 | 115 | 551 | 240,0 → 260,0 Energie | +8,33 % | 13,8 | 5,75 | +160,0 % |
| 9 | 135 | 686 | 260,0 → 280,0 Energie | +7,69 % | 17,6 | 6,75 | +180,0 % |
| 10 | 160 | 846 | 280,0 → 300,0 Energie | +7,14 % | 22,4 | 8,00 | +200,0 % |
| 11 | 188 | 1.034 | 300,0 → 320,0 Energie | +6,67 % | 28,2 | 9,40 | +220,0 % |
| 12 | 222 | 1.256 | 320,0 → 340,0 Energie | +6,25 % | 35,5 | 11,1 | +240,0 % |
| 13 | 262 | 1.518 | 340,0 → 360,0 Energie | +5,88 % | 44,5 | 13,1 | +260,0 % |
| 14 | 310 | 1.828 | 360,0 → 380,0 Energie | +5,56 % | 55,8 | 15,5 | +280,0 % |
| 15 | 365 | 2.193 | 380,0 → 400,0 Energie | +5,26 % | 69,4 | 18,2 | +300,0 % |
| 16 | 431 | 2.624 | 400,0 → 420,0 Energie | +5,00 % | 86,2 | 21,6 | +320,0 % |
| 17 | 509 | 3.133 | 420,0 → 440,0 Energie | +4,76 % | 107 | 25,4 | +340,0 % |
| 18 | 600 | 3.733 | 440,0 → 460,0 Energie | +4,55 % | 132 | 30,0 | +360,0 % |
| 19 | 708 | 4.441 | 460,0 → 480,0 Energie | +4,35 % | 163 | 35,4 | +380,0 % |
| 20 | 836 | 5.277 | 480,0 → 500,0 Energie | +4,17 % | 201 | 41,8 | +400,0 % |
| 21 | 986 | 6.263 | 500,0 → 520,0 Energie | +4,00 % | 246 | 49,3 | +420,0 % |
| 22 | 1.164 | 7.427 | 520,0 → 540,0 Energie | +3,85 % | 303 | 58,2 | +440,0 % |
| 23 | 1.373 | 8.800 | 540,0 → 560,0 Energie | +3,70 % | 371 | 68,7 | +460,0 % |
| 24 | 1.620 | 10.420 | 560,0 → 580,0 Energie | +3,57 % | 454 | 81,0 | +480,0 % |
| 25 | 1.912 | 12.332 | 580,0 → 600,0 Energie | +3,45 % | 554 | 95,6 | +500,0 % |

#### Plasmawerfer – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 40 | 40 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 36,0 | +1,1 % |
| 2 | 47 | 87 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 42,8 | +2,2 % |
| 3 | 56 | 143 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 51,5 | +3,3 % |
| 4 | 66 | 209 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 61,4 | +4,4 % |
| 5 | 78 | 287 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 73,3 | +5,6 % |
| 6 | 92 | 379 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 87,4 | +6,7 % |
| 7 | 108 | 487 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 104 | +7,8 % |
| 8 | 127 | 614 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 123 | +8,9 % |
| 9 | 150 | 764 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 147 | +10,0 % |
| 10 | 177 | 941 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 175 | +11,1 % |

#### Plasmawerfer – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,818 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 36 | 36 | 110,0 → 126,5 HP | +15,00 % | 2,40 | 2,182 | +15,0 % |
| 2 | 42 | 78 | 126,5 → 143,0 HP | +13,04 % | 3,22 | 2,545 | +30,0 % |
| 3 | 50 | 128 | 143,0 → 159,5 HP | +11,54 % | 4,33 | 3,030 | +45,0 % |
| 4 | 59 | 187 | 159,5 → 176,0 HP | +10,34 % | 5,70 | 3,576 | +60,0 % |
| 5 | 70 | 257 | 176,0 → 192,5 HP | +9,38 % | 7,47 | 4,242 | +75,0 % |
| 6 | 82 | 339 | 192,5 → 209,0 HP | +8,57 % | 9,57 | 4,970 | +90,0 % |
| 7 | 97 | 436 | 209,0 → 225,5 HP | +7,89 % | 12,3 | 5,879 | +105,0 % |
| 8 | 115 | 551 | 225,5 → 242,0 HP | +7,32 % | 15,7 | 6,970 | +120,0 % |
| 9 | 135 | 686 | 242,0 → 258,5 HP | +6,82 % | 19,8 | 8,182 | +135,0 % |
| 10 | 160 | 846 | 258,5 → 275,0 HP | +6,38 % | 25,1 | 9,697 | +150,0 % |
| 11 | 188 | 1.034 | 275,0 → 291,5 HP | +6,00 % | 31,3 | 11,394 | +165,0 % |
| 12 | 222 | 1.256 | 291,5 → 308,0 HP | +5,66 % | 39,2 | 13,455 | +180,0 % |
| 13 | 262 | 1.518 | 308,0 → 324,5 HP | +5,36 % | 48,9 | 15,879 | +195,0 % |
| 14 | 310 | 1.828 | 324,5 → 341,0 HP | +5,08 % | 61,0 | 18,788 | +210,0 % |
| 15 | 365 | 2.193 | 341,0 → 357,5 HP | +4,84 % | 75,4 | 22,121 | +225,0 % |
| 16 | 431 | 2.624 | 357,5 → 374,0 HP | +4,62 % | 93,4 | 26,121 | +240,0 % |
| 17 | 509 | 3.133 | 374,0 → 390,5 HP | +4,41 % | 115 | 30,848 | +255,0 % |
| 18 | 600 | 3.733 | 390,5 → 407,0 HP | +4,23 % | 142 | 36,364 | +270,0 % |
| 19 | 708 | 4.441 | 407,0 → 423,5 HP | +4,05 % | 175 | 42,909 | +285,0 % |
| 20 | 836 | 5.277 | 423,5 → 440,0 HP | +3,90 % | 215 | 50,667 | +300,0 % |
| 21 | 986 | 6.263 | 440,0 → 456,5 HP | +3,75 % | 263 | 59,758 | +315,0 % |
| 22 | 1.164 | 7.427 | 456,5 → 473,0 HP | +3,61 % | 322 | 70,545 | +330,0 % |
| 23 | 1.373 | 8.800 | 473,0 → 489,5 HP | +3,49 % | 394 | 83,212 | +345,0 % |
| 24 | 1.620 | 10.420 | 489,5 → 506,0 HP | +3,37 % | 481 | 98,182 | +360,0 % |
| 25 | 1.912 | 12.332 | 506,0 → 522,5 HP | +3,26 % | 586 | 115,879 | +375,0 % |
| 26 | 2.256 | 14.588 | 522,5 → 539,0 HP | +3,16 % | 714 | 136,727 | +390,0 % |
| 27 | 2.662 | 17.250 | 539,0 → 555,5 HP | +3,06 % | 870 | 161,333 | +405,0 % |
| 28 | 3.141 | 20.391 | 555,5 → 572,0 HP | +2,97 % | 1.057 | 190,364 | +420,0 % |
| 29 | 3.707 | 24.098 | 572,0 → 588,5 HP | +2,88 % | 1.285 | 224,667 | +435,0 % |
| 30 | 4.374 | 28.472 | 588,5 → 605,0 HP | +2,80 % | 1.560 | 265,091 | +450,0 % |

#### Plasmawerfer – Panzerung

**Verändert:** Panzerung. Jeder erlittene Treffer sinkt um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Nutzen gemessen an den effektiven Lebenspunkten (Leben ÷ (1 − Reduktion)) mit Grund-Leben, ohne Mindestschaden. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,65 Münzen je eff. HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eff. HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 30 | 30 | Panzerung 10,0 → 11,5 (−9,1 % → −10,3 %) | +1,36 % | 22,0 | 18,2 | +1,4 % |
| 2 | 35 | 65 | Panzerung 11,5 → 13,0 (−10,3 % → −11,5 %) | +1,35 % | 26,0 | 21,2 | +2,7 % |
| 3 | 42 | 107 | Panzerung 13,0 → 14,5 (−11,5 % → −12,7 %) | +1,33 % | 31,6 | 25,5 | +4,1 % |
| 4 | 49 | 156 | Panzerung 14,5 → 16,0 (−12,7 % → −13,8 %) | +1,31 % | 37,4 | 29,7 | +5,5 % |
| 5 | 58 | 214 | Panzerung 16,0 → 17,5 (−13,8 % → −14,9 %) | +1,29 % | 44,9 | 35,2 | +6,8 % |
| 6 | 69 | 283 | Panzerung 17,5 → 19,0 (−14,9 % → −16,0 %) | +1,28 % | 54,0 | 41,8 | +8,2 % |
| 7 | 81 | 364 | Panzerung 19,0 → 20,5 (−16,0 % → −17,0 %) | +1,26 % | 64,3 | 49,1 | +9,5 % |
| 8 | 96 | 460 | Panzerung 20,5 → 22,0 (−17,0 % → −18,0 %) | +1,24 % | 77,1 | 58,2 | +10,9 % |
| 9 | 113 | 573 | Panzerung 22,0 → 23,5 (−18,0 % → −19,0 %) | +1,23 % | 91,9 | 68,5 | +12,3 % |
| 10 | 133 | 706 | Panzerung 23,5 → 25,0 (−19,0 % → −20,0 %) | +1,21 % | 110 | 80,6 | +13,6 % |
| 11 | 157 | 863 | Panzerung 25,0 → 26,5 (−20,0 % → −20,9 %) | +1,20 % | 131 | 95,2 | +15,0 % |
| 12 | 185 | 1.048 | Panzerung 26,5 → 28,0 (−20,9 % → −21,9 %) | +1,19 % | 156 | 112 | +16,4 % |
| 13 | 219 | 1.267 | Panzerung 28,0 → 29,5 (−21,9 % → −22,8 %) | +1,17 % | 187 | 133 | +17,7 % |
| 14 | 258 | 1.525 | Panzerung 29,5 → 31,0 (−22,8 % → −23,7 %) | +1,16 % | 223 | 156 | +19,1 % |
| 15 | 304 | 1.829 | Panzerung 31,0 → 32,5 (−23,7 % → −24,5 %) | +1,15 % | 265 | 184 | +20,5 % |
| 16 | 359 | 2.188 | Panzerung 32,5 → 34,0 (−24,5 % → −25,4 %) | +1,13 % | 317 | 218 | +21,8 % |
| 17 | 424 | 2.612 | Panzerung 34,0 → 35,5 (−25,4 % → −26,2 %) | +1,12 % | 379 | 257 | +23,2 % |
| 18 | 500 | 3.112 | Panzerung 35,5 → 37,0 (−26,2 % → −27,0 %) | +1,11 % | 452 | 303 | +24,5 % |
| 19 | 590 | 3.702 | Panzerung 37,0 → 38,5 (−27,0 % → −27,8 %) | +1,09 % | 539 | 358 | +25,9 % |
| 20 | 696 | 4.398 | Panzerung 38,5 → 40,0 (−27,8 % → −28,6 %) | +1,08 % | 643 | 422 | +27,3 % |

## Verteidigung

### Bollwerk

- **Freischaltung:** von Anfang an
- **Baukosten:** 4 (+1 je 6 gebaute) · **Upgrade-Basis:** 40
- **Grundwerte:** 1.600 HP · Panzerung 40 · Kapazität 12 · Selbstreparatur 5 HP/s für 0,4 Energie/s

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Leben | 8 | 5 | 251 | 580 | +32.049 % | 0,0250 → 2,93 |

#### Bollwerk – Leben

**Verändert:** Maximale Trefferpunkte. Eigene Kurve: Multiplikator 1 + 2 × (1,85^Stufe − 1) / 0,85, Preiswachstum 1,75 je Stufe – jede Stufe ist effizienter als die vorige. Die Selbstreparatur bleibt bei 5 HP/s. **Je Stufe:** wachsend (×3 bis ×37,5).

Neubau zum Vergleich: 0,0025 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 1.600 → 4.800 HP | +200,00 % | 0,0250 | 0,0016 | +200,0 % |
| 2 | 9 | 14 | 4.800 → 10.720 HP | +123,33 % | 0,0730 | 0,0015 | +570,0 % |
| 3 | 15 | 29 | 10.720 → 21.672 HP | +102,16 % | 0,15 | 0,0014 | +1.254,5 % |
| 4 | 27 | 56 | 21.672 → 41.933 HP | +93,49 % | 0,29 | 0,0013 | +2.520,8 % |
| 5 | 47 | 103 | 41.933 → 79.416 HP | +89,39 % | 0,53 | 0,0013 | +4.863,5 % |
| 6 | 82 | 185 | 79.416 → 148.760 HP | +87,32 % | 0,94 | 0,0012 | +9.197,5 % |
| 7 | 144 | 329 | 148.760 → 277.047 HP | +86,24 % | 1,67 | 0,0011 | +17.215,4 % |
| 8 | 251 | 580 | 277.047 → 514.376 HP | +85,66 % | 2,93 | 0,0011 | +32.048,5 % |

### Bollwerk-Turm

- **Freischaltung:** Forschung „Bollwerk-Turm“ (2 SP)
- **Baukosten:** 130 · **Upgrade-Basis:** 130
- **Grundwerte:** 900 HP · Panzerung 50 · Kapazität 60 · 14 Schaden alle 0,50 s, 3 Energie/Schuss, Reichweite 4,29 Felder · DPS 31,4 (Ø inkl. 12 % Krit)

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Schaden | 40 | 29 | 18.187 | 119.067 | +400 % | 2,90 → 8.912 |
| Feuerrate | 25 | 33 | 1.726 | 11.134 | +150 % | 5,50 → 702 |
| Reichweite | 15 | 39 | 396 | 2.377 | +60 % | 9,75 → 154 |
| Kritische Treffer | 20 | 33 | 754 | 4.764 | +18 % | 37,0 → 988 |
| Effizienz | 20 | 26 | 604 | 3.812 | +100 % | 5,20 → 236 |
| Kapazität | 25 | 23 | 1.243 | 8.017 | +500 % | 1,15 → 360 |
| Strahlübertragung | 10 | 26 | 115 | 611 | +11 % | 23,4 → 114 |
| Leben | 30 | 23 | 2.843 | 18.507 | +450 % | 1,53 → 1.014 |
| Panzerung | 20 | 20 | 453 | 2.860 | +100 % | 4,00 → 177 |

#### Bollwerk-Turm – Schaden

**Verändert:** Schaden je Schuss (Laser: je Sekunde). **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 4,15 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 29 | 29 | Schaden/Schuss 14,0 → 15,4 | +10,00 % | 2,90 | 9,25 | +10,0 % |
| 2 | 34 | 63 | Schaden/Schuss 15,4 → 16,8 | +9,09 % | 3,74 | 10,8 | +20,0 % |
| 3 | 40 | 103 | Schaden/Schuss 16,8 → 18,2 | +8,33 % | 4,80 | 12,8 | +30,0 % |
| 4 | 47 | 150 | Schaden/Schuss 18,2 → 19,6 | +7,69 % | 6,11 | 15,0 | +40,0 % |
| 5 | 55 | 205 | Schaden/Schuss 19,6 → 21,0 | +7,14 % | 7,70 | 17,5 | +50,0 % |
| 6 | 65 | 270 | Schaden/Schuss 21,0 → 22,4 | +6,67 % | 9,75 | 20,7 | +60,0 % |
| 7 | 77 | 347 | Schaden/Schuss 22,4 → 23,8 | +6,25 % | 12,3 | 24,6 | +70,0 % |
| 8 | 91 | 438 | Schaden/Schuss 23,8 → 25,2 | +5,88 % | 15,5 | 29,0 | +80,0 % |
| 9 | 108 | 546 | Schaden/Schuss 25,2 → 26,6 | +5,56 % | 19,4 | 34,4 | +90,0 % |
| 10 | 127 | 673 | Schaden/Schuss 26,6 → 28,0 | +5,26 % | 24,1 | 40,5 | +100,0 % |
| 11 | 150 | 823 | Schaden/Schuss 28,0 → 29,4 | +5,00 % | 30,0 | 47,8 | +110,0 % |
| 12 | 177 | 1.000 | Schaden/Schuss 29,4 → 30,8 | +4,76 % | 37,2 | 56,4 | +120,0 % |
| 13 | 208 | 1.208 | Schaden/Schuss 30,8 → 32,2 | +4,55 % | 45,8 | 66,3 | +130,0 % |
| 14 | 246 | 1.454 | Schaden/Schuss 32,2 → 33,6 | +4,35 % | 56,6 | 78,4 | +140,0 % |
| 15 | 290 | 1.744 | Schaden/Schuss 33,6 → 35,0 | +4,17 % | 69,6 | 92,5 | +150,0 % |
| 16 | 342 | 2.086 | Schaden/Schuss 35,0 → 36,4 | +4,00 % | 85,5 | 109 | +160,0 % |
| 17 | 404 | 2.490 | Schaden/Schuss 36,4 → 37,8 | +3,85 % | 105 | 129 | +170,0 % |
| 18 | 477 | 2.967 | Schaden/Schuss 37,8 → 39,2 | +3,70 % | 129 | 152 | +180,0 % |
| 19 | 563 | 3.530 | Schaden/Schuss 39,2 → 40,6 | +3,57 % | 158 | 180 | +190,0 % |
| 20 | 664 | 4.194 | Schaden/Schuss 40,6 → 42,0 | +3,45 % | 193 | 212 | +200,0 % |
| 21 | 783 | 4.977 | Schaden/Schuss 42,0 → 43,4 | +3,33 % | 235 | 250 | +210,0 % |
| 22 | 924 | 5.901 | Schaden/Schuss 43,4 → 44,8 | +3,23 % | 286 | 295 | +220,0 % |
| 23 | 1.091 | 6.992 | Schaden/Schuss 44,8 → 46,2 | +3,12 % | 349 | 348 | +230,0 % |
| 24 | 1.287 | 8.279 | Schaden/Schuss 46,2 → 47,6 | +3,03 % | 425 | 410 | +240,0 % |
| 25 | 1.519 | 9.798 | Schaden/Schuss 47,6 → 49,0 | +2,94 % | 516 | 484 | +250,0 % |
| 26 | 1.792 | 11.590 | Schaden/Schuss 49,0 → 50,4 | +2,86 % | 627 | 571 | +260,0 % |
| 27 | 2.115 | 13.705 | Schaden/Schuss 50,4 → 51,8 | +2,78 % | 761 | 674 | +270,0 % |
| 28 | 2.496 | 16.201 | Schaden/Schuss 51,8 → 53,2 | +2,70 % | 924 | 796 | +280,0 % |
| 29 | 2.945 | 19.146 | Schaden/Schuss 53,2 → 54,6 | +2,63 % | 1.119 | 939 | +290,0 % |
| 30 | 3.475 | 22.621 | Schaden/Schuss 54,6 → 56,0 | +2,56 % | 1.355 | 1.108 | +300,0 % |
| 31 | 4.100 | 26.721 | Schaden/Schuss 56,0 → 57,4 | +2,50 % | 1.640 | 1.307 | +310,0 % |
| 32 | 4.838 | 31.559 | Schaden/Schuss 57,4 → 58,8 | +2,44 % | 1.984 | 1.543 | +320,0 % |
| 33 | 5.709 | 37.268 | Schaden/Schuss 58,8 → 60,2 | +2,38 % | 2.398 | 1.820 | +330,0 % |
| 34 | 6.737 | 44.005 | Schaden/Schuss 60,2 → 61,6 | +2,33 % | 2.897 | 2.148 | +340,0 % |
| 35 | 7.950 | 51.955 | Schaden/Schuss 61,6 → 63,0 | +2,27 % | 3.498 | 2.535 | +350,0 % |
| 36 | 9.381 | 61.336 | Schaden/Schuss 63,0 → 64,4 | +2,22 % | 4.221 | 2.991 | +360,0 % |
| 37 | 11.069 | 72.405 | Schaden/Schuss 64,4 → 65,8 | +2,17 % | 5.092 | 3.530 | +370,0 % |
| 38 | 13.062 | 85.467 | Schaden/Schuss 65,8 → 67,2 | +2,13 % | 6.139 | 4.165 | +380,0 % |
| 39 | 15.413 | 100.880 | Schaden/Schuss 67,2 → 68,6 | +2,08 % | 7.398 | 4.915 | +390,0 % |
| 40 | 18.187 | 119.067 | Schaden/Schuss 68,6 → 70,0 | +2,04 % | 8.912 | 5.799 | +400,0 % |

#### Bollwerk-Turm – Feuerrate

**Verändert:** Abklingzeit zwischen zwei Schüssen (Feuerrate = 1 ÷ Abklingzeit). Mehr Schüsse brauchen entsprechend mehr Energie pro Sekunde. **Je Stufe:** +6 % Feuerrate.

Neubau zum Vergleich: 4,15 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 33 | 33 | 0,500 → 0,472 s (2,12 Schüsse/s) | +6,00 % | 5,50 | 17,5 | +6,0 % |
| 2 | 38 | 71 | 0,472 → 0,446 s (2,24 Schüsse/s) | +5,66 % | 6,71 | 20,2 | +12,0 % |
| 3 | 45 | 116 | 0,446 → 0,424 s (2,36 Schüsse/s) | +5,36 % | 8,40 | 23,9 | +18,0 % |
| 4 | 53 | 169 | 0,424 → 0,403 s (2,48 Schüsse/s) | +5,08 % | 10,4 | 28,2 | +24,0 % |
| 5 | 63 | 232 | 0,403 → 0,385 s (2,60 Schüsse/s) | +4,84 % | 13,0 | 33,5 | +30,0 % |
| 6 | 74 | 306 | 0,385 → 0,368 s (2,72 Schüsse/s) | +4,62 % | 16,0 | 39,3 | +36,0 % |
| 7 | 88 | 394 | 0,368 → 0,352 s (2,84 Schüsse/s) | +4,41 % | 19,9 | 46,8 | +42,0 % |
| 8 | 104 | 498 | 0,352 → 0,338 s (2,96 Schüsse/s) | +4,23 % | 24,6 | 55,3 | +48,0 % |
| 9 | 122 | 620 | 0,338 → 0,325 s (3,08 Schüsse/s) | +4,05 % | 30,1 | 64,8 | +54,0 % |
| 10 | 144 | 764 | 0,325 → 0,312 s (3,20 Schüsse/s) | +3,90 % | 37,0 | 76,5 | +60,0 % |
| 11 | 170 | 934 | 0,312 → 0,301 s (3,32 Schüsse/s) | +3,75 % | 45,3 | 90,3 | +66,0 % |
| 12 | 201 | 1.135 | 0,301 → 0,291 s (3,44 Schüsse/s) | +3,61 % | 55,6 | 107 | +72,0 % |
| 13 | 237 | 1.372 | 0,291 → 0,281 s (3,56 Schüsse/s) | +3,49 % | 67,9 | 126 | +78,0 % |
| 14 | 279 | 1.651 | 0,281 → 0,272 s (3,68 Schüsse/s) | +3,37 % | 82,8 | 148 | +84,0 % |
| 15 | 330 | 1.981 | 0,272 → 0,263 s (3,80 Schüsse/s) | +3,26 % | 101 | 175 | +90,0 % |
| 16 | 389 | 2.370 | 0,263 → 0,255 s (3,92 Schüsse/s) | +3,16 % | 123 | 207 | +96,0 % |
| 17 | 459 | 2.829 | 0,255 → 0,248 s (4,04 Schüsse/s) | +3,06 % | 150 | 244 | +102,0 % |
| 18 | 542 | 3.371 | 0,248 → 0,240 s (4,16 Schüsse/s) | +2,97 % | 182 | 288 | +108,0 % |
| 19 | 639 | 4.010 | 0,240 → 0,234 s (4,28 Schüsse/s) | +2,88 % | 222 | 340 | +114,0 % |
| 20 | 754 | 4.764 | 0,234 → 0,227 s (4,40 Schüsse/s) | +2,80 % | 269 | 401 | +120,0 % |
| 21 | 890 | 5.654 | 0,227 → 0,221 s (4,52 Schüsse/s) | +2,73 % | 326 | 473 | +126,0 % |
| 22 | 1.051 | 6.705 | 0,221 → 0,216 s (4,64 Schüsse/s) | +2,65 % | 396 | 559 | +132,0 % |
| 23 | 1.240 | 7.945 | 0,216 → 0,210 s (4,76 Schüsse/s) | +2,59 % | 479 | 659 | +138,0 % |
| 24 | 1.463 | 9.408 | 0,210 → 0,205 s (4,88 Schüsse/s) | +2,52 % | 580 | 778 | +144,0 % |
| 25 | 1.726 | 11.134 | 0,205 → 0,200 s (5,00 Schüsse/s) | +2,46 % | 702 | 917 | +150,0 % |

#### Bollwerk-Turm – Reichweite

**Verändert:** Angriffsreichweite (und damit Sichtweite). Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 39 | 39 | 4,29 → 4,46 Felder | +4,00 % | 9,75 | 227 | +4,0 % |
| 2 | 46 | 85 | 4,46 → 4,63 Felder | +3,85 % | 12,0 | 268 | +8,0 % |
| 3 | 54 | 139 | 4,63 → 4,80 Felder | +3,70 % | 14,6 | 315 | +12,0 % |
| 4 | 64 | 203 | 4,80 → 4,97 Felder | +3,57 % | 17,9 | 373 | +16,0 % |
| 5 | 76 | 279 | 4,97 → 5,14 Felder | +3,45 % | 22,0 | 443 | +20,0 % |
| 6 | 89 | 368 | 5,14 → 5,31 Felder | +3,33 % | 26,7 | 519 | +24,0 % |
| 7 | 105 | 473 | 5,31 → 5,49 Felder | +3,23 % | 32,6 | 613 | +28,0 % |
| 8 | 124 | 597 | 5,49 → 5,66 Felder | +3,12 % | 39,7 | 723 | +32,0 % |
| 9 | 147 | 744 | 5,66 → 5,83 Felder | +3,03 % | 48,5 | 858 | +36,0 % |
| 10 | 173 | 917 | 5,83 → 6,00 Felder | +2,94 % | 58,8 | 1.009 | +40,0 % |
| 11 | 204 | 1.121 | 6,00 → 6,17 Felder | +2,86 % | 71,4 | 1.190 | +44,0 % |
| 12 | 241 | 1.362 | 6,17 → 6,34 Felder | +2,78 % | 86,8 | 1.406 | +48,0 % |
| 13 | 284 | 1.646 | 6,34 → 6,51 Felder | +2,70 % | 105 | 1.657 | +52,0 % |
| 14 | 335 | 1.981 | 6,51 → 6,69 Felder | +2,63 % | 127 | 1.954 | +56,0 % |
| 15 | 396 | 2.377 | 6,69 → 6,86 Felder | +2,56 % | 154 | 2.310 | +60,0 % |

#### Bollwerk-Turm – Kritische Treffer

**Verändert:** Chance auf einen kritischen Treffer (doppelter Schaden). Nutzen = Anstieg des durchschnittlichen Schadens (1 + Krit-Chance). **Je Stufe:** +1 Prozentpunkt.

Neubau zum Vergleich: 4,15 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 33 | 33 | Krit-Chance 12 % → 13 % | +0,89 % | 37,0 | 118 | +0,9 % |
| 2 | 38 | 71 | Krit-Chance 13 % → 14 % | +0,88 % | 42,9 | 136 | +1,8 % |
| 3 | 45 | 116 | Krit-Chance 14 % → 15 % | +0,88 % | 51,3 | 161 | +2,7 % |
| 4 | 53 | 169 | Krit-Chance 15 % → 16 % | +0,87 % | 61,0 | 189 | +3,6 % |
| 5 | 63 | 232 | Krit-Chance 16 % → 17 % | +0,86 % | 73,1 | 225 | +4,5 % |
| 6 | 74 | 306 | Krit-Chance 17 % → 18 % | +0,85 % | 86,6 | 264 | +5,4 % |
| 7 | 88 | 394 | Krit-Chance 18 % → 19 % | +0,85 % | 104 | 314 | +6,2 % |
| 8 | 104 | 498 | Krit-Chance 19 % → 20 % | +0,84 % | 124 | 371 | +7,1 % |
| 9 | 122 | 620 | Krit-Chance 20 % → 21 % | +0,83 % | 146 | 436 | +8,0 % |
| 10 | 144 | 764 | Krit-Chance 21 % → 22 % | +0,83 % | 174 | 514 | +8,9 % |
| 11 | 170 | 934 | Krit-Chance 22 % → 23 % | +0,82 % | 207 | 607 | +9,8 % |
| 12 | 201 | 1.135 | Krit-Chance 23 % → 24 % | +0,81 % | 247 | 718 | +10,7 % |
| 13 | 237 | 1.372 | Krit-Chance 24 % → 25 % | +0,81 % | 294 | 846 | +11,6 % |
| 14 | 279 | 1.651 | Krit-Chance 25 % → 26 % | +0,80 % | 349 | 996 | +12,5 % |
| 15 | 330 | 1.981 | Krit-Chance 26 % → 27 % | +0,79 % | 416 | 1.179 | +13,4 % |
| 16 | 389 | 2.370 | Krit-Chance 27 % → 28 % | +0,79 % | 494 | 1.389 | +14,3 % |
| 17 | 459 | 2.829 | Krit-Chance 28 % → 29 % | +0,78 % | 588 | 1.639 | +15,2 % |
| 18 | 542 | 3.371 | Krit-Chance 29 % → 30 % | +0,78 % | 699 | 1.936 | +16,1 % |
| 19 | 639 | 4.010 | Krit-Chance 30 % → 31 % | +0,77 % | 831 | 2.282 | +17,0 % |
| 20 | 754 | 4.764 | Krit-Chance 31 % → 32 % | +0,76 % | 988 | 2.693 | +17,9 % |

#### Bollwerk-Turm – Effizienz

**Verändert:** Senkt die Energie je Schuss (Energie ÷ Effizienz). **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je (Schaden/Energie) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 26 | 26 | Energie/Schuss 3,00 → 2,86 | +5,00 % | 5,20 | 99,5 | +5,0 % |
| 2 | 31 | 57 | Energie/Schuss 2,86 → 2,73 | +4,76 % | 6,51 | 119 | +10,0 % |
| 3 | 36 | 93 | Energie/Schuss 2,73 → 2,61 | +4,55 % | 7,92 | 138 | +15,0 % |
| 4 | 43 | 136 | Energie/Schuss 2,61 → 2,50 | +4,35 % | 9,89 | 165 | +20,0 % |
| 5 | 50 | 186 | Energie/Schuss 2,50 → 2,40 | +4,17 % | 12,0 | 191 | +25,0 % |
| 6 | 59 | 245 | Energie/Schuss 2,40 → 2,31 | +4,00 % | 14,7 | 226 | +30,0 % |
| 7 | 70 | 315 | Energie/Schuss 2,31 → 2,22 | +3,85 % | 18,2 | 268 | +35,0 % |
| 8 | 83 | 398 | Energie/Schuss 2,22 → 2,14 | +3,70 % | 22,4 | 318 | +40,0 % |
| 9 | 98 | 496 | Energie/Schuss 2,14 → 2,07 | +3,57 % | 27,4 | 375 | +45,0 % |
| 10 | 115 | 611 | Energie/Schuss 2,07 → 2,00 | +3,45 % | 33,3 | 440 | +50,0 % |
| 11 | 136 | 747 | Energie/Schuss 2,00 → 1,94 | +3,33 % | 40,8 | 520 | +55,0 % |
| 12 | 161 | 908 | Energie/Schuss 1,94 → 1,88 | +3,23 % | 49,9 | 616 | +60,0 % |
| 13 | 189 | 1.097 | Energie/Schuss 1,88 → 1,82 | +3,12 % | 60,5 | 723 | +65,0 % |
| 14 | 224 | 1.321 | Energie/Schuss 1,82 → 1,76 | +3,03 % | 73,9 | 857 | +70,0 % |
| 15 | 264 | 1.585 | Energie/Schuss 1,76 → 1,71 | +2,94 % | 89,8 | 1.010 | +75,0 % |
| 16 | 311 | 1.896 | Energie/Schuss 1,71 → 1,67 | +2,86 % | 109 | 1.190 | +80,0 % |
| 17 | 367 | 2.263 | Energie/Schuss 1,67 → 1,62 | +2,78 % | 132 | 1.404 | +85,0 % |
| 18 | 433 | 2.696 | Energie/Schuss 1,62 → 1,58 | +2,70 % | 160 | 1.657 | +90,0 % |
| 19 | 512 | 3.208 | Energie/Schuss 1,58 → 1,54 | +2,63 % | 195 | 1.959 | +95,0 % |
| 20 | 604 | 3.812 | Energie/Schuss 1,54 → 1,50 | +2,56 % | 236 | 2.311 | +100,0 % |

#### Bollwerk-Turm – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). Hebt die Grenze, ab der eine Überladung den Turm stilllegt. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 2,17 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 23 | 23 | 60,0 → 72,0 Energie | +20,00 % | 1,15 | 1,92 | +20,0 % |
| 2 | 28 | 51 | 72,0 → 84,0 Energie | +16,67 % | 1,68 | 2,33 | +40,0 % |
| 3 | 33 | 84 | 84,0 → 96,0 Energie | +14,29 % | 2,31 | 2,75 | +60,0 % |
| 4 | 38 | 122 | 96,0 → 108,0 Energie | +12,50 % | 3,04 | 3,17 | +80,0 % |
| 5 | 45 | 167 | 108,0 → 120,0 Energie | +11,11 % | 4,05 | 3,75 | +100,0 % |
| 6 | 54 | 221 | 120,0 → 132,0 Energie | +10,00 % | 5,40 | 4,50 | +120,0 % |
| 7 | 63 | 284 | 132,0 → 144,0 Energie | +9,09 % | 6,93 | 5,25 | +140,0 % |
| 8 | 75 | 359 | 144,0 → 156,0 Energie | +8,33 % | 9,00 | 6,25 | +160,0 % |
| 9 | 88 | 447 | 156,0 → 168,0 Energie | +7,69 % | 11,4 | 7,33 | +180,0 % |
| 10 | 104 | 551 | 168,0 → 180,0 Energie | +7,14 % | 14,6 | 8,67 | +200,0 % |
| 11 | 122 | 673 | 180,0 → 192,0 Energie | +6,67 % | 18,3 | 10,2 | +220,0 % |
| 12 | 145 | 818 | 192,0 → 204,0 Energie | +6,25 % | 23,2 | 12,1 | +240,0 % |
| 13 | 171 | 989 | 204,0 → 216,0 Energie | +5,88 % | 29,1 | 14,3 | +260,0 % |
| 14 | 201 | 1.190 | 216,0 → 228,0 Energie | +5,56 % | 36,2 | 16,7 | +280,0 % |
| 15 | 237 | 1.427 | 228,0 → 240,0 Energie | +5,26 % | 45,0 | 19,8 | +300,0 % |
| 16 | 280 | 1.707 | 240,0 → 252,0 Energie | +5,00 % | 56,0 | 23,3 | +320,0 % |
| 17 | 331 | 2.038 | 252,0 → 264,0 Energie | +4,76 % | 69,5 | 27,6 | +340,0 % |
| 18 | 390 | 2.428 | 264,0 → 276,0 Energie | +4,55 % | 85,8 | 32,5 | +360,0 % |
| 19 | 460 | 2.888 | 276,0 → 288,0 Energie | +4,35 % | 106 | 38,3 | +380,0 % |
| 20 | 543 | 3.431 | 288,0 → 300,0 Energie | +4,17 % | 130 | 45,3 | +400,0 % |
| 21 | 641 | 4.072 | 300,0 → 312,0 Energie | +4,00 % | 160 | 53,4 | +420,0 % |
| 22 | 756 | 4.828 | 312,0 → 324,0 Energie | +3,85 % | 197 | 63,0 | +440,0 % |
| 23 | 893 | 5.721 | 324,0 → 336,0 Energie | +3,70 % | 241 | 74,4 | +460,0 % |
| 24 | 1.053 | 6.774 | 336,0 → 348,0 Energie | +3,57 % | 295 | 87,8 | +480,0 % |
| 25 | 1.243 | 8.017 | 348,0 → 360,0 Energie | +3,45 % | 360 | 104 | +500,0 % |

#### Bollwerk-Turm – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 26 | 26 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 23,4 | +1,1 % |
| 2 | 31 | 57 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 28,2 | +2,2 % |
| 3 | 36 | 93 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 33,1 | +3,3 % |
| 4 | 43 | 136 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 40,0 | +4,4 % |
| 5 | 50 | 186 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 47,0 | +5,6 % |
| 6 | 59 | 245 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 56,0 | +6,7 % |
| 7 | 70 | 315 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 67,2 | +7,8 % |
| 8 | 83 | 398 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 80,5 | +8,9 % |
| 9 | 98 | 496 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 96,0 | +10,0 % |
| 10 | 115 | 611 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 114 | +11,1 % |

#### Bollwerk-Turm – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,144 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 23 | 23 | 900,0 → 1.035,0 HP | +15,00 % | 1,53 | 0,170 | +15,0 % |
| 2 | 28 | 51 | 1.035,0 → 1.170,0 HP | +13,04 % | 2,15 | 0,207 | +30,0 % |
| 3 | 33 | 84 | 1.170,0 → 1.305,0 HP | +11,54 % | 2,86 | 0,244 | +45,0 % |
| 4 | 38 | 122 | 1.305,0 → 1.440,0 HP | +10,34 % | 3,67 | 0,281 | +60,0 % |
| 5 | 45 | 167 | 1.440,0 → 1.575,0 HP | +9,38 % | 4,80 | 0,333 | +75,0 % |
| 6 | 54 | 221 | 1.575,0 → 1.710,0 HP | +8,57 % | 6,30 | 0,400 | +90,0 % |
| 7 | 63 | 284 | 1.710,0 → 1.845,0 HP | +7,89 % | 7,98 | 0,467 | +105,0 % |
| 8 | 75 | 359 | 1.845,0 → 1.980,0 HP | +7,32 % | 10,2 | 0,556 | +120,0 % |
| 9 | 88 | 447 | 1.980,0 → 2.115,0 HP | +6,82 % | 12,9 | 0,652 | +135,0 % |
| 10 | 104 | 551 | 2.115,0 → 2.250,0 HP | +6,38 % | 16,3 | 0,770 | +150,0 % |
| 11 | 122 | 673 | 2.250,0 → 2.385,0 HP | +6,00 % | 20,3 | 0,904 | +165,0 % |
| 12 | 145 | 818 | 2.385,0 → 2.520,0 HP | +5,66 % | 25,6 | 1,074 | +180,0 % |
| 13 | 171 | 989 | 2.520,0 → 2.655,0 HP | +5,36 % | 31,9 | 1,267 | +195,0 % |
| 14 | 201 | 1.190 | 2.655,0 → 2.790,0 HP | +5,08 % | 39,5 | 1,489 | +210,0 % |
| 15 | 237 | 1.427 | 2.790,0 → 2.925,0 HP | +4,84 % | 49,0 | 1,756 | +225,0 % |
| 16 | 280 | 1.707 | 2.925,0 → 3.060,0 HP | +4,62 % | 60,7 | 2,074 | +240,0 % |
| 17 | 331 | 2.038 | 3.060,0 → 3.195,0 HP | +4,41 % | 75,0 | 2,452 | +255,0 % |
| 18 | 390 | 2.428 | 3.195,0 → 3.330,0 HP | +4,23 % | 92,3 | 2,889 | +270,0 % |
| 19 | 460 | 2.888 | 3.330,0 → 3.465,0 HP | +4,05 % | 113 | 3,407 | +285,0 % |
| 20 | 543 | 3.431 | 3.465,0 → 3.600,0 HP | +3,90 % | 139 | 4,022 | +300,0 % |
| 21 | 641 | 4.072 | 3.600,0 → 3.735,0 HP | +3,75 % | 171 | 4,748 | +315,0 % |
| 22 | 756 | 4.828 | 3.735,0 → 3.870,0 HP | +3,61 % | 209 | 5,600 | +330,0 % |
| 23 | 893 | 5.721 | 3.870,0 → 4.005,0 HP | +3,49 % | 256 | 6,615 | +345,0 % |
| 24 | 1.053 | 6.774 | 4.005,0 → 4.140,0 HP | +3,37 % | 312 | 7,800 | +360,0 % |
| 25 | 1.243 | 8.017 | 4.140,0 → 4.275,0 HP | +3,26 % | 381 | 9,207 | +375,0 % |
| 26 | 1.466 | 9.483 | 4.275,0 → 4.410,0 HP | +3,16 % | 464 | 10,859 | +390,0 % |
| 27 | 1.730 | 11.213 | 4.410,0 → 4.545,0 HP | +3,06 % | 565 | 12,815 | +405,0 % |
| 28 | 2.042 | 13.255 | 4.545,0 → 4.680,0 HP | +2,97 % | 687 | 15,126 | +420,0 % |
| 29 | 2.409 | 15.664 | 4.680,0 → 4.815,0 HP | +2,88 % | 835 | 17,844 | +435,0 % |
| 30 | 2.843 | 18.507 | 4.815,0 → 4.950,0 HP | +2,80 % | 1.014 | 21,059 | +450,0 % |

#### Bollwerk-Turm – Panzerung

**Verändert:** Panzerung. Jeder erlittene Treffer sinkt um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Nutzen gemessen an den effektiven Lebenspunkten (Leben ÷ (1 − Reduktion)) mit Grund-Leben, ohne Mindestschaden. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,0963 Münzen je eff. HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eff. HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 20 | 20 | Panzerung 50,0 → 57,5 (−33,3 % → −36,5 %) | +5,00 % | 4,00 | 0,30 | +5,0 % |
| 2 | 23 | 43 | Panzerung 57,5 → 65,0 (−36,5 % → −39,4 %) | +4,76 % | 4,83 | 0,34 | +10,0 % |
| 3 | 27 | 70 | Panzerung 65,0 → 72,5 (−39,4 % → −42,0 %) | +4,55 % | 5,94 | 0,40 | +15,0 % |
| 4 | 32 | 102 | Panzerung 72,5 → 80,0 (−42,0 % → −44,4 %) | +4,35 % | 7,36 | 0,47 | +20,0 % |
| 5 | 38 | 140 | Panzerung 80,0 → 87,5 (−44,4 % → −46,7 %) | +4,17 % | 9,12 | 0,56 | +25,0 % |
| 6 | 45 | 185 | Panzerung 87,5 → 95,0 (−46,7 % → −48,7 %) | +4,00 % | 11,2 | 0,67 | +30,0 % |
| 7 | 53 | 238 | Panzerung 95,0 → 102,5 (−48,7 % → −50,6 %) | +3,85 % | 13,8 | 0,79 | +35,0 % |
| 8 | 62 | 300 | Panzerung 102,5 → 110,0 (−50,6 % → −52,4 %) | +3,70 % | 16,7 | 0,92 | +40,0 % |
| 9 | 73 | 373 | Panzerung 110,0 → 117,5 (−52,4 % → −54,0 %) | +3,57 % | 20,4 | 1,08 | +45,0 % |
| 10 | 86 | 459 | Panzerung 117,5 → 125,0 (−54,0 % → −55,6 %) | +3,45 % | 24,9 | 1,27 | +50,0 % |
| 11 | 102 | 561 | Panzerung 125,0 → 132,5 (−55,6 % → −57,0 %) | +3,33 % | 30,6 | 1,51 | +55,0 % |
| 12 | 120 | 681 | Panzerung 132,5 → 140,0 (−57,0 % → −58,3 %) | +3,23 % | 37,2 | 1,78 | +60,0 % |
| 13 | 142 | 823 | Panzerung 140,0 → 147,5 (−58,3 % → −59,6 %) | +3,12 % | 45,4 | 2,10 | +65,0 % |
| 14 | 168 | 991 | Panzerung 147,5 → 155,0 (−59,6 % → −60,8 %) | +3,03 % | 55,4 | 2,49 | +70,0 % |
| 15 | 198 | 1.189 | Panzerung 155,0 → 162,5 (−60,8 % → −61,9 %) | +2,94 % | 67,3 | 2,93 | +75,0 % |
| 16 | 233 | 1.422 | Panzerung 162,5 → 170,0 (−61,9 % → −63,0 %) | +2,86 % | 81,6 | 3,45 | +80,0 % |
| 17 | 276 | 1.698 | Panzerung 170,0 → 177,5 (−63,0 % → −64,0 %) | +2,78 % | 99,4 | 4,09 | +85,0 % |
| 18 | 325 | 2.023 | Panzerung 177,5 → 185,0 (−64,0 % → −64,9 %) | +2,70 % | 120 | 4,81 | +90,0 % |
| 19 | 384 | 2.407 | Panzerung 185,0 → 192,5 (−64,9 % → −65,8 %) | +2,63 % | 146 | 5,69 | +95,0 % |
| 20 | 453 | 2.860 | Panzerung 192,5 → 200,0 (−65,8 % → −66,7 %) | +2,56 % | 177 | 6,71 | +100,0 % |

### Schildgenerator

- **Freischaltung:** Forschung „Schildgenerator“ (3 SP)
- **Baukosten:** 140 · **Upgrade-Basis:** 140
- **Grundwerte:** 100 HP · Panzerung 10 · Kapazität 140 · Schildradius 3,75 Felder, Schildstärke 2 Schaden/Energie

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Schildstärke | 40 | 31 | 19.586 | 128.228 | +400 % | 3,10 → 9.597 |
| Schildradius | 15 | 42 | 426 | 2.559 | +60 % | 10,5 → 166 |
| Kapazität | 25 | 25 | 1.338 | 8.635 | +500 % | 1,25 → 388 |
| Strahlübertragung | 10 | 28 | 124 | 658 | +11 % | 25,2 → 123 |
| Leben | 30 | 25 | 3.062 | 19.934 | +450 % | 1,67 → 1.092 |

#### Schildgenerator – Schildstärke

**Verändert:** Schildstärke: abgefangener Schaden je Energie. Ein voller Speicher fängt Kapazität × Schildstärke ab. **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 0,500 Münzen je abfangbarem Schaden.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je abfangbarem Schaden | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 31 | 31 | 2,00 → 2,20 Schaden/Energie (voller Speicher 280 → 308) | +10,00 % | 3,10 | 1,107 | +10,0 % |
| 2 | 36 | 67 | 2,20 → 2,40 Schaden/Energie (voller Speicher 308 → 336) | +9,09 % | 3,96 | 1,286 | +20,0 % |
| 3 | 43 | 110 | 2,40 → 2,60 Schaden/Energie (voller Speicher 336 → 364) | +8,33 % | 5,16 | 1,536 | +30,0 % |
| 4 | 51 | 161 | 2,60 → 2,80 Schaden/Energie (voller Speicher 364 → 392) | +7,69 % | 6,63 | 1,821 | +40,0 % |
| 5 | 60 | 221 | 2,80 → 3,00 Schaden/Energie (voller Speicher 392 → 420) | +7,14 % | 8,40 | 2,143 | +50,0 % |
| 6 | 70 | 291 | 3,00 → 3,20 Schaden/Energie (voller Speicher 420 → 448) | +6,67 % | 10,5 | 2,500 | +60,0 % |
| 7 | 83 | 374 | 3,20 → 3,40 Schaden/Energie (voller Speicher 448 → 476) | +6,25 % | 13,3 | 2,964 | +70,0 % |
| 8 | 98 | 472 | 3,40 → 3,60 Schaden/Energie (voller Speicher 476 → 504) | +5,88 % | 16,7 | 3,500 | +80,0 % |
| 9 | 116 | 588 | 3,60 → 3,80 Schaden/Energie (voller Speicher 504 → 532) | +5,56 % | 20,9 | 4,143 | +90,0 % |
| 10 | 137 | 725 | 3,80 → 4,00 Schaden/Energie (voller Speicher 532 → 560) | +5,26 % | 26,0 | 4,893 | +100,0 % |
| 11 | 161 | 886 | 4,00 → 4,20 Schaden/Energie (voller Speicher 560 → 588) | +5,00 % | 32,2 | 5,750 | +110,0 % |
| 12 | 190 | 1.076 | 4,20 → 4,40 Schaden/Energie (voller Speicher 588 → 616) | +4,76 % | 39,9 | 6,786 | +120,0 % |
| 13 | 224 | 1.300 | 4,40 → 4,60 Schaden/Energie (voller Speicher 616 → 644) | +4,55 % | 49,3 | 8,000 | +130,0 % |
| 14 | 265 | 1.565 | 4,60 → 4,80 Schaden/Energie (voller Speicher 644 → 672) | +4,35 % | 60,9 | 9,464 | +140,0 % |
| 15 | 313 | 1.878 | 4,80 → 5,00 Schaden/Energie (voller Speicher 672 → 700) | +4,17 % | 75,1 | 11,179 | +150,0 % |
| 16 | 369 | 2.247 | 5,00 → 5,20 Schaden/Energie (voller Speicher 700 → 728) | +4,00 % | 92,2 | 13,179 | +160,0 % |
| 17 | 435 | 2.682 | 5,20 → 5,40 Schaden/Energie (voller Speicher 728 → 756) | +3,85 % | 113 | 15,536 | +170,0 % |
| 18 | 514 | 3.196 | 5,40 → 5,60 Schaden/Energie (voller Speicher 756 → 784) | +3,70 % | 139 | 18,357 | +180,0 % |
| 19 | 606 | 3.802 | 5,60 → 5,80 Schaden/Energie (voller Speicher 784 → 812) | +3,57 % | 170 | 21,643 | +190,0 % |
| 20 | 715 | 4.517 | 5,80 → 6,00 Schaden/Energie (voller Speicher 812 → 840) | +3,45 % | 207 | 25,536 | +200,0 % |
| 21 | 844 | 5.361 | 6,00 → 6,20 Schaden/Energie (voller Speicher 840 → 868) | +3,33 % | 253 | 30,143 | +210,0 % |
| 22 | 996 | 6.357 | 6,20 → 6,40 Schaden/Energie (voller Speicher 868 → 896) | +3,23 % | 309 | 35,571 | +220,0 % |
| 23 | 1.175 | 7.532 | 6,40 → 6,60 Schaden/Energie (voller Speicher 896 → 924) | +3,12 % | 376 | 41,964 | +230,0 % |
| 24 | 1.386 | 8.918 | 6,60 → 6,80 Schaden/Energie (voller Speicher 924 → 952) | +3,03 % | 457 | 49,500 | +240,0 % |
| 25 | 1.636 | 10.554 | 6,80 → 7,00 Schaden/Energie (voller Speicher 952 → 980) | +2,94 % | 556 | 58,429 | +250,0 % |
| 26 | 1.930 | 12.484 | 7,00 → 7,20 Schaden/Energie (voller Speicher 980 → 1.008) | +2,86 % | 675 | 68,929 | +260,0 % |
| 27 | 2.278 | 14.762 | 7,20 → 7,40 Schaden/Energie (voller Speicher 1.008 → 1.036) | +2,78 % | 820 | 81,357 | +270,0 % |
| 28 | 2.688 | 17.450 | 7,40 → 7,60 Schaden/Energie (voller Speicher 1.036 → 1.064) | +2,70 % | 995 | 96,000 | +280,0 % |
| 29 | 3.171 | 20.621 | 7,60 → 7,80 Schaden/Energie (voller Speicher 1.064 → 1.092) | +2,63 % | 1.205 | 113,250 | +290,0 % |
| 30 | 3.742 | 24.363 | 7,80 → 8,00 Schaden/Energie (voller Speicher 1.092 → 1.120) | +2,56 % | 1.459 | 133,643 | +300,0 % |
| 31 | 4.416 | 28.779 | 8,00 → 8,20 Schaden/Energie (voller Speicher 1.120 → 1.148) | +2,50 % | 1.766 | 157,714 | +310,0 % |
| 32 | 5.211 | 33.990 | 8,20 → 8,40 Schaden/Energie (voller Speicher 1.148 → 1.176) | +2,44 % | 2.137 | 186,107 | +320,0 % |
| 33 | 6.149 | 40.139 | 8,40 → 8,60 Schaden/Energie (voller Speicher 1.176 → 1.204) | +2,38 % | 2.583 | 219,607 | +330,0 % |
| 34 | 7.255 | 47.394 | 8,60 → 8,80 Schaden/Energie (voller Speicher 1.204 → 1.232) | +2,33 % | 3.120 | 259,107 | +340,0 % |
| 35 | 8.561 | 55.955 | 8,80 → 9,00 Schaden/Energie (voller Speicher 1.232 → 1.260) | +2,27 % | 3.767 | 305,750 | +350,0 % |
| 36 | 10.102 | 66.057 | 9,00 → 9,20 Schaden/Energie (voller Speicher 1.260 → 1.288) | +2,22 % | 4.546 | 360,786 | +360,0 % |
| 37 | 11.921 | 77.978 | 9,20 → 9,40 Schaden/Energie (voller Speicher 1.288 → 1.316) | +2,17 % | 5.484 | 425,750 | +370,0 % |
| 38 | 14.066 | 92.044 | 9,40 → 9,60 Schaden/Energie (voller Speicher 1.316 → 1.344) | +2,13 % | 6.611 | 502,357 | +380,0 % |
| 39 | 16.598 | 108.642 | 9,60 → 9,80 Schaden/Energie (voller Speicher 1.344 → 1.372) | +2,08 % | 7.967 | 592,786 | +390,0 % |
| 40 | 19.586 | 128.228 | 9,80 → 10,00 Schaden/Energie (voller Speicher 1.372 → 1.400) | +2,04 % | 9.597 | 699,500 | +400,0 % |

#### Schildgenerator – Schildradius

**Verändert:** Schildradius. Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 42 | 42 | 3,75 → 3,90 Felder | +4,00 % | 10,5 | 280 | +4,0 % |
| 2 | 50 | 92 | 3,90 → 4,05 Felder | +3,85 % | 13,0 | 333 | +8,0 % |
| 3 | 58 | 150 | 4,05 → 4,20 Felder | +3,70 % | 15,7 | 387 | +12,0 % |
| 4 | 69 | 219 | 4,20 → 4,35 Felder | +3,57 % | 19,3 | 460 | +16,0 % |
| 5 | 81 | 300 | 4,35 → 4,50 Felder | +3,45 % | 23,5 | 540 | +20,0 % |
| 6 | 96 | 396 | 4,50 → 4,65 Felder | +3,33 % | 28,8 | 640 | +24,0 % |
| 7 | 113 | 509 | 4,65 → 4,80 Felder | +3,23 % | 35,0 | 753 | +28,0 % |
| 8 | 134 | 643 | 4,80 → 4,95 Felder | +3,12 % | 42,9 | 893 | +32,0 % |
| 9 | 158 | 801 | 4,95 → 5,10 Felder | +3,03 % | 52,1 | 1.053 | +36,0 % |
| 10 | 186 | 987 | 5,10 → 5,25 Felder | +2,94 % | 63,2 | 1.240 | +40,0 % |
| 11 | 220 | 1.207 | 5,25 → 5,40 Felder | +2,86 % | 77,0 | 1.467 | +44,0 % |
| 12 | 259 | 1.466 | 5,40 → 5,55 Felder | +2,78 % | 93,2 | 1.727 | +48,0 % |
| 13 | 306 | 1.772 | 5,55 → 5,70 Felder | +2,70 % | 113 | 2.040 | +52,0 % |
| 14 | 361 | 2.133 | 5,70 → 5,85 Felder | +2,63 % | 137 | 2.407 | +56,0 % |
| 15 | 426 | 2.559 | 5,85 → 6,00 Felder | +2,56 % | 166 | 2.840 | +60,0 % |

#### Schildgenerator – Kapazität

**Verändert:** Energiespeicher; jede Energie fängt Schaden in Höhe der Schildstärke ab. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,00 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 25 | 25 | 140,0 → 168,0 Energie | +20,00 % | 1,25 | 0,89 | +20,0 % |
| 2 | 30 | 55 | 168,0 → 196,0 Energie | +16,67 % | 1,80 | 1,07 | +40,0 % |
| 3 | 35 | 90 | 196,0 → 224,0 Energie | +14,29 % | 2,45 | 1,25 | +60,0 % |
| 4 | 41 | 131 | 224,0 → 252,0 Energie | +12,50 % | 3,28 | 1,46 | +80,0 % |
| 5 | 49 | 180 | 252,0 → 280,0 Energie | +11,11 % | 4,41 | 1,75 | +100,0 % |
| 6 | 58 | 238 | 280,0 → 308,0 Energie | +10,00 % | 5,80 | 2,07 | +120,0 % |
| 7 | 68 | 306 | 308,0 → 336,0 Energie | +9,09 % | 7,48 | 2,43 | +140,0 % |
| 8 | 80 | 386 | 336,0 → 364,0 Energie | +8,33 % | 9,60 | 2,86 | +160,0 % |
| 9 | 95 | 481 | 364,0 → 392,0 Energie | +7,69 % | 12,4 | 3,39 | +180,0 % |
| 10 | 112 | 593 | 392,0 → 420,0 Energie | +7,14 % | 15,7 | 4,00 | +200,0 % |
| 11 | 132 | 725 | 420,0 → 448,0 Energie | +6,67 % | 19,8 | 4,71 | +220,0 % |
| 12 | 156 | 881 | 448,0 → 476,0 Energie | +6,25 % | 25,0 | 5,57 | +240,0 % |
| 13 | 184 | 1.065 | 476,0 → 504,0 Energie | +5,88 % | 31,3 | 6,57 | +260,0 % |
| 14 | 217 | 1.282 | 504,0 → 532,0 Energie | +5,56 % | 39,1 | 7,75 | +280,0 % |
| 15 | 256 | 1.538 | 532,0 → 560,0 Energie | +5,26 % | 48,6 | 9,14 | +300,0 % |
| 16 | 302 | 1.840 | 560,0 → 588,0 Energie | +5,00 % | 60,4 | 10,8 | +320,0 % |
| 17 | 356 | 2.196 | 588,0 → 616,0 Energie | +4,76 % | 74,8 | 12,7 | +340,0 % |
| 18 | 420 | 2.616 | 616,0 → 644,0 Energie | +4,55 % | 92,4 | 15,0 | +360,0 % |
| 19 | 496 | 3.112 | 644,0 → 672,0 Energie | +4,35 % | 114 | 17,7 | +380,0 % |
| 20 | 585 | 3.697 | 672,0 → 700,0 Energie | +4,17 % | 140 | 20,9 | +400,0 % |
| 21 | 690 | 4.387 | 700,0 → 728,0 Energie | +4,00 % | 172 | 24,6 | +420,0 % |
| 22 | 815 | 5.202 | 728,0 → 756,0 Energie | +3,85 % | 212 | 29,1 | +440,0 % |
| 23 | 961 | 6.163 | 756,0 → 784,0 Energie | +3,70 % | 259 | 34,3 | +460,0 % |
| 24 | 1.134 | 7.297 | 784,0 → 812,0 Energie | +3,57 % | 318 | 40,5 | +480,0 % |
| 25 | 1.338 | 8.635 | 812,0 → 840,0 Energie | +3,45 % | 388 | 47,8 | +500,0 % |

#### Schildgenerator – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 28 | 28 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 25,2 | +1,1 % |
| 2 | 33 | 61 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 30,0 | +2,2 % |
| 3 | 39 | 100 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 35,9 | +3,3 % |
| 4 | 46 | 146 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 42,8 | +4,4 % |
| 5 | 54 | 200 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 50,8 | +5,6 % |
| 6 | 64 | 264 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 60,8 | +6,7 % |
| 7 | 76 | 340 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 73,0 | +7,8 % |
| 8 | 89 | 429 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 86,3 | +8,9 % |
| 9 | 105 | 534 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 103 | +10,0 % |
| 10 | 124 | 658 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 123 | +11,1 % |

#### Schildgenerator – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,400 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 25 | 25 | 100,0 → 115,0 HP | +15,00 % | 1,67 | 1,667 | +15,0 % |
| 2 | 30 | 55 | 115,0 → 130,0 HP | +13,04 % | 2,30 | 2,000 | +30,0 % |
| 3 | 35 | 90 | 130,0 → 145,0 HP | +11,54 % | 3,03 | 2,333 | +45,0 % |
| 4 | 41 | 131 | 145,0 → 160,0 HP | +10,34 % | 3,96 | 2,733 | +60,0 % |
| 5 | 49 | 180 | 160,0 → 175,0 HP | +9,38 % | 5,23 | 3,267 | +75,0 % |
| 6 | 58 | 238 | 175,0 → 190,0 HP | +8,57 % | 6,77 | 3,867 | +90,0 % |
| 7 | 68 | 306 | 190,0 → 205,0 HP | +7,89 % | 8,61 | 4,533 | +105,0 % |
| 8 | 80 | 386 | 205,0 → 220,0 HP | +7,32 % | 10,9 | 5,333 | +120,0 % |
| 9 | 95 | 481 | 220,0 → 235,0 HP | +6,82 % | 13,9 | 6,333 | +135,0 % |
| 10 | 112 | 593 | 235,0 → 250,0 HP | +6,38 % | 17,5 | 7,467 | +150,0 % |
| 11 | 132 | 725 | 250,0 → 265,0 HP | +6,00 % | 22,0 | 8,800 | +165,0 % |
| 12 | 156 | 881 | 265,0 → 280,0 HP | +5,66 % | 27,6 | 10,400 | +180,0 % |
| 13 | 184 | 1.065 | 280,0 → 295,0 HP | +5,36 % | 34,3 | 12,267 | +195,0 % |
| 14 | 217 | 1.282 | 295,0 → 310,0 HP | +5,08 % | 42,7 | 14,467 | +210,0 % |
| 15 | 256 | 1.538 | 310,0 → 325,0 HP | +4,84 % | 52,9 | 17,067 | +225,0 % |
| 16 | 302 | 1.840 | 325,0 → 340,0 HP | +4,62 % | 65,4 | 20,133 | +240,0 % |
| 17 | 356 | 2.196 | 340,0 → 355,0 HP | +4,41 % | 80,7 | 23,733 | +255,0 % |
| 18 | 420 | 2.616 | 355,0 → 370,0 HP | +4,23 % | 99,4 | 28,000 | +270,0 % |
| 19 | 496 | 3.112 | 370,0 → 385,0 HP | +4,05 % | 122 | 33,067 | +285,0 % |
| 20 | 585 | 3.697 | 385,0 → 400,0 HP | +3,90 % | 150 | 39,000 | +300,0 % |
| 21 | 690 | 4.387 | 400,0 → 415,0 HP | +3,75 % | 184 | 46,000 | +315,0 % |
| 22 | 815 | 5.202 | 415,0 → 430,0 HP | +3,61 % | 225 | 54,333 | +330,0 % |
| 23 | 961 | 6.163 | 430,0 → 445,0 HP | +3,49 % | 275 | 64,067 | +345,0 % |
| 24 | 1.134 | 7.297 | 445,0 → 460,0 HP | +3,37 % | 336 | 75,600 | +360,0 % |
| 25 | 1.338 | 8.635 | 460,0 → 475,0 HP | +3,26 % | 410 | 89,200 | +375,0 % |
| 26 | 1.579 | 10.214 | 475,0 → 490,0 HP | +3,16 % | 500 | 105,267 | +390,0 % |
| 27 | 1.864 | 12.078 | 490,0 → 505,0 HP | +3,06 % | 609 | 124,267 | +405,0 % |
| 28 | 2.199 | 14.277 | 505,0 → 520,0 HP | +2,97 % | 740 | 146,600 | +420,0 % |
| 29 | 2.595 | 16.872 | 520,0 → 535,0 HP | +2,88 % | 900 | 173,000 | +435,0 % |
| 30 | 3.062 | 19.934 | 535,0 → 550,0 HP | +2,80 % | 1.092 | 204,133 | +450,0 % |

### Heilturm

- **Freischaltung:** Forschung „Heilturm“ (2 SP)
- **Baukosten:** 110 · **Upgrade-Basis:** 110
- **Grundwerte:** 90 HP · Panzerung 6 · Kapazität 80 · Heilung 20 HP alle 0,90 s, 6 Energie je Heilung, Reichweite 4,11 Felder

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Heilkraft | 40 | 24 | 15.389 | 100.751 | +400 % | 2,40 → 7.541 |
| Heiltempo | 25 | 28 | 1.460 | 9.419 | +150 % | 4,67 → 594 |
| Heilreichweite | 15 | 33 | 335 | 2.011 | +60 % | 8,25 → 131 |
| Effizienz | 20 | 22 | 511 | 3.226 | +100 % | 4,40 → 199 |
| Kapazität | 25 | 20 | 1.052 | 6.783 | +500 % | 1,00 → 305 |
| Strahlübertragung | 10 | 22 | 98 | 518 | +11 % | 19,8 → 97,0 |
| Leben | 30 | 20 | 2.406 | 15.661 | +450 % | 1,33 → 858 |
| Panzerung | 20 | 17 | 383 | 2.420 | +17 % | 20,0 → 524 |

#### Heilturm – Heilkraft

**Verändert:** Heilung je Heilvorgang. **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 4,95 Münzen je HP/s.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 24 | 24 | 20,0 → 22,0 HP je Heilung | +10,00 % | 2,40 | 10,8 | +10,0 % |
| 2 | 29 | 53 | 22,0 → 24,0 HP je Heilung | +9,09 % | 3,19 | 13,1 | +20,0 % |
| 3 | 34 | 87 | 24,0 → 26,0 HP je Heilung | +8,33 % | 4,08 | 15,3 | +30,0 % |
| 4 | 40 | 127 | 26,0 → 28,0 HP je Heilung | +7,69 % | 5,20 | 18,0 | +40,0 % |
| 5 | 47 | 174 | 28,0 → 30,0 HP je Heilung | +7,14 % | 6,58 | 21,1 | +50,0 % |
| 6 | 55 | 229 | 30,0 → 32,0 HP je Heilung | +6,67 % | 8,25 | 24,8 | +60,0 % |
| 7 | 65 | 294 | 32,0 → 34,0 HP je Heilung | +6,25 % | 10,4 | 29,3 | +70,0 % |
| 8 | 77 | 371 | 34,0 → 36,0 HP je Heilung | +5,88 % | 13,1 | 34,7 | +80,0 % |
| 9 | 91 | 462 | 36,0 → 38,0 HP je Heilung | +5,56 % | 16,4 | 41,0 | +90,0 % |
| 10 | 107 | 569 | 38,0 → 40,0 HP je Heilung | +5,26 % | 20,3 | 48,2 | +100,0 % |
| 11 | 127 | 696 | 40,0 → 42,0 HP je Heilung | +5,00 % | 25,4 | 57,2 | +110,0 % |
| 12 | 149 | 845 | 42,0 → 44,0 HP je Heilung | +4,76 % | 31,3 | 67,1 | +120,0 % |
| 13 | 176 | 1.021 | 44,0 → 46,0 HP je Heilung | +4,55 % | 38,7 | 79,2 | +130,0 % |
| 14 | 208 | 1.229 | 46,0 → 48,0 HP je Heilung | +4,35 % | 47,8 | 93,6 | +140,0 % |
| 15 | 246 | 1.475 | 48,0 → 50,0 HP je Heilung | +4,17 % | 59,0 | 111 | +150,0 % |
| 16 | 290 | 1.765 | 50,0 → 52,0 HP je Heilung | +4,00 % | 72,5 | 131 | +160,0 % |
| 17 | 342 | 2.107 | 52,0 → 54,0 HP je Heilung | +3,85 % | 88,9 | 154 | +170,0 % |
| 18 | 403 | 2.510 | 54,0 → 56,0 HP je Heilung | +3,70 % | 109 | 181 | +180,0 % |
| 19 | 476 | 2.986 | 56,0 → 58,0 HP je Heilung | +3,57 % | 133 | 214 | +190,0 % |
| 20 | 562 | 3.548 | 58,0 → 60,0 HP je Heilung | +3,45 % | 163 | 253 | +200,0 % |
| 21 | 663 | 4.211 | 60,0 → 62,0 HP je Heilung | +3,33 % | 199 | 298 | +210,0 % |
| 22 | 782 | 4.993 | 62,0 → 64,0 HP je Heilung | +3,23 % | 242 | 352 | +220,0 % |
| 23 | 923 | 5.916 | 64,0 → 66,0 HP je Heilung | +3,12 % | 295 | 415 | +230,0 % |
| 24 | 1.089 | 7.005 | 66,0 → 68,0 HP je Heilung | +3,03 % | 359 | 490 | +240,0 % |
| 25 | 1.285 | 8.290 | 68,0 → 70,0 HP je Heilung | +2,94 % | 437 | 578 | +250,0 % |
| 26 | 1.517 | 9.807 | 70,0 → 72,0 HP je Heilung | +2,86 % | 531 | 683 | +260,0 % |
| 27 | 1.790 | 11.597 | 72,0 → 74,0 HP je Heilung | +2,78 % | 644 | 806 | +270,0 % |
| 28 | 2.112 | 13.709 | 74,0 → 76,0 HP je Heilung | +2,70 % | 781 | 950 | +280,0 % |
| 29 | 2.492 | 16.201 | 76,0 → 78,0 HP je Heilung | +2,63 % | 947 | 1.121 | +290,0 % |
| 30 | 2.940 | 19.141 | 78,0 → 80,0 HP je Heilung | +2,56 % | 1.147 | 1.323 | +300,0 % |
| 31 | 3.470 | 22.611 | 80,0 → 82,0 HP je Heilung | +2,50 % | 1.388 | 1.561 | +310,0 % |
| 32 | 4.094 | 26.705 | 82,0 → 84,0 HP je Heilung | +2,44 % | 1.679 | 1.842 | +320,0 % |
| 33 | 4.831 | 31.536 | 84,0 → 86,0 HP je Heilung | +2,38 % | 2.029 | 2.174 | +330,0 % |
| 34 | 5.701 | 37.237 | 86,0 → 88,0 HP je Heilung | +2,33 % | 2.451 | 2.565 | +340,0 % |
| 35 | 6.727 | 43.964 | 88,0 → 90,0 HP je Heilung | +2,27 % | 2.960 | 3.027 | +350,0 % |
| 36 | 7.938 | 51.902 | 90,0 → 92,0 HP je Heilung | +2,22 % | 3.572 | 3.572 | +360,0 % |
| 37 | 9.366 | 61.268 | 92,0 → 94,0 HP je Heilung | +2,17 % | 4.308 | 4.215 | +370,0 % |
| 38 | 11.052 | 72.320 | 94,0 → 96,0 HP je Heilung | +2,13 % | 5.194 | 4.973 | +380,0 % |
| 39 | 13.042 | 85.362 | 96,0 → 98,0 HP je Heilung | +2,08 % | 6.260 | 5.869 | +390,0 % |
| 40 | 15.389 | 100.751 | 98,0 → 100,0 HP je Heilung | +2,04 % | 7.541 | 6.925 | +400,0 % |

#### Heilturm – Heiltempo

**Verändert:** Abklingzeit zwischen zwei Heilungen (Heiltempo = 1 ÷ Abklingzeit). **Je Stufe:** +6 % Tempo.

Neubau zum Vergleich: 4,95 Münzen je HP/s.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 28 | 28 | 0,900 → 0,849 s (1,18 Heilungen/s) | +6,00 % | 4,67 | 21,0 | +6,0 % |
| 2 | 32 | 60 | 0,849 → 0,804 s (1,24 Heilungen/s) | +5,66 % | 5,65 | 24,0 | +12,0 % |
| 3 | 38 | 98 | 0,804 → 0,763 s (1,31 Heilungen/s) | +5,36 % | 7,09 | 28,5 | +18,0 % |
| 4 | 45 | 143 | 0,763 → 0,726 s (1,38 Heilungen/s) | +5,08 % | 8,85 | 33,7 | +24,0 % |
| 5 | 53 | 196 | 0,726 → 0,692 s (1,44 Heilungen/s) | +4,84 % | 11,0 | 39,7 | +30,0 % |
| 6 | 63 | 259 | 0,692 → 0,662 s (1,51 Heilungen/s) | +4,62 % | 13,7 | 47,3 | +36,0 % |
| 7 | 74 | 333 | 0,662 → 0,634 s (1,58 Heilungen/s) | +4,41 % | 16,8 | 55,5 | +42,0 % |
| 8 | 88 | 421 | 0,634 → 0,608 s (1,64 Heilungen/s) | +4,23 % | 20,8 | 66,0 | +48,0 % |
| 9 | 103 | 524 | 0,608 → 0,584 s (1,71 Heilungen/s) | +4,05 % | 25,4 | 77,2 | +54,0 % |
| 10 | 122 | 646 | 0,584 → 0,562 s (1,78 Heilungen/s) | +3,90 % | 31,3 | 91,5 | +60,0 % |
| 11 | 144 | 790 | 0,562 → 0,542 s (1,84 Heilungen/s) | +3,75 % | 38,4 | 108 | +66,0 % |
| 12 | 170 | 960 | 0,542 → 0,523 s (1,91 Heilungen/s) | +3,61 % | 47,0 | 127 | +72,0 % |
| 13 | 200 | 1.160 | 0,523 → 0,506 s (1,98 Heilungen/s) | +3,49 % | 57,3 | 150 | +78,0 % |
| 14 | 236 | 1.396 | 0,506 → 0,489 s (2,04 Heilungen/s) | +3,37 % | 70,0 | 177 | +84,0 % |
| 15 | 279 | 1.675 | 0,489 → 0,474 s (2,11 Heilungen/s) | +3,26 % | 85,6 | 209 | +90,0 % |
| 16 | 329 | 2.004 | 0,474 → 0,459 s (2,18 Heilungen/s) | +3,16 % | 104 | 247 | +96,0 % |
| 17 | 389 | 2.393 | 0,459 → 0,446 s (2,24 Heilungen/s) | +3,06 % | 127 | 292 | +102,0 % |
| 18 | 458 | 2.851 | 0,446 → 0,433 s (2,31 Heilungen/s) | +2,97 % | 154 | 343 | +108,0 % |
| 19 | 541 | 3.392 | 0,433 → 0,421 s (2,38 Heilungen/s) | +2,88 % | 188 | 406 | +114,0 % |
| 20 | 638 | 4.030 | 0,421 → 0,409 s (2,44 Heilungen/s) | +2,80 % | 228 | 478 | +120,0 % |
| 21 | 753 | 4.783 | 0,409 → 0,398 s (2,51 Heilungen/s) | +2,73 % | 276 | 565 | +126,0 % |
| 22 | 889 | 5.672 | 0,398 → 0,388 s (2,58 Heilungen/s) | +2,65 % | 335 | 667 | +132,0 % |
| 23 | 1.049 | 6.721 | 0,388 → 0,378 s (2,64 Heilungen/s) | +2,59 % | 406 | 787 | +138,0 % |
| 24 | 1.238 | 7.959 | 0,378 → 0,369 s (2,71 Heilungen/s) | +2,52 % | 491 | 928 | +144,0 % |
| 25 | 1.460 | 9.419 | 0,369 → 0,360 s (2,78 Heilungen/s) | +2,46 % | 594 | 1.095 | +150,0 % |

#### Heilturm – Heilreichweite

**Verändert:** Heilreichweite. Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 33 | 33 | 4,11 → 4,27 Felder | +4,00 % | 8,25 | 201 | +4,0 % |
| 2 | 39 | 72 | 4,27 → 4,44 Felder | +3,85 % | 10,1 | 237 | +8,0 % |
| 3 | 46 | 118 | 4,44 → 4,60 Felder | +3,70 % | 12,4 | 280 | +12,0 % |
| 4 | 54 | 172 | 4,60 → 4,76 Felder | +3,57 % | 15,1 | 329 | +16,0 % |
| 5 | 64 | 236 | 4,76 → 4,93 Felder | +3,45 % | 18,6 | 390 | +20,0 % |
| 6 | 75 | 311 | 4,93 → 5,09 Felder | +3,33 % | 22,5 | 457 | +24,0 % |
| 7 | 89 | 400 | 5,09 → 5,26 Felder | +3,23 % | 27,6 | 542 | +28,0 % |
| 8 | 105 | 505 | 5,26 → 5,42 Felder | +3,12 % | 33,6 | 639 | +32,0 % |
| 9 | 124 | 629 | 5,42 → 5,59 Felder | +3,03 % | 40,9 | 755 | +36,0 % |
| 10 | 146 | 775 | 5,59 → 5,75 Felder | +2,94 % | 49,6 | 889 | +40,0 % |
| 11 | 173 | 948 | 5,75 → 5,91 Felder | +2,86 % | 60,5 | 1.053 | +44,0 % |
| 12 | 204 | 1.152 | 5,91 → 6,08 Felder | +2,78 % | 73,4 | 1.242 | +48,0 % |
| 13 | 240 | 1.392 | 6,08 → 6,24 Felder | +2,70 % | 88,8 | 1.461 | +52,0 % |
| 14 | 284 | 1.676 | 6,24 → 6,41 Felder | +2,63 % | 108 | 1.729 | +56,0 % |
| 15 | 335 | 2.011 | 6,41 → 6,57 Felder | +2,56 % | 131 | 2.039 | +60,0 % |

#### Heilturm – Effizienz

**Verändert:** Senkt die Energie je Heilung (Energie ÷ Effizienz). **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je (HP/Energie) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 22 | 22 | 6,00 → 5,71 Energie je Heilung | +5,00 % | 4,40 | 132 | +5,0 % |
| 2 | 26 | 48 | 5,71 → 5,45 Energie je Heilung | +4,76 % | 5,46 | 156 | +10,0 % |
| 3 | 31 | 79 | 5,45 → 5,22 Energie je Heilung | +4,55 % | 6,82 | 186 | +15,0 % |
| 4 | 36 | 115 | 5,22 → 5,00 Energie je Heilung | +4,35 % | 8,28 | 216 | +20,0 % |
| 5 | 43 | 158 | 5,00 → 4,80 Energie je Heilung | +4,17 % | 10,3 | 258 | +25,0 % |
| 6 | 50 | 208 | 4,80 → 4,62 Energie je Heilung | +4,00 % | 12,5 | 300 | +30,0 % |
| 7 | 59 | 267 | 4,62 → 4,44 Energie je Heilung | +3,85 % | 15,3 | 354 | +35,0 % |
| 8 | 70 | 337 | 4,44 → 4,29 Energie je Heilung | +3,70 % | 18,9 | 420 | +40,0 % |
| 9 | 83 | 420 | 4,29 → 4,14 Energie je Heilung | +3,57 % | 23,2 | 498 | +45,0 % |
| 10 | 98 | 518 | 4,14 → 4,00 Energie je Heilung | +3,45 % | 28,4 | 588 | +50,0 % |
| 11 | 115 | 633 | 4,00 → 3,87 Energie je Heilung | +3,33 % | 34,5 | 690 | +55,0 % |
| 12 | 136 | 769 | 3,87 → 3,75 Energie je Heilung | +3,23 % | 42,2 | 816 | +60,0 % |
| 13 | 160 | 929 | 3,75 → 3,64 Energie je Heilung | +3,12 % | 51,2 | 960 | +65,0 % |
| 14 | 189 | 1.118 | 3,64 → 3,53 Energie je Heilung | +3,03 % | 62,4 | 1.134 | +70,0 % |
| 15 | 223 | 1.341 | 3,53 → 3,43 Energie je Heilung | +2,94 % | 75,8 | 1.338 | +75,0 % |
| 16 | 263 | 1.604 | 3,43 → 3,33 Energie je Heilung | +2,86 % | 92,0 | 1.578 | +80,0 % |
| 17 | 311 | 1.915 | 3,33 → 3,24 Energie je Heilung | +2,78 % | 112 | 1.866 | +85,0 % |
| 18 | 367 | 2.282 | 3,24 → 3,16 Energie je Heilung | +2,70 % | 136 | 2.202 | +90,0 % |
| 19 | 433 | 2.715 | 3,16 → 3,08 Energie je Heilung | +2,63 % | 165 | 2.598 | +95,0 % |
| 20 | 511 | 3.226 | 3,08 → 3,00 Energie je Heilung | +2,56 % | 199 | 3.066 | +100,0 % |

#### Heilturm – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,38 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 20 | 20 | 80,0 → 96,0 Energie | +20,00 % | 1,00 | 1,25 | +20,0 % |
| 2 | 23 | 43 | 96,0 → 112,0 Energie | +16,67 % | 1,38 | 1,44 | +40,0 % |
| 3 | 28 | 71 | 112,0 → 128,0 Energie | +14,29 % | 1,96 | 1,75 | +60,0 % |
| 4 | 33 | 104 | 128,0 → 144,0 Energie | +12,50 % | 2,64 | 2,06 | +80,0 % |
| 5 | 38 | 142 | 144,0 → 160,0 Energie | +11,11 % | 3,42 | 2,38 | +100,0 % |
| 6 | 45 | 187 | 160,0 → 176,0 Energie | +10,00 % | 4,50 | 2,81 | +120,0 % |
| 7 | 53 | 240 | 176,0 → 192,0 Energie | +9,09 % | 5,83 | 3,31 | +140,0 % |
| 8 | 63 | 303 | 192,0 → 208,0 Energie | +8,33 % | 7,56 | 3,94 | +160,0 % |
| 9 | 74 | 377 | 208,0 → 224,0 Energie | +7,69 % | 9,62 | 4,62 | +180,0 % |
| 10 | 88 | 465 | 224,0 → 240,0 Energie | +7,14 % | 12,3 | 5,50 | +200,0 % |
| 11 | 104 | 569 | 240,0 → 256,0 Energie | +6,67 % | 15,6 | 6,50 | +220,0 % |
| 12 | 122 | 691 | 256,0 → 272,0 Energie | +6,25 % | 19,5 | 7,62 | +240,0 % |
| 13 | 144 | 835 | 272,0 → 288,0 Energie | +5,88 % | 24,5 | 9,00 | +260,0 % |
| 14 | 170 | 1.005 | 288,0 → 304,0 Energie | +5,56 % | 30,6 | 10,6 | +280,0 % |
| 15 | 201 | 1.206 | 304,0 → 320,0 Energie | +5,26 % | 38,2 | 12,6 | +300,0 % |
| 16 | 237 | 1.443 | 320,0 → 336,0 Energie | +5,00 % | 47,4 | 14,8 | +320,0 % |
| 17 | 280 | 1.723 | 336,0 → 352,0 Energie | +4,76 % | 58,8 | 17,5 | +340,0 % |
| 18 | 330 | 2.053 | 352,0 → 368,0 Energie | +4,55 % | 72,6 | 20,6 | +360,0 % |
| 19 | 390 | 2.443 | 368,0 → 384,0 Energie | +4,35 % | 89,7 | 24,4 | +380,0 % |
| 20 | 460 | 2.903 | 384,0 → 400,0 Energie | +4,17 % | 110 | 28,8 | +400,0 % |
| 21 | 542 | 3.445 | 400,0 → 416,0 Energie | +4,00 % | 135 | 33,9 | +420,0 % |
| 22 | 640 | 4.085 | 416,0 → 432,0 Energie | +3,85 % | 166 | 40,0 | +440,0 % |
| 23 | 755 | 4.840 | 432,0 → 448,0 Energie | +3,70 % | 204 | 47,2 | +460,0 % |
| 24 | 891 | 5.731 | 448,0 → 464,0 Energie | +3,57 % | 249 | 55,7 | +480,0 % |
| 25 | 1.052 | 6.783 | 464,0 → 480,0 Energie | +3,45 % | 305 | 65,8 | +500,0 % |

#### Heilturm – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 22 | 22 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 19,8 | +1,1 % |
| 2 | 26 | 48 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 23,7 | +2,2 % |
| 3 | 31 | 79 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 28,5 | +3,3 % |
| 4 | 36 | 115 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 33,5 | +4,4 % |
| 5 | 43 | 158 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 40,4 | +5,6 % |
| 6 | 50 | 208 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 47,5 | +6,7 % |
| 7 | 59 | 267 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 56,6 | +7,8 % |
| 8 | 70 | 337 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 67,9 | +8,9 % |
| 9 | 83 | 420 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 81,3 | +10,0 % |
| 10 | 98 | 518 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 97,0 | +11,1 % |

#### Heilturm – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,222 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 20 | 20 | 90,0 → 103,5 HP | +15,00 % | 1,33 | 1,481 | +15,0 % |
| 2 | 23 | 43 | 103,5 → 117,0 HP | +13,04 % | 1,76 | 1,704 | +30,0 % |
| 3 | 28 | 71 | 117,0 → 130,5 HP | +11,54 % | 2,43 | 2,074 | +45,0 % |
| 4 | 33 | 104 | 130,5 → 144,0 HP | +10,34 % | 3,19 | 2,444 | +60,0 % |
| 5 | 38 | 142 | 144,0 → 157,5 HP | +9,38 % | 4,05 | 2,815 | +75,0 % |
| 6 | 45 | 187 | 157,5 → 171,0 HP | +8,57 % | 5,25 | 3,333 | +90,0 % |
| 7 | 53 | 240 | 171,0 → 184,5 HP | +7,89 % | 6,71 | 3,926 | +105,0 % |
| 8 | 63 | 303 | 184,5 → 198,0 HP | +7,32 % | 8,61 | 4,667 | +120,0 % |
| 9 | 74 | 377 | 198,0 → 211,5 HP | +6,82 % | 10,9 | 5,481 | +135,0 % |
| 10 | 88 | 465 | 211,5 → 225,0 HP | +6,38 % | 13,8 | 6,519 | +150,0 % |
| 11 | 104 | 569 | 225,0 → 238,5 HP | +6,00 % | 17,3 | 7,704 | +165,0 % |
| 12 | 122 | 691 | 238,5 → 252,0 HP | +5,66 % | 21,6 | 9,037 | +180,0 % |
| 13 | 144 | 835 | 252,0 → 265,5 HP | +5,36 % | 26,9 | 10,667 | +195,0 % |
| 14 | 170 | 1.005 | 265,5 → 279,0 HP | +5,08 % | 33,4 | 12,593 | +210,0 % |
| 15 | 201 | 1.206 | 279,0 → 292,5 HP | +4,84 % | 41,5 | 14,889 | +225,0 % |
| 16 | 237 | 1.443 | 292,5 → 306,0 HP | +4,62 % | 51,3 | 17,556 | +240,0 % |
| 17 | 280 | 1.723 | 306,0 → 319,5 HP | +4,41 % | 63,5 | 20,741 | +255,0 % |
| 18 | 330 | 2.053 | 319,5 → 333,0 HP | +4,23 % | 78,1 | 24,444 | +270,0 % |
| 19 | 390 | 2.443 | 333,0 → 346,5 HP | +4,05 % | 96,2 | 28,889 | +285,0 % |
| 20 | 460 | 2.903 | 346,5 → 360,0 HP | +3,90 % | 118 | 34,074 | +300,0 % |
| 21 | 542 | 3.445 | 360,0 → 373,5 HP | +3,75 % | 145 | 40,148 | +315,0 % |
| 22 | 640 | 4.085 | 373,5 → 387,0 HP | +3,61 % | 177 | 47,407 | +330,0 % |
| 23 | 755 | 4.840 | 387,0 → 400,5 HP | +3,49 % | 216 | 55,926 | +345,0 % |
| 24 | 891 | 5.731 | 400,5 → 414,0 HP | +3,37 % | 264 | 66,000 | +360,0 % |
| 25 | 1.052 | 6.783 | 414,0 → 427,5 HP | +3,26 % | 323 | 77,926 | +375,0 % |
| 26 | 1.241 | 8.024 | 427,5 → 441,0 HP | +3,16 % | 393 | 91,926 | +390,0 % |
| 27 | 1.464 | 9.488 | 441,0 → 454,5 HP | +3,06 % | 478 | 108,444 | +405,0 % |
| 28 | 1.728 | 11.216 | 454,5 → 468,0 HP | +2,97 % | 582 | 128,000 | +420,0 % |
| 29 | 2.039 | 13.255 | 468,0 → 481,5 HP | +2,88 % | 707 | 151,037 | +435,0 % |
| 30 | 2.406 | 15.661 | 481,5 → 495,0 HP | +2,80 % | 858 | 178,222 | +450,0 % |

#### Heilturm – Panzerung

**Verändert:** Panzerung. Jeder erlittene Treffer sinkt um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Nutzen gemessen an den effektiven Lebenspunkten (Leben ÷ (1 − Reduktion)) mit Grund-Leben, ohne Mindestschaden. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 1,15 Münzen je eff. HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eff. HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 17 | 17 | Panzerung 6,0 → 6,9 (−5,7 % → −6,5 %) | +0,85 % | 20,0 | 21,0 | +0,8 % |
| 2 | 19 | 36 | Panzerung 6,9 → 7,8 (−6,5 % → −7,2 %) | +0,84 % | 22,6 | 23,5 | +1,7 % |
| 3 | 23 | 59 | Panzerung 7,8 → 8,7 (−7,2 % → −8,0 %) | +0,83 % | 27,5 | 28,4 | +2,5 % |
| 4 | 27 | 86 | Panzerung 8,7 → 9,6 (−8,0 % → −8,8 %) | +0,83 % | 32,6 | 33,3 | +3,4 % |
| 5 | 32 | 118 | Panzerung 9,6 → 10,5 (−8,8 % → −9,5 %) | +0,82 % | 39,0 | 39,5 | +4,2 % |
| 6 | 38 | 156 | Panzerung 10,5 → 11,4 (−9,5 % → −10,2 %) | +0,81 % | 46,7 | 46,9 | +5,1 % |
| 7 | 45 | 201 | Panzerung 11,4 → 12,3 (−10,2 % → −11,0 %) | +0,81 % | 55,7 | 55,6 | +5,9 % |
| 8 | 53 | 254 | Panzerung 12,3 → 13,2 (−11,0 % → −11,7 %) | +0,80 % | 66,1 | 65,4 | +6,8 % |
| 9 | 62 | 316 | Panzerung 13,2 → 14,1 (−11,7 % → −12,4 %) | +0,80 % | 78,0 | 76,5 | +7,6 % |
| 10 | 73 | 389 | Panzerung 14,1 → 15,0 (−12,4 % → −13,0 %) | +0,79 % | 92,5 | 90,1 | +8,5 % |
| 11 | 86 | 475 | Panzerung 15,0 → 15,9 (−13,0 % → −13,7 %) | +0,78 % | 110 | 106 | +9,3 % |
| 12 | 102 | 577 | Panzerung 15,9 → 16,8 (−13,7 % → −14,4 %) | +0,78 % | 131 | 126 | +10,2 % |
| 13 | 120 | 697 | Panzerung 16,8 → 17,7 (−14,4 % → −15,0 %) | +0,77 % | 156 | 148 | +11,0 % |
| 14 | 142 | 839 | Panzerung 17,7 → 18,6 (−15,0 % → −15,7 %) | +0,76 % | 186 | 175 | +11,9 % |
| 15 | 167 | 1.006 | Panzerung 18,6 → 19,5 (−15,7 % → −16,3 %) | +0,76 % | 220 | 206 | +12,7 % |
| 16 | 198 | 1.204 | Panzerung 19,5 → 20,4 (−16,3 % → −16,9 %) | +0,75 % | 263 | 244 | +13,6 % |
| 17 | 233 | 1.437 | Panzerung 20,4 → 21,3 (−16,9 % → −17,6 %) | +0,75 % | 312 | 288 | +14,4 % |
| 18 | 275 | 1.712 | Panzerung 21,3 → 22,2 (−17,6 % → −18,2 %) | +0,74 % | 371 | 340 | +15,3 % |
| 19 | 325 | 2.037 | Panzerung 22,2 → 23,1 (−18,2 % → −18,8 %) | +0,74 % | 441 | 401 | +16,1 % |
| 20 | 383 | 2.420 | Panzerung 23,1 → 24,0 (−18,8 % → −19,4 %) | +0,73 % | 524 | 473 | +17,0 % |

## Extras

### Lampe

- **Freischaltung:** von Anfang an
- **Baukosten:** 25 · **Upgrade-Basis:** 25
- **Grundwerte:** 60 HP · Panzerung 0 · Kapazität 40 · Verbrauch bei Radius 3 Felder 3,31 E/s

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Lichteffizienz | 20 | 5 | 116 | 732 | +100 % | 1,00 → 45,2 |
| Kapazität | 25 | 5 | 239 | 1.543 | +500 % | 0,25 → 69,3 |
| Strahlübertragung | 10 | 5 | 22 | 117 | +11 % | 4,50 → 21,8 |
| Leben | 30 | 5 | 547 | 3.561 | +450 % | 0,33 → 195 |

#### Lampe – Lichteffizienz

**Verändert:** Senkt den Lichtverbrauch (Verbrauch ÷ Effizienz). Werte für den Standardradius 3 Felder. **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eingesparter E/s | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 3,31 → 3,15 E/s Verbrauch | +5,00 % | 1,00 | 31,8 | +5,0 % |
| 2 | 6 | 11 | 3,15 → 3,01 E/s Verbrauch | +4,76 % | 1,26 | 41,9 | +10,0 % |
| 3 | 7 | 18 | 3,01 → 2,88 E/s Verbrauch | +4,55 % | 1,54 | 53,6 | +15,0 % |
| 4 | 8 | 26 | 2,88 → 2,76 E/s Verbrauch | +4,35 % | 1,84 | 66,8 | +20,0 % |
| 5 | 10 | 36 | 2,76 → 2,65 E/s Verbrauch | +4,17 % | 2,40 | 90,7 | +25,0 % |
| 6 | 11 | 47 | 2,65 → 2,54 E/s Verbrauch | +4,00 % | 2,75 | 108 | +30,0 % |
| 7 | 13 | 60 | 2,54 → 2,45 E/s Verbrauch | +3,85 % | 3,38 | 138 | +35,0 % |
| 8 | 16 | 76 | 2,45 → 2,36 E/s Verbrauch | +3,70 % | 4,32 | 183 | +40,0 % |
| 9 | 19 | 95 | 2,36 → 2,28 E/s Verbrauch | +3,57 % | 5,32 | 233 | +45,0 % |
| 10 | 22 | 117 | 2,28 → 2,20 E/s Verbrauch | +3,45 % | 6,38 | 289 | +50,0 % |
| 11 | 26 | 143 | 2,20 → 2,13 E/s Verbrauch | +3,33 % | 7,80 | 366 | +55,0 % |
| 12 | 31 | 174 | 2,13 → 2,07 E/s Verbrauch | +3,23 % | 9,61 | 465 | +60,0 % |
| 13 | 36 | 210 | 2,07 → 2,00 E/s Verbrauch | +3,12 % | 11,5 | 575 | +65,0 % |
| 14 | 43 | 253 | 2,00 → 1,95 E/s Verbrauch | +3,03 % | 14,2 | 729 | +70,0 % |
| 15 | 51 | 304 | 1,95 → 1,89 E/s Verbrauch | +2,94 % | 17,3 | 918 | +75,0 % |
| 16 | 60 | 364 | 1,89 → 1,84 E/s Verbrauch | +2,86 % | 21,0 | 1.143 | +80,0 % |
| 17 | 71 | 435 | 1,84 → 1,79 E/s Verbrauch | +2,78 % | 25,6 | 1.430 | +85,0 % |
| 18 | 83 | 518 | 1,79 → 1,74 E/s Verbrauch | +2,70 % | 30,7 | 1.765 | +90,0 % |
| 19 | 98 | 616 | 1,74 → 1,70 E/s Verbrauch | +2,63 % | 37,2 | 2.196 | +95,0 % |
| 20 | 116 | 732 | 1,70 → 1,65 E/s Verbrauch | +2,56 % | 45,2 | 2.736 | +100,0 % |

#### Lampe – Kapazität

**Verändert:** Energiespeicher für die Nacht. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 0,62 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 40,0 → 48,0 Energie | +20,00 % | 0,25 | 0,62 | +20,0 % |
| 2 | 5 | 10 | 48,0 → 56,0 Energie | +16,67 % | 0,30 | 0,62 | +40,0 % |
| 3 | 6 | 16 | 56,0 → 64,0 Energie | +14,29 % | 0,42 | 0,75 | +60,0 % |
| 4 | 7 | 23 | 64,0 → 72,0 Energie | +12,50 % | 0,56 | 0,88 | +80,0 % |
| 5 | 9 | 32 | 72,0 → 80,0 Energie | +11,11 % | 0,81 | 1,12 | +100,0 % |
| 6 | 10 | 42 | 80,0 → 88,0 Energie | +10,00 % | 1,00 | 1,25 | +120,0 % |
| 7 | 12 | 54 | 88,0 → 96,0 Energie | +9,09 % | 1,32 | 1,50 | +140,0 % |
| 8 | 14 | 68 | 96,0 → 104,0 Energie | +8,33 % | 1,68 | 1,75 | +160,0 % |
| 9 | 17 | 85 | 104,0 → 112,0 Energie | +7,69 % | 2,21 | 2,12 | +180,0 % |
| 10 | 20 | 105 | 112,0 → 120,0 Energie | +7,14 % | 2,80 | 2,50 | +200,0 % |
| 11 | 24 | 129 | 120,0 → 128,0 Energie | +6,67 % | 3,60 | 3,00 | +220,0 % |
| 12 | 28 | 157 | 128,0 → 136,0 Energie | +6,25 % | 4,48 | 3,50 | +240,0 % |
| 13 | 33 | 190 | 136,0 → 144,0 Energie | +5,88 % | 5,61 | 4,12 | +260,0 % |
| 14 | 39 | 229 | 144,0 → 152,0 Energie | +5,56 % | 7,02 | 4,88 | +280,0 % |
| 15 | 46 | 275 | 152,0 → 160,0 Energie | +5,26 % | 8,74 | 5,75 | +300,0 % |
| 16 | 54 | 329 | 160,0 → 168,0 Energie | +5,00 % | 10,8 | 6,75 | +320,0 % |
| 17 | 64 | 393 | 168,0 → 176,0 Energie | +4,76 % | 13,4 | 8,00 | +340,0 % |
| 18 | 75 | 468 | 176,0 → 184,0 Energie | +4,55 % | 16,5 | 9,38 | +360,0 % |
| 19 | 89 | 557 | 184,0 → 192,0 Energie | +4,35 % | 20,5 | 11,1 | +380,0 % |
| 20 | 104 | 661 | 192,0 → 200,0 Energie | +4,17 % | 25,0 | 13,0 | +400,0 % |
| 21 | 123 | 784 | 200,0 → 208,0 Energie | +4,00 % | 30,7 | 15,4 | +420,0 % |
| 22 | 145 | 929 | 208,0 → 216,0 Energie | +3,85 % | 37,7 | 18,1 | +440,0 % |
| 23 | 172 | 1.101 | 216,0 → 224,0 Energie | +3,70 % | 46,4 | 21,5 | +460,0 % |
| 24 | 203 | 1.304 | 224,0 → 232,0 Energie | +3,57 % | 56,8 | 25,4 | +480,0 % |
| 25 | 239 | 1.543 | 232,0 → 240,0 Energie | +3,45 % | 69,3 | 29,9 | +500,0 % |

#### Lampe – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 5 | 5 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 4,50 | +1,1 % |
| 2 | 6 | 11 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 5,46 | +2,2 % |
| 3 | 7 | 18 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 6,44 | +3,3 % |
| 4 | 8 | 26 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 7,44 | +4,4 % |
| 5 | 10 | 36 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 9,40 | +5,6 % |
| 6 | 11 | 47 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 10,4 | +6,7 % |
| 7 | 13 | 60 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 12,5 | +7,8 % |
| 8 | 16 | 76 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 15,5 | +8,9 % |
| 9 | 19 | 95 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 18,6 | +10,0 % |
| 10 | 22 | 117 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 21,8 | +11,1 % |

#### Lampe – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,417 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 60,0 → 69,0 HP | +15,00 % | 0,33 | 0,556 | +15,0 % |
| 2 | 5 | 10 | 69,0 → 78,0 HP | +13,04 % | 0,38 | 0,556 | +30,0 % |
| 3 | 6 | 16 | 78,0 → 87,0 HP | +11,54 % | 0,52 | 0,667 | +45,0 % |
| 4 | 7 | 23 | 87,0 → 96,0 HP | +10,34 % | 0,68 | 0,778 | +60,0 % |
| 5 | 9 | 32 | 96,0 → 105,0 HP | +9,38 % | 0,96 | 1,000 | +75,0 % |
| 6 | 10 | 42 | 105,0 → 114,0 HP | +8,57 % | 1,17 | 1,111 | +90,0 % |
| 7 | 12 | 54 | 114,0 → 123,0 HP | +7,89 % | 1,52 | 1,333 | +105,0 % |
| 8 | 14 | 68 | 123,0 → 132,0 HP | +7,32 % | 1,91 | 1,556 | +120,0 % |
| 9 | 17 | 85 | 132,0 → 141,0 HP | +6,82 % | 2,49 | 1,889 | +135,0 % |
| 10 | 20 | 105 | 141,0 → 150,0 HP | +6,38 % | 3,13 | 2,222 | +150,0 % |
| 11 | 24 | 129 | 150,0 → 159,0 HP | +6,00 % | 4,00 | 2,667 | +165,0 % |
| 12 | 28 | 157 | 159,0 → 168,0 HP | +5,66 % | 4,95 | 3,111 | +180,0 % |
| 13 | 33 | 190 | 168,0 → 177,0 HP | +5,36 % | 6,16 | 3,667 | +195,0 % |
| 14 | 39 | 229 | 177,0 → 186,0 HP | +5,08 % | 7,67 | 4,333 | +210,0 % |
| 15 | 46 | 275 | 186,0 → 195,0 HP | +4,84 % | 9,51 | 5,111 | +225,0 % |
| 16 | 54 | 329 | 195,0 → 204,0 HP | +4,62 % | 11,7 | 6,000 | +240,0 % |
| 17 | 64 | 393 | 204,0 → 213,0 HP | +4,41 % | 14,5 | 7,111 | +255,0 % |
| 18 | 75 | 468 | 213,0 → 222,0 HP | +4,23 % | 17,8 | 8,333 | +270,0 % |
| 19 | 89 | 557 | 222,0 → 231,0 HP | +4,05 % | 22,0 | 9,889 | +285,0 % |
| 20 | 104 | 661 | 231,0 → 240,0 HP | +3,90 % | 26,7 | 11,556 | +300,0 % |
| 21 | 123 | 784 | 240,0 → 249,0 HP | +3,75 % | 32,8 | 13,667 | +315,0 % |
| 22 | 145 | 929 | 249,0 → 258,0 HP | +3,61 % | 40,1 | 16,111 | +330,0 % |
| 23 | 172 | 1.101 | 258,0 → 267,0 HP | +3,49 % | 49,3 | 19,111 | +345,0 % |
| 24 | 203 | 1.304 | 267,0 → 276,0 HP | +3,37 % | 60,2 | 22,556 | +360,0 % |
| 25 | 239 | 1.543 | 276,0 → 285,0 HP | +3,26 % | 73,3 | 26,556 | +375,0 % |
| 26 | 282 | 1.825 | 285,0 → 294,0 HP | +3,16 % | 89,3 | 31,333 | +390,0 % |
| 27 | 333 | 2.158 | 294,0 → 303,0 HP | +3,06 % | 109 | 37,000 | +405,0 % |
| 28 | 393 | 2.551 | 303,0 → 312,0 HP | +2,97 % | 132 | 43,667 | +420,0 % |
| 29 | 463 | 3.014 | 312,0 → 321,0 HP | +2,88 % | 161 | 51,444 | +435,0 % |
| 30 | 547 | 3.561 | 321,0 → 330,0 HP | +2,80 % | 195 | 60,778 | +450,0 % |

### Mobiler Turm

- **Freischaltung:** Forschung „Mobiler Turm“ (2 SP)
- **Baukosten:** 150 · **Upgrade-Basis:** 150
- **Grundwerte:** 160 HP · Panzerung 12 · Kapazität 120 · 20 Schaden alle 0,50 s, 3 Energie/Schuss, Reichweite 3,75 Felder · DPS 44,8 (Ø inkl. 12 % Krit) · Fahren 1,52 Felder/s, 6,72 Energie/Feld

| Pfad | Stufen | 1. Stufe | letzte Stufe | Summe bis max. | Nutzen gesamt | Münzen je % (1. → letzte) |
|---|---|---|---|---|---|---|
| Schaden | 40 | 33 | 20.985 | 137.386 | +400 % | 3,30 → 10.283 |
| Feuerrate | 25 | 38 | 1.992 | 12.848 | +150 % | 6,33 → 810 |
| Überladung | 12 | 23 | 139 | 788 | +240 % | 1,15 → 22,2 |
| Reichweite | 15 | 45 | 457 | 2.744 | +60 % | 11,2 → 178 |
| Kritische Treffer | 20 | 38 | 871 | 5.499 | +18 % | 42,6 → 1.141 |
| Fahreffizienz | 20 | 30 | 696 | 4.398 | +100 % | 6,00 → 271 |
| Kapazität | 25 | 27 | 1.434 | 9.250 | +500 % | 1,35 → 416 |
| Strahlübertragung | 10 | 30 | 133 | 706 | +11 % | 27,0 → 132 |
| Leben | 30 | 27 | 3.281 | 21.356 | +450 % | 1,80 → 1.170 |
| Panzerung | 20 | 23 | 522 | 3.300 | +32 % | 14,3 → 424 |

#### Mobiler Turm – Schaden

**Verändert:** Schaden je Schuss (Laser: je Sekunde). **Je Stufe:** +10 % des Grundwerts.

Neubau zum Vergleich: 3,35 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 33 | 33 | Schaden/Schuss 20,0 → 22,0 | +10,00 % | 3,30 | 7,37 | +10,0 % |
| 2 | 39 | 72 | Schaden/Schuss 22,0 → 24,0 | +9,09 % | 4,29 | 8,71 | +20,0 % |
| 3 | 46 | 118 | Schaden/Schuss 24,0 → 26,0 | +8,33 % | 5,52 | 10,3 | +30,0 % |
| 4 | 54 | 172 | Schaden/Schuss 26,0 → 28,0 | +7,69 % | 7,02 | 12,1 | +40,0 % |
| 5 | 64 | 236 | Schaden/Schuss 28,0 → 30,0 | +7,14 % | 8,96 | 14,3 | +50,0 % |
| 6 | 75 | 311 | Schaden/Schuss 30,0 → 32,0 | +6,67 % | 11,3 | 16,7 | +60,0 % |
| 7 | 89 | 400 | Schaden/Schuss 32,0 → 34,0 | +6,25 % | 14,2 | 19,9 | +70,0 % |
| 8 | 105 | 505 | Schaden/Schuss 34,0 → 36,0 | +5,88 % | 17,8 | 23,4 | +80,0 % |
| 9 | 124 | 629 | Schaden/Schuss 36,0 → 38,0 | +5,56 % | 22,3 | 27,7 | +90,0 % |
| 10 | 146 | 775 | Schaden/Schuss 38,0 → 40,0 | +5,26 % | 27,7 | 32,6 | +100,0 % |
| 11 | 173 | 948 | Schaden/Schuss 40,0 → 42,0 | +5,00 % | 34,6 | 38,6 | +110,0 % |
| 12 | 204 | 1.152 | Schaden/Schuss 42,0 → 44,0 | +4,76 % | 42,8 | 45,5 | +120,0 % |
| 13 | 240 | 1.392 | Schaden/Schuss 44,0 → 46,0 | +4,55 % | 52,8 | 53,6 | +130,0 % |
| 14 | 284 | 1.676 | Schaden/Schuss 46,0 → 48,0 | +4,35 % | 65,3 | 63,4 | +140,0 % |
| 15 | 335 | 2.011 | Schaden/Schuss 48,0 → 50,0 | +4,17 % | 80,4 | 74,8 | +150,0 % |
| 16 | 395 | 2.406 | Schaden/Schuss 50,0 → 52,0 | +4,00 % | 98,7 | 88,2 | +160,0 % |
| 17 | 466 | 2.872 | Schaden/Schuss 52,0 → 54,0 | +3,85 % | 121 | 104 | +170,0 % |
| 18 | 550 | 3.422 | Schaden/Schuss 54,0 → 56,0 | +3,70 % | 149 | 123 | +180,0 % |
| 19 | 649 | 4.071 | Schaden/Schuss 56,0 → 58,0 | +3,57 % | 182 | 145 | +190,0 % |
| 20 | 766 | 4.837 | Schaden/Schuss 58,0 → 60,0 | +3,45 % | 222 | 171 | +200,0 % |
| 21 | 904 | 5.741 | Schaden/Schuss 60,0 → 62,0 | +3,33 % | 271 | 202 | +210,0 % |
| 22 | 1.067 | 6.808 | Schaden/Schuss 62,0 → 64,0 | +3,23 % | 331 | 238 | +220,0 % |
| 23 | 1.259 | 8.067 | Schaden/Schuss 64,0 → 66,0 | +3,12 % | 403 | 281 | +230,0 % |
| 24 | 1.485 | 9.552 | Schaden/Schuss 66,0 → 68,0 | +3,03 % | 490 | 331 | +240,0 % |
| 25 | 1.753 | 11.305 | Schaden/Schuss 68,0 → 70,0 | +2,94 % | 596 | 391 | +250,0 % |
| 26 | 2.068 | 13.373 | Schaden/Schuss 70,0 → 72,0 | +2,86 % | 724 | 462 | +260,0 % |
| 27 | 2.440 | 15.813 | Schaden/Schuss 72,0 → 74,0 | +2,78 % | 878 | 545 | +270,0 % |
| 28 | 2.880 | 18.693 | Schaden/Schuss 74,0 → 76,0 | +2,70 % | 1.066 | 643 | +280,0 % |
| 29 | 3.398 | 22.091 | Schaden/Schuss 76,0 → 78,0 | +2,63 % | 1.291 | 758 | +290,0 % |
| 30 | 4.010 | 26.101 | Schaden/Schuss 78,0 → 80,0 | +2,56 % | 1.564 | 895 | +300,0 % |
| 31 | 4.731 | 30.832 | Schaden/Schuss 80,0 → 82,0 | +2,50 % | 1.892 | 1.056 | +310,0 % |
| 32 | 5.583 | 36.415 | Schaden/Schuss 82,0 → 84,0 | +2,44 % | 2.289 | 1.246 | +320,0 % |
| 33 | 6.588 | 43.003 | Schaden/Schuss 84,0 → 86,0 | +2,38 % | 2.767 | 1.471 | +330,0 % |
| 34 | 7.774 | 50.777 | Schaden/Schuss 86,0 → 88,0 | +2,33 % | 3.343 | 1.735 | +340,0 % |
| 35 | 9.173 | 59.950 | Schaden/Schuss 88,0 → 90,0 | +2,27 % | 4.036 | 2.048 | +350,0 % |
| 36 | 10.824 | 70.774 | Schaden/Schuss 90,0 → 92,0 | +2,22 % | 4.871 | 2.416 | +360,0 % |
| 37 | 12.772 | 83.546 | Schaden/Schuss 92,0 → 94,0 | +2,17 % | 5.875 | 2.851 | +370,0 % |
| 38 | 15.071 | 98.617 | Schaden/Schuss 94,0 → 96,0 | +2,13 % | 7.083 | 3.364 | +380,0 % |
| 39 | 17.784 | 116.401 | Schaden/Schuss 96,0 → 98,0 | +2,08 % | 8.536 | 3.970 | +390,0 % |
| 40 | 20.985 | 137.386 | Schaden/Schuss 98,0 → 100,0 | +2,04 % | 10.283 | 4.684 | +400,0 % |

#### Mobiler Turm – Feuerrate

**Verändert:** Abklingzeit zwischen zwei Schüssen (Feuerrate = 1 ÷ Abklingzeit). Mehr Schüsse brauchen entsprechend mehr Energie pro Sekunde. **Je Stufe:** +6 % Feuerrate.

Neubau zum Vergleich: 3,35 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 38 | 38 | 0,500 → 0,472 s (2,12 Schüsse/s) | +6,00 % | 6,33 | 14,1 | +6,0 % |
| 2 | 44 | 82 | 0,472 → 0,446 s (2,24 Schüsse/s) | +5,66 % | 7,77 | 16,4 | +12,0 % |
| 3 | 52 | 134 | 0,446 → 0,424 s (2,36 Schüsse/s) | +5,36 % | 9,71 | 19,3 | +18,0 % |
| 4 | 62 | 196 | 0,424 → 0,403 s (2,48 Schüsse/s) | +5,08 % | 12,2 | 23,1 | +24,0 % |
| 5 | 73 | 269 | 0,403 → 0,385 s (2,60 Schüsse/s) | +4,84 % | 15,1 | 27,2 | +30,0 % |
| 6 | 86 | 355 | 0,385 → 0,368 s (2,72 Schüsse/s) | +4,62 % | 18,6 | 32,0 | +36,0 % |
| 7 | 101 | 456 | 0,368 → 0,352 s (2,84 Schüsse/s) | +4,41 % | 22,9 | 37,6 | +42,0 % |
| 8 | 119 | 575 | 0,352 → 0,338 s (2,96 Schüsse/s) | +4,23 % | 28,2 | 44,3 | +48,0 % |
| 9 | 141 | 716 | 0,338 → 0,325 s (3,08 Schüsse/s) | +4,05 % | 34,8 | 52,5 | +54,0 % |
| 10 | 166 | 882 | 0,325 → 0,312 s (3,20 Schüsse/s) | +3,90 % | 42,6 | 61,8 | +60,0 % |
| 11 | 196 | 1.078 | 0,312 → 0,301 s (3,32 Schüsse/s) | +3,75 % | 52,3 | 72,9 | +66,0 % |
| 12 | 232 | 1.310 | 0,301 → 0,291 s (3,44 Schüsse/s) | +3,61 % | 64,2 | 86,3 | +72,0 % |
| 13 | 273 | 1.583 | 0,291 → 0,281 s (3,56 Schüsse/s) | +3,49 % | 78,3 | 102 | +78,0 % |
| 14 | 322 | 1.905 | 0,281 → 0,272 s (3,68 Schüsse/s) | +3,37 % | 95,5 | 120 | +84,0 % |
| 15 | 381 | 2.286 | 0,272 → 0,263 s (3,80 Schüsse/s) | +3,26 % | 117 | 142 | +90,0 % |
| 16 | 449 | 2.735 | 0,263 → 0,255 s (3,92 Schüsse/s) | +3,16 % | 142 | 167 | +96,0 % |
| 17 | 530 | 3.265 | 0,255 → 0,248 s (4,04 Schüsse/s) | +3,06 % | 173 | 197 | +102,0 % |
| 18 | 625 | 3.890 | 0,248 → 0,240 s (4,16 Schüsse/s) | +2,97 % | 210 | 233 | +108,0 % |
| 19 | 738 | 4.628 | 0,240 → 0,234 s (4,28 Schüsse/s) | +2,88 % | 256 | 275 | +114,0 % |
| 20 | 871 | 5.499 | 0,234 → 0,227 s (4,40 Schüsse/s) | +2,80 % | 311 | 324 | +120,0 % |
| 21 | 1.027 | 6.526 | 0,227 → 0,221 s (4,52 Schüsse/s) | +2,73 % | 377 | 382 | +126,0 % |
| 22 | 1.212 | 7.738 | 0,221 → 0,216 s (4,64 Schüsse/s) | +2,65 % | 457 | 451 | +132,0 % |
| 23 | 1.430 | 9.168 | 0,216 → 0,210 s (4,76 Schüsse/s) | +2,59 % | 553 | 532 | +138,0 % |
| 24 | 1.688 | 10.856 | 0,210 → 0,205 s (4,88 Schüsse/s) | +2,52 % | 670 | 628 | +144,0 % |
| 25 | 1.992 | 12.848 | 0,205 → 0,200 s (5,00 Schüsse/s) | +2,46 % | 810 | 741 | +150,0 % |

#### Mobiler Turm – Überladung

**Verändert:** Schaden ×(1 + 0,2 × Stufe), aber Energie je Schuss ×1,25 je Stufe. Braucht ein Schuss mehr Energie als der Speicher fasst, feuert der Turm nicht mehr (Überladung, Grenze ohne Kapazitäts- und Effizienz-Upgrades). **Je Stufe:** +20 % Schaden, ×1,25 Energie.

Neubau zum Vergleich: 3,35 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt | Nebenwirkung |
|---|---|---|---|---|---|---|---|---|
| 1 | 23 | 23 | Schaden 20,0 → 24,0 · Energie/Schuss 3,00 → 3,75 | +20,00 % | 1,15 | 2,57 | +20,0 % | Schaden je Energie −4,0 % |
| 2 | 27 | 50 | Schaden 24,0 → 28,0 · Energie/Schuss 3,75 → 4,69 | +16,67 % | 1,62 | 3,01 | +40,0 % | Schaden je Energie −6,7 % |
| 3 | 31 | 81 | Schaden 28,0 → 32,0 · Energie/Schuss 4,69 → 5,86 | +14,29 % | 2,17 | 3,46 | +60,0 % | Schaden je Energie −8,6 % |
| 4 | 37 | 118 | Schaden 32,0 → 36,0 · Energie/Schuss 5,86 → 7,32 | +12,50 % | 2,96 | 4,13 | +80,0 % | Schaden je Energie −10,0 % |
| 5 | 44 | 162 | Schaden 36,0 → 40,0 · Energie/Schuss 7,32 → 9,16 | +11,11 % | 3,96 | 4,91 | +100,0 % | Schaden je Energie −11,1 % |
| 6 | 51 | 213 | Schaden 40,0 → 44,0 · Energie/Schuss 9,16 → 11,44 | +10,00 % | 5,10 | 5,69 | +120,0 % | Schaden je Energie −12,0 % |
| 7 | 61 | 274 | Schaden 44,0 → 48,0 · Energie/Schuss 11,44 → 14,31 | +9,09 % | 6,71 | 6,81 | +140,0 % | Schaden je Energie −12,7 % |
| 8 | 72 | 346 | Schaden 48,0 → 52,0 · Energie/Schuss 14,31 → 17,88 | +8,33 % | 8,64 | 8,04 | +160,0 % | Schaden je Energie −13,3 % |
| 9 | 85 | 431 | Schaden 52,0 → 56,0 · Energie/Schuss 17,88 → 22,35 | +7,69 % | 11,1 | 9,49 | +180,0 % | Schaden je Energie −13,8 % |
| 10 | 100 | 531 | Schaden 56,0 → 60,0 · Energie/Schuss 22,35 → 27,94 | +7,14 % | 14,0 | 11,2 | +200,0 % | Schaden je Energie −14,3 % |
| 11 | 118 | 649 | Schaden 60,0 → 64,0 · Energie/Schuss 27,94 → 34,92 | +6,67 % | 17,7 | 13,2 | +220,0 % | Schaden je Energie −14,7 % |
| 12 | 139 | 788 | Schaden 64,0 → 68,0 · Energie/Schuss 34,92 → 43,66 | +6,25 % | 22,2 | 15,5 | +240,0 % | Schaden je Energie −15,0 % |

#### Mobiler Turm – Reichweite

**Verändert:** Angriffsreichweite (und damit Sichtweite). Die abgedeckte Fläche wächst etwa doppelt so stark wie der Radius. **Je Stufe:** +4 % des Grundwerts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Feld | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 45 | 45 | 3,75 → 3,90 Felder | +4,00 % | 11,2 | 300 | +4,0 % |
| 2 | 53 | 98 | 3,90 → 4,05 Felder | +3,85 % | 13,8 | 353 | +8,0 % |
| 3 | 63 | 161 | 4,05 → 4,20 Felder | +3,70 % | 17,0 | 420 | +12,0 % |
| 4 | 74 | 235 | 4,20 → 4,35 Felder | +3,57 % | 20,7 | 493 | +16,0 % |
| 5 | 87 | 322 | 4,35 → 4,50 Felder | +3,45 % | 25,2 | 580 | +20,0 % |
| 6 | 103 | 425 | 4,50 → 4,65 Felder | +3,33 % | 30,9 | 687 | +24,0 % |
| 7 | 121 | 546 | 4,65 → 4,80 Felder | +3,23 % | 37,5 | 807 | +28,0 % |
| 8 | 143 | 689 | 4,80 → 4,95 Felder | +3,12 % | 45,8 | 953 | +32,0 % |
| 9 | 169 | 858 | 4,95 → 5,10 Felder | +3,03 % | 55,8 | 1.127 | +36,0 % |
| 10 | 200 | 1.058 | 5,10 → 5,25 Felder | +2,94 % | 68,0 | 1.333 | +40,0 % |
| 11 | 236 | 1.294 | 5,25 → 5,40 Felder | +2,86 % | 82,6 | 1.573 | +44,0 % |
| 12 | 278 | 1.572 | 5,40 → 5,55 Felder | +2,78 % | 100 | 1.853 | +48,0 % |
| 13 | 328 | 1.900 | 5,55 → 5,70 Felder | +2,70 % | 121 | 2.187 | +52,0 % |
| 14 | 387 | 2.287 | 5,70 → 5,85 Felder | +2,63 % | 147 | 2.580 | +56,0 % |
| 15 | 457 | 2.744 | 5,85 → 6,00 Felder | +2,56 % | 178 | 3.047 | +60,0 % |

#### Mobiler Turm – Kritische Treffer

**Verändert:** Chance auf einen kritischen Treffer (doppelter Schaden). Nutzen = Anstieg des durchschnittlichen Schadens (1 + Krit-Chance). **Je Stufe:** +1 Prozentpunkt.

Neubau zum Vergleich: 3,35 Münzen je DPS.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je DPS | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 38 | 38 | Krit-Chance 12 % → 13 % | +0,89 % | 42,6 | 95,0 | +0,9 % |
| 2 | 44 | 82 | Krit-Chance 13 % → 14 % | +0,88 % | 49,7 | 110 | +1,8 % |
| 3 | 52 | 134 | Krit-Chance 14 % → 15 % | +0,88 % | 59,3 | 130 | +2,7 % |
| 4 | 62 | 196 | Krit-Chance 15 % → 16 % | +0,87 % | 71,3 | 155 | +3,6 % |
| 5 | 73 | 269 | Krit-Chance 16 % → 17 % | +0,86 % | 84,7 | 183 | +4,5 % |
| 6 | 86 | 355 | Krit-Chance 17 % → 18 % | +0,85 % | 101 | 215 | +5,4 % |
| 7 | 101 | 456 | Krit-Chance 18 % → 19 % | +0,85 % | 119 | 253 | +6,2 % |
| 8 | 119 | 575 | Krit-Chance 19 % → 20 % | +0,84 % | 142 | 297 | +7,1 % |
| 9 | 141 | 716 | Krit-Chance 20 % → 21 % | +0,83 % | 169 | 353 | +8,0 % |
| 10 | 166 | 882 | Krit-Chance 21 % → 22 % | +0,83 % | 201 | 415 | +8,9 % |
| 11 | 196 | 1.078 | Krit-Chance 22 % → 23 % | +0,82 % | 239 | 490 | +9,8 % |
| 12 | 232 | 1.310 | Krit-Chance 23 % → 24 % | +0,81 % | 285 | 580 | +10,7 % |
| 13 | 273 | 1.583 | Krit-Chance 24 % → 25 % | +0,81 % | 339 | 683 | +11,6 % |
| 14 | 322 | 1.905 | Krit-Chance 25 % → 26 % | +0,80 % | 402 | 805 | +12,5 % |
| 15 | 381 | 2.286 | Krit-Chance 26 % → 27 % | +0,79 % | 480 | 953 | +13,4 % |
| 16 | 449 | 2.735 | Krit-Chance 27 % → 28 % | +0,79 % | 570 | 1.122 | +14,3 % |
| 17 | 530 | 3.265 | Krit-Chance 28 % → 29 % | +0,78 % | 678 | 1.325 | +15,2 % |
| 18 | 625 | 3.890 | Krit-Chance 29 % → 30 % | +0,78 % | 806 | 1.563 | +16,1 % |
| 19 | 738 | 4.628 | Krit-Chance 30 % → 31 % | +0,77 % | 959 | 1.845 | +17,0 % |
| 20 | 871 | 5.499 | Krit-Chance 31 % → 32 % | +0,76 % | 1.141 | 2.178 | +17,9 % |

#### Mobiler Turm – Fahreffizienz

**Verändert:** Senkt die Energie je Schuss und je gefahrenem Feld (Energie ÷ Effizienz). **Je Stufe:** +5 % Effizienz.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je (Schaden/Energie) | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 30 | 30 | Energie/Schuss 3,00 → 2,86 · Fahren 6,72 → 6,40 Energie/Feld | +5,00 % | 6,00 | 80,4 | +5,0 % |
| 2 | 35 | 65 | Energie/Schuss 2,86 → 2,73 · Fahren 6,40 → 6,11 Energie/Feld | +4,76 % | 7,35 | 93,7 | +10,0 % |
| 3 | 42 | 107 | Energie/Schuss 2,73 → 2,61 · Fahren 6,11 → 5,84 Energie/Feld | +4,55 % | 9,24 | 113 | +15,0 % |
| 4 | 49 | 156 | Energie/Schuss 2,61 → 2,50 · Fahren 5,84 → 5,60 Energie/Feld | +4,35 % | 11,3 | 131 | +20,0 % |
| 5 | 58 | 214 | Energie/Schuss 2,50 → 2,40 · Fahren 5,60 → 5,38 Energie/Feld | +4,17 % | 13,9 | 155 | +25,0 % |
| 6 | 69 | 283 | Energie/Schuss 2,40 → 2,31 · Fahren 5,38 → 5,17 Energie/Feld | +4,00 % | 17,2 | 185 | +30,0 % |
| 7 | 81 | 364 | Energie/Schuss 2,31 → 2,22 · Fahren 5,17 → 4,98 Energie/Feld | +3,85 % | 21,1 | 217 | +35,0 % |
| 8 | 96 | 460 | Energie/Schuss 2,22 → 2,14 · Fahren 4,98 → 4,80 Energie/Feld | +3,70 % | 25,9 | 257 | +40,0 % |
| 9 | 113 | 573 | Energie/Schuss 2,14 → 2,07 · Fahren 4,80 → 4,63 Energie/Feld | +3,57 % | 31,6 | 303 | +45,0 % |
| 10 | 133 | 706 | Energie/Schuss 2,07 → 2,00 · Fahren 4,63 → 4,48 Energie/Feld | +3,45 % | 38,6 | 356 | +50,0 % |
| 11 | 157 | 863 | Energie/Schuss 2,00 → 1,94 · Fahren 4,48 → 4,34 Energie/Feld | +3,33 % | 47,1 | 421 | +55,0 % |
| 12 | 185 | 1.048 | Energie/Schuss 1,94 → 1,88 · Fahren 4,34 → 4,20 Energie/Feld | +3,23 % | 57,4 | 496 | +60,0 % |
| 13 | 219 | 1.267 | Energie/Schuss 1,88 → 1,82 · Fahren 4,20 → 4,07 Energie/Feld | +3,12 % | 70,1 | 587 | +65,0 % |
| 14 | 258 | 1.525 | Energie/Schuss 1,82 → 1,76 · Fahren 4,07 → 3,95 Energie/Feld | +3,03 % | 85,1 | 691 | +70,0 % |
| 15 | 304 | 1.829 | Energie/Schuss 1,76 → 1,71 · Fahren 3,95 → 3,84 Energie/Feld | +2,94 % | 103 | 814 | +75,0 % |
| 16 | 359 | 2.188 | Energie/Schuss 1,71 → 1,67 · Fahren 3,84 → 3,73 Energie/Feld | +2,86 % | 126 | 962 | +80,0 % |
| 17 | 424 | 2.612 | Energie/Schuss 1,67 → 1,62 · Fahren 3,73 → 3,63 Energie/Feld | +2,78 % | 153 | 1.136 | +85,0 % |
| 18 | 500 | 3.112 | Energie/Schuss 1,62 → 1,58 · Fahren 3,63 → 3,54 Energie/Feld | +2,70 % | 185 | 1.339 | +90,0 % |
| 19 | 590 | 3.702 | Energie/Schuss 1,58 → 1,54 · Fahren 3,54 → 3,45 Energie/Feld | +2,63 % | 224 | 1.580 | +95,0 % |
| 20 | 696 | 4.398 | Energie/Schuss 1,54 → 1,50 · Fahren 3,45 → 3,36 Energie/Feld | +2,56 % | 271 | 1.864 | +100,0 % |

#### Mobiler Turm – Kapazität

**Verändert:** Energiespeicher (Vorrat für Schüsse bzw. Aktionen, Pufferspeicher im Netz). Hebt die Grenze, ab der eine Überladung den Turm stilllegt. **Je Stufe:** +20 % des Grundwerts.

Neubau zum Vergleich: 1,25 Münzen je Energie.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je Energie | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 27 | 27 | 120,0 → 144,0 Energie | +20,00 % | 1,35 | 1,12 | +20,0 % |
| 2 | 32 | 59 | 144,0 → 168,0 Energie | +16,67 % | 1,92 | 1,33 | +40,0 % |
| 3 | 38 | 97 | 168,0 → 192,0 Energie | +14,29 % | 2,66 | 1,58 | +60,0 % |
| 4 | 44 | 141 | 192,0 → 216,0 Energie | +12,50 % | 3,52 | 1,83 | +80,0 % |
| 5 | 52 | 193 | 216,0 → 240,0 Energie | +11,11 % | 4,68 | 2,17 | +100,0 % |
| 6 | 62 | 255 | 240,0 → 264,0 Energie | +10,00 % | 6,20 | 2,58 | +120,0 % |
| 7 | 73 | 328 | 264,0 → 288,0 Energie | +9,09 % | 8,03 | 3,04 | +140,0 % |
| 8 | 86 | 414 | 288,0 → 312,0 Energie | +8,33 % | 10,3 | 3,58 | +160,0 % |
| 9 | 101 | 515 | 312,0 → 336,0 Energie | +7,69 % | 13,1 | 4,21 | +180,0 % |
| 10 | 120 | 635 | 336,0 → 360,0 Energie | +7,14 % | 16,8 | 5,00 | +200,0 % |
| 11 | 141 | 776 | 360,0 → 384,0 Energie | +6,67 % | 21,2 | 5,88 | +220,0 % |
| 12 | 167 | 943 | 384,0 → 408,0 Energie | +6,25 % | 26,7 | 6,96 | +240,0 % |
| 13 | 197 | 1.140 | 408,0 → 432,0 Energie | +5,88 % | 33,5 | 8,21 | +260,0 % |
| 14 | 232 | 1.372 | 432,0 → 456,0 Energie | +5,56 % | 41,8 | 9,67 | +280,0 % |
| 15 | 274 | 1.646 | 456,0 → 480,0 Energie | +5,26 % | 52,1 | 11,4 | +300,0 % |
| 16 | 323 | 1.969 | 480,0 → 504,0 Energie | +5,00 % | 64,6 | 13,5 | +320,0 % |
| 17 | 381 | 2.350 | 504,0 → 528,0 Energie | +4,76 % | 80,0 | 15,9 | +340,0 % |
| 18 | 450 | 2.800 | 528,0 → 552,0 Energie | +4,55 % | 99,0 | 18,8 | +360,0 % |
| 19 | 531 | 3.331 | 552,0 → 576,0 Energie | +4,35 % | 122 | 22,1 | +380,0 % |
| 20 | 627 | 3.958 | 576,0 → 600,0 Energie | +4,17 % | 150 | 26,1 | +400,0 % |
| 21 | 740 | 4.698 | 600,0 → 624,0 Energie | +4,00 % | 185 | 30,8 | +420,0 % |
| 22 | 873 | 5.571 | 624,0 → 648,0 Energie | +3,85 % | 227 | 36,4 | +440,0 % |
| 23 | 1.030 | 6.601 | 648,0 → 672,0 Energie | +3,70 % | 278 | 42,9 | +460,0 % |
| 24 | 1.215 | 7.816 | 672,0 → 696,0 Energie | +3,57 % | 340 | 50,6 | +480,0 % |
| 25 | 1.434 | 9.250 | 696,0 → 720,0 Energie | +3,45 % | 416 | 59,8 | +500,0 % |

#### Mobiler Turm – Strahlübertragung

**Verändert:** Senkt den Strahlverlust auf eingehenden Strahlen (Verlust × (1 − 0,1 × Stufe), Stufe 10 = verlustfrei). Nutzen gemessen an einem Referenzstrahl mit 10 % Grundverlust (≈ 4 Felder Spannweite, Gegenstelle ohne Upgrade); bei kürzeren Strahlen entsprechend weniger. **Je Stufe:** −10 % des Strahlverlusts.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Nutzen gesamt |
|---|---|---|---|---|---|---|
| 1 | 30 | 30 | Verlustfaktor 100 % → 90 % (Referenz 90,0 % → 91,0 % kommt an) | +1,11 % | 27,0 | +1,1 % |
| 2 | 35 | 65 | Verlustfaktor 90 % → 80 % (Referenz 91,0 % → 92,0 % kommt an) | +1,10 % | 31,9 | +2,2 % |
| 3 | 42 | 107 | Verlustfaktor 80 % → 70 % (Referenz 92,0 % → 93,0 % kommt an) | +1,09 % | 38,6 | +3,3 % |
| 4 | 49 | 156 | Verlustfaktor 70 % → 60 % (Referenz 93,0 % → 94,0 % kommt an) | +1,08 % | 45,6 | +4,4 % |
| 5 | 58 | 214 | Verlustfaktor 60 % → 50 % (Referenz 94,0 % → 95,0 % kommt an) | +1,06 % | 54,5 | +5,6 % |
| 6 | 69 | 283 | Verlustfaktor 50 % → 40 % (Referenz 95,0 % → 96,0 % kommt an) | +1,05 % | 65,5 | +6,7 % |
| 7 | 81 | 364 | Verlustfaktor 40 % → 30 % (Referenz 96,0 % → 97,0 % kommt an) | +1,04 % | 77,8 | +7,8 % |
| 8 | 96 | 460 | Verlustfaktor 30 % → 20 % (Referenz 97,0 % → 98,0 % kommt an) | +1,03 % | 93,1 | +8,9 % |
| 9 | 113 | 573 | Verlustfaktor 20 % → 10 % (Referenz 98,0 % → 99,0 % kommt an) | +1,02 % | 111 | +10,0 % |
| 10 | 133 | 706 | Verlustfaktor 10 % → 0 % (Referenz 99,0 % → 100,0 % kommt an) | +1,01 % | 132 | +11,1 % |

#### Mobiler Turm – Leben

**Verändert:** Maximale Trefferpunkte. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,938 Münzen je HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 27 | 27 | 160,0 → 184,0 HP | +15,00 % | 1,80 | 1,125 | +15,0 % |
| 2 | 32 | 59 | 184,0 → 208,0 HP | +13,04 % | 2,45 | 1,333 | +30,0 % |
| 3 | 38 | 97 | 208,0 → 232,0 HP | +11,54 % | 3,29 | 1,583 | +45,0 % |
| 4 | 44 | 141 | 232,0 → 256,0 HP | +10,34 % | 4,25 | 1,833 | +60,0 % |
| 5 | 52 | 193 | 256,0 → 280,0 HP | +9,38 % | 5,55 | 2,167 | +75,0 % |
| 6 | 62 | 255 | 280,0 → 304,0 HP | +8,57 % | 7,23 | 2,583 | +90,0 % |
| 7 | 73 | 328 | 304,0 → 328,0 HP | +7,89 % | 9,25 | 3,042 | +105,0 % |
| 8 | 86 | 414 | 328,0 → 352,0 HP | +7,32 % | 11,8 | 3,583 | +120,0 % |
| 9 | 101 | 515 | 352,0 → 376,0 HP | +6,82 % | 14,8 | 4,208 | +135,0 % |
| 10 | 120 | 635 | 376,0 → 400,0 HP | +6,38 % | 18,8 | 5,000 | +150,0 % |
| 11 | 141 | 776 | 400,0 → 424,0 HP | +6,00 % | 23,5 | 5,875 | +165,0 % |
| 12 | 167 | 943 | 424,0 → 448,0 HP | +5,66 % | 29,5 | 6,958 | +180,0 % |
| 13 | 197 | 1.140 | 448,0 → 472,0 HP | +5,36 % | 36,8 | 8,208 | +195,0 % |
| 14 | 232 | 1.372 | 472,0 → 496,0 HP | +5,08 % | 45,6 | 9,667 | +210,0 % |
| 15 | 274 | 1.646 | 496,0 → 520,0 HP | +4,84 % | 56,6 | 11,417 | +225,0 % |
| 16 | 323 | 1.969 | 520,0 → 544,0 HP | +4,62 % | 70,0 | 13,458 | +240,0 % |
| 17 | 381 | 2.350 | 544,0 → 568,0 HP | +4,41 % | 86,4 | 15,875 | +255,0 % |
| 18 | 450 | 2.800 | 568,0 → 592,0 HP | +4,23 % | 107 | 18,750 | +270,0 % |
| 19 | 531 | 3.331 | 592,0 → 616,0 HP | +4,05 % | 131 | 22,125 | +285,0 % |
| 20 | 627 | 3.958 | 616,0 → 640,0 HP | +3,90 % | 161 | 26,125 | +300,0 % |
| 21 | 740 | 4.698 | 640,0 → 664,0 HP | +3,75 % | 197 | 30,833 | +315,0 % |
| 22 | 873 | 5.571 | 664,0 → 688,0 HP | +3,61 % | 242 | 36,375 | +330,0 % |
| 23 | 1.030 | 6.601 | 688,0 → 712,0 HP | +3,49 % | 295 | 42,917 | +345,0 % |
| 24 | 1.215 | 7.816 | 712,0 → 736,0 HP | +3,37 % | 360 | 50,625 | +360,0 % |
| 25 | 1.434 | 9.250 | 736,0 → 760,0 HP | +3,26 % | 440 | 59,750 | +375,0 % |
| 26 | 1.692 | 10.942 | 760,0 → 784,0 HP | +3,16 % | 536 | 70,500 | +390,0 % |
| 27 | 1.997 | 12.939 | 784,0 → 808,0 HP | +3,06 % | 652 | 83,208 | +405,0 % |
| 28 | 2.356 | 15.295 | 808,0 → 832,0 HP | +2,97 % | 793 | 98,167 | +420,0 % |
| 29 | 2.780 | 18.075 | 832,0 → 856,0 HP | +2,88 % | 964 | 115,833 | +435,0 % |
| 30 | 3.281 | 21.356 | 856,0 → 880,0 HP | +2,80 % | 1.170 | 136,708 | +450,0 % |

#### Mobiler Turm – Panzerung

**Verändert:** Panzerung. Jeder erlittene Treffer sinkt um Panzerung ÷ (Panzerung + 100), höchstens 90 %. Nutzen gemessen an den effektiven Lebenspunkten (Leben ÷ (1 − Reduktion)) mit Grund-Leben, ohne Mindestschaden. **Je Stufe:** +15 % des Grundwerts.

Neubau zum Vergleich: 0,84 Münzen je eff. HP.

| Stufe | Kosten | Summe | Veränderung | Nutzen | Münzen je % | Münzen je eff. HP | Nutzen gesamt |
|---|---|---|---|---|---|---|---|
| 1 | 23 | 23 | Panzerung 12,0 → 13,8 (−10,7 % → −12,1 %) | +1,61 % | 14,3 | 7,99 | +1,6 % |
| 2 | 27 | 50 | Panzerung 13,8 → 15,6 (−12,1 % → −13,5 %) | +1,58 % | 17,1 | 9,38 | +3,2 % |
| 3 | 31 | 81 | Panzerung 15,6 → 17,4 (−13,5 % → −14,8 %) | +1,56 % | 19,9 | 10,8 | +4,8 % |
| 4 | 37 | 118 | Panzerung 17,4 → 19,2 (−14,8 % → −16,1 %) | +1,53 % | 24,1 | 12,8 | +6,4 % |
| 5 | 44 | 162 | Panzerung 19,2 → 21,0 (−16,1 % → −17,4 %) | +1,51 % | 29,1 | 15,3 | +8,0 % |
| 6 | 51 | 213 | Panzerung 21,0 → 22,8 (−17,4 % → −18,6 %) | +1,49 % | 34,3 | 17,7 | +9,6 % |
| 7 | 61 | 274 | Panzerung 22,8 → 24,6 (−18,6 % → −19,7 %) | +1,47 % | 41,6 | 21,2 | +11,3 % |
| 8 | 72 | 346 | Panzerung 24,6 → 26,4 (−19,7 % → −20,9 %) | +1,44 % | 49,8 | 25,0 | +12,9 % |
| 9 | 85 | 431 | Panzerung 26,4 → 28,2 (−20,9 % → −22,0 %) | +1,42 % | 59,7 | 29,5 | +14,5 % |
| 10 | 100 | 531 | Panzerung 28,2 → 30,0 (−22,0 % → −23,1 %) | +1,40 % | 71,2 | 34,7 | +16,1 % |
| 11 | 118 | 649 | Panzerung 30,0 → 31,8 (−23,1 % → −24,1 %) | +1,38 % | 85,2 | 41,0 | +17,7 % |
| 12 | 139 | 788 | Panzerung 31,8 → 33,6 (−24,1 % → −25,1 %) | +1,37 % | 102 | 48,3 | +19,3 % |
| 13 | 164 | 952 | Panzerung 33,6 → 35,4 (−25,1 % → −26,1 %) | +1,35 % | 122 | 56,9 | +20,9 % |
| 14 | 193 | 1.145 | Panzerung 35,4 → 37,2 (−26,1 % → −27,1 %) | +1,33 % | 145 | 67,0 | +22,5 % |
| 15 | 228 | 1.373 | Panzerung 37,2 → 39,0 (−27,1 % → −28,1 %) | +1,31 % | 174 | 79,2 | +24,1 % |
| 16 | 269 | 1.642 | Panzerung 39,0 → 40,8 (−28,1 % → −29,0 %) | +1,29 % | 208 | 93,4 | +25,7 % |
| 17 | 318 | 1.960 | Panzerung 40,8 → 42,6 (−29,0 % → −29,9 %) | +1,28 % | 249 | 110 | +27,3 % |
| 18 | 375 | 2.335 | Panzerung 42,6 → 44,4 (−29,9 % → −30,7 %) | +1,26 % | 297 | 130 | +28,9 % |
| 19 | 443 | 2.778 | Panzerung 44,4 → 46,2 (−30,7 % → −31,6 %) | +1,25 % | 355 | 154 | +30,5 % |
| 20 | 522 | 3.300 | Panzerung 46,2 → 48,0 (−31,6 % → −32,4 %) | +1,23 % | 424 | 181 | +32,1 % |
