# PREMIUM_UI_AUDIT — Screen-für-Screen-Bestandsaufnahme

Stand: 2026-06-01
Zweck: Klares Bild, **wo** Premium-Komponenten greifen und **wo** noch das alte
Material-Stock-Layout sichtbar ist. Grundlage für den Rollout-Plan
([PREMIUM_UI_ROLLOUT_PLAN.md](PREMIUM_UI_ROLLOUT_PLAN.md)).

Methodik:
- Premium-Komponenten gezählt aus
  [lib/ui/widgets/premium_mobile_ui.dart](../lib/ui/widgets/premium_mobile_ui.dart):
  `PremiumMetricStrip`, `PremiumDecisionSheet`, `PremiumSectionLabel`,
  `PremiumDecisionLine`, `PremiumInlineMetric`, `PremiumStatusHint`.
- „Raw Container-Count" = `Card(` + `ListTile(` + `Container(` Treffer im File
  als Indikator für nicht-premium-gekleidete Bausteine.

Status-Skala:
- **🟢 Premium-Ready** — Premium-Komponenten dominieren, Layout ruhig,
  Spacing konsistent.
- **🟡 Teilweise** — Premium-Komponenten teilweise eingebaut, aber alte
  `Card`/`Container`-Stellen brechen visuell durch.
- **🔴 Alt** — Keine Premium-Nutzung, Stock-Material-Look.

---

## 1. MVP-Kernfluss (Pflicht-Screens für die ersten 10 Min)

### 1.1 [splash_screen.dart](../lib/ui/screens/splash_screen.dart) — 🟡 Teilweise
- **Premium:** 0 Premium-Komponenten, aber sehr klein (192 Zeilen) und nutzt
  AppGradients/AppColors korrekt.
- **Brüche:** Stock-`Image.asset` ohne Premium-Card-Frame, Tap-Hint als
  einfaches `Text` — könnte als `PremiumStatusHint` warm wirken.
- **Wichtigste Verbesserung:** Tap-Hint mit `PremiumStatusHint` ersetzen,
  sonst lassen.
- **Risiko:** Klein, das ist der Marken-Erstkontakt — Inkonsistenz hier wirkt
  besonders billig.

### 1.2 [new_game_screen.dart](../lib/ui/screens/new_game_screen.dart) — 🔴 Alt
- **Premium:** 0. Nutzt Stock-`TextField`, Stock-`Card` für Difficulty-Auswahl,
  Stock-`ListTile`.
- **Brüche:** 6 raw Container, Difficulty-Karten haben kein
  `PremiumDecisionSheet`-Feeling, Startkapital wird ohne KPI-Strip dargestellt.
- **Wichtigste Verbesserung:** Difficulty-Auswahl als `PremiumDecisionSheet`
  + `PremiumStatusHint` mit 2–3 konkreten Konsequenzen je Stufe (passt zu
  [MVP_NEXT_FIXES.md §3.6](MVP_NEXT_FIXES.md)).
- **Risiko:** Save-Format hängt teils an dieser Screen — UI-Refactor darf
  `GameState`-Initialisierung nicht touchen.

### 1.3 [dashboard_screen.dart](../lib/ui/screens/dashboard_screen.dart) — 🟡 Teilweise
- **Premium:** Nur **1** Premium-Komponente in 1531 Zeilen. Trotz Hauptscreen.
- **Brüche:** 40 raw Container, eigene Cash-Card, eigene KPI-Boxen, eigene
  Section-Headers — alles vor-Premium implementiert.
- **Wichtigste Verbesserung:** KPI-Reihen (Kunden, Profit, Auslastung) auf
  `PremiumMetricStrip` umstellen. Cash-Card bleibt eigen (Marken-Element),
  aber Sektionen darunter mit `PremiumSectionLabel` + `PremiumDecisionSheet`
  vereinheitlichen.
- **Risiko:** Größter Bildschirm der App, viele Subsysteme (Mission-Banner,
  Day-End-CTA, Schnellzugriffe). Schrittweise nötig.

### 1.4 [city_map_screen.dart](../lib/ui/screens/city_map_screen.dart) — 🟢 Premium-Ready
- **Premium:** 16 Premium-Komponenten in 527 Zeilen. Hotspot-Sheet ist
  konsequent als `PremiumDecisionSheet` umgesetzt.
