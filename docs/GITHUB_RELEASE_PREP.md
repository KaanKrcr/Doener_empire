# GitHub-Vorbereitung: Erster interner Test-Release

## Vorgeschlagene Labels

- `type:bug` - Fehlerbehebung
- `type:test` - Testfälle/Testinfrastruktur
- `type:docs` - Dokumentation
- `area:android` - Android Build/Packaging
- `area:save-system` - Save/Load/Migration
- `area:economy-balance` - Balancing/Ökonomie
- `area:ui` - UI/UX und Screens
- `severity:critical` - Blocker für Release
- `severity:high` - Hohe Priorität
- `severity:medium` - Mittlere Priorität
- `severity:low` - Niedrige Priorität
- `release:internal-test-1` - Gehört zum aktuellen Test-Release

## Vorgeschlagene Milestones

1. `Internal Test 1 (v1.0.0-internal.1)`
   - Ziel: Stabilität + Kern-Gameplay validieren
   - Zeitraum: sofort bis Ende Testwoche
2. `Stability Patch 1`
   - Ziel: Alle `severity:critical/high` Findings aus Test 1 beheben
3. `Public Beta Readiness`
   - Ziel: Signing, Crashfreiheit, Save-Kompatibilität, Balancing-Mindestniveau

## Vorgeschlagene Start-Issues

1. Android Release Signing auf Keystore umstellen
   - Labels: `type:bug`, `area:android`, `severity:critical`, `release:internal-test-1`
2. KGP-Migrationswarnung (`shared_preferences_android`) beheben/absichern
   - Labels: `type:bug`, `area:android`, `severity:medium`, `release:internal-test-1`
3. App-Name/Label für Android auf "Döner Empire" setzen
   - Labels: `type:docs`, `area:android`, `severity:low`, `release:internal-test-1`
4. Interner Testlauf: Save/Load-Langzeittest (30+ Tage) dokumentieren
   - Labels: `type:test`, `area:save-system`, `severity:high`, `release:internal-test-1`
5. Interner Testlauf: Ökonomie-/Balance-Feedback konsolidieren
   - Labels: `type:test`, `area:economy-balance`, `severity:medium`, `release:internal-test-1`

## Optional: Issue-Template-Felder

- Build/Commit
- Gerät + Android-Version
- Repro-Schritte
- Erwartetes Verhalten
- Tatsächliches Verhalten
- Screenshot/Video
- Save-Stand angehängt? (`ja/nein`)
