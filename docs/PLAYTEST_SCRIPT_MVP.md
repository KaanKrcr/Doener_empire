# PLAYTEST_SCRIPT_MVP — Erste-10-Minuten-Smoke-Test

Stand: 2026-06-01
Zweck: **Manuelle** QA für jeden Codex-PR aus [MVP_NEXT_FIXES.md](MVP_NEXT_FIXES.md).
Wer das hier komplett durchgeht und keinen `BUG`-Eintrag findet, kann den PR mergen.

Voraussetzung:
- `flutter run -d windows` (oder Web) auf `main`-Branch mit dem PR gemerged.
- **Neuer Spielstand** — alten Save vorher löschen (App-Daten leeren oder
  `shared_preferences` zurücksetzen).
- Schwierigkeit: **Normal**, sofern nicht anders angegeben.
- Stoppuhr nebenbei laufen lassen — Soll-Zeiten sind Teil der Spec.

Legende:
- **ERWARTET:** Was passieren muss, damit der Schritt grün ist.
- **BUG:** Konkretes Symptom, das gemeldet werden muss (Issue + Screenshot).
- **NOTIZ:** Zur Beobachtung, nicht zwingend Bug.

---

## PR-1-Spot-Checks (immer mit, ~30 Sek)

> Diese Mini-Checks gehören zu **PR 1 (Umlaute + Standortauswahl)** und werden
> bei jedem Playtest mitgemacht — sie sind so klein, dass sie nicht
> zeitkritisch sind.

- **U1:** Konkurrenz-Tab öffnen → keine Namen mit `?`, `Ã`, `Ä±` o. ä.
  - **BUG:** „Kebap KralÄ±" oder ähnliche Mojibake (siehe
    [KNOWN_RISKS_NEXT.md](KNOWN_RISKS_NEXT.md) R-U1).
- **U2:** Stadt-Liste, Standort-Bottom-Sheet, Tagesabschluss-Dialog —
  alle Umlaute (ä, ö, ü, ß) korrekt gerendert.
- **S1:** City-Map einer Kleinstadt zeigt mindestens **6 Hotspots** (siehe
  [MVP_SCOPE.md](../MVP_SCOPE.md) — Soll: 6, Ist heute: 4).
  - **BUG:** Wenn PR 1 gemerged ist und immer noch 4 Hotspots → zurück an Codex.
- **S2:** Hotspot-Bottom-Sheet zeigt: Traffic, Miete, Kaution, Druck,
  Empfehlung — alle 5 Felder, ohne `null`/`NaN`, in deutscher Locale (Komma
  als Dezimaltrennzeichen für €-Beträge).

→ Wenn alle 4 Checks grün: weiter mit §0.

---

## 0. Setup (00:00 – 00:30)

1. App starten. Splash erscheint, dann Hauptmenü.
   - **ERWARTET:** Buttons „Neues Spiel" und „Fortsetzen" sichtbar. Audio-Toggle
     reagiert. Kein leerer Screen, kein Stack-Trace im Log.
   - **BUG:** App stürzt beim Start ab, weißer Screen, oder „Fortsetzen" ist
     fälschlich aktiv ohne Save.

2. „Neues Spiel" tippen → Schwierigkeit „Normal" wählen → Bestätigen.
   - **ERWARTET:** Wechsel auf `/new-game`, Firmenname-Feld vorbelegt oder leer,
     Button „Spiel starten" aktiv.
   - **BUG:** Schwierigkeit lässt sich nicht auswählen / wird nicht persistiert.

---

## 1. Tutorial-Onboarding (00:30 – 04:00)

### 1.1 Step `openFirstShop`

3. Tutorial-Banner erscheint oben mit Aufgabe „Erste Filiale eröffnen".
   - **ERWARTET:** Banner hat Titel, Beschreibung, „Warum"-Zeile, und Pfeil/Highlight
     auf den Städte-Tab.
   - **BUG:** Banner fehlt, oder Highlight zeigt auf falschen Tab.

