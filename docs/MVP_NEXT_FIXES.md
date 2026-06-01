# MVP_NEXT_FIXES — Design-Spec

Stand: 2026-06-01
Status: **Design only**, noch kein Code. Ziel ist ein klares Briefing für Codex
zur Umsetzung in kleinen, surgical PRs.

Out-of-Scope (bewusst):
- Keine Monetarisierungs-/Payment-Features.
- Keine großen Refactors (kein Rewrite von `game_engine.dart`,
  `competitor_engine.dart`, `corporate_engine.dart`).
- Keine 3D-Stadt, keine Story-Kampagne, kein HR-Manager-Rewrite.

Querverweise: [MVP_SCOPE.md](../MVP_SCOPE.md), [BALANCING.md](../BALANCING.md),
[GAME_DESIGN.md](../GAME_DESIGN.md), [tutorial_model.dart](../lib/models/tutorial_model.dart),
[difficulty_model.dart](../lib/models/difficulty_model.dart),
[competitor_engine.dart](../lib/services/competitor_engine.dart),
[corporate_engine.dart:251](../lib/services/corporate_engine.dart).

---

## 1. Tutorial-Onboarding (erste 10 Minuten)

### 1.1 Designprinzipien

1. **Eine Entscheidung pro Schritt.** Nie zwei Mechaniken gleichzeitig
   einführen.
2. **Pflicht-Pfad ist sehr kurz** (5 Schritte, ~3 Minuten bis zum ersten
   abgeschlossenen Tag). Alles danach ist **soft-guided** (Hinweis-Toast +
   Dismiss-Button), nicht blockierend.
3. **Sichtbares Ziel pro Schritt:** Banner oben mit „Aufgabe: X", grüner Haken
   wenn erledigt. Nie nur Text — immer mit klickbarer CTA.
4. **Skippable nach Schritt 3.** Spieler, die das System kennen, brauchen den
   Long-Pfad nicht. Skip-Button erscheint ab `endFirstDay`.
5. **Kein Modal-Lock auf der Map.** Tutorial nutzt **Coach-Marks** (Highlight +
   Pfeil) statt Vollbild-Dialogen, sonst geht das City-Map-Feeling verloren.

### 1.2 Pflicht-Schritte (P) vs. Optional (O)

| # | Step (enum)                          | P/O | Screen                              | CTA / Verifier                                           | Warum                                          |
|---|--------------------------------------|-----|-------------------------------------|----------------------------------------------------------|------------------------------------------------|
| 1 | `openFirstShop`                      | P   | `/city-map/:cityId` (Startstadt)    | Hotspot tappen → Shop eröffnen → `state.shops.length=1` | Ohne Filiale kein Loop.                        |
| 2 | `understandLocationValues`           | P   | Bottom-Sheet beim Hotspot-Tap       | „Weiter"-Button nach 1 Sek Sicht­barkeit                | Spieler lernt Miete/Traffic/Druck zu lesen.    |
| 3 | `changeProductPrice`                 | P   | Shop-Detail → Sortiment             | Mind. 1 `ShopProduct.price` ≠ `basePrice`                | Hauptlevel des Spiels.                         |
| 4 | `endFirstDay`                        | P   | Dashboard → „Tag beenden"           | `state.currentDay` erhöht                                | Erst hier passiert die Simulation.             |
| 5 | `readDayReport`                      | P   | Tagesabschluss-Dialog               | Dialog mit „Verstanden" schließen                        | Ursache→Wirkung wird hier sichtbar.            |
| 6 | `hireFirstEmployee`                  | O   | Shop-Detail → Mitarbeiter           | Erster Hire                                              | Erst sinnvoll wenn Kapazitätslimit greift.     |
| 7 | `viewDashboardMetrics`               | O   | Dashboard                           | Tab gesehen ≥3 Sek                                       | Soft-Tutorial.                                 |
| 8 | `openEmpireMenu`                     | O   | Imperium-Tab                        | Tab geöffnet                                             | Vorbereitung auf zweite Stadt.                 |
| 9 | `understandHrCompetitionGrowth`      | O   | Konzern-Tab                         | Tab geöffnet                                             | Spät, nur als Hinweis.                         |
|10 | `finishTutorial`                     | O   | Toast „Tutorial fertig"             | Auto-Trigger nach 1. Filialwechsel oder Skip            | Sauberer Abschluss.                            |

