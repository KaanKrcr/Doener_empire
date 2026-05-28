# Bekannte Risiken und Bugs (Interner Test-Release)

## Kritisch vor externem Release

- Release-Signing ist aktuell auf Debug-Key gestellt
  (`android/app/build.gradle.kts`, `buildTypes.release.signingConfig = debug`).
  Für Public Release muss ein echter Keystore mit sicherer Signierung verwendet werden.

## Technische Risiken

- Kotlin-Plugin-Migrationswarnung beim Android-Build:
  Plugin `shared_preferences_android` nutzt noch KGP-Pfad, der in künftigen
  Flutter-Versionen zu Build-Fehlern führen kann.
- Build-Warnung zu erwarteten Cupertino-Fonts (nicht build-blockierend).
  Prüfen, ob `cupertino_icons` benötigt und konsistent eingebunden werden soll.

## Produkt-/UX-Risiken für Testphase

- App-Label auf Android ist derzeit technisch (`doener_empire`) statt
  marketingfreundlich (`Döner Empire`).
- Keine Crash-Reproduktion in den aktuellen Smoke-Tests, aber Fokus für Tester:
  - Corporate-/Imperium-Tab mehrmals öffnen/schließen
  - Alt-Save laden und mehrere Tage fortsetzen
  - Auto-Hire + Lieferdienst über längere Spielstände beobachten

## Verifizierter Stand (2026-05-25)

- `flutter analyze`: erfolgreich, keine Issues
- `flutter test`: alle Tests erfolgreich
- `flutter build apk --debug`: erfolgreich
- `flutter build apk --release`: erfolgreich
