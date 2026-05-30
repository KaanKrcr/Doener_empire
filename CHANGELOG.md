# Changelog

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
