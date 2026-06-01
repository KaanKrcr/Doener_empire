# UNITY_REWRITE_PLAN — Döner Empire 3D (Unity)

Stand: 2026-06-01
Zielbild: `Doener-Empire-3D/docs/assets/doener_empire_mobile_premium_ui.png`
(isometrische 3D-Stadt mit Premium-UI-Overlay, Bottom-Sheet mit KPI-Kacheln).

Entscheidung (vom Owner bestätigt):
- **Echter 3D-Engine: Unity** (kein pseudo-3D in Flutter).
- Spiel-Heimat bleibt das `doener_empire`-Repo (Unity-Projekt als Unterordner `unity/`).
- Bestehende Flutter-App bleibt vorerst erhalten (Referenz für Logik & Balancing),
  wird nicht parallel weiterentwickelt, sobald die Unity-Version trägt.

> **Wichtig:** Dies ist ein **mehrwöchiges** Vorhaben, kein Single-Session-Task.
> Dieser Plan macht es in überprüfbare Meilensteine zerlegbar. Die Dart→C#-
> Portierung der Simulation ist der größte, aber gut planbare Brocken, weil die
> Logik bereits existiert und nur übersetzt wird.

---

## 0. Voraussetzungen (vom Owner zu installieren)

Ohne diese kann **kein** C# kompiliert/getestet und kein Build erzeugt werden.
Aktueller Rechner: Unity NICHT installiert, dotnet NICHT verfügbar.

- [ ] **Unity Hub** + **Unity 6 LTS** (6000.x LTS) mit Modulen:
  - Android Build Support (inkl. OpenJDK + Android SDK/NDK) — Zielplattform Tablet
  - (optional) Windows Build Support für schnelles Desktop-Testing