**Skip-Button** erscheint **ab Schritt 5**. Davor: nur „Weiter"-Buttons. Skip
markiert alle restlichen Steps als `completed` ohne sie auszulösen.

### 1.3 Coach-Mark-Inhalt

Jeder Step zeigt:
- **Aufgabe** (1 Zeile, imperativ — bereits in `TutorialStep.description` vorhanden)
- **Warum** (1 Zeile — bereits in `whyItMatters` vorhanden)
- **Tipp** (1 Zeile — bereits in `hint` vorhanden)

→ Texte sind im Code schon da. Aufgabe ist nur das **Routing/Highlighting**,
nicht der Content.

### 1.4 Erste-10-Min-Sollverlauf (Soll-Telemetrie)

| t (mm:ss) | Erwartetes Ereignis                              |
|-----------|--------------------------------------------------|
| 00:00     | Spielstart, Splash → New Game → Tutorial-Banner  |
| 00:30     | Stadt gewählt, Hotspot getappt                   |
| 01:30     | Erste Filiale eröffnet (Schritt 1 erledigt)      |
| 02:30     | Erster Preis geändert (Schritt 3 erledigt)       |
| 03:30     | Erster Tag simuliert + Bericht geschlossen       |
| 04:00     | Spieler ist im freien Spiel, Tutorial soft-aktiv |
| 04:00-10:00 | 3–5 weitere Tage, evtl. Mitarbeiter eingestellt, Upgrade gekauft |

Wenn nach **5 Min** Schritt 1 nicht erledigt ist → Hint-Banner verstärken
(Pfeil pulsiert), aber **nicht blockieren**.

---

## 2. Filialausbau / Personal-Cap

### 2.1 Problem heute

`GameEngine.maxEmployeesForShop` ist **rein city-tier-basiert** ([game_engine.dart:192](../lib/services/game_engine.dart)).
Damit ist die einzige Wachstumsachse einer Filiale „Personal einstellen bis Cap",
und der Cap ist fix. Es gibt keinen Trade-off „mehr Kapazität gegen mehr
Fixkosten".

### 2.2 Vorschlag: `ShopSizeTier`

Neuer Wert auf `Shop`: `sizeTier` (Default `klein`). Cap wird zu
**min(shopSizeCap, cityTierCap)** — die Stadt bleibt die harte Obergrenze, die
Shop-Stufe ist der **eigentliche Hebel**.

### 2.3 Tabelle: Filialgrößen

| Tier        | Mitarbeiter-Cap | Kapazitäts-Multi (Customer-Throughput) | Ausbau­kosten | Miet-Multi (auf `weeklyRent`) | Moral-Modifier |
|-------------|-----------------|-----------------------------------------|---------------|--------------------------------|----------------|
| `klein`     | 3               | 1.00                                    | — (Start)     | 1.00                           | 0              |
| `mittel`    | 5               | 1.35                                    | 8.000 €       | 1.25                           | −0.02 (mehr Stress, mehr Leute) |
| `gross`     | 8               | 1.75                                    | 25.000 €      | 1.60                           | −0.05          |
| `flagship`  | 12              | 2.20                                    | 70.000 €      | 2.10                           | −0.08 (nur mit Manager kompensierbar) |

Cap-Logik:
```
effectiveCap = min(shopSizeTier.cap, cityTier.cap)
```
→ In `klein`-Städten ist auch ein `flagship`-Ausbau bei **3** gedeckelt
(verhindert Cheese). `flagship` ist erst in `gross`/`metropole` voll nutzbar.