- **Brüche:** Wenig sichtbar — nur das City-Map-Canvas selbst
  ([city_map_view.dart](../lib/ui/widgets/city_map_view.dart)) ist eigener Code,
  aber das ist gewollt (es ist *die* visuelle Bühne).
- **Wichtigste Verbesserung:** Bei Erweiterung auf 6 Hotspots (PR 1)
  Konsistenz prüfen — Risiko, dass neue Hotspots ohne Premium-Sheet
  hinzugefügt werden.
- **Risiko:** Niedrig, vorbildhaft.

### 1.5 [open_shop_screen.dart](../lib/ui/screens/open_shop_screen.dart) — 🟢 Premium-Ready
- **Premium:** 16 Komponenten in 600 Zeilen, dichteste Premium-Nutzung im
  ganzen Projekt.
- **Brüche:** Minimal. Nur 2 raw Container.
- **Wichtigste Verbesserung:** Bei „Mit Inventar"-Toggle in PR 2 (Buyout)
  hier als Referenz nutzen.
- **Risiko:** Niedrig, Goldstandard.

### 1.6 [shop_detail_screen.dart](../lib/ui/screens/shop_detail_screen.dart) — 🟢 Premium-Ready
- **Premium:** 4 in 248 Zeilen, der Rahmen ist Premium.
- **Brüche:** Sind in den Tab-Files (siehe §2).
- **Wichtigste Verbesserung:** Keine am Rahmen.
- **Risiko:** Niedrig — Risiko wandert in die Tabs.

### 1.7 [shop_detail/employees_tab.dart](../lib/ui/screens/shop_detail/employees_tab.dart) — 🟡 Teilweise
- **Premium:** 4 in 1142 Zeilen + nutzt
  [shared_widgets.dart](../lib/ui/screens/shop_detail/shared_widgets.dart) (20 Premium).
- **Brüche:** 24 raw Container, eigene Kandidaten-Karten, eigene
  Skill-Balken.
- **Wichtigste Verbesserung:** Kandidaten-Card auf `PremiumDecisionSheet` +
  Skill-Werte als `PremiumMetricStrip` mit 3 Metriken (Quality, Speed, Lohn).
- **Risiko:** Größter Shop-Detail-Tab. Refactor in 1 PR machbar, aber
  testintensiv (Hire/Fire-Flows).

### 1.8 [shop_detail/products_tab.dart](../lib/ui/screens/shop_detail/products_tab.dart) — 🔴 Alt
- **Premium:** **1** in 423 Zeilen. Praktisch kein Premium-Look.
- **Brüche:** 7 raw Container, Preisslider in Stock-Optik, Marge wird ohne
  Hint-Box angezeigt.
- **Wichtigste Verbesserung:** Pro Produkt: `PremiumDecisionSheet` mit
  Preis-Slider + `PremiumMetricStrip` (Preis, Marge, Index-Vergleich) +
  `PremiumStatusHint` wenn Marge negativ.
- **Risiko:** Tutorial-Step 3 läuft hier durch — UI-Bruch hier killt das
  Onboarding-Gefühl direkt.

### 1.9 [shop_detail/equipment_tab.dart](../lib/ui/screens/shop_detail/equipment_tab.dart) — 🔴 Alt
- **Premium:** 0 in 165 Zeilen.
- **Brüche:** Stock-`ListTile`-Liste, keine KPI-Strips.
- **Wichtigste Verbesserung:** Equipment-Eintrag als `PremiumDecisionSheet`
  mit Boost-Werten als `PremiumInlineMetric`-Reihe.
- **Risiko:** Klein, isoliert.

### 1.10 [shop_detail/upgrades_tab.dart](../lib/ui/screens/shop_detail/upgrades_tab.dart) — 🔴 Alt
- **Premium:** 0 in 321 Zeilen.
- **Brüche:** 7 raw Container, eigene Upgrade-Karten.
- **Wichtigste Verbesserung:** Upgrade-Karte als `PremiumDecisionSheet` mit
  „Vorher/Nachher"-Werten via `PremiumMetricStrip`.
- **Risiko:** Klein.

