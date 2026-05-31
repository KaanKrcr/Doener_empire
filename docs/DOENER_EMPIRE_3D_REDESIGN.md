# Döner Empire 3D — Repo-Aware Redesign Brief

## One-Sentence Pitch
Döner Empire wird von einer mobilen Listen-/Dashboard-Wirtschaftssimulation zu einer Coffee-Inc.-2-inspirierten 3D-City-Tycoon-Simulation: Der Spieler baut ein sichtbares Döner-Filialnetz in deutschen Städten auf, optimiert jeden Standort wirtschaftlich und dominiert Stadtteile gegen KI-Konkurrenz.

## Player Fantasy
Vom ersten kleinen Laden in Fulda/Bayreuth/Göttingen zum stadtweiten und später deutschlandweiten Döner-Konzern. Wachstum soll nicht nur in Zahlen sichtbar sein, sondern auf einer lebendigen 3D-Karte: neue Filialen, Kundenströme, Stadtteil-Hotspots, Konkurrenzläden, Lieferwege und Markenpräsenz.

## Target Player
- Spieler, die Coffee Inc. 2, Game Dev Tycoon, SimCity-lite und Mobile-Tycoons mögen
- Zielgruppe: Casual bis Midcore Management-Spieler
- Hauptreiz: wirtschaftliche Entscheidungen + sichtbarer Aufbau einer Kette

## Platform / Input
Aktueller Stand laut Repo:
- Flutter Mobile App
- Riverpod, GoRouter, fl_chart, flutter_animate
- Kein 3D-Framework vorhanden

Empfohlene Richtung:
- MVP weiter in Flutter halten
- 3D zunächst als stilisierte City-Map-Ebene implementieren, nicht als vollwertige 3D-Welt
- Technische Optionen:
  1. Pseudo-3D/isometrische Stadt in Flutter CustomPainter — schnellster MVP
  2. Flutter + flame/bonfire/isometric package — mehr Spielgefühl
  3. Unity/Godot Rewrite — beste 3D-Basis, aber deutlich größerer Neustart

Empfehlung: Erst Option 1 als Redesign-Prototyp, danach entscheiden ob echter Engine-Wechsel nötig ist.

## Existing Repo Strengths To Keep
Das bestehende Spiel hat bereits viele starke Simulationssysteme:
- Städte und City-Tiers: klein, mittel, groß, Metropole
- Filialen mit Laufkundschaft, Miete, Reputation, Menü, Equipment, Personal
- Tagesabschluss und Historie
- Produkte, Preisstrategie, Qualität, Kombos, Tagesspecials
- Marketing-Kampagnen
- Konkurrenzdruck
- HR, Manager, globale Upgrades
- Story-Kampagne, Achievements, Daily Challenges
- Börse, Produktion, M&A, Konzernsysteme

Diese Systeme sollten nicht gelöscht werden. Das Redesign sollte vor allem die Präsentation und Entscheidungsebene modernisieren.

## Core Loop
1. Stadtkarte öffnen
2. Stadtteil/Standort mit sichtbaren Eigenschaften analysieren
3. Filiale eröffnen oder bestehende Filiale auswählen
4. Preis, Menü, Qualität, Personal, Equipment und Marketing anpassen
5. Tag simulieren
6. Auf Karte und Bericht sehen, was passiert ist: Kundenströme, Warteschlangen, Reputation, Gewinn, Marktanteil
7. Reinvestieren: bessere Filiale, neuer Stadtteil, Konkurrenz angreifen, Konzernsysteme ausbauen

## Session Loop
Eine 5–10-Minuten-Session sollte so aussehen:
1. Dashboard zeigt wichtigste Probleme: Cash, Engpässe, schwache Filialen, Konkurrenz
2. Spieler springt zur City-Map
3. Spieler löst 1–3 Probleme:
   - zu lange Warteschlange → Personal/Equipment
   - niedrige Bewertung → Qualität/Preis/Sauberkeit
   - Konkurrenzdruck → Marketing/Preisstrategie
   - neuer Hotspot → Filiale eröffnen
4. Spieler beendet den Tag
5. Day-End-Report erklärt Ursache und Wirkung
6. Spieler bekommt ein klares nächstes Ziel

## Progression
### Phase 1 — Erste Filiale
- Startstadt wählen
- 1 Standort
- Preis, Menü, Personal, Equipment
- Ziel: 7 Tage überleben, positive Reputation, stabiler Tagesgewinn

### Phase 2 — Stadtteil-Dominanz
- Mehrere Standorte in einer Stadt
- Stadtteil-Marktanteil und Konkurrenz sichtbar machen
- Ziel: 50–70% Marktanteil in Startstadt

