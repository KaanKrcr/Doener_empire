# PREMIUM_UI_RULES — Operative Design-Regeln

Stand: 2026-06-01
Zweck: Konkrete, prüfbare Regeln für jede UI-PR im Premium-Rollout.
Ergänzt [UI_STYLE_GUIDE.md](UI_STYLE_GUIDE.md) (Vision) mit dem, was
**im Code** konkret passieren muss.

Wer das hier nicht einhält, wird im PR-Review zurückgeschickt.

---

## 1. Spacing

Drei feste Skalen, keine freien Werte:

| Token | Pixel | Verwendung                                              |
|-------|-------|----------------------------------------------------------|
| XS    | 4     | Innerhalb einer Zeile (z. B. Icon-Text-Abstand)         |
| S     | 8     | Zwischen Metric-Spalten, zwischen Chips                  |
| M     | 12    | Innenpadding einer Card / Sheet                          |
| L     | 16    | Außen-Margin einer Card / Section                        |
| XL    | 24    | Zwischen Sektionen (`PremiumSectionLabel`-Abstand oben)  |

**Regeln:**
- Verwende **nicht** `15`, `18`, `20`, `22` als Abstand. Wenn das Auge sagt
  „dazwischen", → S oder M.
- Vertikales Spacing in einem `Column` = `SizedBox(height: M)` oder `L`.
- Symmetrisches Padding in `PremiumDecisionSheet` ist bereits gesetzt
  ([premium_mobile_ui.dart:64](../lib/ui/widgets/premium_mobile_ui.dart)) — nicht
  überschreiben.

---

## 2. KPI-Strips (`PremiumMetricStrip`)

**Anatomie:** 2–4 `PremiumInlineMetric` in einer Row.

**Regeln:**
- **Min 2, max 4** Metriken. Bei 5+ → in zwei Strips splitten oder Detail-View.
- Jede Metric hat **Label** (1–2 Wörter, gedämpft) und **Wert** (1 Zeile, kräftig).
- Werte sind formatiert:
  - Geld: `€` rechts, Tausender-Trenner mit `.`, Dezimalkomma. Beispiele:
    `2.450 €`, `15.000,50 €`.
  - Prozent: `42 %` mit Leerzeichen vor `%`.
  - Counts: ohne Einheit, ggf. abgekürzt (`1,2k`, `2,4M`).
- Farben der Werte:
  - Neutral (Standard): `AppColors.textPrimary`.
  - Positiv: `AppColors.success` (z. B. Gewinn).
  - Warnung: `AppColors.warning` (z. B. Auslastung 85 %).
  - Negativ: `AppColors.danger` (z. B. Verlust, Insolvenz-Risiko).
- `dense: true` nur in Reihen mit > 1 Strip auf demselben Screen-Abschnitt.

**Anti-Pattern:**
- ❌ KPI-Strip mit gemischten Datentypen (Geld + Prozent + Datum) ohne klare
  Hierarchie.
