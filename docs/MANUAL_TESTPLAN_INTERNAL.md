# Manueller Testplan - Internal Test 1

## Ziel

Stabilität, Kernfunktionen und Build-Qualität des ersten internen Test-Releases prüfen.

## Testumgebung

- APK: `app-release.apk` (alternativ `app-debug.apk`)
- Plattform: Android (mind. 2 unterschiedliche Geräteklassen empfohlen)
- Testdauer pro Lauf: 30-60 Minuten

## Smoke-Checks (Blocker)

1. App startet ohne Crash.
2. Neues Spiel kann angelegt werden.
3. Speichern/Laden funktioniert.
4. Tagesabschluss funktioniert mehrfach hintereinander.
5. Kein roter Error-Screen bei Navigation durch Haupttabs.

## Kernszenarien

1. Onboarding/Start
   - Neues Spiel starten
   - Erste Filiale eröffnen
   - 3 Tage spielen, dann App schließen/neu öffnen und Save laden
2. Shop-Management
   - Preise anpassen
   - Equipment kaufen
   - Mitarbeiter einstellen/entlassen
3. Lieferdienst
   - Upgrade `lieferdienst` kaufen (falls Cash vorhanden)
   - Tagesabschlüsse vergleichen (mit/ohne Lieferdienst)
   - Prüfen: Provision als separater Kostenblock
4. Auto-Hire
   - Auto-Hire aktivieren
   - Mehrere Tage abschließen
   - Prüfen: begrenzte Hires pro Tag, Cash fällt nicht unkontrolliert
5. Corporate/Imperium
   - Tabs mehrfach öffnen, zwischen Screens wechseln
   - Prüfen auf Exceptions/NoSuchMethodError

## Save-/Kompatibilitätschecks

1. Bestehenden Save laden und weiter spielen.
2. Nach mehreren Tagen erneut speichern/laden.
3. Prüfen, ob Finanzhistorie plausibel bleibt.

## Android-spezifische Checks

1. Installation/Update über APK möglich.
2. App-Start nach Geräte-Neustart.
3. Hintergrund/Vordergrund-Wechsel ohne Absturz.
4. Performance grob prüfen (keine massiven Ruckler bei Tagesabschluss).

## Ergebnisdokumentation pro Tester

- Gerät + Android-Version
- Build-Datei (`debug` oder `release`)
- Getestete Szenarien (IDs/Nummern)
- Gefundene Bugs inkl. Repro-Schritte
- Schweregrad (`critical/high/medium/low`)
- Screenshot/Screenrecording bei Fehlern

## Exit-Kriterien für "Internal Test 1 bestanden"

1. Keine `critical` Abstürze im Smoke-Test.
2. Save/Load reproduzierbar funktionsfähig.
3. Lieferdienst-/Auto-Hire-/Corporate-Tab ohne blockerhafte Fehler.
4. Alle Findings als GitHub-Issues erfasst und priorisiert.
