# GAME_DESIGN.md — Döner Empire

> Game Design Dokument (GDD) für die MVP-Phase.
> Quelle der Wahrheit für *was* das Spiel ist und *wie* es sich anfühlen soll.
> Für visuelle Richtung siehe `docs/UI_STYLE_GUIDE.md`,
> für den genauen Umfang siehe `MVP_SCOPE.md`.

---

## 1. Vision

Döner Empire ist eine **warme, ernsthafte Wirtschaftssimulation** fürs Handy
(und Web). Der Spieler startet mit einem einzigen Imbiss und baut daraus
Schritt für Schritt ein landesweites Döner-Imperium auf.

Das Spiel soll sich anfühlen wie ein **Tycoon-Sim mit Herz** — inspiriert von
der Wirtschaftstiefe à la Coffee Inc., aber mit eigener, bodenständiger
Döner-Identität. **Kein** generischer Idle-Clicker, **keine** Button-Wall.

**Leitfrage jeder Mechanik & jedes Screens:** „Was soll ich als nächstes tun?"

---

## 2. Zielgruppe & Plattform

- **Plattform:** Flutter → Android, iOS, Web (eine Codebasis).
- **Sessionlänge:** 3–10 Minuten pro Session, mehrmals täglich.
- **Spielertyp:** Optimierer, Tüftler, Wirtschaftsspiel-Fans.
- **Monetarisierung:** fair, **niemals Pay2Win** (siehe `MONETIZATION.md`).

---

## 3. Fantasie & Ton

- Vom kleinen Imbiss zum Konzern — ehrlicher Aufstieg, harte Arbeit.
- Echte deutsche Städte (Fulda → Berlin) als greifbare Bühne.
- Trockener, operativer Humor in den Texten:
  - `Kapazität limitiert: 38 Kunden verloren`
  - `Preis wirkt hoch fürs Uni-Viertel`
  - `Bahnhof braucht Tempo, nicht Premium-Zutaten`

---

## 4. Core Gameplay Loop

```
        ┌──────────────────────────────────────────────────┐
        │  1. BEOBACHTEN   Tagesabschluss: Umsatz, verlorene │
        │                  Kunden, Bewertung, Konkurrenz     │
        │            ↓                                       │
        │  2. ENTSCHEIDEN  Preis, Zutaten-Qualität, Personal,│
        │                  Equipment, Marketing              │
        │            ↓                                       │
        │  3. INVESTIEREN  Upgrades / neue Filiale / neue    │
        │                  Stadt freischalten                │
        │            ↓                                       │
        │  4. EXPANDIEREN  Mehr Standorte, mehr Städte,      │
        │                  später Konzern-Ebene              │
        └──────────────────────────────────────────────────┘
                     (ein Spieltag ≈ wenige Minuten)
```

Der Loop läuft auf einem **Tick-System**: ein Tick = 1 Spielstunde
(`kTickIntervalSeconds`), der Laden ist `kDailyOpenHours` Stunden geöffnet.
Am Tagesende fällt die Bilanz, dann beginnt die nächste Entscheidungsrunde.

---

## 5. Kernsysteme

| System            | Spieler-Entscheidung                          | Modell / Service (Code)                |
|-------------------|-----------------------------------------------|----------------------------------------|
| **Filialen**      | Wo eröffnen? Welcher Standort-Typ?            | `Shop`, `LocationEngine`               |
| **Städte**        | Welche Stadt als nächstes freischalten?       | `CityData` (`kAllCities`)              |
| **Speisekarte**   | Welche Produkte? Welcher Preis?               | `ProductData` (`kAllProducts`)         |
| **Equipment**     | Welche Geräte für Qualität/Kapazität/Tempo?   | `EquipmentData` (`kAllEquipment`)      |
| **Personal**      | Wen einstellen? Schichten?                    | `EmployeeTypeData`, `HrEngine`         |
| **Marketing**     | Welche Kampagne, lokal/stadt-/konzernweit?    | `MarketingCampaign`-Listen             |
| **Nachfrage**     | (ergibt sich) Tageszeit, Wochentag, Saison    | `GameEngine`, `time_profile_model`     |
| **Konkurrenz**    | Reagieren auf Wettbewerber                    | `CompetitorEngine`                     |
| **Simulation**    | —                                             | `GameEngine` (pure Funktionen)         |

### Nachfrage-Modell (vereinfacht)
```
Kunden ≈ FootTraffic(Stadt, Standort, Tageszeit, Saison)
         × Reputation
         × Marketing-Boost
         × Preis-Attraktivität(Preis vs. Zielgruppe & Döner-Index)
verkauft = min(Kunden, Kapazität(Equipment + Personal))
Gewinn  = verkauft × (Preis − Zutatenkosten) − Miete − Löhne − Marketing
```
Verlorene Kunden durch zu geringe Kapazität sind ein **sichtbares Signal**
zum Investieren — nie eine versteckte Strafe.

---

## 6. Progression

1. **Solo-Imbiss** — ein Laden in einer kostenlosen Kleinstadt, Preis & Qualität lernen.
2. **Zweite Filiale** — Kapazität & Standort-Personality verstehen.
3. **Stadtwechsel** — größere Städte freischalten (`unlockCost` aus Gesamtumsatz).
4. **Konzern** *(Post-MVP-Ausbau)* — stadt-/konzernweites Marketing, HR-Manager, M&A.

Gating erfolgt über **Gesamtumsatz-Schwellen** (z. B. Mittelstadt ab 30.000 €),
nicht über Echtgeld — Fortschritt ist immer durch Spielen erreichbar.

---

## 7. Game-Feel ("Juice")

- Animierte Geld-Zähler, Konfetti bei Meilensteinen (`flutter_animate`).
- Sound & Haptik (`audioplayers`, `sound_service.dart`).
- Tagesabschluss-Dialog als emotionaler Beat.
- City-Map als visuelle Hauptbühne (pseudo-3D, siehe `docs/MVP_3D_CITY_MAP.md`).

---

## 8. Erweiterungen (Post-MVP, bewusst ausgeklammert)

Siehe `MVP_SCOPE.md` §„Nicht im MVP". Geplant, aber **nicht** im ersten Wurf:
Story-Kampagne, Börsengang/Aktien, Produktionsanlagen, kosmetische Marken-Skins,
**Chaos-Modus** (optionaler, bezahlbarer Spaß-Modus, kein Vorteil), DLC-Städte/-Länder.

---

## 9. Designprinzipien (nicht verhandelbar)

1. **Kein Pay2Win.** Echtgeld kauft nie Spielvorteil.
2. **Jede Zahl ist konfigurierbar** — zentral in `lib/core/constants.dart`.
3. **MVP klein halten.** Lieber wenige Systeme, die sich gut anfühlen.
4. **Bestehende Simulation bewahren** — neue Features adaptieren, nicht parallel bauen.
5. **Entscheidungsfokus** — jeder Screen hilft beim nächsten Zug.