4. Städte-Tab tippen → Startstadt wählen (z. B. Fulda) → Hotspot tippen.
   - **ERWARTET:** Standort-Bottom-Sheet mit Traffic, Miete, Kaution,
     Empfehlung sichtbar.
   - **BUG:** Bottom-Sheet zeigt `null`/`NaN`, Werte überlappen UI, oder
     Sheet öffnet sich nicht.

### 1.2 Step `understandLocationValues`

5. Im Bottom-Sheet 1 Sek. warten → „Weiter"-Button erscheint.
   - **ERWARTET:** Tutorial-Banner aktualisiert auf nächsten Step.
   - **BUG:** „Weiter" erscheint sofort (kein Lesefenster) oder gar nicht.

6. „Filiale eröffnen" tippen → Kaution wird abgezogen → Wechsel zu Shop-Detail.
   - **ERWARTET:** `state.shops.length == 1`, Cash gesunken um Kaution + erste
     Wochenmiete. Filiale hat Default-Menü.
   - **BUG:** Cash wird doppelt abgezogen, Menü ist leer, oder Filiale wird
     in falscher Stadt angelegt.

### 1.3 Step `changeProductPrice`

7. Sortiment-Tab → Döner im Fladenbrot auf z. B. 7,00 € setzen.
   - **ERWARTET:** Preis-Slider/Feld reagiert, Vorschau (Marge, „Döner-Index")
     aktualisiert sich live. Step gilt als erledigt.
   - **BUG:** Eingabe wird verworfen, Komma/Punkt-Trennung bricht
     (deutsche Locale), Marge wird negativ ohne Warnung.

### 1.4 Step `endFirstDay`

8. Zurück zum Dashboard → „Tag beenden" tippen.
   - **ERWARTET:** Tick-Animation läuft (~3 Sek pro Stunde × 14 Stunden ist
     im Skip-Modus schneller), dann Tagesabschluss-Dialog.
   - **BUG:** Tick hängt, doppelte Tage gezählt, App freezt.

### 1.5 Step `readDayReport`

9. Tagesabschluss-Dialog lesen → „Verstanden" / „OK" tippen.
   - **ERWARTET:** Dialog zeigt Umsatz, Kosten (Miete, Zutaten, Lohn), Gewinn,
     Kunden, Ruf-Delta. Werte sind konsistent (Umsatz − Kosten = Gewinn).
   - **BUG:** Werte stimmen nicht überein, deutsche Umlaute zerschossen
     („Tagesabschluß" als `Tagesabschlu?`), Dialog lässt sich nicht schließen.

10. Skip-Button auf Tutorial-Banner sollte jetzt sichtbar sein.
    - **ERWARTET:** „Tutorial überspringen" erscheint, ist klickbar, schließt
      restliche Steps sauber.
    - **NOTIZ:** Skip jetzt **nicht** drücken — wir testen die optionalen Steps.

---

## 2. Mitarbeiter einstellen (04:00 – 05:30)

11. Shop-Detail → Mitarbeiter-Tab → Bewerberpool öffnen.
    - **ERWARTET:** Mindestens 3 Bewerber sichtbar, mit Skill, Lohn, Hire-Fee.
    - **BUG:** Pool leer auf Tag 1 (Easy/Normal sollte mit Bewerbern starten),
      Skills sind alle gleich, Löhne sind 0.

12. Einen Döner-Meister einstellen.
    - **ERWARTET:** Hire-Fee wird einmalig abgezogen, Mitarbeiter erscheint im
      Team-Listing, Personal-Cap-Zähler aktualisiert (z. B. 1/3 in Kleinstadt).
    - **BUG:** Cap-Anzeige zeigt 1/5 in Kleinstadt (Cap ist falsch), oder Hire
      kostet 0 €.

---

## 3. Filiale ausbauen (05:30 – 07:00)

> Nur relevant, sobald **PR 5 (Filialausbau / Personal-Cap)** gemerged ist.
> Davor: Schritt überspringen und in `NOTIZ` vermerken „Feature noch nicht da".

13. 2–3 Tage zu Ende spielen, bis Cash ≥ 12.000 €. Auslastung beobachten.
    - **ERWARTET:** Dashboard zeigt steigende Tagesgewinne, Kapazitäts-Hint
      erscheint, wenn Filiale ans Limit kommt.
    - **BUG:** Cash sinkt trotz Gewinn (Konto-Bug), oder Kapazitäts-Hint
      bleibt aus, obwohl `potentialCustomers > capacity`.

14. Shop-Detail → „Ausbauen auf mittel" tippen → Bestätigen.
    - **ERWARTET:**
      - Dialog zeigt Vorher/Nachher: Cap 3 → 5, Miete 1200 → 1500/Woche, Kosten 8.000 €.
      - Cash − 8.000 €.
      - `shop.sizeTier == mittel`, Mitarbeiter-Cap = 5.
      - 1 Spieltag „Umbau" — Tagesumsatz ist sichtbar reduziert.
      - Moral-Delta −0.02, sichtbar im Team-Listing.
    - **BUG:** Cap zeigt 5 in Kleinstadt (sollte auf Stadt-Cap 3 gedeckelt
      sein), Miete wird nicht angepasst, oder Umbau-Tag fehlt.

15. In Kleinstadt versuchen, auf `flagship` zu wechseln.
    - **ERWARTET:** Button ist sichtbar, aber Tooltip warnt „Cap der Stadt
      begrenzt auf 3" — Ausbau erlaubt, aber Cap-Anzeige bleibt 3/12.
    - **BUG:** Cap 12/12 in Kleinstadt — Stadt-Cap wird ignoriert.

---

## 4. Konkurrenz beobachten (07:00 – 09:00)

> **Status:** Konkurrenz-Reaktionen + Anti-Monopol sind **aus dem MVP gefallen**
> (siehe [NEXT_FEATURE_BACKLOG.md](NEXT_FEATURE_BACKLOG.md), Phase „Nach MVP").
> Dieser Block bleibt im Skript, ist aber im MVP-Smoke-Test **optional** —
> nur die heutige Basis-Konkurrenz aus `competitor_engine.dart` testen.

16. Preise um +25 % über Markt setzen, 7 Tage spielen.
    - **ERWARTET:**
      - Konkurrenz-Tab zeigt `cheapMass`/`aggressive` mit gesunkenem
        `priceLevel`.
      - Toast oder Event-Log-Eintrag: „Konkurrenz reagiert auf deine Preise in
        {Stadt}".
      - Marktanteil des Spielers sinkt leicht (≤ 10 %).
    - **BUG:** Konkurrenz reagiert gar nicht, oder reagiert global statt
      stadtspezifisch.

17. Preise zurück auf Markt + 1× Stadtfest-Sponsoring buchen, weitere 14 Tage
    spielen.
    - **ERWARTET:**
      - Spieler-Marktanteil > 60 % möglich.
      - Neuer Konkurrent spawnt mit `priceLevel ≤ 0.85` und
        `personality = aggressive`.
      - Mietfaktor ×1.10 greift sichtbar (Tagesabschluss zeigt höhere
        Mietzeile, wenn >70 % Anteil).
    - **BUG:** Kein Spawn, oder Spawn ignoriert `_naturalCompetitorCap`,
      oder Mietfaktor wird persistent in `weeklyRent` geschrieben (sollte nur
      Berechnung sein).

---

## 5. Buyout testen (09:00 – 10:00+)

> Setzt voraus: **PR 2 (Buyout gibt Filialen)** gemerged.

18. Cash auf ≥ 200.000 € hochspielen (Schnelltest: Save manipulieren oder
    mehrere Tage simulieren). Konzern-Tab → M&A.
    - **ERWARTET:** Liste der akquirierbaren Konkurrenten mit neuem Preis
      (`shopCount × 60k × repFactor × marketCap`). Vorher/Nachher-Dialog beim
      Klick.
    - **BUG:** Preis weicht von Formel ab, oder Dialog fehlt komplett.

19. Konkurrenten kaufen ohne Inventar-Option.
    - **ERWARTET:**
      - Cash − berechneter Preis.
      - Neue Filialen haben: leeres Equipment, **30 % von `effectiveCap`**
        Personal mit mittlerem Skill, Ruf = 0.7 × Konkurrenten-Ruf,
        Moral 0.55, Regulars 0.0, sizeTier=klein.
      - Konkurrent verschwindet aus Liste.
    - **BUG:** Filiale spawnt mit 0 Mitarbeitern, oder Ruf wird 1:1 übernommen
      (zu stark), oder `wasAcquired`/`originalCompetitorName` fehlt im UI.

20. Sofort versuchen, in derselben Stadt einen zweiten Konkurrenten zu kaufen.
    - **ERWARTET:** Button disabled mit Tooltip „Cooldown 30 Tage". Cooldown
      ist stadt-spezifisch, andere Städte gehen.
    - **BUG:** Zweiter Kauf möglich, oder Cooldown global (blockiert auch
      andere Städte).

21. Save → App neu starten → Save laden.
    - **ERWARTET:** `lastAcquisitionDayPerCity` persistiert, Cooldown bleibt.
    - **BUG:** Cooldown ist nach Save/Load weg.

---

## 6. Was als Bug zählt (Kriterien)

**P0 — Merge-Blocker:**
- App-Crash, Datenverlust, Save-Load bricht.
- Cash/Cap/Ruf-Werte sind mathematisch inkonsistent (Summen stimmen nicht).
- Falsche Personal-Caps (Stadt-Cap ignoriert).
- Tutorial blockiert den Spieler (kein Skip, kein Weiter, falsche Highlights).

**P1 — Vor Release fixen:**
- Falsche Beträge in UI vs. State (z. B. Dialog zeigt 8.000 €, Abzug ist 7.999,99 €).
- Umlaute kaputt (`?` statt `ä`/`ö`/`ü`), kaputtes Locale (Komma/Punkt).
- Toast/Event-Log für neue Konkurrenz-Reaktionen fehlt.
- Buyout-Dialog ohne Vorher/Nachher-Preview.

**P2 — Polish:**
- Animation ruckelt, Sound fehlt, Tooltip-Text suboptimal.
- Reihenfolge der Tutorial-Coach-Marks nicht ideal.
- Werte sehen „komisch", aber sind in der Spec definiert.

**Kein Bug:**
- Subjektives „fühlt sich schwer/leicht" — gehört in [BALANCING_PLAYTEST_NOTES.md](BALANCING_PLAYTEST_NOTES.md).
- „Ich hätte es anders designt" — gehört ins Design-Review, nicht hierher.

---

## 7. Soll-Telemetrie (zum Vergleich)

| Zeit (mm:ss) | Schritt erreicht                        |
|--------------|------------------------------------------|
| 00:30        | Neues Spiel gestartet                    |
| 01:30        | Erste Filiale eröffnet                   |
| 02:30        | Erster Preis geändert                    |
| 03:30        | Erster Tag simuliert + Bericht gelesen   |
| 05:30        | Erster Mitarbeiter eingestellt           |
| 07:00        | Filiale auf `mittel` ausgebaut (mit PR 5)|
| 09:00        | Konkurrenz reagiert sichtbar (Post-MVP)  |
| 10:00+       | Erster Buyout durchgeführt (mit PR 2)    |

Wer >12 Min braucht: in `BALANCING_PLAYTEST_NOTES.md` notieren, **wo** der
Zeitverlust war.