### 1.11 [shop_detail/marketing_tab.dart](../lib/ui/screens/shop_detail/marketing_tab.dart) — 🔴 Alt
- **Premium:** 0 in 304 Zeilen.
- **Brüche:** 8 raw Container, Kampagnen-Karten in Stock-Optik.
- **Wichtigste Verbesserung:** Kampagnen-Karte als `PremiumDecisionSheet`,
  Risiko-Level als `PremiumStatusHint` (success/warning/danger via
  `MarketingRisk`).
- **Risiko:** Klein, aber sichtbar — Marketing ist sehr früh im Spielfluss.

### 1.12 [day_end_dialog.dart](../lib/ui/widgets/day_end_dialog.dart) — 🟢 Premium-Ready
- **Premium:** 15 in 709 Zeilen, am intensivsten genutzte Premium-Klasse.
- **Brüche:** 10 raw Container, aber meist für Layout-Spacing (nicht für
  Inhalt).
- **Wichtigste Verbesserung:** Bei „Tagesbericht v2" (Backlog §2.4) als
  Goldstandard erhalten.
- **Risiko:** Niedrig.

---

## 2. Management-Screens (Imperium-Tab + Reports)

### 2.1 [corporate_screen.dart](../lib/ui/screens/corporate_screen.dart) — 🟡 Teilweise
- **Premium:** 7 in **2561** Zeilen (mit Abstand größter Screen).
- **Brüche:** 41 raw Container — der Riesen-Screen ist eine Mischung aus
  Premium-Headern und alten Sub-Listen (HR, M&A, Manager-Liste, KPIs).
- **Wichtigste Verbesserung:** Jeden Tab-Block sektionsweise refactoren:
  M&A-Karten als `PremiumDecisionSheet`, KPI-Bereiche als
  `PremiumMetricStrip`. Ein-PR-Lösung ist nicht realistisch — auf 2 PRs
  splitten (M&A + Rest).
- **Risiko:** **Hoch.** Datei ist groß, viele Sub-Flows (Buyout, Auto-Hire,
  Manager, Aktien). Refactor-Reihenfolge muss Buyout-PR (PR 2 in
  PR_REVIEW_CHECKLIST) respektieren.

### 2.2 [finance_screen.dart](../lib/ui/screens/finance_screen.dart) — 🟡 Teilweise
- **Premium:** 8 in 1362 Zeilen.
- **Brüche:** 27 raw Container, Charts/Tabellen oft selbstgebaut.
- **Wichtigste Verbesserung:** Zusammenfassungs-KPIs (Cash, Schulden,
  Cashflow) auf `PremiumMetricStrip`. Detail-Tabellen bleiben (Charts sind
  legitim eigen).
- **Risiko:** Mittel — Finanzen ist Zahlenheavy, Fehler in der Darstellung
  fallen sofort auf.

### 2.3 [stats_screen.dart](../lib/ui/screens/stats_screen.dart) — 🟡 Teilweise
- **Premium:** 16 in 1130 Zeilen, gute Adoption.
- **Brüche:** 26 raw Container, eigene Konkurrenz-Cards.
- **Wichtigste Verbesserung:** Konkurrenz-Card auf `PremiumDecisionSheet` mit
  `PremiumStatusHint` für „expandiert / schrumpft".
- **Risiko:** Klein.

### 2.4 [cities_screen.dart](../lib/ui/screens/cities_screen.dart) — 🟢 Premium-Ready
- **Premium:** 31 in 737 Zeilen, höchste Dichte aller Screens.
- **Brüche:** 5 raw Container, alle vermutlich für Layout-Spacing.
- **Wichtigste Verbesserung:** Keine größere.
- **Risiko:** Niedrig.

### 2.5 [bank_screen.dart](../lib/ui/screens/bank_screen.dart) — 🔴 Alt
- **Premium:** 0 in 561 Zeilen.
- **Brüche:** 9 raw Container, Kredit-Optionen als Stock-Cards.
- **Wichtigste Verbesserung:** Kredit-Option als `PremiumDecisionSheet` mit
  KPI-Strip (Zinssatz, Laufzeit, Monatsrate), aktiver Kredit als
  `PremiumStatusHint`.
- **Risiko:** Mittel — Bank-Logik ist sensibel (Zinsrechnung, Rückzahlung).

### 2.6 [achievements_screen.dart](../lib/ui/screens/achievements_screen.dart) — 🔴 Alt
- **Premium:** 0 in 291 Zeilen.
- **Brüche:** 4 raw Container, eigene Achievement-Cards.
- **Wichtigste Verbesserung:** Achievement-Eintrag als
  `PremiumDecisionSheet` mit Progress-Bar; freigeschaltete als
  `PremiumStatusHint(success)`.
