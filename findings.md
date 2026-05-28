# Döner Empire – Findings

## Ausgangslage

Aktueller Projektpfad:

```text
/data/.openclaw/workspace/projects/doener-empire
```

Aktueller GitHub-Stand laut Clone:

```text
1130c834f0f40a886bb3dd70b46a09381f6ff2b6
```

Übergabe von Codex:
- Lieferdienst-Fix/Provision umgesetzt.
- HR-Manager + Auto-Hire-Skalierung umgesetzt.
- Difficulty-Integration erweitert.
- Save-Migration/Stabilität ergänzt.
- `flutter analyze` und `flutter test` laut README_STATUS grün.

## Lokale Verifikation

Ausgeführt mit lokaler Flutter-SDK:

```text
/data/.openclaw/toolchains/flutter
Flutter 3.44.0 / Dart 3.12.0
```

Ergebnisse:
- `flutter analyze`: grün, keine Issues.
- `flutter test`: grün, alle Tests bestanden.
- `flutter build web --release`: erfolgreich, Ausgabe in `build/web`.

Hinweise:
- 11 Dependencies haben neuere Versionen, sind aber durch Constraints inkompatibel. Kein aktueller Fehler.
- Web-Build meldet erwartete Font-Warnung zu Cupertino Icons; bereits als Known Issue ähnlich dokumentiert.
- Android-Build wurde nicht ausgeführt, weil Android SDK auf diesem Server fehlt.

## Vergleich gegen Snapshot 2026-05-25

Alter Snapshot:

```text
/data/.openclaw/workspace-coding/doener-empire-source-review
```

Auffällige neue/erweiterte Bereiche:
- `lib/models/difficulty_model.dart`
- `lib/models/hr_manager_model.dart`
- `lib/models/tutorial_model.dart`
- `lib/services/hr_engine.dart`
- zusätzliche Tests: `branch_naming_test`, `difficulty_system_test`, `hr_system_test`, erweiterte Stability-/Regressionstests.

Diff-Größe gegen Basis `2452c6b`:
- 72 Dateien geändert
- ca. 5636 Insertions / 1136 Deletions

Bewertung:
- Umfang groß, aber Zielbereiche sind testseitig abgedeckt.
- Keine statischen Hinweise auf negative Lieferdienst-Bestellwertlogik.
- Save-Migrationen sind explizit getestet.

## Lieferdienst-Befunde

Bestätigt:
- `lieferdienst` ist globales Upgrade.
- Lieferdienst nutzt `deliveryRevenueFraction` + `deliveryCommissionRate` statt negativem `avgOrderValueBoost`.
- Keine negative `avgOrderValueBoost`-Angabe im Upgrade-Modell gefunden.
- `deliveryCommissionCosts` wird in `DailyRecord` serialisiert und mit Default `0` geladen.
- Legacy-Shop-Upgrade `lieferdienst` wird beim Laden in `globalUpgradeIds` migriert und aus Shops entfernt.
- `processDay` addiert Lieferprovision separat zu Kosten und History.
- Eigene Liefer-App senkt effektive Provision auf 8%.

Zusätzlicher E2E-Test:
- 50 Ingame-Tage mit 4 Shops, `lieferdienst` + `eigen_lieferdienst`.
- Ergebnis: grün.

## HR / Auto-Hire-Befunde

Bestätigt:
- Auto-Hire läuft pro Shop in einer begrenzten Schleife.
- Max-Hires pro Tag sind begrenzt und difficulty-/HR-modifiziert.
- Stop-Bedingungen vorhanden: Cap, leerer Kandidatenpool, Cash-Reserve, fehlender Bedarf.
- Kandidaten werden aus Pool entfernt, nicht unbegrenzt nachgefüllt.
- HR-Defaults für Alt-Saves sind sicher (`HrStrategy.balanced`, kein Manager, leerer Kandidatenpool).
- Difficulty beeinflusst Kandidatenqualität, Gehalt, Recruiting-Geschwindigkeit und Auto-Hire-Aggressivität.

Zusätzlicher E2E-Test:
- 50 Ingame-Tage mit Auto-Hire, großem Pool, Easy + FillFast.
- Ergebnis: grün.

## Bekannte verbleibende Risiken

- Android-Release-Signing nutzt laut `KNOWN_ISSUES.md` noch Debug-Konfiguration.
- Android SDK fehlt auf diesem Server; APK/AAB-Build muss in Android-fähiger Umgebung laufen.
- Manuelle Tests auf echten Geräten bleiben nötig: Save/Load, Navigation, Tagesabschluss, Performance.
- App-Label Android ist noch technisch (`doener_empire`).
- Dependency-Updates sollten nicht blind gemacht werden; mehrere Major/Constraint-Sprünge.

## Empfehlung

Dieser Stand sieht für den nächsten Schritt stabil genug aus. Sinnvoll ist jetzt:
1. E2E-Test + Plan-/Findings-Dateien committen.
2. Android Release-Vorbereitung angehen.
3. Manuelles internes Testpaket nach `docs/MANUAL_TESTPLAN_INTERNAL.md` durchführen.
4. Erst danach neue Gameplay-Features beginnen.
