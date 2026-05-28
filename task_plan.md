# Döner Empire – Arbeitsplan

## Ziel
Aktuellen GitHub-Stand stabil übernehmen, gegen den älteren Snapshot vom 2026-05-25 validieren und erst danach neue Features priorisieren.

## Nicht-Ziele für diese Phase
- Keine neuen Gameplay-Features vor Stabilitätsfreigabe.
- Kein großes Architektur-Refactoring ohne konkreten Befund.
- Kein Release-Signing umstellen, solange Gameplay-Stabilität nicht geprüft ist.

## Phase 1 – Baseline sichern
Status: complete

Erledigt:
- Git-Stand geprüft: `1130c834f0f40a886bb3dd70b46a09381f6ff2b6`.
- Lokale Flutter-SDK unter `/data/.openclaw/toolchains/flutter` bereitgestellt.
- `flutter analyze` lokal ausgeführt: grün, keine Issues.
- `flutter test` lokal ausgeführt: grün, alle Tests bestanden.
- `flutter build web --release` ausgeführt: erfolgreich, Build in `build/web`.

Akzeptanz:
- Analyse/Test/Build-Ergebnis ist dokumentiert.
- Produktcode blieb unverändert.

## Phase 2 – Vergleich gegen Snapshot 25.05.
Status: complete

Erledigt:
- Alten Snapshot `/data/.openclaw/workspace-coding/doener-empire-source-review` mit aktuellem Repo verglichen.
- Hinzugekommen: Difficulty-, HR-, Tutorial-Modelle/Services und zusätzliche Regressionstests.
- Fokusprüfung: Lieferdienst, HR/Auto-Hire, Difficulty, Save-Migration.

Akzeptanz:
- Kritische Verhaltensänderungen sind in `findings.md` beschrieben.

## Phase 3 – Lieferdienst E2E validieren
Status: complete

Erledigt:
- Bestehende Tests geprüft: Delivery-Provision im Day-End-Record, nicht-negativer Umsatz, separate Provision, globale Legacy-Migration.
- Zusätzlichen E2E-Test ergänzt: 50 Ingame-Tage mit Lieferdienst + eigener Liefer-App.
- Test prüft: Umsatz/Kosten nicht negativ, Provision separat, Provision kleiner als Umsatz, Kostenaufteilung plausibel inkl. globaler Upgrade-Kosten.

Akzeptanz:
- E2E-Test `test/e2e_validation_test.dart` läuft grün.

## Phase 4 – HR / Auto-Hire E2E validieren
Status: complete

Erledigt:
- Bestehende Tests geprüft: HR-Defaults, HR-Kosten, Difficulty-Einfluss, Auto-Hire-Begrenzung, leerer Pool.
- Zusätzlichen E2E-Test ergänzt: 50 Ingame-Tage mit Auto-Hire, großem Kandidatenpool, Easy + FillFast.
- Test prüft: mehrere Hires möglich, Mitarbeiter-Cap wird eingehalten, Cash bleibt positiv, Kandidatenpool sinkt passend zu Hires.

Akzeptanz:
- E2E-Test `test/e2e_validation_test.dart` läuft grün.

## Phase 5 – Entscheidung nächster Schritt
Status: complete

Empfehlung:
1. E2E-Test und Plan-/Findings-Dateien committen und nach GitHub pushen lassen.
2. Danach Android-Release-Vorbereitung: echtes Signing, App-Label, APK/AAB-Build in Android-fähiger Umgebung.
3. Danach manueller Internal-Test nach `docs/MANUAL_TESTPLAN_INTERNAL.md`.
4. Erst danach neue Gameplay-Features priorisieren.

## Fehler / Blocker

| Fehler | Ursache | Lösung/Status |
|---|---|---|
| `flutter: not found` | Server hatte keine Flutter-SDK im PATH | Lokale SDK in `/data/.openclaw/toolchains/flutter` installiert |
| Flutter Bootstrap: `unzip` fehlt | Systemtool nicht verfügbar, Elevated nicht erlaubt | Lokaler Python-Wrapper `/data/.openclaw/toolchains/bin/unzip` genutzt |
| Flutter Test Crash: `impellerc` nicht ausführbar | Python-Wrapper erhielt ZIP-Permissions nicht | Execute-Bits in Flutter-Cache gesetzt, Tests danach grün |
| Erste E2E-Testannahme Delivery-Kosten falsch | Globale Upgrade-Tageskosten fehlten in Testformel | Test auf öffentliches Verhalten korrigiert |
| Erste E2E-Testannahme Auto-Hire-Cash falsch | Tagesgewinn kann Hiring Fees überkompensieren | Test auf Pool-/Employee-Verhalten statt Cash-Fall korrigiert |
