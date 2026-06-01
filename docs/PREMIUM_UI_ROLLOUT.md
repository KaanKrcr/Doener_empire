# Premium UI Rollout Status

## Premium-ready Screens
- Dashboard
- City Map
- Open Shop
- Shop-Detail (inkl. Personal-Tab)
- Tagesabschluss-Dialog
- Cities
- Finance
- Stats / Konkurrenz
- Corporate / M&A / zentrale Konzern-Übersicht
- Settings (Premium-Sections + Status-Hints)
- Achievements
- Campaign
- Weekly Report Dialog
- Quarterly Report Dialog
- Bankruptcy Dialog

## Noch offen / nur teilweise angepasst
- Einzelne tiefe Unterbereiche in sehr großen Screens (z. B. alle Corporate-Submodule) sind nur punktuell poliert.
- Einige Legacy-Dialoge in Randbereichen (z. B. seltene Bestätigungsdialoge) nutzen noch Standard-`AlertDialog`.
- Feintuning von Animationen ist absichtlich konservativ gehalten (kein schweres Motion-Upgrade).

## Angewendete UI-Regeln
- Einheitliche Abschnittsstruktur mit `PremiumSectionLabel`.
- KPI-Hierarchie über `PremiumMetricStrip` statt loser Textblöcke.
- Entscheidungsflächen über `PremiumDecisionSheet` statt gemischter Card-Stile.
- Status-Kommunikation über `PremiumStatusHint` mit klaren Tönen:
  - `success` für stabile/positive Lage
  - `warning` für Handlungsbedarf
  - `danger` für kritische Risiken
- Empty States enthalten konkrete nächste Aktion statt nur „keine Daten“.
- Mobile-first Spacing und kurze, operative Copy gemäß `docs/UI_STYLE_GUIDE.md`.

## Bekannte Risiken / Follow-ups
- Sehr lange Labels in einzelnen dynamischen KPI-Werten können auf kleinen Displays weiterhin kürzen (Ellipsis), funktional aber stabil.
- Für volle Konsistenz sollten verbleibende seltene Dialoge in einem separaten kleinen Follow-up auf Premium-Sheets umgestellt werden.
- Optionales QA-Follow-up: visuelle Snapshot-Prüfung auf 360px Breite für Textumbrüche in Campaign/Achievements.