- **Risiko:** Niedrig, isoliert.

### 2.7 [campaign_screen.dart](../lib/ui/screens/campaign_screen.dart) — 🔴 Alt
- **Premium:** 0 in 678 Zeilen.
- **Brüche:** 14 raw Container — höchster raw-Count ohne jede Premium-Nutzung.
- **Wichtigste Verbesserung:** Marketing-Kampagnen-Karten als
  `PremiumDecisionSheet` + Risiko-Hint. Aktive Kampagnen-Sektion mit
  `PremiumSectionLabel`.
- **Risiko:** Niedrig, isoliert. Größter Effekt-pro-Aufwand-Hebel.

### 2.8 [branding_screen.dart](../lib/ui/screens/branding_screen.dart) — 🔴 Alt
- **Premium:** 0 in 179 Zeilen.
- **Brüche:** 5 raw Container.
- **Wichtigste Verbesserung:** Markenauswahl als `PremiumDecisionSheet`-Grid.
- **Risiko:** Niedrig, kosmetisch.

### 2.9 [menu_screen.dart](../lib/ui/screens/menu_screen.dart) — 🔴 Alt
- **Premium:** 0 in 287 Zeilen.
- **Brüche:** 3 raw Container.
- **Wichtigste Verbesserung:** Sektion-Header als `PremiumSectionLabel`,
  Save-Slot-Karten als `PremiumDecisionSheet`.
- **Risiko:** Niedrig.

### 2.10 [empire_card_screen.dart](../lib/ui/screens/empire_card_screen.dart) — 🔴 Alt
- **Premium:** 0 in 243 Zeilen.
- **Brüche:** 1 raw Container — sehr klein.
- **Wichtigste Verbesserung:** Empire-Card-Werte als `PremiumMetricStrip`,
  Hintergrund als `PremiumDecisionSheet` mit goldenem Border.
- **Risiko:** Niedrig, aber dieser Screen ist „Trophy-Moment" — Premium-Look
  zahlt extra ein.

### 2.11 [settings_screen.dart](../lib/ui/screens/settings_screen.dart) — 🟢 Premium-Ready
- **Premium:** 14 in 167 Zeilen, hohe Dichte für kleinen Screen.
- **Brüche:** 3 raw Container, vermutlich Spacing.
- **Wichtigste Verbesserung:** Keine.
- **Risiko:** Niedrig.

---

## 3. Reports & Dialoge

### 3.1 [day_end_dialog.dart](../lib/ui/widgets/day_end_dialog.dart)
Siehe §1.12 — 🟢 Premium-Ready.

### 3.2 [weekly_report_dialog.dart](../lib/ui/widgets/weekly_report_dialog.dart) — 🟡 Teilweise
- **Premium:** 8 in 163 Zeilen, Rahmen ist Premium.
- **Brüche:** 1 raw Container — sehr wenig.
- **Wichtigste Verbesserung:** Konsistenz mit `day_end_dialog` prüfen, gleiche
  Sektion-Header und KPI-Strip-Pattern.
- **Risiko:** Niedrig.

### 3.3 [quarterly_report_dialog.dart](../lib/ui/widgets/quarterly_report_dialog.dart) — 🟢 Premium-Ready
- **Premium:** 7 in 152 Zeilen.
- **Brüche:** 1 raw Container.
- **Wichtigste Verbesserung:** Keine.
- **Risiko:** Niedrig.

### 3.4 [bankruptcy_dialog.dart](../lib/ui/widgets/bankruptcy_dialog.dart) — 🔴 Alt
- **Premium:** 0 in 234 Zeilen.
- **Brüche:** 2 raw Container, eigene Fail-State-Visualisierung.
- **Wichtigste Verbesserung:** Insolvenz-Statistiken als
  `PremiumMetricStrip`, Sektion „Was du gelernt hast" mit
  `PremiumStatusHint(warning)`. Wichtig: visuell **deutlich anders** als
  Erfolgs-Dialoge bleiben (rot-betont).
- **Risiko:** Niedrig — bisher sehen Bankrott-Screens „billig" aus, ein
  Premium-Polish hier hebt Drama.

