# Döner Empire

Mobile-Wirtschaftssimulation in Flutter — vom kleinen Imbiss zum landesweiten
Döner-Imperium.

## Spielfeatures

- **Filialen & Expansion:** Standorte in echten Städten eröffnen, Equipment &
  Mitarbeiter, Tageszeit-/Wochentag-Nachfrage, Jahreszeiten
- **Speisekarte & Strategie:** Preisstrategie + umsatzoptimale Preis-Empfehlung,
  Kombo-Menüs, Zutaten-Qualitätsstufen, Tagesspecial
- **Story-Kampagne:** 8 Kapitel mit Cash-Belohnungen und permanenten
  Konzern-Perks; Trophäen-Galerie; Marken-Skins; Start-Szenarien
- **Retention:** Daily Challenges, Wochen-Report, Quartalssteuer
- **Konzern:** Börsengang/Aktienkurs, Produktionsanlagen, M&A, HR-Manager,
  globale Upgrades, stadt-/konzernweites Marketing
- **Analyse:** Produkt-Profitabilität, Filial-Ranking, Marktanteile,
  Unternehmens-Gesundheit, Kundenbewertungen, Dashboard-Hinweise
- **Game-Feel:** Sound & Haptik, Animationen, Konfetti, Events/Krisen

Details: siehe [CHANGELOG.md](CHANGELOG.md).

## Voraussetzungen

- Flutter `3.44.0` (Stable) oder kompatibel
- Dart `3.12.x`
- Android Studio / Android SDK (für Android-Builds)
- Java `17` (Gradle/Android Plugin nutzt Java 17)

## Setup

1. Abhängigkeiten installieren:
   - `flutter pub get`
2. Projekt analysieren:
   - `flutter analyze`
3. Tests ausführen:
   - `flutter test`
4. Lokaler Start:
   - `flutter run`

## Android Build

- Debug APK:
  - `flutter build apk --debug`
  - Output: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK:
  - `flutter build apk --release`
  - Output: `build/app/outputs/flutter-apk/app-release.apk`

Hinweis: Aktuell ist im Release-Build noch die Debug-Signing-Config aktiv
(`android/app/build.gradle.kts`), damit interne Test-Builds direkt erstellt
werden können.

## Interner Test-Release (Kurzablauf)

1. `flutter analyze`
2. `flutter test`
3. `flutter build apk --release`
4. APK auf Testgerät installieren
5. Manuellen Testplan ausführen:
   - siehe [docs/MANUAL_TESTPLAN_INTERNAL.md](docs/MANUAL_TESTPLAN_INTERNAL.md)

## Release-Dokumente

- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Bekannte Risiken/Bugs: [KNOWN_ISSUES.md](KNOWN_ISSUES.md)
- GitHub-Issue/Label/Milestone-Vorschläge:
  [docs/GITHUB_RELEASE_PREP.md](docs/GITHUB_RELEASE_PREP.md)
