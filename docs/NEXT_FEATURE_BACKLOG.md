# NEXT_FEATURE_BACKLOG — Döner Empire

Stand: 2026-06-01
Zweck: Konsolidierter Backlog **nach** Prioritäten. Verhindert Scope-Creep
in MVP-PRs und gibt Codex eine klare „Was als nächstes?"-Reihenfolge.

Quellen: [MVP_SCOPE.md](../MVP_SCOPE.md), [MVP_NEXT_FIXES.md](MVP_NEXT_FIXES.md),
[KNOWN_RISKS_NEXT.md](KNOWN_RISKS_NEXT.md), [GAME_DESIGN.md](../GAME_DESIGN.md),
[KNOWN_ISSUES.md](../KNOWN_ISSUES.md).

Out-of-Scope für **alle** Stufen:
- Monetarisierung, IAP, Werbung.
- Cloud-Save, Accounts, Multiplayer.
- Voller 3D-Engine-Wechsel.

Skala:
- **Aufwand:** S (≤ 1 Tag) / M (2–4 Tage) / L (1+ Woche) / XL (Wochen).
- **Wert:** L / M / H (für Spieler-Erlebnis).

---

## 1. MVP-Pflicht (jetzt umsetzen, 5 offene PRs)

Diese Punkte schließen den MVP ab. Reihenfolge entspricht den PRs in
[PR_REVIEW_CHECKLIST.md](PR_REVIEW_CHECKLIST.md).

| # | Feature                              | Aufwand | Wert | Status   | Notiz                                  |
|---|--------------------------------------|---------|------|----------|----------------------------------------|
| 1 | Umlaute / Mojibake fixen             | S       | M    | offen    | PR 1 — Voraussetzung für Playtest-UX  |
| 2 | 6 Hotspots pro Stadt-Tier            | S       | M    | offen    | PR 1 — aus [MVP_SCOPE.md](../MVP_SCOPE.md) |
| 3 | Buyout: echte Filialen + Rebalance   | M       | H    | offen    | PR 2 — [MVP_NEXT_FIXES.md §4](MVP_NEXT_FIXES.md) |
| 4 | Difficulty-Multiplikatoren spreizen  | S       | H    | offen    | PR 3 — [MVP_NEXT_FIXES.md §3.3](MVP_NEXT_FIXES.md) |
| 5 | Tutorial: Coach-Marks + Verifier     | M       | H    | offen    | PR 4 — [MVP_NEXT_FIXES.md §1](MVP_NEXT_FIXES.md) |
| 6 | `ShopSizeTier` + Personal-Cap        | M       | H    | offen    | PR 5 — [MVP_NEXT_FIXES.md §2](MVP_NEXT_FIXES.md) |
| 7 | Tagesabschluss: Ursache-Wirkung schärfen | S–M | M    | offen    | aus [MVP_SCOPE.md](../MVP_SCOPE.md) §2 — kann in PR 4 mit |

**Definition of Done für MVP:**
[MVP_SCOPE.md §5](../MVP_SCOPE.md). Alle 7 Punkte oben grün + Playtest §1–§5
ohne P0/P1-Bug auf Easy & Normal.

---

## 2. Nach MVP — direkter Anschluss (Sprint 2)

Features, die das Spiel deutlich besser machen, aber den MVP-Release nicht
blockieren. Reihenfolge = empfohlene Umsetzung.

### 2.1 Konkurrenz-Reaktionen + Anti-Monopol
- **Aufwand:** M • **Wert:** H
- War als alte PR 4 im MVP, ist rausgefallen, weil zu groß im Kombi-Sprint.
- Spec: [MVP_NEXT_FIXES.md §3.4–§3.6](MVP_NEXT_FIXES.md).
- Datei-Scope: nur `competitor_engine.dart` + `game_state.dart`
  + Toast/Event-Log-UI.
- Tests: Stadt-spezifischer Boost mit Decay, Mietfaktor als
  Berechnungs-Step (nicht persistent).
- Risiko-Refs: R-K1, R-K2, R-K3, R-K4 in [KNOWN_RISKS_NEXT.md](KNOWN_RISKS_NEXT.md).

### 2.2 Day-End-Animation (Kundendots zur Filiale)
- **Aufwand:** M • **Wert:** M
- Offen aus [MVP_SCOPE.md](../MVP_SCOPE.md) §2 City-Map-MVP.
- Reines UI/Animation, keine Engine-Änderung.
- Akzeptanz: ein Kundendot pro N Kunden (`actualCustomers / N`), zieht von
  Hotspot-Rand zur Filiale, dauert ≤ 2 Sek im Day-End-Skip-Modus.

### 2.3 Konkurrenz-Hotspots auf City-Map
- **Aufwand:** M • **Wert:** M
- Offen aus [MVP_SCOPE.md](../MVP_SCOPE.md) — Marktanteilszonen sichtbar
  machen.
