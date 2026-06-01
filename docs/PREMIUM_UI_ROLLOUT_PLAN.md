# PREMIUM_UI_ROLLOUT_PLAN — Schrittweiser UI-Premium-Rollout

Stand: 2026-06-01
Zweck: Aus [PREMIUM_UI_AUDIT.md](PREMIUM_UI_AUDIT.md) konkrete, kleine PRs
ableiten, die Codex screenweise abarbeiten kann.

Out-of-Scope für alle PRs:
- Keine Spiel-/Engine-Logik anfassen.
- Keine neuen Packages.
- Keine Änderungen an `theme.dart`, `premium_mobile_ui.dart` (außer der
  *möglichen* PR-C-Erweiterung, siehe dort).
- Keine Monetarisierung.
- Keine Refactors, die nicht für den Premium-Look nötig sind.

Allgemeine Regel: **Diff < 600 LOC pro PR**, sonst splitten.

Designregeln: [PREMIUM_UI_RULES.md](PREMIUM_UI_RULES.md).

---

## PR A — MVP-Kernfluss (Tutorial-Pfad)

**Ziel:** Die ersten 10 Minuten Spielzeit sollen sich konsistent premium
anfühlen. Alles, was im Playtest-Script
[PLAYTEST_SCRIPT_MVP.md](PLAYTEST_SCRIPT_MVP.md) §0–§3 berührt wird.

### Betroffene Dateien

- `lib/ui/screens/new_game_screen.dart` — 🔴→🟢
- `lib/ui/screens/dashboard_screen.dart` — 🟡→🟢 (nur KPI-Reihe + Sections,
  Cash-Card bleibt eigen)
- `lib/ui/screens/shop_detail/products_tab.dart` — 🔴→🟢
- `lib/ui/screens/shop_detail/employees_tab.dart` — 🟡→🟢 (nur
  Kandidaten-Card; Hire-Logik unverändert)
- `lib/ui/screens/splash_screen.dart` — 🟡→🟢 (nur Tap-Hint)

### Konkrete Änderungen

| Datei                              | Änderung                                                                                |
|------------------------------------|-----------------------------------------------------------------------------------------|
| `new_game_screen.dart`             | Difficulty-Karten → `PremiumDecisionSheet` + `PremiumStatusHint` mit 2–3 Konsequenzen. Startkapital → `PremiumMetricStrip`. |
| `dashboard_screen.dart`            | KPI-Reihe (Kunden, Profit, Auslastung) → `PremiumMetricStrip(dense:true)`. Section-Header → `PremiumSectionLabel`. Quick-Action-Liste → `PremiumDecisionSheet`. Cash-Card NICHT anfassen. |
| `shop_detail/products_tab.dart`    | Pro Produkt: `PremiumDecisionSheet` mit Slider, darunter `PremiumMetricStrip(Preis/Marge/Index)`. Negativ-Marge → `PremiumStatusHint(danger)`. |
| `shop_detail/employees_tab.dart`   | Kandidaten-Card → `PremiumDecisionSheet`. Skill-Werte als 3-Spalt-`PremiumMetricStrip`. Lohn als `PremiumInlineMetric`. Hire-Button bleibt. |
| `splash_screen.dart`               | Tap-Hint als `PremiumStatusHint(success)`.                                              |

### Akzeptanzkriterien

- [ ] [PLAYTEST_SCRIPT_MVP.md §0–§3](PLAYTEST_SCRIPT_MVP.md) komplett
      durchläuft, ohne dass eine Stelle „Stock-Material" aussieht.
- [ ] `flutter analyze` und `flutter test` grün.
- [ ] Diff in `lib/services/`, `lib/models/`, `lib/providers/` = **0**.
- [ ] Cash-Card auf Dashboard ist visuell unverändert.
- [ ] Difficulty-Auswahl zeigt 2–3 konkrete Konsequenzen pro Stufe (passt
      zu [MVP_NEXT_FIXES.md §3.6](MVP_NEXT_FIXES.md)).
