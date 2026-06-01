# KNOWN_RISKS_NEXT — Risiko-Register für die nächsten PRs

Stand: 2026-06-01
Zweck: Bekannte Risiken **vor** der Umsetzung. Jeder Eintrag hat
Wahrscheinlichkeit, Impact, Mitigation und Owner.

Skalen:
- Wahrscheinlichkeit: **L** (low) / **M** (medium) / **H** (high)
- Impact: **L** / **M** / **H**
- Priorität = max(W, I), nur als Sortierhilfe.

Querverweise: [MVP_NEXT_FIXES.md](MVP_NEXT_FIXES.md),
[PR_REVIEW_CHECKLIST.md](PR_REVIEW_CHECKLIST.md),
[PLAYTEST_SCRIPT_MVP.md](PLAYTEST_SCRIPT_MVP.md).

---

## 1. Tutorial-Risiken

### R-T1 — Tutorial zu passiv (W: M / I: H)
**Beobachtung:** Aktuelle Steps sind reine Banner-Texte ohne UI-Highlight.
Spieler tappt blind weiter oder ignoriert das Tutorial komplett.

**Mitigation:**
- Coach-Marks mit Pulsations-Animation auf CTA-Element (PR 2).
- Step-Verifier State-basiert, damit das Tutorial **erkennt**, wann der
  Spieler die Aufgabe erledigt hat, statt nur „Weiter" zu zeigen.
- Soll-Telemetrie: wenn nach 5 Min Step 1 nicht erledigt → Hint verstärken.

**Owner:** PR 2.
**Verifier:** `PLAYTEST_SCRIPT_MVP.md §1`, Soll-Zeiten ≤ §7-Tabelle.

### R-T2 — Tutorial blockiert die City-Map-Erkundung (W: M / I: M)
**Beobachtung:** Modal-Tutorials nehmen den Map-Wow-Effekt komplett raus.

**Mitigation:** Coach-Marks haben Backdrop **nur** auf CTA, restliche Map
bleibt schwenkbar und tappbar.

**Owner:** PR 2.
**Verifier:** Manuell — Map lässt sich während Coach-Mark schwenken.

### R-T3 — Veteranen sehen Tutorial erneut nach Update (W: M / I: M)
**Beobachtung:** Alte Saves haben kein Tutorial-Feld → Default-Wert.

**Mitigation:** Default für fehlendes Feld = `tutorialCompleted = true`.
Nur neue Saves starten mit Tutorial. Im PR-Review explizit testen.

**Owner:** PR 2.
**Verifier:** Save-Roundtrip mit Save aus Pre-Tutorial-Version.

---

## 2. Difficulty-Risiken

### R-D1 — Difficulty-Stufen zu ähnlich (W: H / I: H)
**Beobachtung:** Bestehende Multiplikatoren bei `hard` sind 1.12..1.40 — nahe
an Normal, Spieler merkt den Unterschied nicht.

**Mitigation:** Neue Tabelle in [MVP_NEXT_FIXES.md §3.3](MVP_NEXT_FIXES.md)
spreizt deutlich. Easy = 0.45..1.60, Impossible = 0.45..1.90.

**Owner:** PR 1.
**Verifier:** `BALANCING_PLAYTEST_NOTES.md §3.1–§3.5`, Median-Werte
müssen klare Korridore zeigen.

### R-D2 — Impossible wird zur Unspielbar-Spirale (W: M / I: H)
**Beobachtung:** 8 Multiplikatoren multiplizieren sich teilweise gegenseitig
(Preis-Sensitivität × Konkurrenz-Aggression × Ökonomie-Druck) → Spieler
verliert vor Tag 5.

**Mitigation:**
- Soll-Korridor in [BALANCING_PLAYTEST_NOTES.md §2](BALANCING_PLAYTEST_NOTES.md):
  Impossible-Profitabilität Tag 8–14, nicht unmöglich.
- Falls Playtest <Tag 8: `economicPressureMultiplier` zurückdrehen oder
  Startkapital bei Impossible anheben (statt alle 8 Werte zu tunen).

**Owner:** PR 1 + Tuning-Backlog.
**Verifier:** Playtest mit 3 Runs Impossible, mindestens 1× Tag 14 erreicht.

