# MVP_SCOPE.md — Döner Empire

> Definiert **bewusst eng**, was der erste spielbare, veröffentlichbare Build
> enthält. Regel: Wenn ein Feature nicht den Core Loop aus `GAME_DESIGN.md` §4
> trägt, gehört es **nicht** ins MVP.

---

## 1. MVP-Ziel (eine Zeile)

> Der Spieler kann **einen Dönerladen betreiben, Kunden bedienen, Geld
> verdienen, Upgrades & weitere Filialen kaufen** — und das fühlt sich gut an.

---

## 2. Im MVP enthalten ✅

### Wirtschaft / Core Loop
- [x] Ein Spielstand mit Startkapital (`kStartingCash`).
- [x] Erste Filiale in einer kostenlosen Kleinstadt eröffnen.
- [x] Tick-basierte Tagessimulation (`kTickIntervalSeconds`, `kDailyOpenHours`).
- [x] Tagesabschluss mit Umsatz / Kosten / Gewinn / verlorenen Kunden.
- [x] Speisekarte mit Default-Produkten (`kAllProducts`, `isDefault: true`).
- [x] Preis pro Produkt setzen; Preis-Attraktivität vs. Döner-Index.

### Investition / Wachstum
- [x] Equipment kaufen (Spieß, Kasse, Fritteuse … aus `kAllEquipment`).
- [x] Personal einstellen (`kEmployeeTypes`).
- [x] Mindestens eine lokale Marketing-Kampagne (`kAllCampaigns`).
- [x] Zweite Filiale + Stadtwechsel über Umsatz-Schwellen (`unlockCost`).

### Bühne / UX
- [x] City-Map als zentrale Ansicht (`CityMapScreen`, `LocationEngine`).
- [x] Standort-Detail im Bottom-Sheet (Zielgruppe, Traffic, Miete, Risiko).
- [x] Speichern/Laden lokal (`save_service.dart`, `shared_preferences`).
- [x] Basis-Game-Feel: Geld-Animation, Tagesabschluss-Dialog, Sound an/aus.
- [x] Schwierigkeitsgrade als Multiplikatoren (`kDifficultyModifiers`).

### Qualität
- [x] `flutter analyze` ohne Fehler.
- [x] Kern-Logik durch Tests in `test/` abgedeckt.

---

## 3. **Nicht** im MVP ❌ (Post-MVP)

Diese Systeme existieren teils im Code, sind aber **kein MVP-Erfolgskriterium**
und werden für ein fokussiertes erstes Release zurückgestellt / hinter Flags:

- ❌ Story-Kampagne (`campaign_engine.dart`) als Pflicht-Onboarding.
- ❌ Konzern-Ebene: Börsengang/Aktien, Produktionsanlagen, M&A, HR-Manager.
- ❌ Stadt- & konzernweites Marketing als Kernfokus.
- ❌ **Kosmetische Items / Marken-Skins** → eigener Monetarisierungs-Schritt.
- ❌ **Chaos-Modus** → optionaler Zusatzmodus *nach* MVP.
- ❌ **DLCs** (neue Länder/Städte-Pakete).
- ❌ Cloud-Save / Accounts / Multiplayer.
- ❌ Voller 3D-Engine-Wechsel, Innenraum-Sim, manuelles Kochen, Logistik.

> Reihenfolge nach MVP: **Kosmetik → Chaos-Modus → DLC** (siehe `MONETIZATION.md`).

---

## 4. Abgrenzung zum bestehenden Code

Das Repo enthält bereits viele Post-MVP-Systeme. **Nicht löschen** — bewahren
(siehe `AGENTS.md`). Für das MVP-Release gilt:

- Core-Loop-Screens sind der **Default-Pfad**.
- Fortgeschrittene Systeme bleiben erreichbar, sind aber nicht Teil des
  Onboardings / der MVP-Erfolgsmetriken.
- Optional über Feature-Flags ausblendbar, falls für ein schlankes erstes
  Release gewünscht.

---

## 5. Definition of Done (MVP)

Ein neuer Spieler kann **ohne Erklärung**:
1. einen Laden eröffnen,
2. einen Preis setzen und einen Tag simulieren,
3. am Ergebnis erkennen, was zu verbessern ist,
4. ein Upgrade oder eine zweite Filiale kaufen,
5. eine neue Stadt freischalten.

…und das in **unter 10 Minuten** verstehen, ohne dass je Echtgeld nötig ist.
