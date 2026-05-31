# Döner Empire 3D — Mobile Premium UI Style Guide

## Visual Thesis
Döner Empire 3D wirkt wie eine hochwertige mobile Business-Simulation: dunkle, ruhige Management-Oberfläche, warme Döner-/Feuer-Akzente und eine isometrische City-Map als emotionale Hauptbühne.

## Design Pillars
1. **City first** — Die Stadtkarte ist der Star, nicht das Dashboard.
2. **Premium statt verspielt** — Wenige Farben, klare Typografie, ruhige Flächen.
3. **Entscheidungen sichtbar machen** — Jede Zahl muss zu einer Handlung führen.
4. **Warm business** — Business-Sim-Seriosität, aber mit Food-Tycoon-Wärme.
5. **Mobile readable** — Alles muss auf einem Smartphone in 3 Sekunden scannbar sein.

## Mood Keywords
- Premium
- Warm
- Unternehmerisch
- Isometrisch
- Kompakt
- Ruhig
- Taktisch
- Coffee-Inc.-inspiriert, aber eigenständig

## Color System
Bestehende App-Farben bleiben Grundlage, werden aber strenger eingesetzt.

### Core Colors
- Background: `#14100E` — dunkles Holzbraun
- Surface: `#1F1813` — dunkle Panel-Fläche
- Elevated Surface: `#241B15` — Bottom Sheets / Detailflächen
- Primary Accent: `#E85D2F` — geröstetes Orange
- Secondary Accent: `#FFB347` — warmes Curry-Gelb
- Success: `#7BC950` — Salat-Grün
- Danger / Competitor: `#E74C3C` — Tomaten-Rot
- Text Primary: `#FAF4E8` — Cremeweiß
- Text Secondary: `#C4B5A0` — Sand
- Text Muted: `#7A6A5C` — gedämpftes Braun

### Usage Rules
- Orange nur für primäre Aktionen, aktive States und wichtige Highlights.
- Grün nur für positive Performance oder eigene Expansion.
- Rot nur für Risiko, Konkurrenz oder Verlust.
- Keine bunten Icon-Cluster. Maximal 1–2 Akzentfarben pro Screen.
- Große Flächen bleiben dunkel und ruhig.

## Typography
### Display / Numbers
- Font: `Baloo2`
- Einsatz: Cash, Screen-Titel, große KPIs, Stadtname
- Wirkung: freundlich, markant, food-tycoon passend

### Body / UI
- Font: `Inter`
- Einsatz: Labels, Erklärtexte, Tabellen, Buttons
- Wirkung: seriös, lesbar, modern

### Rules
- Screen-Titel: 20–24 px
- Große KPI-Zahl: 22–34 px
- Labels: 10–12 px, uppercase optional, hoher Letter-Spacing
- Body: 12–14 px
- Keine langen Marketing-Texte im Produkt-UI.

## Layout Structure
### Default Mobile Screen
1. **Top Bar**
   - Company name / city name
   - Cash balance
   - Day counter or quick status

2. **Primary Visual Area**
   - Isometric city map
   - Filialen, Hotspots, Konkurrenz, Kundenströme
   - Minimal overlay only

3. **Context Bottom Sheet**
   - Selected location/shop
   - 3–5 decisive KPIs
   - 1 primary action
   - 1 optional secondary action

4. **Navigation**
   - Bottom navigation remains simple
   - Recommended tabs: City, Dashboard, Shops, Finance, Corporate

## City Map Direction
### Visual Style
- Isometric / pseudo-3D low-poly city
- Warm street lights, dark base, orange shop glow
- Buildings are background texture, not clutter
- Hotspots must be readable as tappable markers

### Map Objects
- Own shop: green/orange highlight, kebab icon, subtle glow
- Competitor: muted red marker, less visual dominance
- Hotspot: icon + score or status
- Customer flow: small dots or short animated trails
- Market share: optional soft influence zones

### Do
- Use large tap targets
- Keep labels short
- Show one selected location clearly
- Animate customer flow only when it explains demand