### R-D3 — Easy ist langweilig (W: M / I: L)
**Beobachtung:** Wenn Easy zu großzügig wird, gibt es keinen Loop-Anreiz.

**Mitigation:** Easy soll **schnellen** Loop bieten (progressSpeedMultiplier
1.35), nicht **trivialen**. Konkurrenz reagiert seltener, aber nicht nie.

**Owner:** PR 1.

---

## 3. ShopSizeTier / Filialausbau

### R-S1 — Ausbau wird No-Brainer (W: H / I: H)
**Beobachtung:** Wenn Kapazitäts-Multi >> Mietkosten, ist Ausbau immer
profitabel.

**Mitigation:**
- Miet-Multi 1.25 → 1.60 → 2.10 ist **superlinear**, Kapazitäts-Multi
  1.35 → 1.75 → 2.20 ist **sublinear**.
- Moral-Delta sorgt für versteckte Kosten (mehr Manager-Bedarf bei größeren
  Filialen).
- Umbau-Tag (1 Tag schlechter Umsatz + Ruf −0.1).
- Konkurrenz-Trigger: Ausbau zählt als „starkes Signal".

**Owner:** PR 3.
**Verifier:** [BALANCING_PLAYTEST_NOTES.md §3.3](BALANCING_PLAYTEST_NOTES.md) —
Ausbau-Zeitpunkt im Soll-Korridor, nicht sofort.

### R-S2 — Cap-Logik wird in Kleinstadt verwirrend (W: M / I: M)
**Beobachtung:** `flagship` in Kleinstadt = Cap 3 (Stadt-Cap), nicht 12.
Spieler versteht nicht, warum er gerade 70.000 € für Cap 3 gezahlt hat.

**Mitigation:**
- Ausbau-Dialog zeigt **vor** Bestätigung den `effectiveCap`:
  „Cap 3/12 — durch Stadt begrenzt".
- Tooltip auf Cap-Anzeige erklärt min(shopTier, cityTier).
- Idealerweise: `flagship`-Button in Kleinstadt komplett disabled mit Hinweis
  „Erst in größeren Städten".

**Owner:** PR 3.

### R-S3 — Migration alter Saves schlägt fehl (W: M / I: H)
**Beobachtung:** Save-Files ohne `sizeTier`-Feld → Crash beim Laden.

**Mitigation:**
- Default in `Shop.fromJson`: `sizeTier = ShopSizeTier.klein` bei fehlendem Feld.
- Test mit alter Save-Datei aus pre-PR3-Build im CI.

**Owner:** PR 3.
**Verifier:** [PR_REVIEW_CHECKLIST.md PR 3](PR_REVIEW_CHECKLIST.md) — Save-Migration-Item.

---

## 4. Konkurrenz / Anti-Monopol

### R-K1 — Anti-Monopol fühlt sich unfair an (W: M / I: H)
**Beobachtung:** Spieler wird für Erfolg „bestraft" — klassisches
4X-Frust-Pattern.

**Mitigation:**
- Mechaniken sind **emergent** (Konkurrenz reagiert auf Markt), nicht
  identitätsbasiert.
- Klare Kommunikation: Toast „Konkurrenz reagiert auf deinen Erfolg" mit
  konkreter Stadt.
- **Kein** harter Cap auf Spieler-Filialen, **kein** erzwungener Verkauf
  ([MVP_NEXT_FIXES.md §3.5](MVP_NEXT_FIXES.md)).
- Mietfaktor ×1.10 ist die einzige „Steuer" und maximal moderat.

**Owner:** PR 4.

### R-K2 — Boost wird global statt stadt-spezifisch (W: M / I: M)
**Beobachtung:** Klassischer Fehler beim Refactor — globale Map vergessen.

**Mitigation:** Test, der einen Boost in Stadt A setzt und in Stadt B
prüft, dass `aggressivenessBoostByCity['B']` weiter 0 ist.

**Owner:** PR 4.

### R-K3 — Mietfaktor wird persistent geschrieben (W: H / I: H)
**Beobachtung:** Wenn Codex `shop.weeklyRent *= 1.10` schreibt, bleibt der
Effekt auch nach Marktanteils-Rückgang.

**Mitigation:**
- Mietfaktor **nur** in der Tagesberechnung (`processDay` / `dailyRent`-Reader).
- Snapshot-Test: `shop.weeklyRent` vor und nach `processDay` identisch.