- Spieler sieht, **wo** Konkurrenten stehen → Buyout-Entscheidung wird
  räumlich, nicht nur tabellarisch.

### 2.4 Tagesbericht v2 — „Was hat den Tag gemacht?"
- **Aufwand:** M • **Wert:** H
- Aktuell zeigt der Dialog Summen. Spieler braucht **Treiber-Liste**:
  - Top-3-Produkte (Marge × Stück)
  - Top-Kostenposten
  - Vergleich zum Vortag (Δ Umsatz, Δ Kunden, Δ Ruf)
- Datei-Scope: `lib/ui/screens/day_end_dialog.dart` + Berechnungs-Helper.
- Kein neuer State.

### 2.5 Kartellamt-Event (sanftes Anti-Monopol)
- **Aufwand:** S • **Wert:** M
- Aus [MVP_NEXT_FIXES.md §3.5](MVP_NEXT_FIXES.md) — bewusst Post-MVP.
- Bei >75 % Marktanteil in einer Stadt: 1× pro 30 Tagen Event mit
  Geldstrafe (5 % Cash), klar kommuniziert, **kein** erzwungener Verkauf.

### 2.6 Save-Versions-Feld + Migration-Framework
- **Aufwand:** M • **Wert:** M
- Aus [KNOWN_RISKS_NEXT.md R-M2](KNOWN_RISKS_NEXT.md).
- Heute hat jeder Save kein `saveVersion`, jede Migration ist ad hoc.
- Einfaches Pattern: `{"saveVersion": 1, ...}` + Migration-Pipeline.
- Lohnt sich vor jedem größeren Datenmodell-Change.

---

## 3. Nice-to-have (Sprint 3+)

Features, die Tiefe geben, aber nicht für die ersten 10 Spielstunden
nötig sind.

### 3.1 Manager / Auto-Pricing pro Filiale
- **Aufwand:** M • **Wert:** M
- Hooks existieren bereits (`managerEmployeeIds`,
  [corporate_engine.dart:310](../lib/services/corporate_engine.dart)).
- Auto-Pricing-Strategie: Manager passt Preise leicht an Konkurrenz an,
  ±5 % vom Marktdurchschnitt.
- Spieler kann Manager-Strategie wählen: „defensiv / neutral / aggressiv".

