# PR_REVIEW_CHECKLIST — Codex-PRs (MVP-Reihe)

Stand: 2026-06-01
Zielgruppe: Reviewer der 5 PRs aus dem aktuellen MVP-Sprint.

PR-Übersicht:
| PR | Titel                              | Tag-Spez                                     |
|----|------------------------------------|----------------------------------------------|
| 1  | Umlaute + Standortauswahl          | UI-Polish, Bug-Fix, Hotspots erweitern       |
| 2  | Buyout gibt Filialen               | M&A-Rebalance, [MVP_NEXT_FIXES.md §4](MVP_NEXT_FIXES.md) |
| 3  | Difficulty-Tuning                  | [MVP_NEXT_FIXES.md §3.3](MVP_NEXT_FIXES.md)  |
| 4  | Tutorial-Führung                   | [MVP_NEXT_FIXES.md §1](MVP_NEXT_FIXES.md)    |
| 5  | Filialausbau / Personal-Cap        | [MVP_NEXT_FIXES.md §2](MVP_NEXT_FIXES.md)    |

> Reihenfolge: PR 1 → 2 → 3 → 4 → 5. PR 1 ist Voraussetzung für saubere
> Playtests (Umlaute), PR 5 hängt vom Save-Format her von keinem anderen ab,
> kann aber parallel zu 3/4 laufen.

**Generelle Regeln für jeden PR (vor dem PR-spezifischen Teil prüfen):**
- [ ] `flutter analyze` ohne Warnungen.
- [ ] `flutter test` grün.
- [ ] Diff < 500 LOC netto, sonst zurück an Codex mit Bitte zu splitten.
- [ ] Keine Änderungen in `pubspec.yaml`, Build-Configs, CI ohne Begründung.
- [ ] Keine Monetarisierungs-Imports/Hooks.
- [ ] Save-Load-Roundtrip funktioniert (alter Save → laden → Tag spielen → speichern).
- [ ] Deutsche UI-Texte: Umlaute korrekt, keine Mojibake (`?` statt `ä`).

---

## PR 1 — Umlaute + Standortauswahl

### Scope

Zwei Themen werden zusammen gemacht, weil beide klein sind und beide die
City-Map-UX betreffen:

1. **Umlaute / Mojibake:** Strings im Repo mit zerschossenem Encoding fixen
   (z. B. `'Kebap KralÄ±'` in
   [competitor_model.dart](../lib/models/competitor_model.dart):156).
2. **Standortauswahl:** Hotspot-Anzahl pro Stadt von 4 auf **6** anheben
   (offen aus [MVP_SCOPE.md](../MVP_SCOPE.md)), Bottom-Sheet-Felder
   konsistent.

### Wahrscheinlich betroffene Dateien

- `lib/models/competitor_model.dart` — `kCompetitorNames` Mojibake.
- `lib/core/constants.dart` — `kLocationTemplates` (heute 4 Templates pro
  Tier, künftig 6).
- `lib/models/city_map_model.dart` — Hotspot-Layout.
- `lib/ui/screens/city_map_screen.dart`, `.../city_map_view.dart` —
  Hotspot-Rendering, Bottom-Sheet.
- `lib/services/location_engine.dart` — Standort-Adapter.
- `lib/core/localization.dart` (falls existent) — Sicherstellen, dass
  Source-Strings UTF-8 sind.
- `test/competitor_model_test.dart`, `test/location_engine_test.dart`.

### Akzeptanzkriterien

- [ ] `grep -P '[ÃÂ][^a-zA-Z]'` über `lib/` liefert **keine** Treffer.
- [ ] Alle Datei-Encodings = UTF-8 ohne BOM (Windows-Standard `CRLF` ist OK).
- [ ] `kLocationTemplates[CityTier.klein]` hat **6** Einträge — die
      neuen 2 sind plausibel (z. B. „Einkaufszentrum", „Universität" oder
      vergleichbare lokale Hotspots). Begründung der Wahl im PR-Body.