**Owner:** PR 4.
**Verifier:** Explizit als Item in [PR_REVIEW_CHECKLIST.md PR 4](PR_REVIEW_CHECKLIST.md).

### R-K4 — Toast-Spam (W: M / I: L)
**Beobachtung:** Trigger feuert jeden Tag erneut → 5 identische Toasts.

**Mitigation:** Trigger setzt `lastTriggeredDayByCity`, neuer Toast erst nach
14 Tagen oder nach Boost-Ablauf.

**Owner:** PR 4.

---

## 5. Buyout-Risiken

### R-B1 — Buyout-Werte inkonsistent zwischen Engine und UI (W: H / I: H)
**Beobachtung:** UI zeigt Preis A, `acquireCompetitor` rechnet Preis B
(z. B. weil `marketShare` zwischen Klick und Bestätigung neu berechnet wurde).

**Mitigation:**
- Preis im UI **einfrieren** zum Zeitpunkt des Dialog-Öffnens.
- `acquireCompetitor` nimmt den eingefrorenen Preis als Parameter, nicht neu
  berechnet.
- Test: zwischen Dialog-Open und Confirm einen `processDay` simulieren —
  Preis im Dialog bleibt.

**Owner:** PR 5.

### R-B2 — 30 % Personal in Kleinstadt = 0 Mitarbeiter (W: H / I: M)
**Beobachtung:** `floor(0.3 × 3) = 0`. Übernommene Filiale ist sofort
unverkäuflich.

**Mitigation:**
- `max(1, floor(0.3 × effectiveCap))` für `shopCount ≥ 1`.
- Spec sagt „30 %", aber Mindestwert 1 ist sinnvoll und in der Tabelle in
  [MVP_NEXT_FIXES.md §4.3](MVP_NEXT_FIXES.md) implizit, hier explizit machen.

**Owner:** PR 5.

### R-B3 — Cooldown frustriert späteres Spielen (W: L / I: M)
**Beobachtung:** Spieler will in Stadt X expandieren, 2 Konkurrenten da,
darf nur einen kaufen.

**Mitigation:**
- Cooldown ist **pro Stadt**, mehrere Städte parallel.
- 30 Tage entsprechen ~1 Monat Spielzeit, nicht 30 Min Realzeit.
- Cooldown sichtbar machen: Konzern-Tab zeigt „nächste Akquisition in {X} Tagen".

**Owner:** PR 5.

### R-B4 — Übernommene Filialen sind zu schwach → Spieler verkauft sofort (W: M / I: L)
**Beobachtung:** Ruf × 0.7, Moral 0.55, kein Equipment — wirkt wie ein
Geldverbrennungs-Kauf.

**Mitigation:**
- Marktanteil-Faktor im Preis sorgt dafür, dass Spieler **für Marktanteil**
  zahlt, nicht für die Filiale.
- UI-Dialog kommuniziert: „Du kaufst Marktanteil + Standorte, nicht
  schlüsselfertige Filialen."
- Falls Playtest Median +1/+2 „zu schwach": Personal-Anteil auf 40 % erhöhen
  (Spec lässt 30 % als Anker, Tuning-Backlog).

**Owner:** PR 5 + [BALANCING_PLAYTEST_NOTES.md §3.5](BALANCING_PLAYTEST_NOTES.md).

### R-B5 — Inventar-Option nicht klar (W: L / I: L)
**Beobachtung:** Toggle „mit Inventar" für +30 % wirkt willkürlich.

**Mitigation:** Tooltip: „Übernimmt Basis-Spieß + Basis-Kasse pro Filiale.
Spart ~1.500 € pro Filiale an Equipment-Kosten, lohnt sich ab 3 Filialen".

**Owner:** PR 5.

---

## 6. Save / Migration / Cross-Cutting

### R-M1 — Mehrere PRs ändern Save-Format gleichzeitig (W: M / I: H)
**Beobachtung:** PR 3 (`sizeTier`), PR 4 (`aggressivenessBoostByCity`), PR 5
(`lastAcquisitionDayPerCity`) fügen alle Felder hinzu. Bei falscher
Reihenfolge bricht ein PR den Save eines anderen.