### 2.4 Wann ist Ausbau **kein No-Brainer**?

- **Miete steigt sofort** (kein Grace-Period). Wenn aktuelle Auslastung <70 % →
  ROI negativ.
- **Moral sinkt** bei Stufenwechsel um den `morale-modifier` (siehe Tabelle).
  Niedrige Moral → langsame Kapazität, höheres Kündigungsrisiko. Reaktivierung
  durch Manager / Schulung / Lohn-Bonus.
- **Reputations-Delle:** Beim Ausbau ist die Filiale 1 Spieltag „im Umbau",
  Tagesumsatz × 0.3, Ruf −0.1 (einmalig, regeneriert).
- **Konkurrenz-Trigger:** Ein Ausbau in einer Stadt zählt als „starkes Signal",
  setzt `competitorAggressivenessBonus += 0.05` für 14 Spieltage in dieser
  Stadt (siehe §3.4).

### 2.5 Akzeptanzkriterien (Codex)

- [ ] `ShopSizeTier { klein, mittel, gross, flagship }` in `shop_model.dart`,
      Default `klein`, JSON-Roundtrip + Migration (fehlender Wert → `klein`).
- [ ] `Shop.sizeTier` per `copyWith` änderbar.
- [ ] `GameEngine.maxEmployeesForShop` nutzt **min(sizeTierCap, cityTierCap)**.
- [ ] Kapazitäts-Multi greift in `calculateShopStats` als Multi auf
      `capacity` (NICHT auf `potentialCustomers`).
- [ ] Miet-Multi greift auf `weeklyRent` beim Wechsel (persistent, nicht
      jeden Tag neu berechnet).
- [ ] Beim Ausbau: Cash-Abzug, 1 Tag „Umbau" (Flag auf Shop), einmaliger
      Ruf-Delta, Moral-Delta.
- [ ] Tests: Cap-Logik, Cash-Abzug, Umbau-Tag verringert Umsatz, Migration
      alter Saves.
- [ ] UI: Ausbau-Button im Shop-Detail mit Vorschau „Cap 3 → 5, Miete
      1200 € → 1500 €/Woche, Kosten 8.000 €".

---

## 3. Schwierigkeit & Konkurrenz

### 3.1 Status

`DifficultyModifiers` mit 8 Werten × 4 Stufen existiert
([difficulty_model.dart:8](../lib/models/difficulty_model.dart)). Werte sind
nahe an `1.0` (z.B. `hard.competitorAggressivenessMultiplier = 1.20`). In der
Praxis fühlt sich `hard` zu nah an `normal` an, weil mehrere Multiplikatoren
gegeneinander arbeiten.

### 3.2 Ziel: spürbare Trennung

