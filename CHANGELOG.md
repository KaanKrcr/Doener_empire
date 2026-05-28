# Changelog

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