- [ ] Analog 6 Templates für `mittel`, `gross`, `metropole`.
- [ ] City-Map zeigt alle 6 Hotspots ohne Überlappung in Default-Auflösung.
- [ ] Bottom-Sheet zeigt **Traffic, Miete, Kaution, Druck, Empfehlung** —
      alle 5 Felder, deutsche Locale (Komma für Dezimaltrenner, `€`-Symbol
      hinten).
- [ ] Bestehende Saves mit 4-Hotspot-Layout bleiben spielbar (City-Map
      regeneriert sich aus Templates, keine harte Save-Migration nötig).

### Tests

- [ ] Unit: `kLocationTemplates.values.every((t) => t.length == 6)`.
- [ ] Unit: Konkurrent-Namen ASCII oder gültiges UTF-8 (kein `Ä±`-Pattern).
- [ ] Widget-Test (optional): Bottom-Sheet rendert Werte für eine Stadt.
- [ ] Manuell: [PLAYTEST_SCRIPT_MVP.md „PR-1-Spot-Checks"](PLAYTEST_SCRIPT_MVP.md).

### Typische Fehler

- ⚠️ Codex fixt nur die offensichtlichen Mojibake-Stellen, übersieht
      String-Konstanten in UI-Widgets.
- ⚠️ Hotspot-Layout wird in `city_map_screen.dart` hardcoded auf 6 Slots,
      aber `kLocationTemplates` hat 4 → Index-Out-of-Range.
- ⚠️ Neue Hotspot-Namen sind generisch („Standort 5"), nicht thematisch.
- ⚠️ Datei wird in falschem Encoding gespeichert (UTF-16 LE durch
      PowerShell-`Out-File` ohne `-Encoding utf8`).
- ⚠️ Bestehende Tests vergleichen Strings, brechen wegen Re-Encoding.

---

## PR 2 — Buyout gibt Filialen

### Scope

Konkurrenz-Aufkauf erzeugt heute „nackte" Filialen
([corporate_engine.dart:259](../lib/services/corporate_engine.dart)).
Rebalance gemäß [MVP_NEXT_FIXES.md §4](MVP_NEXT_FIXES.md): neue Preisformel,
übertragene Werte (Ruf × 0.7, Moral 0.55, regulars 0.0, 30 % Personal),
30-Tage-Cooldown pro Stadt.

### Wahrscheinlich betroffene Dateien

- `lib/services/corporate_engine.dart` — `acquisitionPrice`, `acquireCompetitor`.
- `lib/models/game_state.dart` — `lastAcquisitionDayPerCity` Map.
- `lib/services/save_service.dart` — Migration (Default `{}`).
- `lib/ui/screens/corporate_screen.dart` — Vorher/Nachher-Dialog,
  Inventar-Toggle, Cooldown-Anzeige.
- `test/corporate_engine_test.dart`.

### Akzeptanzkriterien

- [ ] Preis-Formel exakt: `shopCount × 60_000 × repFactor × (1 + marketShare × 1.5)`,
      `repFactor = clamp(rep/3, 0.7, 1.6)`.
- [ ] Übernommene Filialen:
      - `reputation = 0.7 × competitor.reputation`
      - `morale = 0.55`
      - `regulars = 0.0`
      - `sizeTier = klein` (nach PR 5; vor PR 5: Default-Wert)
      - `employees = max(1, floor(0.3 × effectiveCap))`
      - Equipment leer (ohne Inventar-Option)
- [ ] Inventar-Option: `price × 1.3`, +1× `spiess_standard` und
      +1× `kasse_basic` pro Filiale.
- [ ] 30-Tage-Cooldown pro Stadt; andere Städte unberührt; Cooldown
      persistiert über Save/Load.
- [ ] HR-Auffüllung nutzt `HrEngine`-Helper, kein eigener Skill-Roll.
- [ ] UI-Dialog zeigt: Cash-Delta, Filial-Anzahl, Personal, Ruf, Moral —
      **vor** Bestätigung. Preis wird beim Dialog-Open eingefroren (siehe
      [KNOWN_RISKS_NEXT.md R-B1](KNOWN_RISKS_NEXT.md)).
- [ ] `wasAcquired=true`, `originalCompetitorName` korrekt gesetzt — UI
      zeigt „ehemals {Name}".

### Tests

- [ ] Unit: Preis für `shopCount=3, rep=4.0, marketShare=0.30` ≈ 348.000 €,
      Toleranz ±1 %.
- [ ] Unit: Personal-Anzahl `max(1, floor(0.3 × cap))` — auch in Kleinstadt
      nie 0.
- [ ] Unit: Cooldown blockt selbe Stadt, lässt andere Stadt durch.
- [ ] Save-Roundtrip mit gesetztem `lastAcquisitionDayPerCity` ≠ leer.
- [ ] Save-Roundtrip mit altem Save ohne diese Map → Default `{}`.
- [ ] Manuell: [PLAYTEST_SCRIPT_MVP.md §5](PLAYTEST_SCRIPT_MVP.md).

### Typische Fehler

- ⚠️ `repFactor` clamp falsch herum (0.7 als Obergrenze statt 1.6).
- ⚠️ `floor(0.3 × 3) = 0` in Kleinstadt — keine Mitarbeiter beim Buyout.
      Mindestwert 1 vergessen.
- ⚠️ Preis im UI nicht eingefroren — zwischen Klick und Confirm rechnet
      sich `marketShare` neu (siehe R-B1).
- ⚠️ Cooldown global statt pro Stadt.
- ⚠️ Migration vergisst Default `{}` — alter Save crasht beim Laden.
- ⚠️ Ruf wird 1:1 übernommen statt × 0.7 (Buyout ist zu stark, siehe R-B4).

---

## PR 3 — Difficulty-Tuning

### Scope

Multiplikatoren-Werte neu setzen gemäß
[MVP_NEXT_FIXES.md §3.3](MVP_NEXT_FIXES.md). Klein, fokussiert, kein
Engine-Refactor.

### Wahrscheinlich betroffene Dateien

- `lib/models/difficulty_model.dart` — `kDifficultyModifiers` Map.
- `lib/ui/screens/new_game_screen.dart` (oder Difficulty-Selector) —
  sichtbarere Beschreibungstexte je Stufe (Spec §3.6).
- `test/difficulty_model_test.dart` (neu falls fehlend).

### Akzeptanzkriterien

- [ ] Alle 8 Multiplikatoren × 4 Stufen entsprechen Tabelle §3.3.
- [ ] **Keine** anderen Engines wurden „mitgefixt" (kein Refactor in
      `game_engine.dart` / `hr_engine.dart` / `competitor_engine.dart`).
- [ ] Easy ist **strikt verzeihender** als Normal in **jedem** Modifier.
- [ ] Impossible ist **strikt härter** als Hard in **jedem** Modifier.
- [ ] Save-Migration: alter Save mit Schwierigkeit `normal` lädt mit neuen
      Werten ohne Crash; ungültiger String → Fallback `normal`.
- [ ] Difficulty-Selector-Beschreibung enthält 2–3 konkrete Konsequenzen
      pro Stufe (z. B. „Hard: Konkurrenz +40 %, Personal teurer").

### Tests

- [ ] Unit: für jeden Modifier Monotonie easy→normal→hard→impossible
      (`<=` oder `>=`, je nach Richtung).
- [ ] Snapshot-Test der gesamten Map (Regression).
- [ ] Manuell: [BALANCING_PLAYTEST_NOTES.md](BALANCING_PLAYTEST_NOTES.md)
      auf allen 4 Stufen, Tag-1-Gewinn vergleichen.

### Typische Fehler

- ⚠️ Codex „verbessert" UI-Texte und ändert dabei Strings, die in Tests
      verglichen werden.
- ⚠️ Numerische Werte als Strings statt `double` (Locale-Probleme).
- ⚠️ Multiplikator auf `1.0` gelassen, weil Codex „sicherheitshalber"
      Diffs minimiert.
- ⚠️ Beschreibungstexte beziehen sich auf alte (näher an 1.0 liegende)
      Werte und sind nun irreführend.

---

## PR 4 — Tutorial-Führung

### Scope

Coach-Marks + State-basierte Step-Verifier gemäß
[MVP_NEXT_FIXES.md §1](MVP_NEXT_FIXES.md). 5 Pflicht + 5 Optional, Skip ab
Step 5.

### Wahrscheinlich betroffene Dateien

- `lib/models/tutorial_model.dart` — *möglichst nicht*, nur falls neue
  Felder nötig (Skippable-Flag, P/O-Klassifizierung). Bevorzugt ableiten.
- `lib/ui/widgets/tutorial_banner.dart` / `tutorial_coach_mark.dart` (neu).
- `lib/ui/screens/dashboard_screen.dart`, `city_map_screen.dart`,
  `shop_detail/*` — Targets für Highlight-Anchor (`GlobalKey`).
- `lib/providers/game_provider.dart` — Auto-Detection erledigter Steps.

### Akzeptanzkriterien

- [ ] Coach-Marks blockieren **nicht** die ganze Map — Map bleibt schwenkbar,
      nur der CTA-Bereich hat Backdrop.
- [ ] Skip-Button erscheint **erst ab Step 5** (`readDayReport`).
- [ ] Pflicht-Steps 1–5 sind nicht abbrechbar, optional 6–10 dismissable.
- [ ] Verifier sind State-basiert (`shops.length >= 1`, `currentDay >= 1`,
      Preis-Diff zu `basePrice`), nicht Klick-Zähler.
- [ ] Bestehende Texte aus `tutorial_model.dart` werden 1:1 wiederverwendet.
- [ ] Tutorial-State persistiert im Save. **Default für fehlendes Feld in
      altem Save** = `tutorialCompleted = true` (Veteranen kriegen kein
      Tutorial-Reset, siehe R-T3).
- [ ] Soll-Telemetrie: Step 1 ≤ 1:30, Step 3 ≤ 2:30, Step 5 ≤ 3:30 in
      typischen Playtest-Runs.

### Tests

- [ ] Widget-Test: Coach-Mark erscheint bei korrektem Step, verschwindet
      bei State-Match.
- [ ] Unit: Skip setzt alle nachfolgenden Steps auf `completed`.
- [ ] Unit: alter Save ohne Tutorial-Feld → `tutorialCompleted = true`.
- [ ] Manuell: [PLAYTEST_SCRIPT_MVP.md §1](PLAYTEST_SCRIPT_MVP.md).

### Typische Fehler

- ⚠️ Coach-Mark blockiert versehentlich Bottom-Sheet (z-index falsch).
- ⚠️ Highlights zeigen nach Navigation auf falschen Tab.
- ⚠️ Step-Erkennung doppelt: `tutorial_provider` und `game_provider`
      markieren parallel → State-Diskrepanz.
- ⚠️ Veteranen-Save zeigt Tutorial-Banner erneut nach Update.
- ⚠️ Skip-Button erscheint zu früh (vor Step 5) und Spieler skipt Pflicht-Loop.

---

## PR 5 — Filialausbau / Personal-Cap

### Scope

`ShopSizeTier` mit Cap/Kosten/Miete/Moral-Tabelle aus
[MVP_NEXT_FIXES.md §2](MVP_NEXT_FIXES.md). Effective-Cap =
`min(shopSizeCap, cityTierCap)`.

### Wahrscheinlich betroffene Dateien

- `lib/models/shop_model.dart` — `ShopSizeTier`-Enum + Feld + Migration.
- `lib/services/game_engine.dart` — `maxEmployeesForShop`,
  `calculateShopStats` Kapazitäts-Multi.
- `lib/services/save_service.dart` — Migration (Default `klein`).
- `lib/ui/screens/shop_detail/*` — Ausbau-Button + Vorher/Nachher-Dialog.
- `lib/core/constants.dart` — `kShopSizeTiers`-Tabelle.
- `test/shop_model_test.dart`, `test/game_engine_test.dart`.

### Akzeptanzkriterien

- [ ] Default `sizeTier = klein` für alle Shop-Konstruktoren.
- [ ] JSON-Migration: alter Save ohne `sizeTier` → `klein` (Test mit
      Fixture).
- [ ] `maxEmployeesForShop` ist strikt `min(shopCap, cityCap)` — auch in
      Kleinstadt mit `flagship` = Cap 3.
- [ ] Kapazitäts-Multi greift auf `capacity` (NICHT auf `potentialCustomers`).
- [ ] Miet-Multi wird **einmalig** in `weeklyRent` geschrieben (beim
      Ausbau), nicht jeden Tag neu berechnet.
- [ ] Umbau-Tag: 1× Umsatz × 0.3, 1× Ruf −0.1, 1× Moral-Delta gemäß Tabelle.
- [ ] Ausbau-Button disabled bei nicht genug Cash, Tooltip korrekt.
- [ ] In Kleinstadt: `flagship`-Button entweder disabled oder zeigt
      „Cap 3/12" Hint (Codex wählt eine Variante, dokumentiert im PR-Body).
- [ ] Ausbau ist **kein No-Brainer** — Soll-Korridor für ersten Ausbau
      in [BALANCING_PLAYTEST_NOTES.md §2](BALANCING_PLAYTEST_NOTES.md) wird
      eingehalten (Normal: Tag 12–18).

### Tests

- [ ] Unit: `effectiveCap` für jede Kombination shopTier × cityTier (16
      Fälle).
- [ ] Unit: Ausbau-Kosten-Abzug, Miet-Update, Moral-Delta.
- [ ] Save-Roundtrip mit allen 4 Tiers.
- [ ] Save-Roundtrip mit altem Fixture (kein `sizeTier`-Feld) → `klein`.
- [ ] Manuell: [PLAYTEST_SCRIPT_MVP.md §3](PLAYTEST_SCRIPT_MVP.md).

### Typische Fehler

- ⚠️ Kapazitäts-Multi doppelt angewendet (`capacity` und `potentialCustomers`).
- ⚠️ Miete wird beim Ausbau überschrieben statt multipliziert.
- ⚠️ Umbau-Tag wird auf **alle** Filialen angewendet statt nur auf die
      gerade ausgebaute.
- ⚠️ Migration fehlt → alte Saves crashen mit
      `type 'Null' is not a subtype of 'String'`.
- ⚠️ Personal-Cap-Anzeige zeigt `12/12` in Kleinstadt (Stadt-Cap
      ignoriert) — klassischer R-S2-Bug.

---

## Cross-PR-Checks (am Ende, vor Release)

- [ ] Reihenfolge eingehalten: PR 1 vor allem (Umlaute für saubere
      Playtests), dann 2 → 3 → 4 → 5 frei mischbar.
- [ ] [CHANGELOG.md](../CHANGELOG.md) aktualisiert: ein Eintrag pro PR mit
      User-facing-Beschreibung.
- [ ] [README_STATUS.md](../README_STATUS.md) gibt aktuellen MVP-Stand wieder.
- [ ] Alle 5 PRs zusammen: Vollständiger Playtest §1–§5 in
      [PLAYTEST_SCRIPT_MVP.md](PLAYTEST_SCRIPT_MVP.md) ohne P0/P1-Bug.
- [ ] [BALANCING_PLAYTEST_NOTES.md](BALANCING_PLAYTEST_NOTES.md) für
      Easy + Normal mindestens je 3 Runs, Hard + Impossible je 1 Run.
- [ ] [KNOWN_RISKS_NEXT.md](KNOWN_RISKS_NEXT.md): alle H/H-Risiken adressiert
      oder bewusst akzeptiert.

> **Hinweis zum Risiko-Register:** [KNOWN_RISKS_NEXT.md](KNOWN_RISKS_NEXT.md)
> wurde auf dem alten PR-Mapping geschrieben (PR 1=Difficulty etc.). Die
> Risiken selbst sind weiterhin gültig, nur die PR-Owner-Zuordnung muss
> mental remapped werden:
> - Alte PR 1 (Difficulty) ↔ neue PR 3
> - Alte PR 2 (Tutorial) ↔ neue PR 4
> - Alte PR 3 (ShopSize) ↔ neue PR 5
> - Alte PR 4 (Konkurrenz) ↔ Post-MVP (siehe [NEXT_FEATURE_BACKLOG.md](NEXT_FEATURE_BACKLOG.md))
> - Alte PR 5 (Buyout) ↔ neue PR 2
> Wird beim nächsten Touch auf KNOWN_RISKS_NEXT.md aktualisiert.
