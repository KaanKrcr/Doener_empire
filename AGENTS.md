# AGENTS.md — Döner Empire 3D

These instructions are for Codex, Claude Code, OpenClaw, and other coding agents working in this repository.

## Read First
Before changing gameplay UI or product direction, read:

- `docs/UI_STYLE_GUIDE.md`
- `docs/DOENER_EMPIRE_3D_REDESIGN.md`
- `docs/MVP_3D_CITY_MAP.md`

Treat `docs/UI_STYLE_GUIDE.md` as the source of truth for visual direction.

## Product Direction
Döner Empire 3D is a **premium mobile business simulation**.

The target feel:

- dark, refined management UI
- warm döner/fire/orange accents
- cream typography
- city map as the main stage
- bottom-sheet driven decisions
- Coffee-Inc.-inspired business depth, but original identity

The game should feel like a serious but warm tycoon sim — not a generic clicker, idle-game button wall, or SaaS dashboard.

## Core UI Rules
- The **City Map** is the primary visual workspace.
- Use fewer, stronger panels instead of many generic cards.
- Keep every screen decision-focused.
- Every UI element should help the player answer: “What should I do next?”
- Use `AppColors`, `AppText`, and the existing theme tokens before introducing new styling.
- Use orange for primary actions/highlights, green for positive ownership/performance, red for risk/competition/loss.
- Keep copy short, operational, and specific.

Good UI copy:

- `Kapazität limitiert: 38 Kunden verloren`
- `Preis wirkt hoch für Uni-Viertel`
- `Bahnhof braucht Tempo, nicht Premium-Zutaten`

Avoid:

- generic marketing slogans
- cluttered stat walls
- bright cartoon restaurant-game UI
- unnecessary decorative cards

## Architecture Rules
- Preserve existing simulation systems unless explicitly asked to change them.
- Prefer adapting existing models/services over creating parallel systems.
- Keep changes small, reviewable, and testable.
- Separate visual/UI changes from balancing/gameplay logic changes.
- Do not rewrite the project into Unity/Godot unless explicitly requested.

Important existing systems:

- `GameState`
- `Shop`
- `CityData`
- `LocationTemplate`
- `GameEngine`
- `CompetitorEngine`
- `LocationEngine`
- `CityMapScreen`
- `CityMapView`

## Recommended Workflow
1. Read the relevant docs listed above.
2. State the intended change briefly.
3. Make the smallest useful diff.
4. Run validation:
   - `flutter analyze`
   - relevant `flutter test` commands
5. Report:
   - what changed
   - files touched
   - validation result
   - remaining risks

If Flutter is not available in the environment, say so clearly and still run lightweight checks such as `git diff --check`.

## Current Visual Reference
Primary UI concept image:

- `docs/assets/doener_empire_mobile_premium_ui.png`

Use it as a mood and hierarchy reference, not as a pixel-perfect target.

## Current MVP Direction
The current MVP direction is:

- pseudo-3D/isometric city map in Flutter
- selectable city hotspots
- location/shop details in a bottom-sheet style panel
- existing economy simulation behind the visual layer
- future additions: animated customer flow, competitor influence zones, market-share overlays

## Non-Goals
Do not introduce these unless the user explicitly asks:

- full 3D engine rewrite
- indoor restaurant simulation
- manual cooking gameplay
- multiplayer
- complex traffic/logistics simulation
- generic dashboard redesign disconnected from the city map
