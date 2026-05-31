# Changelog

## 1.11.0-internal - 2026-05-31

### Economy / Shop-System

- Stammkunden / Loyalität: Filialen mit *dauerhaft* hoher Reputation bauen über
  die Zeit einen treuen Kundenstamm auf (Zeit-Integral der Reputation, nicht nur
  Momentaufnahme) und erhalten dafür einen stabilen Kundenstrom-Bonus (bis
  +10 %). Niedrige Reputation oder geschlossene Filialen bauen den Stamm wieder
  ab; charmante Mitarbeiter beschleunigen den Aufbau. Neues `Shop.regulars`
  (0..0,5, Default 0 = balance-neutral) — speicherkompatibel, keine UI-Änderung.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 171 Tests erfolgreich

## 1.10.0-internal - 2026-05-31

### Konkurrenzsystem

- Marktaustritt (Decline & Exit): Dauerhaft schwache Konkurrenten (niedrige
  Reputation UND niedriger Marktanteil) schrumpfen schrittweise — sie verlieren
  zuerst Filialen und verlassen schließlich den Markt. Strauchelnde Ketten
  expandieren nicht mehr. Difficulty-skaliert (aggressivere Märkte = zähere
  Konkurrenz); der letzte Wettbewerber einer Stadt scheidet nie durch Schwäche
  aus, damit kein Markt verödet. Symmetrisch zur Konkurrenz-Übernahme. Nutzt nur
  vorhandene Felder — keine Save-Änderung, sichtbar über die bestehende
  Konkurrenz-Liste.

### Tests

- Regressionstest, der die City-Map-Ökonomik (`LocationEngine`/`CityMapLocation`)
  gegen die kanonische Filialöffnungs-Formel (footTraffic/Miete/Kaution) sperrt.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 164 Tests erfolgreich

## 1.9.1-internal - 2026-05-31

### Tutorial überarbeitet (weniger blockierend)

- Die Tutorial-Karte verdeckt den Bildschirm nicht mehr: Eingeklappt ist sie
  jetzt eine schlanke Ein-Zeilen-Pille (Schritt-Badge + Titel + Aufklapp-Pfeil)
  statt eines großen Blocks mit Fortschrittsbalken, Beschreibung und Buttons.
- Sanftes Auf-/Zuklappen (animiert), aufgeräumtere Detail-Ansicht, Tippen auf
  die Pille klappt auf.
- „Später" klappt jetzt nur noch ein (Tutorial bleibt aktiv), statt das Tutorial
  versehentlich ganz zu beenden — nur „Überspringen" beendet es.
- Bewusst weiterhin oben verankert, damit unten platzierte Aktionsbuttons
  (z. B. „Tag beenden") nicht verdeckt werden.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 156 Tests erfolgreich

## 1.9.0-internal - 2026-05-31

### Lokalisierung (Grundlage)

- Sprach-Grundlage DE/TR/EN: Persistierte Sprachwahl (`LanguageService`) + ein
  erweiterbares `AppStrings`-System. Der bisherige Platzhalter „Sprache ändern"
  ist jetzt ein funktionierender Sprach-Picker im Spielmenü. Vollständig
  übersetzt sind aktuell die App-Navigation und das Spielmenü; die übrigen
  In-Game-Texte bleiben vorerst deutsch und werden inkrementell ergänzt.
- Bewusst als schlanke, build-sichere Fassade umgesetzt (kein gen-l10n/ARB-
  Umbau) — die vollständige String-Migration ist als eigener Schritt vorgesehen.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 156 Tests erfolgreich

## 1.8.0-internal - 2026-05-31

### Sim-Tiefe (Block B)

- Mitarbeiter-Moral / Burnout: Jede Filiale hat eine Team-Moral. Dauerhafte
  Überlastung (an der Kapazitätsgrenze) drückt die Moral, ausreichend Personal
  lässt sie sich erholen; Mentor hebt, Hitzkopf senkt sie. Die Moral moduliert
  die Personal-Leistung (±, neutral bei Standard-Moral 0,75) und löst bei
  niedrigen Werten eine Burnout-Warnung aus. Anzeige im Personal-Tab.
  Speicherkompatibel & balance-neutral by default.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 152 Tests erfolgreich

## 1.7.0-internal - 2026-05-31

### Sim-Tiefe (Block B)

- Mitarbeiter-Schichtplanung (Peak-Staffing): Jeder Mitarbeiter kann auf eine
  Schicht (Ganztags/Früh/Mittag/Abend) gesetzt werden. Wer Personal auf die
  Stoßzeit des Standorts ausrichtet (Bürogegend→Mittag, Uni/Wohngebiet/
  Ausgehviertel→Abend), erhöht die effektive Kapazität um bis zu +15 %.
  Standorte mit gleichmäßiger Nachfrage (touristisch/Verkehrsknoten) bieten
  keinen Schicht-Vorteil. Bedienbar pro Mitarbeiter im Personal-Tab; die
  optimale Schicht ist mit ⭐ markiert. Balance-neutral by default (alle
  „ganztags" = keine Änderung), speicherkompatibel.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 146 Tests erfolgreich (inkl. Stoßzeiten, Kapazitäts-Bonus und
  Save-Kompatibilität)

## 1.6.0-internal - 2026-05-31

### Trophäen & Technik (Block C)

- Neue Trophäen für die jüngsten Systeme: „Preis-Stratege" (erster
  Einkaufsvertrag), „Franchise-Gründer" (erstes Prestige) und „Prestige-Meister"
  (5 Prestige-Punkte). Erscheinen automatisch in der Trophäen-Galerie.
