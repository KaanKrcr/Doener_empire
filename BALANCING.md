# BALANCING.md — Döner Empire

> **Grundregel: Alle Zahlen sind konfigurierbar.**
> Die *einzige* Quelle der Wahrheit für Balancing-Werte ist
> **`lib/core/constants.dart`** (plus `lib/models/difficulty_model.dart` und
> `lib/models/upgrade_model.dart`). Es stehen **keine** Magic Numbers in der
> Simulationslogik (`lib/services/game_engine.dart`) — diese liest immer aus
> den Konstanten.

---

## 1. Konfigurations-Philosophie

- **Daten statt Code:** Städte, Produkte, Equipment, Personal, Kampagnen sind
  `const`-Listen typisierter Modelle — nicht hartkodierte Werte im Engine-Code.
- **Tuning ohne Logikänderung:** Eine Zahl ändern = nur `constants.dart` (bzw.
  `difficulty_model.dart`) anfassen, nie `game_engine.dart`.
- **Schwierigkeit = Multiplikatoren:** Globale Stellschrauben liegen in
  `kDifficultyModifiers` und skalieren die Basiswerte (keine doppelten Tabellen).

> **Nächster Ausbau (optional):** Konstanten in eine externe `balancing.json`
> auslagern und beim Start laden, damit auch ohne Rebuild getunt werden kann.
> Für das MVP genügt `constants.dart` als zentrale Config-Schicht.

---

## 2. Globale Stellschrauben (`constants.dart`)

| Konstante                 | Wert (Default) | Bedeutung                                  |
|---------------------------|----------------|--------------------------------------------|
| `kStartingCash`           | 15.000 €       | Startkapital                               |
| `kNationalAvgDoenerPrice` | 8,03 €         | Döner-Index (Referenz für Preis-Wirkung)   |
| `kTickIntervalSeconds`    | 3,0 s          | Realzeit pro Spielstunde                   |
| `kHoursPerDay`            | 24             | Stunden pro Spieltag                       |
| `kDailyOpenHours`         | 14,0           | Öffnungsstunden (10–24 Uhr)                |

---

## 3. Städte (`kAllCities`) — Freischalt-Ökonomie

| Tier        | Unlock (Gesamtumsatz) | Beispiel              | Miete-Basis | Foot-Traffic-Basis |
|-------------|-----------------------|-----------------------|-------------|--------------------|
| `klein`     | 0 € (Start)           | Fulda, Bayreuth       | 1.100–1.300 | 4.500–6.000        |
| `mittel`    | 30.000–50.000 €       | Augsburg, Münster     | 1.700–2.000 | 8.500–10.000       |
| `gross`     | 150.000–200.000 €     | Frankfurt, Köln       | 3.800–4.500 | 18.000–22.000      |
| `metropole` | 500.000–750.000 €     | Berlin, Hamburg, München | 6.500–8.000 | 40.000–50.000   |

Pro Stadt: `population`, `state` (für Regional-Synergie), `tier`, `unlockCost`,
`rentBase`, `footTrafficBase`. **Standort-Faktoren** (Multiplikatoren auf
Traffic & Miete) liegen pro Tier in `kLocationTemplates`.

---

## 4. Produkte (`kAllProducts`) — Margen

| Produkt           | Basispreis | Zutatenkosten | Marge | Default | Benötigt Equipment |
|-------------------|-----------:|--------------:|------:|:-------:|--------------------|
| Döner im Fladen   | 6,50 €     | 2,20 €        | 4,30 €| ✅      | —                  |
| Dürüm Döner       | 7,00 €     | 2,40 €        | 4,60 €| ✅      | —                  |
| Veg. Döner        | 6,50 €     | 1,80 €        | 4,70 €| ✅      | —                  |
| Döner-Box         | 9,50 €     | 3,50 €        | 6,00 €| —       | `fritteuse_standard` |
| Lahmacun          | 4,00 €     | 1,20 €        | 2,80 €| —       | `ofen_lahmacun`    |
| Pommes            | 3,50 €     | 0,80 €        | 2,70 €| —       | `fritteuse_standard` |
| Ayran             | 2,00 €     | 0,50 €        | 1,50 €| ✅      | —                  |
| Cola / Fanta      | 2,50 €     | 0,80 €        | 1,70 €| ✅      | —                  |