### 3.5 [mission_banner.dart](../lib/ui/widgets/mission_banner.dart) — 🔴 Alt
- **Premium:** 0 in 316 Zeilen.
- **Brüche:** 8 raw Container, eigene Banner-Optik.
- **Wichtigste Verbesserung:** Banner als kompakter `PremiumDecisionSheet`
  mit `PremiumStatusHint` für Mission-Status (offen/aktiv/erledigt).
- **Risiko:** Mittel — Mission-Banner überlagert andere Screens, Premium-Look
  hier zahlt überall ein.

### 3.6 [tutorial_navigation.dart](../lib/ui/tutorial_navigation.dart) — 🟡 Teilweise (work-in-progress)
- **Premium:** unbekannt (Datei ist Codex-WIP, nicht gemerged).
- **Brüche:** entsteht parallel zur PR 4 (Tutorial-Führung).
- **Wichtigste Verbesserung:** Coach-Marks müssen als `PremiumDecisionSheet`
  mit Backdrop + `PremiumStatusHint` für „Aufgabe / Warum / Tipp"
  umgesetzt sein.
- **Risiko:** Mittel — wenn Tutorial mit eigener UI-Sprache entsteht, fühlt
  sich Onboarding fremd an.

---

## 4. Heatmap (Bilanz)

| Screen / Widget                | LOC  | Premium | Raw  | Status         |
|--------------------------------|------|---------|------|----------------|
| splash_screen                  | 192  | 0       | 2    | 🟡 Teilweise   |
| new_game_screen                | 476  | 0       | 6    | 🔴 Alt         |
| dashboard_screen               | 1531 | 1       | 40   | 🟡 Teilweise   |
| city_map_screen                | 527  | 16      | 5    | 🟢 Premium     |
| open_shop_screen               | 600  | 16      | 2    | 🟢 Premium     |
| shop_detail_screen             | 248  | 4       | 3    | 🟢 Premium     |
| shop_detail/employees_tab      | 1142 | 4 (+20) | 24   | 🟡 Teilweise   |
| shop_detail/products_tab       | 423  | 1       | 7    | 🔴 Alt         |
| shop_detail/equipment_tab      | 165  | 0       | 4    | 🔴 Alt         |
| shop_detail/upgrades_tab       | 321  | 0       | 7    | 🔴 Alt         |
| shop_detail/marketing_tab      | 304  | 0       | 8    | 🔴 Alt         |
| shop_detail/shared_widgets     | 230  | 20      | 1    | 🟢 Premium     |
| corporate_screen               | 2561 | 7       | 41   | 🟡 Teilweise   |
| finance_screen                 | 1362 | 8       | 27   | 🟡 Teilweise   |
| stats_screen                   | 1130 | 16      | 26   | 🟡 Teilweise   |
| cities_screen                  | 737  | 31      | 5    | 🟢 Premium     |
| bank_screen                    | 561  | 0       | 9    | 🔴 Alt         |
| achievements_screen            | 291  | 0       | 4    | 🔴 Alt         |
| campaign_screen                | 678  | 0       | 14   | 🔴 Alt         |
| branding_screen                | 179  | 0       | 5    | 🔴 Alt         |
| menu_screen                    | 287  | 0       | 3    | 🔴 Alt         |
| empire_card_screen             | 243  | 0       | 1    | 🔴 Alt         |
| settings_screen                | 167  | 14      | 3    | 🟢 Premium     |
| day_end_dialog                 | 709  | 15      | 10   | 🟢 Premium     |
| weekly_report_dialog           | 163  | 8       | 1    | 🟡 Teilweise   |
| quarterly_report_dialog        | 152  | 7       | 1    | 🟢 Premium     |
| bankruptcy_dialog              | 234  | 0       | 2    | 🔴 Alt         |
| mission_banner                 | 316  | 0       | 8    | 🔴 Alt         |
| tutorial_navigation (WIP)      | ?    | ?       | ?    | 🟡 unbekannt   |

**Bilanz:**
- 🟢 Premium: 8 Screens/Widgets
- 🟡 Teilweise: 6
- 🔴 Alt: 12
- ⏳ WIP: 1 (Tutorial)

Größter Hebel pro Aufwand: die 5 reinen 🔴-Tabs in `shop_detail/` —
zusammen ~1.300 LOC, alle visuell ähnlich gebaut, ein einziges Pattern
löst alle.
