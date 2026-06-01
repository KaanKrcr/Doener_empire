# MODULE_STRUCTURE.md — Döner Empire

> Technische Modulstruktur für die (Weiter-)Umsetzung.
> Beschreibt die **bestehende** Architektur und wie zukünftige MVP- und
> Post-MVP-Features dort einzuhängen sind. Siehe auch `AGENTS.md`.

---

## 1. Architektur in einem Satz

Eine **geschichtete Flutter-App**: typisierte **Daten/Modelle** → **pure
Engine-Funktionen** (Simulation ohne Seiteneffekte) → **Provider** (Riverpod,
State) → **UI** (Screens/Widgets). Alle Balancing-Zahlen liegen zentral in
`lib/core/constants.dart`.

```
┌─────────────────────────────────────────────────────────────┐
│  UI            lib/ui/        Screens, Widgets (Flutter)      │
│      ▲ liest State / sendet Intents                          │
│  PROVIDER      lib/providers/ Riverpod – hält GameState       │
│      ▲ ruft pure Funktionen                                  │
│  SERVICES      lib/services/  Engines (pure) + IO (save/sound)│
│      ▲ operiert auf                                          │
│  MODELS        lib/models/    Datenklassen (GameState, Shop…) │
│      ▲ Defaults/Werte aus                                    │
│  CORE/CONFIG   lib/core/      constants, theme, router, l10n  │
└─────────────────────────────────────────────────────────────┘
```

**Abhängigkeitsregel:** Pfeile zeigen nur nach unten. UI kennt Provider;
Provider kennt Services; Services kennen Models + Core. **Models und Engines
kennen niemals die UI.**

---

## 2. Verzeichnisse (Ist-Zustand)

```
lib/
├── core/                  # Querschnitt & Konfiguration
│   ├── constants.dart     #  ► ALLE Balancing-Zahlen (Single Source of Truth)
│   ├── theme.dart         #  AppColors / AppText – Design-Tokens
│   ├── router.dart        #  go_router Routen
│   └── localization.dart  #  Texte / Sprache
│
├── models/                # Reine Datenklassen (kein Verhalten/IO)
│   ├── game_state.dart    #  ► zentraler, unveränderlicher Spielzustand
│   ├── shop_model.dart    #  Filiale
│   ├── city_model.dart    #  Stadt + Standort-Templates
│   ├── product_model.dart, equipment_model.dart, employee_model.dart
│   ├── marketing_model.dart, competitor_model.dart, upgrade_model.dart
│   ├── difficulty_model.dart   #  Schwierigkeits-Multiplikatoren
│   └── … (campaign, brand, mission, quality, event, stock, production …)
│
├── services/              # Logik & IO
│   ├── game_engine.dart        #  ► Kern-Simulation, PURE statische Methoden
│   ├── location_engine.dart    #  Adapter Standortdaten ↔ City-Map-UI
│   ├── competitor_engine.dart  #  Konkurrenz-Verhalten
│   ├── corporate_engine.dart, hr_engine.dart, campaign_engine.dart,
│   │                              mission_engine.dart  (Post-MVP-Tiefe)
│   ├── save_service.dart       #  Persistenz (shared_preferences)
│   ├── sound_service.dart      #  Audio/Haptik (Seiteneffekt-IO)
│   └── review_util.dart, share_util.dart
│
├── providers/
│   └── game_provider.dart      #  ► Riverpod: hält GameState, treibt Ticks,
│                               #    ruft GameEngine, persistiert via SaveService
│
├── ui/
│   ├── main_scaffold.dart
│   ├── screens/                #  city_map, shop_detail, finance, dashboard …
│   │   └── shop_detail/        #  Tabs: products, equipment, employees,
│   │                           #        marketing, upgrades
│   └── widgets/                #  money_display, day_end_dialog, city_map_view,
│                               #  confetti_overlay, premium_mobile_ui …
│
└── main.dart                   #  Einstieg, ProviderScope, Router-Bootstrap
```

---

## 3. Daten- & Kontrollfluss (ein Spieltick)

```
UI (Button "Tag starten")
   → game_provider  (Intent)
      → GameEngine.simulateTick(state, constants)   // pure: in → out
        ↳ liest constants.dart + difficulty_model
        ↳ ruft CompetitorEngine / HrEngine bei Bedarf
      ← liefert NEUEN GameState (kein Mutieren)
   → provider setzt neuen State + SaveService.save()
→ UI rebuildet aus State (Riverpod)
```

**Kernprinzip:** `GameEngine` gibt für jede Zustandsänderung ein **neues**
`GameState` zurück (siehe Kommentar in `game_engine.dart`). Das macht die
Simulation deterministisch und voll testbar (siehe `test/`).

---

## 4. Wo hängt sich welches Feature ein?

| Feature                     | Neuer/angepasster Ort                                   |
|-----------------------------|---------------------------------------------------------|
| Neue Stadt / Produkt / Gerät| **nur** `lib/core/constants.dart` (Daten ergänzen)      |
| Balancing-Tuning            | `constants.dart` / `difficulty_model.dart`              |
| Neue Wirtschaftsregel       | `services/game_engine.dart` + Test in `test/`           |
| Neuer Screen                | `lib/ui/screens/…` + Route in `core/router.dart`        |
| Neues UI-Element            | `lib/ui/widgets/…`, Styling über `theme.dart`-Tokens    |
| **Kosmetik (Post-MVP)**     | UI-Schicht + `services/store_service.dart` (Flags) — **nie** Engine |
| **Chaos-Modus (Post-MVP)**  | eigener Modus-Zustand + getrennter Engine-Pfad/Flag     |
| **DLC (Post-MVP)**          | zusätzliche Daten-Pakete, geladen über Entitlement-Flag |

---

## 5. Regeln für sauberes Wachstum

1. **Config zentral:** keine Magic Numbers in Engine/UI — alles über `core/`.
2. **Engine bleibt pur:** keine IO, keine `DateTime.now()`, keine Zufalls-
   Seeds ohne Injektion → testbar bleiben.
3. **Bestehendes adaptieren**, keine Parallelsysteme bauen (`AGENTS.md`).
4. **Visuelles von Logik trennen:** UI-PRs vs. Balancing-PRs getrennt halten.
5. **Monetarisierung isoliert:** Kaufzustände wirken nur in der UI; die
   Simulation kennt sie nicht (garantiert „kein Pay2Win", siehe `MONETIZATION.md`).
6. **Jede Engine-Änderung kommt mit Test** in `test/`.

---

## 6. Tests als Architektur-Sicherung

`test/` spiegelt die Systeme (`*_engine`, Balancing, Regression). Da `GameEngine`
pur ist, lassen sich Wirtschaft, Preise, Konkurrenz, Steuern etc. ohne UI
verifizieren. Pflicht vor Push: `flutter analyze` + relevante `flutter test`.