**Mitigation:**
- Jede neue Feld-Ergänzung hat einen **Default** (`klein`, `{}`, `{}`).
- Save-Roundtrip-Test in jedem PR mit Save-Fixture aus pre-PR-Stand.
- Reihenfolge in [MVP_NEXT_FIXES.md §6](MVP_NEXT_FIXES.md): 1 → 2 → 3 → 4 → 5.

**Owner:** Alle PRs.
**Verifier:** Save-Migration-Item in [PR_REVIEW_CHECKLIST.md](PR_REVIEW_CHECKLIST.md).

### R-M2 — Save-Versions-Feld fehlt (W: H / I: M)
**Beobachtung:** Aktuell kein expliziter `saveVersion`-Schlüssel im JSON.
Spätere Migrationen werden hart.

**Mitigation:**
- **Im MVP nicht fixen** — würde zu großer Refactor.
- Aber dokumentieren als Post-MVP-Risk und beim nächsten größeren
  Refactor mitnehmen.

**Owner:** Post-MVP.

---

## 7. UI / Texte / Lokalisierung

### R-U1 — Umlaute zerschossen (W: M / I: M)
**Beobachtung:** Bereits in [competitor_model.dart](../lib/models/competitor_model.dart)
sichtbar: `'Kebap KralÄ±'` statt `Kralı` — Mojibake durch falsches Encoding.

**Mitigation:**
- Alle neuen Strings in UTF-8 ohne BOM speichern.
- Vor jedem PR-Merge: `grep -P '[ÃÂ][^a-zA-Z]'` über `lib/` (oder
  Ripgrep mit `--encoding=utf-8`), prüfen.
- Tests vergleichen Strings als Bytes, nicht via Konsole.

**Owner:** Alle PRs mit UI-Strings (PR 2, 3, 4, 5).

### R-U2 — Komma/Punkt-Trennung in Preisfeldern (W: M / I: M)
**Beobachtung:** Deutsche Locale erwartet `7,00`, Code parst `7.00`.

**Mitigation:**
- Preis-Eingabefelder nutzen `NumberFormat.decimalPattern('de_DE')`.
- Test mit `7,00` und `7.00`, beides muss als 7.0 ankommen.

**Owner:** PR 2 (Tutorial-Step 3 testet das implizit), PR 3 (Ausbau-Kosten-Display).

### R-U3 — Lange Labels sprengen UI (W: M / I: L)
**Beobachtung:** „Ausbauen auf Flagship-Filiale (70.000 €)" passt nicht in
schmale Buttons.

**Mitigation:**
- Buttons mit `TextOverflow.ellipsis` und Tooltip.
- Im Smoke-Test auf 360×640 (Phone-Default) prüfen.

**Owner:** PR 3, PR 5.

---

## 8. Tests / CI

### R-CI1 — Keine CI für Save-Fixtures (W: H / I: M)
**Beobachtung:** Save-Migrations-Tests laufen lokal, aber kein Fixture im Repo.

**Mitigation:**
- Pro neuer Migration: 1 JSON-Fixture in `test/fixtures/saves/` (z. B.
  `pre_sizetier_v1.json`).
- Test lädt Fixture, prüft Defaults.

**Owner:** PR 3, PR 4, PR 5.

### R-CI2 — Flutter-Test ist langsam → Tests werden geskippt (W: M / I: M)
**Beobachtung:** Wenn der lokale Run > 60 Sek dauert, neigt Codex dazu,
Tests zu „vergessen".

**Mitigation:**
- Neue Tests klein halten (Unit, kein WidgetTest wenn vermeidbar).
- PR-Checkliste hat explizites `flutter test`-Item.
- Bei Test-Lücke: PR zurück.

**Owner:** Reviewer.

### R-CI3 — Tests gegen Floating-Point ohne Toleranz (W: H / I: L)
**Beobachtung:** Buyout-Preis = 348.000 € exakt scheitert wegen `1e-9`.

**Mitigation:**
- `expect(price, closeTo(348000, 100))` mit ±1 % Toleranz.
- Generelle Regel im Review.

**Owner:** Alle PRs mit Numerik (PR 1, 3, 4, 5).

---

## 9. Prozess-Risiken