- „Regional aufgestellt" prüft jetzt korrekt Filialen in 3 *verschiedenen*
  Städten (vorher nur Filialzahl).
- Refactor: Achievement-Prüfungen laufen jetzt zustandsbasiert
  (`bool Function(GameState)`) statt über eine starre 9-Parameter-Signatur mit
  totem Argument — sauberer und erweiterbar.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 139 Tests erfolgreich

## 1.5.0-internal - 2026-05-31

### Sim-Tiefe & Wiederspielwert (Block B)

- Prestige / Franchise (New-Game+): Ab 1 Mio € Gesamtumsatz lässt sich ein
  Franchise neu gründen — das Imperium wird zurückgesetzt, der Spieler behält
  aber dauerhaft akkumulierte Prestige-Punkte (1 Punkt je 1 Mio € Umsatz). Jeder
  Punkt gibt dauerhaft +2 % Kundschaft (gedeckelt bei +30 %) und höheres
  Startkapital (+10.000 € je Punkt). Endgame-Loop für Vielspieler, im
  Konzern→Strategie-Tab mit Bestätigung. Prestige-Stufe erscheint in der
  teilbaren „Mein Imperium"-Karte. Speicherkompatibel.
- Konkurrenz-Übernahme (Buyout): In Städten mit eigener Filiale lässt sich ein
  Wettbewerber aufkaufen — Kaufpreis skaliert mit Filialzahl, Reputation und
  Marktanteil (gedeckelt). Entfernt den Konkurrenten und gibt einen Marken- und
  Reputationsschub in der betroffenen Stadt. Späte Cash-Senke mit echtem
  Marktnutzen, bedienbar in der Konkurrenz-Liste (Imperium-Tab).

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 138 Tests erfolgreich (inkl. Prestige, Konkurrenz-Übernahme,
  Nachfrage-Wirkung, Teilen und Save-Kompatibilität)

## 1.4.0-internal - 2026-05-31

### Sim-Tiefe (Block B)

- Einkaufsverträge / Preisbindung: Gegen eine einmalige Gebühr lässt sich der
  Zutaten-Preisindex für 14/30/60 Tage einfrieren — die strategische Antwort auf
  die Inflations-Simulation (A3). Wer rechtzeitig sichert, schützt seine Marge
  bei steigenden Preisen; wer falsch wettet, zahlt drauf. Gebühr skaliert mit
  den erwarteten Zutaten-Ausgaben (längere Bindung = günstigere Tagesprämie).
  Bedienbar über den Finanzen-Tab; speicherkompatibel (neue Felder mit
  Defaults).
- Dashboard-Hinweis: Bei hoher Zutateninflation ohne aktive Preisbindung weist
  das bestehende Hinweis-System auf die Absicherung im Finanzen-Tab hin
  (Discoverability).

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 122 Tests erfolgreich (inkl. Vertrags-Logik, Hedge-Wirkung,
  Save-Kompatibilität und Inflations-Hinweis)

## 1.3.0-internal - 2026-05-31

### Kulturmoment & Viralität (Block A)

- Politik-/News-Events: Das Event-System erhält sieben aktuelle deutsche
  Themen-Events mit echten Entscheidungen — „Dönerpreisbremse im Gespräch",
  Mehrwertsteuer-Streit, Energiekosten-Schock, Mindestlohn-Erhöhung,
  „Döner-Index" der Medien, virale #DönerChallenge und „Bester Döner der
  Stadt"-Voting. Wirken über Cash/Reputation/Markenbekanntheit.
- Döner-Index / teilbarer Preisvergleich: Eigener Ø-Döner-Preis wird gegen den
  Bundesschnitt (~8,03 €) gestellt — sichtbar als eigene Zeile in der
  „Mein Imperium"-Karte und im teilbaren Zusammenfassungstext
  (`#Döner-Index`).
- Inflations-/Zutatenpreis-Simulation: Ein deterministischer Zutaten-Preisindex
  (langsame Inflation + Rohstoff-Zyklus, gedeckelt auf ±max, 7 Tage Schonfrist)
  lässt Fleisch/Brot/Energie über die Zeit teurer werden und drückt die Marge —
  die spielbare Seite der „warum ist Döner so teuer"-Debatte. Sichtbar als
  Indikator im Finanzen-Tab.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 111 Tests erfolgreich (inkl. neuer Tests für Politik-Events,
  Döner-Index und Zutaten-Inflation)

## 1.2.0-internal - 2026-05-31

### Gameplay-Tiefe