- [ ] **.NET SDK 8** (für Editor-unabhängiges Kompilieren/Unit-Tests der Logik,
  z.B. via `dotnet test` in einem reinen C#-Class-Library-Spiegel)
- [ ] **Git LFS** (Unity-Assets: Modelle, Texturen → binär, gehören in LFS)
- [ ] Android-Gerät mit USB-Debugging (bereits vorhanden: Galaxy Tab S9 `R52T800N9MB`)

Render-Pipeline: **URP (Universal Render Pipeline)** — mobiltauglich, gute Optik
für den isometrischen Look. Kein HDRP (zu schwer fürs Tablet).

---

## 1. Zielarchitektur

```
unity/                            ← Unity-Projekt (Git LFS für Binärassets)
  Assets/
    Scripts/
      Core/          ← Enums, Konstanten, Utilities (toolchain-unabhängig)
      Models/        ← Daten-Klassen (Shop, Employee, Competitor, GameState …)
      Data/          ← ScriptableObjects (Cities, Products, Equipment, Campaigns)
      Simulation/    ← Engines (GameEngine, CompetitorEngine, CorporateEngine …)
      Save/          ← JSON-Speicher (kompatibel zur Flutter-Save-Struktur)
      View3D/        ← City-Map-Szene: Kamera, Hotspots, Shop-Prefabs, Kundendots
      UI/            ← UI-Toolkit (UXML/USS) Screens nach Referenzbild
      App/           ← Bootstrapping, Scene-Flow, DI/Service-Locator
    Scenes/
      Boot.unity
      MainMenu.unity
      CityMap.unity   ← Hauptszene (3D-Stadt + UI-Overlay)
    Art/
      Models/        ← .glb/.fbx: Gebäude, Dönerladen L1–L3, Konkurrenzladen
      Materials/
      Textures/
    UI/
      *.uxml / *.uss ← UI-Layout + Styles (Premium-Theme)
  Packages/manifest.json
  ProjectSettings/
```

**Trennprinzip:** `Core`, `Models`, `Simulation`, `Save` sind **reines C#
ohne UnityEngine-Abhängigkeit** (außer wo nötig). Dadurch:
- per `dotnet test` außerhalb von Unity testbar,
- 1:1 gegen die bestehenden Flutter-Tests verifizierbar (gleiche Erwartungswerte).

---

## 2. Dart → C# Mapping (Portierungs-Tabelle)

| Flutter (Dart)                              | Unity (C#)                                 | Aufwand | Hinweise |
|---------------------------------------------|--------------------------------------------|---------|----------|
| `lib/core/constants.dart`                   | `Data/GameData.cs` + ScriptableObjects     | M       | Städte, Produkte, Equipment, Mitarbeiter, Kampagnen, LocationTemplates |
| `lib/models/difficulty_model.dart`          | `Models/DifficultyModel.cs`                | S       | Enum + Modifier-Struct + Map |
| `lib/models/shop_model.dart`                | `Models/Shop.cs`                           | M       | `copyWith` → C# `with`/Clone; JSON-Felder identisch halten |
| `lib/models/employee_model.dart`            | `Models/Employee.cs`                       | S       | |
| `lib/models/competitor_model.dart`          | `Models/Competitor.cs`                     | M       | RNG-Verhalten reproduzieren |
| `lib/models/game_state.dart`                | `Models/GameState.cs`                      | L       | Zentrale Aggregatklasse |
| `lib/models/*` (übrige ~20 Modelle)         | `Models/*.cs`                              | L       | 1:1 Felder + JSON |
| `lib/services/game_engine.dart`             | `Simulation/GameEngine.cs`                 | XL      | Kern: Tagessimulation, Stats, Kapazität |
| `lib/services/competitor_engine.dart`       | `Simulation/CompetitorEngine.cs`           | L       | |
| `lib/services/corporate_engine.dart`        | `Simulation/CorporateEngine.cs`            | L       | Buyout, Auto-Hire, Manager |
| `lib/services/hr_engine.dart`               | `Simulation/HrEngine.cs`                   | M       | |
| `lib/services/campaign_engine.dart`         | `Simulation/CampaignEngine.cs`             | M       | |
| `lib/services/mission_engine.dart`          | `Simulation/MissionEngine.cs`              | M       | |
| `lib/services/location_engine.dart`         | `Simulation/LocationEngine.cs`             | M       | Adapter Standortdaten ↔ 3D-Map |
| `lib/services/save_service.dart`            | `Save/SaveService.cs`                      | M       | `JsonUtility`/Newtonsoft; Feldnamen exakt wie Flutter |
| `lib/providers/game_provider.dart`          | `App/GameController.cs`                     | L       | Riverpod-Notifier → C#-Controller + Events |
| `lib/ui/screens/*`                          | `UI/*.uxml + *.cs`                          | XL      | Komplett neu im UI-Toolkit nach Referenzbild |
| `lib/ui/widgets/city_map_view.dart`         | `View3D/CityMapController.cs` + Szene       | XL      | Pseudo-3D → echtes 3D |

**Übersetzungs-Konventionen:**
- Dart `double` → C# `float` (Spiel-Werte; bei Geld ggf. `double` beibehalten,
  konsistent mit Flutter-Tests).
- Dart immutable `copyWith` → C# `record` mit `with`-Expression.
- Dart `enum.name` (JSON) → C# `Enum.ToString()` / `Enum.Parse` (identische Strings).
- Riverpod `StateNotifier` → C# Controller mit `event Action` / UniRx (optional).
- `intl` `NumberFormat('#,##0','de_DE')` → `value.ToString("#,##0", new CultureInfo("de-DE"))`.

---

## 3. 3D-Szene (CityMap.unity) — nach Referenzbild

### 3.1 Kamera
- **Orthografische** Kamera, fester isometrischer Winkel (~30° X-Rotation, 45° Y).
- Pinch-Zoom (Orthographic Size), Pan per Drag, sanftes Fokus-Tween auf Filiale.
- Mobile-Safe-Area beachten (Top-Bar + Bottom-Sheet überlagern die Szene).

### 3.2 Stadt-Layout
- Grid aus modularen Gebäudekacheln (Straßen, Häuserblöcke) — instanziiert aus
  `Art/Models`.
- **6–10 Hotspots** pro Stadt (aus `kLocationTemplates`, je CityTier), als
  klickbare 3D-Marker mit schwebendem Label (wie „HAUPTSTRASSE 12 ★4.6").
- Spieler-Filiale: Gebäude mit **Neon-Outline** (Emissive/Outline-Shader, orange),
  je `sizeTier` ein anderes Modell (L1–L3 / flagship).
- Konkurrenz: eigene Lade-Prefabs mit Label (Name + ★), rote Einflusszone optional.

### 3.3 Day-End-Animation
- Kundendots (GPU-instanziierte kleine Meshes/Particles) bewegen sich von
  Hotspot-Rand zur Filiale, Menge ∝ `actualCustomers`.
- Umsatz-Popup über der Filiale (Worldspace-Canvas).

### 3.4 Assets (MVP-Liste)
- Gebäudekacheln: Wohnblock, Business, Bahnhof, Uni, Mall (je 1 Low-Poly-Modell)
- Dönerladen L1/L2/L3 + flagship
- Konkurrenzladen (1 Modell, umfärbbar)
- Kundendot, Standortmarker-Pin
- Skybox/Beleuchtung: Abend-Stimmung wie im Referenzbild (warmes Licht, Neon)
- Quelle: Asset Store (Synty/Low-Poly City) oder eigene Blender-Modelle.

---

## 4. UI (UI-Toolkit) — exakt nach Referenzbild

Premium-Theme aus dem bestehenden Flutter-Style übernehmen
([UI_STYLE_GUIDE.md](UI_STYLE_GUIDE.md), [PREMIUM_UI_RULES.md](PREMIUM_UI_RULES.md)).
Farben/Tokens 1:1: bg `#14100E`, surface `#1F1813`, primary `#E85D2F`,
gold `#FFC93C`, success `#7BC950`, danger `#E74C3C`.

### 4.1 Komponenten (USS-Klassen, Pendant zu premium_mobile_ui.dart)
- `.metric-strip` / `.inline-metric` → KPI-Kacheln (Wert groß, Label klein)
- `.decision-sheet` → abgerundetes Panel mit Border/Shadow
- `.section-label` → gesperrtes Mini-Label
- `.status-hint` (success/warning/danger) → farbige Hinweis-Box
- `.primary-button` / `.secondary-button`

### 4.2 CityMap-HUD (Referenzbild-Mapping)
- **Top-Bar:** Logo-Badge + „Döner Empire" links; Chart/Bell/Settings rechts.
- **Status-Strip:** Kontostand (Geld-Icon + Label) | Tag + Wochentag (Kalender).
- **Floating Action Buttons** rechts an der Szene: Fokus/Location, Karte, Stats.
- **Bottom-Sheet (selektierte Filiale):**
  - Titel + Edit-Stift, Subtitle „STADTTEIL, STADT", Badge „AKTIVE FILIALE ●"
  - Sterne-Rating + Zahl + „REPUTATION"
  - 4 KPI-Kacheln: **Marktanteil (Donut)**, **Fußgänger/Tag**, **Wochenmiete**,
    **Prognose Gewinn** — je mit Mini-Sparkline.
  - Buttons: **OPTIMIEREN** (primär) + **FILIALE ÖFFNEN** (sekundär).
- **Bottom-Nav:** Übersicht · Filialen · Manager · Forschung · Shop.

### 4.3 Übrige Screens
ShopDetail (Tabs), Finance, Corporate, Bank, NewGame, Reports — als UI-Toolkit-
Dokumente, Logik aus C#-Controllern. Reihenfolge siehe Meilensteine.

---

## 5. Meilensteine (überprüfbar)

| M | Inhalt | Verifikation |
|---|--------|--------------|
| **M0** | Voraussetzungen installiert, leeres Unity-URP-Projekt in `unity/`, läuft auf Tablet | Build startet, schwarze Szene auf Gerät |
| **M1** | Daten-Layer portiert: `Core/Enums`, `Data/GameData`, `Models/Difficulty` | `dotnet test` grün, Werte == Flutter-Konstanten |
| **M2** | Kernmodelle + GameState + Save (JSON-kompatibel) | Roundtrip-Test: Flutter-Save lädt in C# |
| **M3** | GameEngine-Port: Tagessimulation, Stats, Kapazität | Unit-Tests spiegeln Flutter-`test/`-Erwartungen |
| **M4** | Übrige Engines (Competitor, Corporate, HR, Campaign, Mission) | Unit-Tests grün |
| **M5** | CityMap-Szene: Kamera, 1 Stadt, Hotspots, Filiale eröffnen | Auf Tablet: Hotspot tippen → Filiale erscheint |
| **M6** | Premium-HUD nach Referenzbild (Top-Bar, Status, Bottom-Sheet, Nav) | Visueller Abgleich mit PNG |
| **M7** | Day-End-Animation + Report | Kundendots + Bericht sichtbar |
| **M8** | ShopDetail + Management-Screens | Voller Core-Loop spielbar |
| **M9** | Balancing-Parität mit Flutter, Polish, Sound | Playtest §0–§5 (analog PLAYTEST_SCRIPT_MVP) |

Reihenfolge zwingend M0→M3 (Fundament), danach M5/M6 (sichtbares 3D) parallel
zu M4 möglich.

---

## 6. Risiken / Tradeoffs

| Risiko | Mitigation |
|--------|------------|
| **Kompletter Logik-Rewrite** (~17k LOC Dart) | Modulweise portieren, jede Engine gegen bestehende Flutter-Tests spiegeln. Logik existiert bereits — nur Übersetzung. |
| **3D-Assets fehlen** | MVP mit Asset-Store-Low-Poly-City; eigene Modelle später. |
| **Save-Inkompatibilität** Flutter↔Unity | JSON-Feldnamen exakt übernehmen; Roundtrip-Test in M2. |
| **Mobile-Performance** (3D + viele Dots) | URP, GPU-Instancing, LODs, Dot-Pooling. |
| **Doppelte Codebasis** (Flutter + Unity) | Flutter „einfrieren" sobald Unity M8 erreicht; nicht beide pflegen. |
| **Determinismus/RNG** weicht von Flutter ab | Seedbare RNG, gleiche Verteilungslogik wie Dart. |
| **Scope-Explosion** (Coffee-Inc-Vergleich) | Non-Goals aus DOENER_EMPIRE_3D_REDESIGN.md gelten weiter (kein begehbares 3D, keine Innenraum-Sim). |

---

## 7. Nächste konkrete Schritte

1. **Owner:** Unity Hub + Unity 6 LTS (Android-Modul) + .NET 8 SDK installieren.
2. **Owner oder ich:** Leeres Unity-URP-Mobile-Projekt unter `unity/` anlegen
   (Editor-gebunden — muss einmalig im Editor erzeugt werden).
3. **Ich/Codex:** Daten-Layer-Port (M1) in `unity/Assets/Scripts/` ablegen —
   eine Foundation-Slice liegt bereits unter `unity/Assets/Scripts/` als Start.
4. Pro Meilenstein: portieren → `dotnet test` gegen gespiegelte Erwartungswerte →
   im Editor verdrahten → auf Tablet verifizieren.

> **Toolchain-Hinweis:** Bis Unity + .NET installiert sind, ist der hier
> abgelegte C#-Code **nicht kompiliert/getestet**. Er ist eine sorgfältige,
> review-fähige Übersetzung der vollständig gelesenen Dart-Quellen und dient als
> Startpunkt für M1.
