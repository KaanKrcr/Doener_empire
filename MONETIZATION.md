# MONETIZATION.md — Döner Empire

> **Oberstes Gebot: Kein Pay2Win. Niemals.**
> Echtgeld kauft in Döner Empire **niemals** Spielvorteil, Fortschritt,
> Geschwindigkeit, Währung mit Spielnutzen oder Wettbewerbsvorteil.
> In-App-Käufe sind **ausschließlich kosmetisch** oder ein **optionaler,
> vorteilsfreier Chaos-Modus**.

---

## 1. Grundsätze (nicht verhandelbar)

| ✅ Erlaubt                                  | ❌ Verboten                                   |
|--------------------------------------------|-----------------------------------------------|
| Kosmetische Items (Skins, Themes, Deko)    | Spielwährung kaufen, die Vorteil bringt       |
| Optionaler Chaos-Modus (Spaß, kein Vorteil)| Upgrades/Equipment/Personal für Echtgeld      |
| DLC-Inhalte (neue Städte/Länder/Szenarien) | Zeit-Skip / Boost / „schneller verdienen"     |
| Einmaliger „Supporter"-Kauf (Dankeschön)   | Energie-/Lebens-Systeme, Lootboxen, Gacha     |
| Werbefrei-Kauf (falls je Werbung käme)     | Paywalls vor Core-Loop-Inhalten               |

**Fairness-Test für jede neue Kaufoption:** „Verschafft das einem zahlenden
Spieler *irgendeinen* mechanischen Vorteil gegenüber einem nicht zahlenden?"
→ Bei *Ja*: **nicht umsetzen.**

---

## 2. MVP-Monetarisierung

**Keine.** Das MVP wird **komplett kostenlos und ohne IAP** ausgeliefert.
Erst nach validierter Retention werden Monetarisierungs-Schritte aktiviert.
So bleibt der Core Loop sauber bewertbar.

---

## 3. Roadmap nach MVP (in dieser Reihenfolge)

### Stufe 1 — Kosmetik 🎨
Rein optische Personalisierung, **null Gameplay-Effekt**:
- **Marken-Skins:** Logo-/Farb-Sets, Schaufenster-Deko der Filialen.
- **City-Map-Themes:** alternative Map-Styles (Tag/Nacht, Retro, Neon).
- **Geld-/Konfetti-FX-Pakete:** andere Animationen beim Tagesabschluss.
- **Modell:** Einzelkauf je Item oder thematische Bundles.

### Stufe 2 — Chaos-Modus 🌶️ (optionaler Zusatzmodus)
Ein **separater Spielmodus** für Spaß & Wiederspielwert — kauf **freischaltend**,
aber ohne Vorteil für den normalen Karrieremodus:
- Überdrehte Events (Touristen-Ansturm, Soßen-Krise, Konkurrenz-Wahnsinn).
- Eigene Bestenliste/Scoring, **getrennt** vom normalen Spielstand.
- Bringt **keine** Vorteile, Währung oder Upgrades in den Hauptmodus zurück.
- **Modell:** einmaliger Kauf, der den Modus dauerhaft freischaltet.

### Stufe 3 — DLCs 🌍
Inhalts-Erweiterungen, die das Spiel *verbreitern*, nicht *erleichtern*:
- Neue Länder/Stadt-Pakete (eigene Städte, Standort-Typen, Events).
- Neue Szenarien/Start-Konstellationen als Herausforderung.
- **Fairness:** DLC-Städte folgen denselben Balancing-Regeln (`BALANCING.md`);
  sie sind **nicht** profitabler/schneller als Basis-Inhalte — nur *neu*.
- **Modell:** einmaliger Kauf pro DLC-Paket.

---

## 4. Technische Umsetzung (Ausblick)

- **Entitlement-Schicht** (z. B. `services/store_service.dart`, Post-MVP):
  kapselt Käufe und liefert nur **Flags** (`hasSkin(x)`, `chaosUnlocked`,
  `ownsDlc(id)`).
- Die Simulation (`game_engine.dart`) **liest niemals** Kaufzustände, die
  Wirtschaftswerte verändern — sie kennt nur Spielmechanik.
- Kosmetik-Flags wirken **ausschließlich** in der UI-Schicht (`lib/ui/...`).
- Käufe sind an die Store-Plattform gebunden (Google Play / App Store),
  Wiederherstellung („Restore Purchases") wird unterstützt.

---

## 5. Was wir bewusst NICHT tun

- Keine Lootboxen, kein Gacha, keine Zufallskäufe.
- Keine zeitbasierten Energiesysteme oder „warte oder zahle".
- Keine doppelte Spielwährung mit Echtgeld-Brücke.
- Keine FOMO-Timer auf Core-Inhalte.
- Keine Werbung im MVP (falls je, dann opt-in / belohnungsfrei oder werbefrei-Kauf).

> Wenn eine Monetarisierungs-Idee nicht eindeutig in *Kosmetik*, *Chaos-Modus*
> oder *DLC* fällt — gehört sie nicht ins Spiel.