Der **Spielerpreis** ist gegenüber `basePrice` frei wählbar; die
Preis-Attraktivität wird gegen Zielgruppe und `kNationalAvgDoenerPrice` gewogen.

---

## 5. Equipment (`kAllEquipment`) — Kapazität / Qualität / Tempo

Beispielprogression Spieß: `spiess_klein` (800 €, +40 Kap, +0,15 Qual) →
`spiess_standard` (2.500 €, +100, +0,40) → `spiess_profi` (7.000 €, +200, +0,80).
Weitere Achsen: Kasse (Tempo), Fritteuse/Ofen (schalten Produkte frei),
Kühlschrank (`ingredientSavingBonus` 0,08).

**Tuning-Achsen pro Gerät:** `price`, `qualityBonus`, `capacityBonus`,
`speedBonus`, `ingredientSavingBonus`.

---

## 6. Personal (`kEmployeeTypes`)

| Typ            | Lohn/Tag | Qualität | Tempo |
|----------------|---------:|---------:|------:|
| Döner-Meister  | 80 €     | 0,40     | 0,20  |
| Kassierer/in   | 65 €     | 0,05     | 0,40  |
| Küchenhilfe    | 55 €     | 0,10     | 0,25  |

Löhne werden zusätzlich durch `candidateSalaryMultiplier` (Schwierigkeit)
skaliert.

---

## 7. Marketing (`kAllCampaigns` / city / global)

Tuning-Achsen pro Kampagne: `cost`, `durationDays`, `scope`, `customerBoost`,
`avgOrderValueMod`, `reputationBoostPerDay`, `reputationBoostOnce`,
`viralChance`, `brandAwarenessDelta`, `risk`. Spannweite von „Flyer" (400 €,
+15 %) bis „TV-Werbung national" (25.000 €, brand +1,5). **Wichtig fürs
Balancing:** keine Kampagne darf einen *dauerhaften* Vorteil ohne laufende
Kosten erzeugen.

---

## 8. Schwierigkeit (`kDifficultyModifiers`)

Globale Multiplikatoren je `GameDifficulty` (easy / normal / hard / impossible):
`hrRecruitmentSpeed`, `candidateQuality`, `candidateSalary`,
`competitorAggressiveness`, `customerPriceSensitivity`, `progressSpeed`,
`reputationPenalty`, `economicPressure`. `normal` = alle 1,0 (Referenz).

---

## 9. Balancing-Leitplanken (Soll-Werte)

| Metrik                              | Zielkorridor                |
|-------------------------------------|-----------------------------|
| Erste Filiale profitabel nach       | 2–4 Spieltage               |
| Erster Stadtwechsel nach            | ~15–25 Spieltage            |
| Verlorene Kunden (gut gemanagt)     | < 10 % der Nachfrage        |
| Pleite-Risiko bei vernünftigem Spiel| nahe 0 (auf `normal`)       |
| Optimaler Preis vs. Döner-Index     | meist 0,9×–1,15× je Lage    |

Diese Korridore werden über die Tests in `test/` (u. a.
`stability_balance_test.dart`, `optimal_price_test.dart`,
`location_economics_consistency_test.dart`) abgesichert.

---

## 10. Wie tune ich einen Wert? (Checkliste)

1. Wert in `lib/core/constants.dart` (oder `difficulty_model.dart`) ändern.
2. `flutter analyze` ausführen.
3. Relevante Tests laufen lassen (`flutter test test/<bereich>_test.dart`).
4. Logik in `game_engine.dart` **nicht** anfassen — nur Daten.
5. Änderung in `CHANGELOG.md` notieren.