### Avoid
- Realistic city simulation complexity
- Tiny buildings with unreadable details
- Too many floating badges
- Full 3D camera controls in MVP

## Components
### Bottom Sheet: Selected Location
Required content:
- Location name
- Audience / personality
- Foot traffic
- Weekly rent
- Reputation or expected reputation
- Market share or competition pressure
- One recommendation line
- Primary action button

Example actions:
- `Filiale eröffnen`
- `Optimieren`
- `Marketing starten`
- `Personal erhöhen`

### KPI Tiles
Use sparingly. Max 4 per row/section.

Recommended KPIs:
- Cash
- Tagesgewinn
- Kunden heute
- Ruf
- Marktanteil
- Kapazitätsauslastung

### Buttons
Primary:
- Orange filled
- Verb-focused label
- Example: `Filiale eröffnen`, `Tag abschließen`, `Optimieren`

Secondary:
- Dark/outlined
- Lower emphasis
- Example: `Details`, `Vergleichen`, `Zurück`

Danger:
- Red only for irreversible/risky actions
- Example: `Filiale schließen`

## Motion Direction
Motion should make the business feel alive, not noisy.

### Required Motion Ideas
1. **Map entrance**
   - City fades/slides in subtly when opened.

2. **Hotspot selection**
   - Selected marker scales up slightly.
   - Bottom sheet content crossfades.

3. **Day simulation**
   - Customer dots move toward shops.
   - Revenue pulses above owned shops.
   - Competitor action appears as short red ping.

4. **Performance feedback**
   - Profit up: soft green pulse
   - Capacity limit: amber warning pulse
   - Reputation drop: brief red review bubble

### Avoid
- Confetti for normal actions
- Constant bouncing UI
- Large decorative animations over dense information

## Screen-Level Guidance
### City Screen
Primary purpose: choose where to expand or optimize.

Must show:
- city map
- current shops
- available hotspots
- selected hotspot panel

Should not show:
- full financial history
- long shop lists
- unrelated campaign content

### Dashboard Screen
Primary purpose: decide what needs attention today.

Must show:
- cash
- today profit/revenue/customers
- top 3 alerts
- next recommended action

Should not become a card mosaic.

### Shop Detail Screen
Primary purpose: optimize one branch.

Must show:
- selected shop identity
- reputation
- capacity vs demand
- menu/prices
- staff/equipment bottlenecks
- recommended next fix

### Finance Screen
Primary purpose: understand cashflow.

Must show:
- trend
- revenue/cost/profit split
- rent, salary, ingredients
- forecast if no action changes

## Copy Style
Use practical operator language.

Good:
- `Kapazität limitiert: 38 Kunden verloren`
- `Preis wirkt hoch für Uni-Viertel`
- `Marketing bringt Traffic, aber Wartezeit senkt Ruf`
- `Bahnhof braucht Tempo, nicht Premium-Zutaten`

Avoid:
- `Baue dein ultimatives Imperium auf!`
- `Werde der beste Dönerboss!`
- `Mega krasse Expansion!`

## Implementation Notes For Agents
When changing UI:
1. Start from the City Map and bottom sheet model.
2. Keep existing simulation systems intact unless explicitly asked.
3. Reuse `AppColors`, `AppText`, and existing theme tokens.
4. Prefer fewer, stronger panels over many cards.
5. Every new UI element must answer: what decision does this help the player make?

## Reference Asset
Primary visual target:

`docs/assets/doener_empire_mobile_premium_ui.png`

Use it as mood/reference, not as exact UI to copy pixel-for-pixel.

## Non-Goals
- No generic SaaS dashboard aesthetic
- No bright cartoon restaurant game UI
- No cluttered idle-game button wall
- No realistic city-builder complexity
- No full 3D rewrite required for the MVP

## Acceptance Checklist
Before considering a UI change done:
- [ ] City/selected shop is visually dominant
- [ ] Primary action is obvious
- [ ] Max 3–5 major KPIs visible in one context
- [ ] Colors are restrained
- [ ] Text is short and operational
- [ ] UI works on phone-sized screens
- [ ] Existing simulation logic remains compatible