- ❌ Strip ohne Labels („magische Zahlen").
- ❌ Eigene Container mit ähnlichem Look → immer den Strip benutzen.

---

## 3. Status-Hints (`PremiumStatusHint`)

**Drei Töne, drei Aufgaben:**

| Tone     | Verwendung                                                              |
|----------|-------------------------------------------------------------------------|
| success  | Bestätigung, freigeschaltet, „läuft", positive Anomalie                |
| warning  | Achtung, Cooldown, Auslastung hoch, Mission läuft, Risiko mittel        |
| danger   | Verlust, Bankrott-Nähe, Personal-Kündigung, Risiko hoch                 |

**Regeln:**
- **Max 1 Hint pro Sektion**. Mehr → Spieler übersieht alle.
- Text ist **imperativ oder zustandsbeschreibend**, nie lang:
  - ✅ „Hohe Auslastung — mehr Personal nötig."
  - ✅ „Cooldown: 12 Tage."
  - ❌ „Bitte beachten Sie, dass die Auslastung Ihrer Filiale aktuell …"
- Nicht für reine Info-Texte missbrauchen — dafür `PremiumDecisionLine`.

---

## 4. Buttons

**Drei Klassen, klare Hierarchie:**

| Klasse        | Wann                                                | Aussehen                       |
|---------------|------------------------------------------------------|--------------------------------|
| Primary       | Die eine Hauptaktion einer Sektion / eines Sheets    | `ElevatedButton` (Theme, Orange) |
| Secondary     | Alternative Aktion                                   | `OutlinedButton` (Theme)         |
| Tertiary/Link | Mehr Info, Abbrechen, Detail                         | `TextButton`                     |

**Regeln:**
- **Max 1 Primary pro Sheet**. Sonst weiß der Spieler nicht, was als nächstes.
- Primary mit `€`-Betrag rechtfertigt Spacing: Label links, Betrag rechts in
  derselben Row.
- Icons in Buttons nur, wenn das Verb sonst unklar wäre (Speichern → `💾`
  nicht nötig; Teilen → `↗` ja).
- **Keine Stock-Material-`FloatingActionButton`** mehr im Spiel — wenn doch
  nötig, durch Themed Button ersetzen.

**Anti-Pattern:**
- ❌ Drei gleich aussehende `ElevatedButton` nebeneinander („wo soll ich
  hin?").
- ❌ Primary-Button in einer reinen Anzeige-Sektion ohne Aktion.

---

## 5. Dialoge

**Drei Typen:**

| Typ            | Wofür                                       | Komponente                                 |
|----------------|----------------------------------------------|--------------------------------------------|
| Decision-Sheet | Modal mit Wahl / Bestätigung                 | `PremiumDecisionSheet` innen, `AlertDialog` außen |
| Report-Dialog  | Tagesabschluss, Quartal, Insolvenz           | Eigener Scaffold-Dialog, Premium-Sektionen   |
| Snackbar       | Kurze Bestätigung (1 Zeile, < 3 Sek)        | Theme-`SnackBar`                            |

**Regeln:**
- Jeder Dialog hat **Titel**, **maximal 2 Section-Blocks**, **1 Primary + 1 Secondary** Button. Mehr → Screen statt Dialog.
- Report-Dialoge müssen `day_end_dialog`-Pattern folgen:
  1. Hero-KPI oben (Gewinn / Verlust).
  2. `PremiumMetricStrip` mit 3–4 Treibern.
  3. Sektion mit `PremiumSectionLabel` für Details.
  4. CTA unten.
- **Erfolgs-** und **Bankrott-**Dialoge nutzen das **gleiche** Pattern, nur
  Akzentfarben unterscheiden sich. Konsistenz schlägt Drama.

---

## 6. Leere Zustände (Empty States)

Heute uneinheitlich umgesetzt. Soll-Pattern:

- **Icon** (Emoji oder Material-Icon, 32–48 px) zentriert.
- **Headline** (Baloo2, 16 px, `textPrimary`).
- **Erklärung** (Inter, 12 px, `textSecondary`, max 2 Zeilen).
- **Primary-CTA** oder **Hint**, was den State auflöst.

**Beispiele:**
- Keine Mitarbeiter: „Noch kein Team — Erster Hire startet hier."
- Keine Konkurrenz: „Markt geschlossen — Eröffne eine Filiale, um Konkurrenz
  anzuziehen."
- Keine Achievements: „Noch nichts freigeschaltet — Spiel mehr, lerne mehr."

**Komponenten-Lücke:** Aktuell gibt es **kein** `PremiumEmptyState`-Widget.
Workaround: `PremiumDecisionSheet` mit Inhalt nach obigem Pattern.
Empfehlung: In PR C (siehe [PREMIUM_UI_ROLLOUT_PLAN.md](PREMIUM_UI_ROLLOUT_PLAN.md))
als neue Komponente ergänzen.

---

## 7. Animationen

Existierende Animationen ([animated_money.dart](../lib/ui/widgets/animated_money.dart),
[money_pulse.dart](../lib/ui/widgets/money_pulse.dart),
[confetti_overlay.dart](../lib/ui/widgets/confetti_overlay.dart)) bleiben.

**Regeln für neue Animationen:**
- **Dauer:**
  - Micro-Feedback (Tap, Toggle): 120–180 ms.
  - State-Change (Karte aufklappen, Wert ändert sich): 220–320 ms.
  - Hero (Eröffnung Filiale, Tagesabschluss): 400–600 ms.
- **Easing:** `Curves.easeOutCubic` Standard. Bei Bouncy-Moment
  (`Curves.elasticOut`) nur einmal pro Screen.
- **Niemals** mehr als 2 Animationen parallel im selben Sichtfeld.
- Animationen müssen sich **abschalten lassen** (Settings) — bestehende
  `sound_service`-ähnliche Logik wäre der richtige Ort für später (nicht in
  dieser PR-Welle bauen).

**Anti-Pattern:**
- ❌ Endlos-Pulsation auf nicht-CTA-Elementen.
- ❌ Tap-Feedback länger als 200 ms.

---

## 8. Mobile-First-Regeln

Zielauflösung: **360 × 640 dp** (kleines Phone). Größere Auflösungen sind
Bonus, dürfen aber den 360-Layout nicht brechen.

**Regeln:**
- **Touch-Target ≥ 44 × 44 dp.** Buttons in Listen mit weniger Höhe → zurück.
- **Lange Labels** mit `TextOverflow.ellipsis` + Tooltip auf Long-Press.
- **Horizontale Scrolls** vermeiden. Ausnahme: explizite Galerien
  (Achievement-Trophies, City-Cards).
- **Bottom-Sheets** nicht höher als 80 % Screen-Höhe. Mehr → Vollbild-Screen.
- **City-Map** hat Sicherheits-Inset für Tabs unten (bestehend, nicht ändern).
- **KPI-Strips** auf 360 dp: max 4 Metriken bei `dense: true`, max 3 ohne dense.

**Testen:**
- Jeder PR muss in **Phone-Default-Größe** geprüft sein. Screenshot
  beilegen.

---

## 9. Komponenten-Lücken (Inventar vs. Bedarf)

Existiert in [premium_mobile_ui.dart](../lib/ui/widgets/premium_mobile_ui.dart):
- `PremiumMetricData` (Daten)
- `PremiumMetricStrip` (Container)
- `PremiumDecisionSheet` (Sheet-Rahmen)
- `PremiumSectionLabel` (Section-Header)
- `PremiumDecisionLine` (kurze Erklärung)
- `PremiumInlineMetric` (einzelne Metric)
- `PremiumStatusHint` mit `PremiumStatusTone {success, warning, danger}`

**Fehlt vermutlich (Vorschläge, in PR C umsetzen):**

| Vorschlag                  | Wofür                                                       | Heutiger Workaround                  |
|---------------------------|--------------------------------------------------------------|--------------------------------------|
| `PremiumEmptyState`       | Empty States (§6)                                            | `PremiumDecisionSheet` mit Inhalt    |
| `PremiumPrimaryButton`    | Primary-CTA mit `€`-Betrag rechts, einheitliches Layout      | `ElevatedButton.icon` + manueller Row |
| `PremiumProgressRow`      | Achievement-Progress, Tutorial-Step-Progress                 | `LinearProgressIndicator` + Wrapper  |
| `PremiumHeroValue`        | Große Zahl als Hero (Tagesabschluss, Empire-Card)            | `Text` mit `AppText.display(size:34)` |
| `PremiumBadge`            | Kleines „Acquired", „Aktiv", Tier-Label inline               | Custom `Container` mit Border        |

Diese Liste ist Vorschlag, kein Auftrag. Erst implementieren, wenn der
Workaround in einer PR auftaucht. Ergo: nicht spekulativ.

---

## 10. Was NIE in eine UI-PR gehört

- ❌ Engine-Logik (`lib/services/*`).
- ❌ State-Refactor (`lib/providers/game_provider.dart`).
- ❌ Datenmodelle (`lib/models/*`).
- ❌ Save-Format-Änderungen.
- ❌ Neue Packages in `pubspec.yaml`.
- ❌ Änderungen an `theme.dart` (Farben/Typografie sind fixiert).
- ❌ Animationen mit eigenem `Ticker`, wenn ein bestehender Helper reicht.
- ❌ „Mitfix" von Code, der nicht zur Premium-Umstellung gehört.

---

## 11. Schnellprüfung (PR-Review-Cheatsheet)

Vor dem Merge fragen:

1. Sieht die Sektion in 360 × 640 dp sauber aus?
2. Ist **ein** Primary-Button erkennbar?
3. Sind KPIs als `PremiumMetricStrip` umgesetzt, nicht als eigene
   Container?
4. Gibt es **maximal 1** `PremiumStatusHint` pro Sektion?
5. Sind alle Geldwerte deutsch formatiert (`1.234,56 €`)?
6. Spacing nur aus den Tokens in §1?
7. Touch-Targets ≥ 44 dp?
8. `flutter analyze` clean?
9. Diff außerhalb `lib/ui/` = **0**?

Wenn 1 Antwort ein „nein" ist → zurück an Codex mit konkretem Verweis auf
die Regel.