Easy = Sandbox („nichts geht kaputt"), Normal = ausgewogen, Hard = harte
ökonomische Konsequenzen, Impossible = Roguelike-Druck.

### 3.3 Empfohlene Multiplikatoren (Tuning-Vorschlag)

| Modifier                              | Easy  | Normal | Hard  | Impossible |
|---------------------------------------|-------|--------|-------|------------|
| `hrRecruitmentSpeedMultiplier`        | 1.60  | 1.00   | 0.70  | 0.45       |
| `candidateQualityMultiplier`          | 1.25  | 1.00   | 0.85  | 0.70       |
| `candidateSalaryMultiplier`           | 0.80  | 1.00   | 1.20  | 1.45       |
| `competitorAggressivenessMultiplier`  | 0.60  | 1.00   | 1.40  | 1.90       |
| `customerPriceSensitivityMultiplier`  | 0.65  | 1.00   | 1.30  | 1.65       |
| `progressSpeedMultiplier`             | 1.35  | 1.00   | 0.80  | 0.60       |
| `reputationPenaltyMultiplier`         | 0.60  | 1.00   | 1.30  | 1.70       |
| `economicPressureMultiplier`          | 0.75  | 1.00   | 1.25  | 1.55       |

Begründung pro Achse:
- **Recruitment-Speed × Salary**: Easy = Bewerber überall, billig. Impossible =
  Wochen warten, teure Talente.
- **PriceSensitivity**: Auf Hard reicht 50 Cent über Markt für spürbaren
  Customer-Drop, auf Easy verzeihen Kunden +20 %.
- **competitorAggressiveness × economicPressure** wirken zusammen — auf
  Impossible wachsen Konkurrenten 1.9× schneller **und** Fixkosten sind 1.55×
  → echte Squeeze.

### 3.4 Konkurrenz-Reaktionen (Verfeinerung)

Heute reagiert die KI nur auf Spieler-**Preisniveau**
([competitor_engine.dart:264](../lib/services/competitor_engine.dart)). Drei
neue Signale hinzufügen — **alle in `competitor_engine.dart`**, keine externen
Module:

1. **Hohe Gewinne (Spieler).**
   Trigger: Spieler-Tagesgewinn in der Stadt > 2× Stadt-Median (rolling 7d).
   Effekt: `aggressivenessBoost = +0.15` für 14 Tage (additiv auf
   `competitorAggressivenessMultiplier`), erhöht Expansions- und Preiskampf-Chance.
   Narrativ: „Die Konkurrenz hat deinen Erfolg gerochen."

2. **Hohe Preise (Spieler ≥ +20 % über Stadt-Schnitt).**
   Effekt: `cheapMass` + `aggressive` öffnen mit 1.5× Chance neue Filialen in
   derselben Stadt; Marketing-Push auf Preis-Slogan.

3. **Monopolstellung (Spieler-Marktanteil > 60 % einer Stadt).**
   Effekt:
   - Neue Konkurrenten spawnen mit `priceLevel = 0.75–0.85` und
     `personality = aggressive`.
   - Spawn-Chance je Tag = 0.04 statt 0.02 (siehe `processDay`).
   - **Cap bleibt** bei `_naturalCompetitorCap` — nur die Spawn-Wahrscheinlichkeit
     steigt.

### 3.5 Anti-Monopol — was ist *fair*?

Ziel: Monopol bleibt erreichbar, aber teuer zu halten — **kein** Bestrafen
durch Cap oder hard-coded Caps auf Spieler-Filialen.

| Mechanik                              | Fair? | Begründung                                          |
|---------------------------------------|-------|-----------------------------------------------------|
| Cap auf Spieler-Filialen pro Stadt    | ❌    | Bestraft Erfolg, fühlt sich willkürlich an.         |
| Strengere Konkurrenz-Spawns (§3.4)    | ✅    | Reagiert auf Marktverhalten, nicht auf Identität.   |
| „Kartellamt"-Event mit Geldstrafe     | ⚠️   | Nur als seltenes Event (≥75 % Anteil, 1× pro 30d), klar kommuniziert. Geldstrafe = 5 % Cash, *kein* erzwungener Verkauf. |
| Höhere Mieten in dominierten Städten  | ✅    | Mietfaktor ×1.10 bei >70 % Anteil — Markt korrigiert sich. |
| Spieler-Filialen werden enteignet     | ❌    | Zu hart, kein Save-Reset-Risiko im MVP.             |

**MVP-Empfehlung:** §3.4 + Mietfaktor (✅-Zeile). Kartellamt-Event als Post-MVP.

### 3.6 Akzeptanzkriterien (Codex)

- [ ] `kDifficultyModifiers` auf neue Tabelle (§3.3) gesetzt.
- [ ] `CompetitorEngine.processDay` liest neue Signale (Gewinn, Preisniveau,
      Marktanteil) aus `GameState` und passt `aggressivenessBoost` pro Stadt an.
- [ ] `aggressivenessBoost` ist **stadtspezifisch** und temporär (Decay über
      14 Tage), nicht global.
- [ ] Mietfaktor ×1.10 wirkt auf `weeklyRent`-Berechnung beim Tagesabschluss
      *ab* >70 % Marktanteil (kein Save-State-Mutation, sondern Berechnung).
- [ ] Tests: Boost greift/erlischt, Spawns reagieren auf Monopol-Schwelle,
      Easy bleibt verzeihend.
- [ ] UI: Schwierigkeits-Wähler zeigt 2–3 spürbare Konsequenzen statt
      generischen Text.

---

## 4. Buyout-Regel (M&A)

### 4.1 Status

`CorporateEngine.acquireCompetitor` ([corporate_engine.dart:259](../lib/services/corporate_engine.dart))
erzeugt `shopCount` Player-Shops mit:
- Default-Menü (alle `isDefault`-Produkte zum `basePrice`)
- **leerem Equipment**
- **leerem Personal**
- Ruf = Konkurrenten-Ruf
- `locationName` aus Template (round-robin, **nicht echte Konkurrenz-Standorte**)

Preis = `shopCount × 60.000 € × repFactor` (rep/3, clamp 0.7..1.6).

### 4.2 Designentscheidung

**Ja, Spieler bekommt Filialen** — das ist der ganze Sinn des M&A. Aber:

1. **Übernommene Filialen starten mit klaren Nachteilen**, damit M&A nicht
   strikt besser ist als „selbst eröffnen + ausbauen":
   - Equipment: leer (heute schon so) → Spieler muss nachrüsten.
   - Personal: **30 % von `effectiveCap`**, mit zufälligem Skill-Profil im
     mittleren Drittel (kein Top-Personal geschenkt). Salary = aktuelle
     Markt-Salary × `candidateSalaryMultiplier`.
   - Ruf: **0.7 × Konkurrenten-Ruf**, da Übergangsphase / Markenwechsel
     („ehemals X" — bereits via `originalCompetitorName` im UI).
   - `morale = 0.55` (statt Default 0.75) → muss aktiv gehoben werden.
   - `regulars = 0.0` — Stammkundschaft springt nicht 1:1 mit.
   - `sizeTier = klein` (egal wie groß der Konkurrent war).

2. **Equipment-Übergabe optional**, aber teuer:
   Bei Akquisition wahlweise „mit Inventar" → **+30 %** auf Kaufpreis,
   Filialen erhalten je 1× Basis-Equipment (`spiess_standard`, `kasse_basic`).
   Default-Klick = ohne Inventar.

3. **Preisformel anpassen**, weil Reputation jetzt nicht voll übertragen wird:

```
basePrice  = shopCount * 60_000
repFactor  = clamp(reputation / 3.0, 0.7, 1.6)
marketCap  = (1 + competitor.marketShare * 1.5)   // belohnt starken Marktanteil
price      = basePrice * repFactor * marketCap
```

Beispiel: Konkurrent mit 3 Filialen, Ruf 4.0, 30 % Marktanteil:
`3 × 60k × 1.33 × 1.45 = ~347k €` (vorher: `~240k €`).

### 4.3 Tabelle: Übernahme-Effekte

| Eigenschaft        | Wert beim Buyout                          |
|--------------------|-------------------------------------------|
| Filialen-Anzahl    | `competitor.shopCount`                    |
| Locations          | Template-Round-Robin (heute), MVP-OK      |
| Equipment          | leer (oder Basis-Pack bei +30 %)          |
| Personal           | 30 % von `effectiveCap`, mittleres Skill  |
| Ruf                | `0.7 × competitor.reputation`             |
| Moral              | `0.55`                                    |
| Regulars           | `0.0`                                     |
| SizeTier           | `klein`                                   |
| Menü               | Default-Produkte zu `basePrice`           |
| Flag               | `wasAcquired=true`, `originalCompetitorName` |
| Cooldown           | Pro Stadt 30 Spieltage zwischen Buyouts   |

### 4.4 Warum das M&A spannend macht

- Spieler bezahlt für **Marktanteil** + **Standort-Zugang in vollen Städten**,
  nicht für eine schlüsselfertige Filiale.
- 30-Tage-Cooldown verhindert „alle Konkurrenten in einer Stadt am selben Tag
  schlucken".
- Übernommene Filialen sind **investitions­bedürftig** — der Spieler hat
  weiterhin etwas zu tun, statt einen Idle-Cashflow zu kaufen.

### 4.5 Akzeptanzkriterien (Codex)

- [ ] `acquisitionPrice(Competitor)` nutzt neue Formel inkl.
      `marketShare`-Faktor.
- [ ] `acquireCompetitor` setzt `reputation`, `morale`, `regulars`, `sizeTier`
      gemäß Tabelle.
- [ ] Optional-Flag `withInventory` (default `false`); bei `true`:
      `price × 1.3` + 1× `spiess_standard` + 1× `kasse_basic` pro Filiale.
- [ ] 30-Tage-Cooldown pro Stadt: `GameState.lastAcquisitionDayPerCity` (Map),
      `acquireCompetitor` lehnt ab, wenn nicht erreicht.
- [ ] 30 % Personal-Auffüllung nutzt bestehende HR-Helfer (`HrEngine`), kein
      eigenes Skill-Roll.
- [ ] Tests: Preis-Formel, Personal-Auffüllung, Cooldown, Migration alter Saves
      (fehlende Map → leer).
- [ ] UI: Akquise-Dialog zeigt Vorher/Nachher (Ruf 4.0 → 2.8, Personal 0 → 3,
      Cash − X €).

---

## 5. Risiken / Tradeoffs

| Risiko                                                                     | Mitigation                                                       |
|----------------------------------------------------------------------------|------------------------------------------------------------------|
| Schwierigkeits-Rebalance (§3.3) macht alte Saves „kaputt"                  | Werte nur prospektiv anwenden; alte Saves behalten ihre Difficulty-Wahl, Spieler-Wahrnehmung ändert sich erst nach Save-Migration. Im Save-Migrator nichts ändern. |
| `ShopSizeTier` bricht alte Saves                                           | Default-Wert `klein` bei fehlendem JSON-Feld; explizit getestet. |
| Konkurrenz-Boost (§3.4) wird unsichtbar / unverständlich                   | Toast „Konkurrenz reagiert auf deinen Erfolg in {Stadt}" beim Trigger. |
| Buyout fühlt sich nach Preiserhöhung schlecht an                           | Spielerlebnis: Vorher/Nachher-Dialog, „warum so teuer?"-Tooltip. |
| Coach-Marks im Tutorial konkurrieren mit City-Map-Gesten                   | Tutorial blockiert nur den **CTA-Bereich**, Map bleibt schwenkbar. |
| 30-Tage-Cooldown frustriert späteres Spielen                               | Cooldown ist *pro Stadt*, nicht global. Mehrere Städte parallel möglich. |
| Mietfaktor ×1.10 bei Monopol verstößt gegen „kein Cap"-Versprechen         | Nicht-blockierend, klar kommuniziert als „Standort-Inflation". Spieler kann zahlen. |

---

## 6. Reihenfolge der Umsetzung (Empfehlung an Codex)

1. **Schwierigkeit-Multiplikatoren neu tunen** (§3.3) — kleinster Diff,
   sofortige spürbare Verbesserung. *Eigener PR.*
2. **Tutorial-Coach-Marks** (§1) — nutzt vorhandene Texte, nur Routing/UI.
   *Eigener PR.*
3. **ShopSizeTier** (§2) — Datenmodell + Engine-Integration. *Eigener PR.*
4. **Konkurrenz-Reaktionen** (§3.4 + §3.5) — `competitor_engine.dart` only.
   *Eigener PR.*
5. **Buyout-Rebalance** (§4) — `corporate_engine.dart` only. *Eigener PR.*

Jeder Schritt: Tests grün, `flutter analyze` clean, eine UI-Verifikation.