### Phase 3 — Regionale Expansion
- Weitere Städte aus bestehenden kAllCities freischalten
- Städte bekommen visuelle Karten mit unterschiedlichen Hotspots
- Ziel: Konzernführung statt Mikro-Management

### Phase 4 — Konzernspiel
- HR-Manager, globale Preise, globale Qualität, Produktion, Aktien, M&A
- Bestehende Repo-Systeme bleiben Endgame, werden aber besser erklärt und visualisiert

## FTUE / First 5 Minutes
1. Spieler sieht nicht zuerst ein Dashboard, sondern eine kleine 3D/isometrische Stadtkarte.
2. Tutorial markiert einen günstigen Startstandort.
3. Spieler eröffnet ersten Laden.
4. Drei Entscheidungen:
   - Produkt-Fokus: Klassisch / Günstig / Premium
   - Preis: empfohlen 6,50 €
   - erster Mitarbeiter
5. Simulation zeigt Kundenpunkte, Warteschlange und Tagesumsatz.
6. Day-End-Dialog zeigt: Umsatz, Kosten, Gewinn, Kunden, Bewertung, Engpass.
7. Spieler bekommt erste Mission: „Verbessere deine Bewertung auf 3,8+“ oder „Erreiche 500 € Tagesumsatz“.

## Game Systems
### 1. City Map Layer
Neue zentrale UX-Ebene.

Pro Stadt:
- 6–10 Standorte/Hotspots statt nur eine Listenkarte
- Standorttypen:
  - Bahnhof
  - Uni
  - Innenstadt
  - Wohngebiet
  - Business District
  - Nachtviertel
  - Einkaufszentrum
  - Touristenmeile

Jeder Standort hat:
- footTraffic
- rentFactor
- targetAudience
- peakHours
- competitorPresence
- visualPosition auf Karte

### 2. District / Location Personality
Das Repo hat bereits `LocationPersonality` und Zeitprofile. Diese sollten zur Grundlage für Stadtteile werden.

Beispiele:
- Uni: preissensibel, viel Mittag/Abend, Social-Media-Marketing stark
- Business: hohe Kaufkraft, Mittagsspitze, Premiumprodukte stark
- Bahnhof: hohe Laufkundschaft, niedrige Loyalität, Schnelligkeit wichtig
- Nachtviertel: Abend/Nacht stark, Combos/Getränke stark

### 3. Filialmanagement
Bestehende Systeme behalten:
- menu
- equipment
- employees
- reputation
- campaigns
- upgrades
- autoHire

Neu visualisieren:
- Kapazitätsengpass als Warteschlange
- Reputation als Sterne/Review-Bubbles
- Umsatz als Tages-Popup über Filiale
- Konkurrenzdruck als rote Einflusszone

### 4. Konkurrenz
Bestehender CompetitorEngine bleibt, aber Karte macht ihn sichtbar:
- Konkurrenten als eigene Läden auf Hotspots
- Marktanteil pro Stadtteil
- Aktionen auf Karte: Rabatt, Premium-Offensive, Neueröffnung

### 5. Day Simulation
Bestehender End-Day-Button bleibt MVP-tauglich.

Verbesserung:
- Vor Tagesabschluss: Prognose anzeigen
- Während Tagesabschluss: kurze animierte City-Map-Simulation
- Danach: Bericht mit Ursachen, nicht nur Zahlen

### 6. Reports / Advisor
Ein Coffee-Inc.-ähnliches Spiel braucht klare Analyse.

Beispiele:
- „Filiale Fulda Bahnhof verliert 23% potenzielle Kunden wegen Kapazitätslimit.“
- „Preis liegt 18% über Erwartung im Uni-Viertel.“
- „Marketing wirkt gut, aber Qualität senkt Wiederkehrquote.“

## Content Types
### Cities aus aktuellem Repo
Start mit bestehenden Städten:
- Fulda
- Bayreuth
- Göttingen
- Augsburg
- Münster
- Braunschweig
- Frankfurt
- Köln
- Stuttgart
- Düsseldorf
- Berlin
- Hamburg
- München

### Location Types
Neue Content-Tabelle ergänzen:
- station
- university
- downtown
- residential
- business
- nightlife
- mall
- tourist

### Visual Assets MVP
- Low-poly/isometrische Gebäudekacheln
- Dönerladen-Level 1–3
- Konkurrentenladen
- Kundenpunkte/Agenten
- Straßen/Wege
- Standortmarker

## Economy / Rewards
Bestehende Zahlen können bleiben, aber die Kartenentscheidung braucht klarere Standortlogik.