- [ ] Skill-Werte in `employees_tab` zeigen drei Metriken im KPI-Strip:
      `Quality`, `Speed`, `Lohn/Tag`.
- [ ] Produkt-Marge < 0 zeigt `PremiumStatusHint(danger)` „Verlustmarge".

### Was ausdrücklich NICHT geändert werden darf

- ❌ `lib/services/*` — keine Engine-Änderung.
- ❌ `lib/providers/game_provider.dart` — kein State-Refactor.
- ❌ `lib/core/theme.dart` — Farben/Typografie bleiben.
- ❌ `premium_mobile_ui.dart` — keine neue Komponente in dieser PR.
- ❌ City-Map / Open-Shop / Shop-Detail-Rahmen — bereits 🟢.
- ❌ Tutorial-Logik — gehört zu PR 4 (Tutorial-Führung) in
      [PR_REVIEW_CHECKLIST.md](PR_REVIEW_CHECKLIST.md).

---

## PR B — Management-Screens (Imperium + Reports)

**Ziel:** Die wichtigsten Mid-/Late-Game-Screens auf Premium-Niveau heben.

### Betroffene Dateien

- `lib/ui/screens/corporate_screen.dart` — 🟡→🟢 (sektionsweise; falls > 600 LOC
  Diff: in PR B1 = M&A-Sektion + PR B2 = Rest splitten)
- `lib/ui/screens/finance_screen.dart` — 🟡→🟢 (KPI-Köpfe, Charts bleiben)
- `lib/ui/screens/stats_screen.dart` — 🟡→🟢 (Konkurrenz-Cards)
- `lib/ui/screens/bank_screen.dart` — 🔴→🟢
- `lib/ui/screens/campaign_screen.dart` — 🔴→🟢

### Konkrete Änderungen

| Datei                  | Änderung                                                                                       |
|------------------------|------------------------------------------------------------------------------------------------|
| `corporate_screen.dart`| M&A-Karten → `PremiumDecisionSheet` mit `PremiumMetricStrip(Filialen/Ruf/Marktanteil)`. KPI-Bereiche oben → `PremiumMetricStrip`. HR-Auto-Hire-Block bleibt funktional, nur Optik. |
| `finance_screen.dart`  | Top-Zusammenfassung (Cash, Schulden, Cashflow) → `PremiumMetricStrip`. Charts bleiben unangetastet. Sektion-Header → `PremiumSectionLabel`. |
| `stats_screen.dart`    | Konkurrenz-Card → `PremiumDecisionSheet`. „Expandiert / schrumpft" → `PremiumStatusHint`. |
| `bank_screen.dart`     | Kredit-Option → `PremiumDecisionSheet`. KPIs (Zins, Laufzeit, Rate) → `PremiumMetricStrip`. Aktiver Kredit → `PremiumStatusHint(warning)`. |
| `campaign_screen.dart` | Kampagnen-Karte → `PremiumDecisionSheet`. Risiko-Level (low/medium/high) → `PremiumStatusHint(success/warning/danger)`. Aktive Kampagnen → eigene Sektion mit `PremiumSectionLabel("AKTIV")`. |

### Akzeptanzkriterien

- [ ] Jeder dieser 5 Screens scrollt sich konsistent zu City-Map / Open-Shop.
- [ ] `flutter analyze`, `flutter test` grün.
- [ ] Charts in `finance_screen` rendern unverändert (Pixel-Vergleich
      Stichprobe).
- [ ] Kein neuer State, keine neuen Provider, keine Engine-Änderung.
- [ ] In `corporate_screen` muss der M&A-Flow weiterhin den 30-Tage-Cooldown
      respektieren (PR 2 in PR_REVIEW_CHECKLIST).
- [ ] In `campaign_screen` ist die Risiko-Farbe konsistent mit
      `MarketingRisk`-Enum.

### Was ausdrücklich NICHT geändert werden darf