### 3.2 Schulung / Mitarbeiter-Training v2
- **Aufwand:** M • **Wert:** M
- Existiert in Ansätzen — ausbauen: Skill-Caps anheben, Cooldowns,
  Spezialisierungen (z. B. „Stoßzeit-Profi").

### 3.3 Stadt-Events
- **Aufwand:** M • **Wert:** M
- Z. B. „Stadtfest läuft 3 Tage → Traffic +30 %" oder „Stromausfall im
  Viertel → Filiale geschlossen".
- Modelliert über bestehendes `event_model.dart`.

### 3.4 Achievement-Pass / Meilensteine
- **Aufwand:** S • **Wert:** M
- `achievement_model.dart` existiert, aber Meilensteine nicht
  vollständig verdrahtet. Fertig­machen + UI.

### 3.5 Marketing-Effekte spürbarer machen
- **Aufwand:** S • **Wert:** M
- Heute fühlt sich Marketing zu „pauschal" an. Konkrete sichtbare
  Konsequenzen pro Kampagne (z. B. Toast „Influencer-Post hat 230 zusätzliche
  Kunden gebracht").

### 3.6 Mitarbeiter-Kündigungen + Moral-Konsequenzen
- **Aufwand:** S • **Wert:** M
- Moral ist im Modell, aber Konsequenzen sind dünn. Niedrige Moral →
  Kündigungs-Risiko, Lohn-Bonus als Gegenmittel.

### 3.7 Lieferanten / Zutaten-Qualität
- **Aufwand:** M • **Wert:** M
- Heute gibt es nur Zutatenkosten. Mehrstufige Qualität (`günstig` /
  `standard` / `bio`) mit Marge ↔ Ruf-Tradeoff.

### 3.8 Speichern in Slots / Mehrere Spielstände
- **Aufwand:** S • **Wert:** S
- Heute genau 1 Save. Sehr einfaches Quality-of-Life.

---

## 4. Später / DLC-Kandidaten

Größere Systeme, die das Spiel ein anderes Spiel machen. Nicht für 1.0.

### 4.1 Konzern-Ebene (volle M&A-Tiefe)
- **Aufwand:** XL • **Wert:** H
- Heute existiert `corporate_engine.dart` als Adapter. Voll ausgebaut:
  Börse, Aktien, Konzern-Steuern, Konzern-HR-Manager mit eigenen
  KPIs, Produktions-Lizenzen, Franchising.
- Eigene MVP-Phase, eigenes Doc.

### 4.2 Story-Kampagne als Pflicht-Onboarding
- **Aufwand:** L • **Wert:** M
- Aus [MVP_SCOPE.md](../MVP_SCOPE.md) Post-MVP-Liste. Strukturierte
  Mission-Reihe statt freies Sandbox-Onboarding.

### 4.3 Chaos-Modus
- **Aufwand:** M • **Wert:** M
- Zufällige Mini-Krisen (Gesundheitsamt, Mitarbeiter-Streik, virale
  Beschwerde). Existiert teilweise als Idee in `event_model.dart`.

### 4.4 Innenraum-Sim / manuelles Kochen
- **Aufwand:** XL • **Wert:** M
- Aus [MVP_SCOPE.md](../MVP_SCOPE.md) explizit Post-MVP. Würde 3D-/
  2.5D-Engine erfordern.

### 4.5 Logistik-Layer
- **Aufwand:** L • **Wert:** M
- Zentrallager, LKW-Routen, Lieferketten-Engpässe. Macht das Spiel
  business-simulationslastiger.

### 4.6 Marken-Skins / kosmetische Items
- **Aufwand:** M • **Wert:** L
- Aus [MVP_SCOPE.md](../MVP_SCOPE.md) als „kosmetische Monetarisierung"
  gelistet. **Bewusst nicht im Scope** dieses Backlogs, da hier
  Monetarisierungs-frei. Wenn überhaupt: rein kosmetisch ohne Bezahl-Layer.

### 4.7 Cloud-Save / Accounts / Multiplayer
- **Aufwand:** XL • **Wert:** L
- Aus [MVP_SCOPE.md](../MVP_SCOPE.md) explizit Post-MVP.

---

## 5. Tech-Debt-Backlog (orthogonal zu Features)

Diese Punkte sind keine Features, sondern Hygiene. Können zwischen
Feature-PRs als „Refresh-PR" eingestreut werden.

| # | Thema                                          | Aufwand | Wert | Notiz                                    |
|---|------------------------------------------------|---------|------|------------------------------------------|
| T1| Save-Versions-Feld + Migration-Pipeline        | M       | M    | Siehe §2.6 — wird zur Pflicht ab Sprint 3 |
| T2| Save-Fixtures in `test/fixtures/saves/`        | S       | M    | Aus [KNOWN_RISKS_NEXT.md R-CI1](KNOWN_RISKS_NEXT.md) |
| T3| `flutter test` Performance < 30 Sek            | S       | M    | Aus R-CI2                                |
| T4| `flutter analyze` als Pre-Commit-Hook          | S       | L    | Verhindert Warning-Drift                 |
| T5| Konsolidierung redundanter Provider-State      | M       | L    | `game_provider.dart` ist gewachsen       |
| T6| UI-Smoke-Test auf 360×640 Phone-Auflösung      | S       | L    | Lange Labels (siehe R-U3)                |
| T7| Localization-Stub für spätere i18n             | M       | L    | Strings in `lib/core/localization.dart` zentralisieren |

---

## 6. Entscheidungsfragen (zur Klärung mit Game-Owner)

Diese Fragen blockieren keinen PR, sollten aber **vor Sprint 2** geklärt sein,
damit Codex nicht in falsche Richtungen läuft.

1. **Konkurrenz-Reaktionen** (§2.1) — wirklich Post-MVP, oder doch
   noch in den MVP nachziehen, sobald PRs 1–5 grün sind?
2. **Tagesbericht v2** (§2.4) — wie weit detaillieren? Liste reicht, oder
   sollen Charts kommen?
3. **Kartellamt-Event** (§2.5) — Geldstrafe ist eine Option; alternative:
   PR-Schaden statt Cash. Was wirkt fairer im Playtest?
4. **Mehrere Save-Slots** (§3.8) — wäre QoL, aber bricht Save-Format leicht.
   Vor oder nach Save-Versions-Feld (T1)?
5. **DLC-Layer** (§4) — wirklich DLC-Strategie oder „1.0 enthält alles, 2.0
   ist Sequel"?

---

## 7. Reihenfolge-Empfehlung (next 3 Sprints)

| Sprint | Inhalt                                                    | Dauer    |
|--------|-----------------------------------------------------------|----------|
| 1      | MVP-Pflicht §1 (PRs 1–5) + Tagesabschluss-Schärfung      | ~2 Wochen |
| 2      | §2.1 Konkurrenz-Reaktionen + §2.2 Day-End-Animation + §2.4 Tagesbericht v2 | ~3 Wochen |
| 3      | §2.3 Konkurrenz-Hotspots + §2.5 Kartellamt + T1 Save-Versions + §3.1 Manager | ~3 Wochen |

Danach ist das Spiel **1.0-ready**. Alles darüber hinaus ist Post-Release.