MVP-Beispiel:
- Startkapital: bestehender Wert aus GameState/NewGame übernehmen
- Standortkosten = city.rentBase * location.rentFactor
- Foot traffic = city.footTrafficBase * location.footTrafficFactor
- Kunden pro Tag = footTraffic * Nachfragefaktoren * Konkurrenz * Reputation

Neue Belohnungen:
- Stadtteil-Dominanz-Bonus
- Standort-Synergien bei mehreren Filialen in einer Stadt
- Markenpräsenz sichtbar auf Karte

## UX Flow
Empfohlene neue Hauptnavigation:
1. City Map
2. Empire Dashboard
3. Shops
4. Finance
5. Corporate

Wichtigste Änderung:
- `CitiesScreen` wird von Listenansicht zu Map-Auswahl umgebaut.
- `DashboardScreen` bleibt, wird aber zur Management-Zentrale.
- `OpenShopScreen` wird Standortauswahl + Standortanalyse.
- `ShopDetailScreen` bleibt für Detailoptimierung.

## MVP Scope
### MVP 3D/City Redesign — enthalten
- Eine neue `CityMapScreen` für eine Stadt
- 6 Standort-Hotspots pro Stadt
- Pseudo-3D/isometrische Karte mit Gebäuden und Standortmarkern
- Bestehende Filialen auf der Karte anzeigen
- Neue Filiale per Hotspot eröffnen
- Standortdetails: Miete, Laufkundschaft, Zielgruppe, Konkurrenz
- Day-End-Animation light: Kundenpunkte bewegen sich zu Läden
- Day-End-Report mit 3 wichtigsten Insights

### Bestehende Systeme wiederverwenden
- GameState
- Shop
- CityData
- LocationTemplate
- GameEngine.calculateShopStats
- CompetitorEngine
- Marketing/Product/Equipment/Employee Models

### Neue/angepasste Dateien
- `lib/models/location_model.dart`
- `lib/models/city_map_model.dart`
- `lib/ui/screens/city_map_screen.dart`
- `lib/ui/widgets/city_map_view.dart`
- `lib/ui/widgets/location_hotspot.dart`
- `lib/services/location_engine.dart`
- `docs/DOENER_EMPIRE_3D_REDESIGN.md`
- `docs/MVP_3D_CITY_MAP.md`
- `docs/BALANCING_CITY_LOCATIONS.md`

## Non-Goals
Für den ersten Redesign-MVP ausdrücklich nicht bauen:
- Keine frei begehbare 3D-Stadt
- Keine Innenraum-Simulation
- Kein manuelles Döner-Zubereiten
- Kein kompletter Unity/Godot-Neustart
- Kein Multiplayer
- Keine komplexe Lieferfahrzeug-Simulation

## Risks
1. Flutter echtes 3D ist riskant
   - Lösung: Erst isometrisch/pseudo-3D mit klarer Art Direction.

2. Bestehende Systeme sind schon umfangreich
   - Lösung: Nicht noch mehr Systeme hinzufügen, sondern bessere Karte + bessere Erklärbarkeit.

3. UI kann überladen wirken
   - Lösung: City Map als emotionale Oberfläche, Detailwerte nur in Bottom Sheet.

4. Coffee Inc. 2-Vergleich erzeugt zu hohe Scope-Erwartung
   - Lösung: Fokus auf Coffee-Inc.-Feeling: Standortanalyse, Marktanteil, Konkurrenz, Expansion — nicht auf komplette Feature-Kopie.

## Prototype Test
Der Redesign-Prototyp ist erfolgreich, wenn ein Tester nach 10 Minuten:
- versteht, warum ein Standort gut/schlecht ist
- eine Filiale über die Karte eröffnen kann
- sieht, wie Kunden/Konkurrenz/Reputation die Karte beeinflussen
- einen weiteren Tag simulieren möchte
- eine konkrete Verbesserungsentscheidung treffen kann

Testaufgaben:
1. Öffne Fulda als Karte.
2. Eröffne eine Filiale am Bahnhof oder Uni-Hotspot.
3. Beende 3 Tage.
4. Verbessere einen Engpass.
5. Erreiche 4.0 Reputation oder positiven Tagesgewinn.

## Open Questions
- Soll das Spiel langfristig in Flutter bleiben oder ist ein Unity/Godot-Wechsel offen?
- Wie wichtig ist echtes 3D gegenüber isometrischem 3D-Look?
- Soll die Karte realen deutschen Städten ähneln oder stilisierte Fantasie-Stadtteile nutzen?
- Soll der Spieler pro Stadt mehrere Stadtteile kontrollieren oder pro Stadt nur einzelne Hotspots?
- Soll Coffee Inc. 2 eher bei UI/Analyse oder bei Konzernsimulation als Vorbild dienen?