- Kundentypen / Stadt-Demografie-Mix: Jede Filiale hat je nach Standort-Typ
  (Bürogegend, Uni-Viertel, Wohngebiet, …) einen Mix aus vier Kundensegmenten
  (Studenten, Familien, Feinschmecker, Mittagshektik). Der Mix moduliert
  Preissensibilität und durchschnittlichen Bonwert. Sichtbar als
  „Stammkundschaft"-Karte im Sortiment-Tab. Balance-neutral kalibriert
  (Segment-Mittel ≈ 1.0, kein globaler Umsatz-Drift).
- Mitarbeiter-Training: Zusätzlich zum bestehenden passiven On-the-Job-Wachstum
  jetzt bezahlte Kurse — gezielt einen Stat (Tempo/Freundlichkeit/
  Zuverlässigkeit/Erfahrung) gegen Cash um eine Stufe anheben. Kosten steigen
  mit der Zielstufe; ein Training-Coach (HR) macht Kurse günstiger.
- Konkurrenz-Preisreaktion: KI-Konkurrenten vergleichen ihr Preisniveau mit dem
  Stadt-Durchschnitt des Spielers und reagieren je Persönlichkeit — Aggressive
  und CheapMass unterbieten, Premium setzen sich bewusst darüber, Balanced
  ziehen nach, Traditionelle nur träge.

### Technisch

- Refactor: `shop_detail_screen.dart` (2304 Zeilen) in Tab-Module unter
  `lib/ui/screens/shop_detail/` aufgeteilt (Sortiment, Equipment, Personal,
  Marketing, Ausstattung, geteilte Widgets) via `part`/`part of` —
  verhaltensneutral.

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 98 Tests erfolgreich (inkl. neuer Tests für Kundensegmente,
  bezahltes Training und Konkurrenz-Preisreaktion)

## 1.1.0-internal - 2026-05-30

### Optik & Game-Feel

- Gebündelte Schriften (Baloo 2 / Inter) + app-weite Typografie
- Animationen (flutter_animate), Tap-Feedback (Pressable), Seiten-Übergänge
- Tagesabschluss-Konfetti, Splash-Politur
- Sound-Effekte (Kenney CC0) + Haptik, Mute-Schalter im Spielmenü
- Aktienkurs-Chart auf fl_chart umgestellt

### Story & Progression

- Story-Kampagne: 8 Kapitel mit Zielen, Cash-Belohnungen und permanenten
  Konzern-Perks; Perk-Übersicht; Kapitel-Abschluss-Feier
- Trophäen-Galerie (eigener Screen)
- Filial-Branding / Skins über Trophäen freischaltbar
- Start-Szenarien (Klassisch, Schuldenstart, Hardcore, High-Roller)

### Gameplay-Tiefe

- Kombo-Menüs / Mittagsangebote (an Produkt-/Equipment-Progression gekoppelt)
- Produkt-Qualitätsstufen (Günstig/Standard/Premium)
- Tagesspecial (täglich rotierendes Gericht mit Bonus-Nachfrage)
- Krisen-Events (Küchenbrand, Shitstorm, Einbruch, Stromausfall, u. a.)
- Quartalssteuer (12 % auf den Monatsgewinn)

### Analyse & Komfort

- Produkt-Profitabilität + Filial-Ranking (Finanzen)
- Dashboard-Hinweise (Verluste/Ruf/Liquidität)
- Unternehmens-Gesundheit (Health-Score) im Imperium-Tab
- Wochen-Report alle 7 Tage
- Empire-Share-Card (teilbare Zusammenfassung)

### Behoben

- Neues-Spiel zeigte veraltetes Startkapital (50 Mio. statt echtem Wert)

### Weitere Gameplay-/Analyse-Features

- Daily Challenges (tägliche, relativ gestellte Ziele mit Belohnung)
- Jahreszeiten (saisonale Kategorie-Nachfrage)
- Kunden-Bewertungen (prozedural aus Reputation/Preis/Qualität)
- Marktanteil-Visualisierung pro Stadt
- Preis-Empfehlung (umsatzoptimale Preise per Knopfdruck)
- 4 neue Trophäen (Langzeit-Ziele)
- Dashboard entzerrt (Tagesspecial + Tagesaufgabe als eine „Heute"-Karte)

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test`: 83 Tests erfolgreich (inkl. 60-Tage-Integrationstest aller Systeme)
- `flutter build apk --debug` erfolgreich

## 1.0.0-internal.1 - 2026-05-25

### Hinzugefügt

- Interne Release-Dokumentation für den ersten Testlauf:
  - Setup-/Build-Anleitung in der README
  - Liste bekannter Risiken/Bugs
  - Vorschläge für GitHub-Issues, Labels und Milestones
  - Manueller Testplan für interne Tester

### Geprüft

- `flutter analyze` ohne Findings
- `flutter test` erfolgreich
- Android Build:
  - `flutter build apk --debug` erfolgreich
  - `flutter build apk --release` erfolgreich

### Hinweise

- Release-Signing nutzt aktuell Debug-Key (nur für interne Verteilung geeignet).
- Build-Warnung zur Kotlin-Plugin-Migration (`shared_preferences_android`) bleibt offen.