### R-P1 — Codex „verbessert" mit (W: H / I: M)
**Beobachtung:** Codex hat die Tendenz, beim Bearbeiten einer Datei adjacente
Code-Smells „mitzufixen".

**Mitigation:**
- Jeder PR hat einen klaren Scope in [PR_REVIEW_CHECKLIST.md](PR_REVIEW_CHECKLIST.md).
- Diff > 500 LOC → automatisch zurück mit Bitte zu splitten.
- Im Review: jede Datei außerhalb der „wahrscheinlich betroffen"-Liste
  begründen lassen.

**Owner:** Reviewer.

### R-P2 — PR-Reihenfolge wird gebrochen (W: M / I: H)
**Beobachtung:** PR 5 (Buyout) braucht `sizeTier` aus PR 3.

**Mitigation:**
- PR-Branches voneinander ableiten: PR 5 branched von PR 3, nicht von `main`.
- Oder: Merge-Reihenfolge strikt 1 → 2 → 3 → 4 → 5, jeder PR rebased auf
  vorherigen.

**Owner:** Reviewer + Codex-Briefing.

### R-P3 — Playtest wird übersprungen (W: H / I: H)
**Beobachtung:** Unit-Tests grün → PR wird gemerged ohne UI-Verifikation.

**Mitigation:**
- [PR_REVIEW_CHECKLIST.md](PR_REVIEW_CHECKLIST.md) hat `Manuell:`-Items, die
  vor Merge gehakt sein müssen.
- Mindestens 1 Run pro PR aus [PLAYTEST_SCRIPT_MVP.md](PLAYTEST_SCRIPT_MVP.md).

**Owner:** Reviewer.

---

## 10. Risiko-Übersicht (sortiert nach Priorität)

| ID    | Titel                                            | W | I | Owner         |
|-------|--------------------------------------------------|---|---|---------------|
| R-D1  | Difficulty-Stufen zu ähnlich                     | H | H | PR 1          |
| R-S1  | Ausbau wird No-Brainer                           | H | H | PR 3          |
| R-K3  | Mietfaktor persistent geschrieben                | H | H | PR 4          |
| R-B1  | Buyout-Werte UI vs. Engine                       | H | H | PR 5          |
| R-CI1 | Keine Save-Fixtures in CI                        | H | M | PR 3/4/5      |
| R-T1  | Tutorial zu passiv                               | M | H | PR 2          |
| R-D2  | Impossible-Spirale                               | M | H | PR 1 + Tuning |
| R-S3  | Save-Migration `sizeTier`                        | M | H | PR 3          |
| R-K1  | Anti-Monopol unfair                              | M | H | PR 4          |
| R-M1  | Mehrere Save-Format-Changes parallel             | M | H | Alle          |
| R-P2  | PR-Reihenfolge gebrochen                         | M | H | Reviewer      |
| R-P3  | Playtest übersprungen                            | H | H | Reviewer      |
| R-B2  | 30 % Personal floor → 0                          | H | M | PR 5          |
| R-U1  | Umlaute / Mojibake                               | M | M | Alle UI       |
| R-S2  | Cap-Logik verwirrend                             | M | M | PR 3          |
| R-K2  | Boost global statt stadt-spezifisch              | M | M | PR 4          |
| R-T2  | Tutorial blockt City-Map                         | M | M | PR 2          |
| R-T3  | Veteranen sehen Tutorial erneut                  | M | M | PR 2          |
| R-CI3 | Float-Tests ohne Toleranz                        | H | L | Alle          |
| R-K4  | Toast-Spam                                       | M | L | PR 4          |
| R-B3  | Buyout-Cooldown frustriert                       | L | M | PR 5          |
| R-B4  | Übernahmen zu schwach                            | M | L | PR 5 + Tuning |
| R-U2  | Komma/Punkt-Trennung                             | M | M | PR 2/3        |
| R-D3  | Easy langweilig                                  | M | L | PR 1          |
| R-CI2 | Slow Tests werden geskippt                       | M | M | Reviewer      |
| R-U3  | Lange Labels sprengen UI                         | M | L | PR 3/5        |
| R-B5  | Inventar-Option unklar                           | L | L | PR 5          |
| R-M2  | Save-Versions-Feld fehlt                         | H | M | Post-MVP      |
| R-P1  | Codex „verbessert" mit                           | H | M | Reviewer      |
