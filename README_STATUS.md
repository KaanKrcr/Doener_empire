# README_STATUS - Doener Empire

## Aktueller Stand
- Projektstatus: in aktiver Entwicklung, Working Tree mit umfangreichen lokalen Änderungen.
- Fokus der letzten Iteration: Stabilisierung von Lieferdienst-Logik und HR-/Auto-Hire-Skalierung sowie Difficulty-Balancing.
- Aktueller Branch: `main`
- Basis-Commit (letzter vorhandener Commit vor diesem Übergabe-Commit): `2452c6b54539d1ed5e85427b693d838b132ad222`

## Letzte Änderungen
- Difficulty-System (`easy`, `normal`, `hard`, `impossible`) weiter integriert (Save-Fallback auf `normal` für alte Saves).
- HR-System erweitert (u. a. `hr_engine`, `hr_manager_model`) mit Difficulty-abhängiger Rekrutierung/Auto-Hire-Dynamik.
- Stabilitäts-/Regressionstests ergänzt für:
  - Save-Migrationen aus Legacy-Ständen
  - Lieferprovision und Tagesabschlusslogik
  - Auto-Hire-Grenzen und Pool-Verhalten
  - Corporate-Tab-Stabilität
- UI/Flow-Anpassungen in mehreren Screens und Widgets.

## Offene Todos / Bugs
- Release-Signing steht weiter auf Debug-Konfiguration (vor Public Release umstellen).
- Warnung zur Kotlin-Plugin-Migration (`shared_preferences_android`) beobachten/beheben.
- Längere manuelle Runs für Cash-/Tageslogik weiter nötig (insb. Delivery + Auto-Hire in großen Spielständen).
- Save-Kompatibilität bleibt kritisch bei Legacy-Saves: Delivery-/History-Felder und alte Shop-/Upgrade-Pfade weiter gegentesten.

## Ergebnis Flutter Analyze / Test
- Ausgeführt am: 2026-05-28 18:37:43 +02:00
- `flutter analyze`: **erfolgreich**, keine Findings.
- `flutter test`: **erfolgreich**, alle Tests bestanden (inkl. HR/Difficulty/Regression/Stability-Suiten).

## Nächster sinnvoller Schritt
1. Clemens/OpenClaw übernimmt auf diesem Stand und validiert den Lieferdienst-Fix gegen den älteren Snapshot vom 2026-05-25.
2. Danach gezielte End-to-End-Checks für HR-Manager/Auto-Hire-Skalierung über 20-50 Ingame-Tage in mehreren Difficulty-Stufen.
3. Anschließend nur verbleibende Stabilitätsfixes priorisieren, keine neuen Features vorziehen.