- ❌ Finance-Chart-Berechnungen / Datenpipelines.
- ❌ HR-Engine, Corporate-Engine, Bank-Engine.
- ❌ `MarketingCampaign`-Datenmodell.
- ❌ Schon-🟢-Screens aus dem Audit.

---

## PR C — Dialoge, Reports und Polish

**Ziel:** Alle modalen Stellen + Inkonsistenzen zwischen Dialogen aufräumen.
Hier ist auch die einzige PR, in der `premium_mobile_ui.dart` **erweitert**
werden darf (siehe Akzeptanz).

### Betroffene Dateien

- `lib/ui/widgets/bankruptcy_dialog.dart` — 🔴→🟢
- `lib/ui/widgets/mission_banner.dart` — 🔴→🟢
- `lib/ui/widgets/weekly_report_dialog.dart` — 🟡→🟢 (Konsistenz mit Day-End)
- `lib/ui/tutorial_navigation.dart` — Koordination mit PR 4
- (optional) `lib/ui/widgets/premium_mobile_ui.dart` — neue Komponenten,
  siehe „Komponenten-Lücken" in [PREMIUM_UI_RULES.md](PREMIUM_UI_RULES.md).

### Konkrete Änderungen

| Datei                         | Änderung                                                                                   |
|-------------------------------|--------------------------------------------------------------------------------------------|
| `bankruptcy_dialog.dart`      | Statistiken-Block → `PremiumMetricStrip`. Lessons-Learned-Block → `PremiumStatusHint(warning)`. Roter Border auf umschließendem `PremiumDecisionSheet`. |
| `mission_banner.dart`         | Banner-Innenleben → kompakter `PremiumDecisionSheet`. Status-Pill → `PremiumStatusHint`. |
| `weekly_report_dialog.dart`   | Konsistenz mit `day_end_dialog`: gleiche Sektion-Header, gleiche KPI-Strip-Höhe. |
| `tutorial_navigation.dart`    | Koordination mit PR 4: Coach-Marks nutzen `PremiumDecisionSheet` + `PremiumStatusHint`. Falls PR 4 vor PR C: nur Review. Falls PR C zuerst: Stub-Widget vorbereiten. |
| `premium_mobile_ui.dart` (opt)| **Falls nötig:** `PremiumPrimaryButton` und `PremiumEmptyState` ergänzen. Strikt isoliert, Tests + Story-Like-Demo. |

### Akzeptanzkriterien

- [ ] Bankruptcy- und Erfolgs-Dialoge haben das **gleiche** Sektion-Header-
      und KPI-Strip-Pattern, nur unterschiedliche Akzentfarben.
- [ ] Mission-Banner überlagert City-Map / Dashboard ohne sichtbaren Bruch.
- [ ] `weekly_report_dialog` und `day_end_dialog` haben identische Sektion-
      Spacing-Werte (siehe [PREMIUM_UI_RULES.md](PREMIUM_UI_RULES.md) §1).
- [ ] Wenn `premium_mobile_ui.dart` erweitert wird: neue Komponenten haben
      Doc-Kommentar mit Verwendungszweck und mindestens 1 Beispiel im
      gleichen PR (zB konkrete Einbindung in einem Dialog).
- [ ] `flutter analyze`, `flutter test` grün.

### Was ausdrücklich NICHT geändert werden darf

- ❌ Insolvenz-Trigger, Mission-Mechanik, Reporting-Berechnung.
- ❌ Tutorial-Flow-Logik (gehört zu PR 4).

---

## PR D — Restliche UI-Brüche (Long-Tail)

**Ziel:** Alle übrigen 🔴-Screens, die nicht im Kern-Loop sind. Niedrigste
Priorität, kann aufgeschoben werden.

### Betroffene Dateien

- `lib/ui/screens/achievements_screen.dart` — 🔴→🟢
- `lib/ui/screens/branding_screen.dart` — 🔴→🟢
- `lib/ui/screens/menu_screen.dart` — 🔴→🟢
- `lib/ui/screens/empire_card_screen.dart` — 🔴→🟢
- `lib/ui/screens/shop_detail/equipment_tab.dart` — 🔴→🟢
- `lib/ui/screens/shop_detail/upgrades_tab.dart` — 🔴→🟢
- `lib/ui/screens/shop_detail/marketing_tab.dart` — 🔴→🟢

