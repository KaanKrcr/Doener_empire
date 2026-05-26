# Phase 3: Schwierigkeitsstufen (Difficulty)

## Übersicht
In Phase 3 wurde ein zentrales Difficulty-System eingefuehrt und mit den Kernmechaniken des Spiels verbunden.

## Enthaltene Stufen
- `easy`
- `normal`
- `hard`
- `impossible`

## Zentrales Modell
Die Difficulty-Konfiguration liegt zentral in:
- `lib/models/difficulty_model.dart`

Enthaltene Modifier:
- `hrRecruitmentSpeedMultiplier`
- `candidateQualityMultiplier`
- `candidateSalaryMultiplier`
- `competitorAggressivenessMultiplier`
- `customerPriceSensitivityMultiplier`
- `progressSpeedMultiplier`
- `reputationPenaltyMultiplier`
- `economicPressureMultiplier`

## Balancing-Werte

### easy
- `hrRecruitmentSpeedMultiplier: 1.40`
- `candidateQualityMultiplier: 1.20`
- `candidateSalaryMultiplier: 0.85`
- `competitorAggressivenessMultiplier: 0.75`
- `customerPriceSensitivityMultiplier: 0.75`
- `progressSpeedMultiplier: 1.25`
- `reputationPenaltyMultiplier: 0.75`
- `economicPressureMultiplier: 0.85`

### normal
- `hrRecruitmentSpeedMultiplier: 1.00`
- `candidateQualityMultiplier: 1.00`
- `candidateSalaryMultiplier: 1.00`
- `competitorAggressivenessMultiplier: 1.00`
- `customerPriceSensitivityMultiplier: 1.00`
- `progressSpeedMultiplier: 1.00`
- `reputationPenaltyMultiplier: 1.00`
- `economicPressureMultiplier: 1.00`

### hard
- `hrRecruitmentSpeedMultiplier: 0.78`
- `candidateQualityMultiplier: 0.88`
- `candidateSalaryMultiplier: 1.12`
- `competitorAggressivenessMultiplier: 1.20`
- `customerPriceSensitivityMultiplier: 1.15`
- `progressSpeedMultiplier: 0.90`
- `reputationPenaltyMultiplier: 1.18`
- `economicPressureMultiplier: 1.12`

### impossible
- `hrRecruitmentSpeedMultiplier: 0.62`
- `candidateQualityMultiplier: 0.78`
- `candidateSalaryMultiplier: 1.28`
- `competitorAggressivenessMultiplier: 1.45`
- `customerPriceSensitivityMultiplier: 1.32`
- `progressSpeedMultiplier: 0.75`
- `reputationPenaltyMultiplier: 1.40`
- `economicPressureMultiplier: 1.24`

## Implementierte Wirkungen

### Neue Spielstaende
- Schwierigkeit ist im New-Game-Screen auswaehlbar.
- Auswahl wird in `GameState` gespeichert.

### Save-Kompatibilitaet
- Alte Savegames ohne Difficulty-Feld werden automatisch auf `normal` gesetzt.

### HR / Recruitment
- Poolgroesse, Refresh-Intervall, Refresh-Kosten und Auto-Hire-Tempo haengen von Difficulty ab.
- Kandidatenqualitaet und Kandidatengehaelter skalieren ueber Difficulty.
- Gilt auch fuer manuelle Kandidatenvorschlaege im Shop-Detail.

### KI-Gegner / Konkurrenz
- Konkurrenz-Spawn, Aktionsfrequenz und Aggressivitaet sind difficulty-abhaengig.
- Konkurrenzdruck in der Nachfrageberechnung steigt mit hoeherer Schwierigkeit.

### Preis / Nachfrage / Kunden
- Preissensitivitaet der Kunden skaliert ueber `customerPriceSensitivityMultiplier`.
- Reputationsstrafen bei Preisfehlern skalieren ueber `reputationPenaltyMultiplier`.

### Fortschritt
- Progress-Tempo wirkt auf Umsatz-/Missionsfortschritt (interne Bewertung) und Brand-/City-Reputation-Wachstum.

### Wirtschaftlicher Druck
- Operative Kosten werden ueber `economicPressureMultiplier` verstaerkt/entschaerft.

## Mobile-UI
- Schwierigkeit als mobilfreundliche Auswahlkarten mit Kurzbeschreibung.

## QA-Checkliste (manuell)
1. Neues Spiel starten und jede Schwierigkeit einmal auswaehlen.
2. Speichern/Laden pruefen: Schwierigkeit bleibt erhalten.
3. Altes Savegame (ohne Difficulty) laden: muss als `normal` laufen.
4. Recruiting vergleichen:
   - Anzahl Kandidaten
   - Qualitaet
   - Gehalt
   - Auto-Hire-Verhalten
5. Preisfehler vergleichen (z. B. 30-40 % ueber Basispreis):
   - Nachfrageeinbruch auf `impossible` deutlich staerker als auf `easy`.
6. Konkurrenzvergleich in derselben Stadt:
   - Auf `hard/impossible` spuerbar aggressiver als `easy`.
7. Progressvergleich (mehrere Tage):
   - Missionen/Unlocks auf `easy` schneller, auf `impossible` langsamer.

## Automatisierte Tests
- Ausfuehrung: `flutter test`
- Enthalten: Difficulty-Regressionen + bestehende Stabilitaets-/Feature-Tests.

## Offene Follow-ups
- Feintuning durch Playtest-Telemetrie (insb. `hard`/`impossible`).
- Optional: Difficulty-Anzeige in Settings/Dashboard als read-only Status.
- Optional: spaetere "Difficulty change"-Policy mit Warnhinweis.
