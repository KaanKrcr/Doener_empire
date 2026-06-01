# MVP_SCOPE.md - Döner Empire

Dieses Dokument bleibt eng auf den ersten stabilen, spielbaren Release fokussiert.

## 1. MVP-Ziel
Der Spieler kann einen Dönerladen betreiben, Preise steuern, Tage simulieren,
Ergebnisse verstehen und aus Gewinnen in Upgrades oder weitere Filialen investieren.

## 2. Ehrlicher Implementierungsstatus
Legende:
- `[x]` = existiert wirklich im Spiel
- `[ ]` = fehlt noch oder muss verbessert werden

### Kernpfad (Spielerfluss)
- [x] Neuer Spieler kann ein Spiel starten (`/new-game` -> `/game`)
- [x] Ersten Laden über City-Map eröffnen (`/city-map/:cityId` -> `/open-shop/:cityId`)
- [x] Preise pro Produkt in der Filiale setzen (Shop-Detail -> Sortiment)
- [x] Tag simulieren (Dashboard -> `Tag beenden`)
- [ ] Tagesabschluss mit klarer Ursache-Wirkung ist teilweise vorhanden und muss weiter geschärft werden
- [x] Upgrade-Kauf in der Filiale ist möglich
- [x] Zweite Filiale kann gekauft werden (erneut über City-Map/Open-Shop)

### City-Map / Redesign-MVP
- [x] Route `/city-map/:cityId` vorhanden
- [x] `CityMapScreen` + `CityMapView` mit pseudo-3D/isometrischer Darstellung vorhanden
- [ ] 6 Hotspots pro Stadt sind noch nicht umgesetzt (aktuell 4 pro City-Tier)
- [x] Standortpanel zeigt zentrale Kennzahlen (Traffic, Miete, Kaution, Druck, Empfehlung)
- [x] Bestehende Filialpräsenz ist auf der Karte sichtbar
- [x] `LocationEngine` als Adapter zwischen Standortdaten und Map-UI vorhanden
- [ ] Day-End-Animation mit Kundendots zur Filiale fehlt noch
- [ ] Konkurrenz-Hotspots und Marktanteilszonen auf der Stadtkarte fehlen noch

### Guardrails
- [x] Keine Monetarisierungs-Implementierung im MVP-Pfad
- [x] Bestehende Simulationssysteme bleiben bestehen (kein Rewrite)

## 3. Im MVP enthalten
### Wirtschaft / Core Loop
- [x] Ein Spielstand mit Startkapital (`kStartingCash`)
- [x] Erste Filiale in einer kostenlosen Kleinstadt eröffnen
- [x] Tick-basierte Tagessimulation (`kTickIntervalSeconds`, `kDailyOpenHours`)
- [x] Tagesabschluss mit Umsatz / Kosten / Gewinn
- [x] Speisekarte mit Default-Produkten (`kAllProducts`, `isDefault: true`)
- [x] Preis pro Produkt setzen

### Investition / Wachstum
- [x] Equipment kaufen (`kAllEquipment`)
- [x] Personal einstellen (`kEmployeeTypes`)
- [x] Lokale Marketing-Kampagnen (`kAllCampaigns`)
- [x] Zweite Filiale + Stadtwechsel über Umsatz-Schwellen (`unlockCost`)

### Bühne / UX
- [x] City-Map als zentrale Ansicht (`CityMapScreen`, `LocationEngine`)
- [x] Standort-Detail im Bottom-Sheet
- [x] Speichern/Laden lokal (`save_service.dart`, `shared_preferences`)
- [x] Basis-Game-Feel: Geld-Animation, Tagesabschluss-Dialog, Sound an/aus
- [x] Schwierigkeitsgrade als Multiplikatoren (`kDifficultyModifiers`)

### Qualität
- [x] `flutter analyze` ohne Fehler
- [x] Kern-Logik durch Tests in `test/` abgedeckt

## 4. Nicht im MVP (Post-MVP)
- [ ] Story-Kampagne als Pflicht-Onboarding
- [ ] Konzern-Ebene als Kernfokus (Börse, Produktion, M&A, HR-Manager)
- [ ] Stadt- und konzernweites Marketing als Hauptfokus
- [ ] Kosmetische Items / Marken-Skins als Monetarisierung
- [ ] Chaos-Modus
- [ ] DLC-Pakete
- [ ] Cloud-Save / Accounts / Multiplayer
- [ ] Voller 3D-Engine-Wechsel, Innenraum-Sim, manuelles Kochen, Logistik

## 5. Definition of Done (MVP)
Ein neuer Spieler kann in unter 10 Minuten:
1. einen Laden eröffnen
2. einen Preis setzen und einen Tag simulieren
3. am Ergebnis erkennen, was zu verbessern ist
4. ein Upgrade oder eine zweite Filiale kaufen
5. eine neue Stadt freischalten
