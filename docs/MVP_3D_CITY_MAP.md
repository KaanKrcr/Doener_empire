# MVP 3D City Map

## Ziel
Döner Empire bekommt eine Coffee-Inc.-2-inspirierte City-Map-Ebene, ohne die bestehende Wirtschaftssimulation neu zu schreiben.

## Geliefert
- Neue Route `/city-map/:cityId`
- Neue `CityMapScreen` als zentrale Stadtansicht
- Pseudo-3D/isometrische Map über `CustomPainter`
- Hotspots pro bestehendem `LocationTemplate`
- Standortpanel mit Zielgruppe, Risiko, Empfehlung, Traffic, Miete und Kaution
- Filiale direkt vom ausgewählten Hotspot eröffnen
- Bestehende Filialen auf der Stadtkarte anzeigen und öffnen
- `LocationEngine` als testbarer Adapter zwischen bestehenden Standortdaten und Map-UI

## Bewusst nicht enthalten
- Kein echter 3D-Engine-Wechsel
- Keine Innenraum-Simulation
- Keine neue Wirtschaftssimulation
- Keine komplexen Lieferfahrzeuge

## Nächster Ausbauschritt
- Kundendots beim Tagesabschluss animieren
- Konkurrenz-Hotspots sichtbar machen
- Marktanteilszonen pro Stadtteil einfärben
- Standort-spezifische Balancing-Tabelle erweitern