### Konkrete Änderungen

Pro Datei dasselbe Muster:
1. Karten/Einträge → `PremiumDecisionSheet`.
2. Numerische Reihen → `PremiumMetricStrip` (max 4 Einträge).
3. Sektion-Header → `PremiumSectionLabel`.
4. Status („Aktiv", „Freigeschaltet", „Gesperrt") → `PremiumStatusHint`.

| Datei                              | Besonderheit                                                                |
|------------------------------------|-----------------------------------------------------------------------------|
| `achievements_screen.dart`         | Progress-Bar bleibt eigen (kein Premium-Equivalent). Freigeschaltete → `PremiumStatusHint(success)`. |
| `empire_card_screen.dart`          | Goldener Border auf `PremiumDecisionSheet` (Trophy-Moment).                 |
| `equipment_tab.dart`               | Boost-Werte (`qualityBonus`, `capacityBonus`, ...) als `PremiumMetricStrip`. |
| `upgrades_tab.dart`                | „Vorher/Nachher"-Werte als zwei `PremiumMetricStrip` untereinander.         |
| `marketing_tab.dart`               | Identisches Pattern wie `campaign_screen` aus PR B — Code wiederverwenden. |

### Akzeptanzkriterien

- [ ] Keine 🔴-Screens mehr im Audit nach diesem PR (Audit-Doc aktualisieren).
- [ ] `flutter analyze`, `flutter test` grün.
- [ ] Diff < 600 LOC netto pro Datei, sonst PR D splitten in D1/D2.

### Was ausdrücklich NICHT geändert werden darf

- ❌ Achievement-Trigger-Logik.
- ❌ Equipment-/Upgrade-Daten.
- ❌ Bestehende 🟢-Screens.

---

## Reihenfolge & Abhängigkeiten

```
  PR 1 (Umlaute + Standortauswahl)  ┐
  PR 2 (Buyout)                     │  MVP-Funktionsreihe
  PR 3 (Difficulty)                 │  → siehe PR_REVIEW_CHECKLIST.md
  PR 4 (Tutorial)                   │
  PR 5 (Filialausbau)               ┘

  PR A (UI Kernfluss)               ── nach PR 4 (Tutorial-UI berührt PR A)
  PR B (UI Management)              ── nach PR 2 (Buyout-UI in PR B)
  PR C (UI Dialoge/Polish)          ── parallel zu B möglich
  PR D (UI Long-Tail)               ── ganz am Ende, optional
```

**Empfohlene Merge-Reihenfolge:**
PR 1 → PR 3 → PR 5 → PR 2 → PR 4 → **PR A** → **PR B** → **PR C** → PR D.

PR A nach PR 4, damit Tutorial-Coach-Marks im neuen Look entstehen.
PR B nach PR 2, damit M&A-UI auf der neuen Buyout-Logik aufbaut.

---

## Gemeinsame Definition of Done (für jede PR)

- [ ] Audit-Tabelle in [PREMIUM_UI_AUDIT.md](PREMIUM_UI_AUDIT.md) §4
      aktualisiert (Status hochziehen).
- [ ] [CHANGELOG.md](../CHANGELOG.md) Eintrag „UI: {Screen} auf Premium".
- [ ] Screenshot-Vergleich vorher/nachher im PR-Body (mobile + Desktop).
- [ ] `flutter analyze` clean, `flutter test` grün.
- [ ] Manueller Playtest §0–§5 aus [PLAYTEST_SCRIPT_MVP.md](PLAYTEST_SCRIPT_MVP.md)
      ohne neuen P1/P2-Bug.
- [ ] Diff in `lib/services/`, `lib/models/`, `lib/providers/` = **0**
      (Hard-Regel, verletzt = zurück an Codex).
