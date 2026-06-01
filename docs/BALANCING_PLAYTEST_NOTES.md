# BALANCING_PLAYTEST_NOTES — Manuelle Beobachtungen

Stand: 2026-06-01
Zweck: Sammelstelle für **subjektive** Balancing-Beobachtungen aus Playtests.
Ergänzt [PLAYTEST_SCRIPT_MVP.md](PLAYTEST_SCRIPT_MVP.md) (Bugs) und gibt Codex
Datengrundlage für Nach-Tuning.

Pro Run:
- Tester-Initialen + Datum + Build-Hash (oder `git rev-parse --short HEAD`).
- Schwierigkeit.
- Startstadt.
- Genau **eine Zeile pro Frage** in der Tabelle.

Wenn ein Run vorzeitig abbricht (Frust, Bug, Zeit): notieren mit
`abandoned@day=X`.

---

## 1. Pro-Run-Tabelle

Eine Tabelle pro Schwierigkeit. Neue Zeilen unten anhängen.

### 1.1 Easy

| Datum      | Tester | Build  | Startstadt | Filiale profitabel ab Tag | Kapazitäts-Engpass ab Tag | Ausbau gemacht an Tag | Konkurrenz spürbar ab Tag | Erster Buyout-Versuch (Tag, Erfolg?) | Notiz / Frust-Punkt |
|------------|--------|--------|------------|---------------------------|----------------------------|------------------------|---------------------------|--------------------------------------|---------------------|
| YYYY-MM-DD |        |        |            |                           |                            |                        |                           |                                      |                     |

### 1.2 Normal

| Datum      | Tester | Build  | Startstadt | Filiale profitabel ab Tag | Kapazitäts-Engpass ab Tag | Ausbau gemacht an Tag | Konkurrenz spürbar ab Tag | Erster Buyout-Versuch (Tag, Erfolg?) | Notiz / Frust-Punkt |
|------------|--------|--------|------------|---------------------------|----------------------------|------------------------|---------------------------|--------------------------------------|---------------------|
| YYYY-MM-DD |        |        |            |                           |                            |                        |                           |                                      |                     |

### 1.3 Hard

| Datum      | Tester | Build  | Startstadt | Filiale profitabel ab Tag | Kapazitäts-Engpass ab Tag | Ausbau gemacht an Tag | Konkurrenz spürbar ab Tag | Erster Buyout-Versuch (Tag, Erfolg?) | Notiz / Frust-Punkt |
|------------|--------|--------|------------|---------------------------|----------------------------|------------------------|---------------------------|--------------------------------------|---------------------|
| YYYY-MM-DD |        |        |            |                           |                            |                        |                           |                                      |                     |

### 1.4 Impossible

| Datum      | Tester | Build  | Startstadt | Filiale profitabel ab Tag | Kapazitäts-Engpass ab Tag | Ausbau gemacht an Tag | Konkurrenz spürbar ab Tag | Erster Buyout-Versuch (Tag, Erfolg?) | Notiz / Frust-Punkt |
|------------|--------|--------|------------|---------------------------|----------------------------|------------------------|---------------------------|--------------------------------------|---------------------|
| YYYY-MM-DD |        |        |            |                           |                            |                        |                           |                                      |                     |

---

## 2. Soll-Korridore (Design-Erwartung)

Werte sind **Designziel**, nicht harte Anforderung. Abweichungen >50 % gehören
in den Tuning-Backlog.

| Frage                                | Easy        | Normal      | Hard        | Impossible    |
|--------------------------------------|-------------|-------------|-------------|---------------|
| Erste Filiale profitabel ab Tag      | 2–3         | 3–5         | 5–8         | 8–14          |
| Erster Kapazitäts-Engpass ab Tag     | 4–6         | 6–10        | 10–14       | 12–20         |
| Erster Ausbau (`klein→mittel`) ab Tag| 8–12        | 12–18       | 18–28       | 25–40         |
| Konkurrenz reagiert spürbar ab Tag   | 10–14       | 7–10        | 4–6         | 2–4           |
| Erster Buyout möglich ab Cash        | ~120k       | ~200k       | ~300k       | ~400k         |
| Erste Stadt 2 freigeschaltet ab Tag  | 12–18       | 18–25       | 25–35       | 35–55         |

---

## 3. Vergleichsfragen — Auswertungs-Block

Nach **mindestens 3 Runs** pro Schwierigkeit:

### 3.1 „Wann wird die erste Filiale profitabel?"
- Easy: _____ (Median)
- Normal: _____ (Median)
- Hard: _____ (Median)
- Impossible: _____ (Median)

→ Wenn Easy ≈ Normal: `customerPriceSensitivityMultiplier` für Easy weiter
nach unten (0.65 → 0.55).
→ Wenn Impossible nie profitabel wird (>30 Tage): `economicPressureMultiplier`
für Impossible reduzieren oder Startkapital anheben.

### 3.2 „Wann entsteht das erste Kapazitäts-Problem?"
- Easy: _____
- Normal: _____
- Hard: _____
- Impossible: _____

→ Wenn früher als Soll-Korridor: Capacity-Multi zu niedrig oder
Customer-Boost-Kampagnen zu stark.
→ Wenn nie: Stadt-Traffic zu niedrig oder Filiale zu effizient.

### 3.3 „Wann braucht man den ersten Ausbau (`mittel`)?"
- Easy: _____
- Normal: _____
- Hard: _____
- Impossible: _____

→ Wenn nie freiwillig gemacht: Ausbau-Kosten zu hoch oder Trade-off zu
schwach → Cap-Multi prüfen.
→ Wenn sofort am Tag 5: Ausbau-Kosten zu niedrig oder Personal-Cap zu
niedrig.

### 3.4 „Wie stark reagiert die Konkurrenz?"
Skala 1–5 (1 = ignoriert mich, 5 = übermächtig).

| Schwierigkeit | Run 1 | Run 2 | Run 3 | Median |
|---------------|-------|-------|-------|--------|
| Easy          |       |       |       |        |
| Normal        |       |       |       |        |
| Hard          |       |       |       |        |
| Impossible    |       |       |       |        |

→ Soll: Easy 1–2, Normal 2–3, Hard 3–4, Impossible 4–5.

### 3.5 „Ist Buyout zu stark / zu schwach?"
Skala −2 (viel zu schwach) … 0 (genau richtig) … +2 (viel zu stark).

| Schwierigkeit | Run 1 | Run 2 | Run 3 | Median |
|---------------|-------|-------|-------|--------|
| Easy          |       |       |       |        |
| Normal        |       |       |       |        |
| Hard          |       |       |       |        |
| Impossible    |       |       |       |        |

→ Wenn Buyout durchgängig +1/+2 (zu stark): `marketCap`-Faktor von 1.5 auf
1.8 erhöhen → Preis steigt.
→ Wenn −1/−2 (zu schwach): Ruf-Multi von 0.7 auf 0.8, oder Personal-Anteil
von 30 % auf 40 %.

---

## 4. Frust-Punkte (Freitext-Sammlung)

Format: `[Datum] [Tester] [Difficulty] [Tag] — Beobachtung`.

Beispiele für die Art Eintrag, die hier rein soll:
- `2026-06-02 KK Normal Tag 7 — Kapazitäts-Hint kommt zu spät, Filiale war schon 3 Tage limitiert.`
- `2026-06-02 KK Hard Tag 11 — Konkurrenz spawnt 2 neue Filialen in 3 Tagen, fühlt sich willkürlich an.`

```
[YYYY-MM-DD] [Tester] [Diff] [Tag] —
```

---

## 5. „Funktioniert besser als erwartet" (Positiv-Liste)

Wenn etwas auffallend gut wirkt, hier eintragen — verhindert, dass beim
nächsten Tuning ein gutes System „aus Versehen" geschwächt wird.

```
[YYYY-MM-DD] [Tester] [Diff] [Tag] —
```

---

## 6. Tuning-Backlog (von Beobachtungen abgeleitet)

Wenn aus §3 oder §4 ein konkreter Tuning-Vorschlag entsteht, hier als
Tabelle. Jeder Eintrag braucht **Beobachtung → Vorschlag → Erwartete Wirkung**.

| Datum      | Beobachtung                                    | Vorschlag                                                | Erwartete Wirkung                          | Status     |
|------------|------------------------------------------------|----------------------------------------------------------|--------------------------------------------|------------|
| YYYY-MM-DD |                                                |                                                          |                                            | offen      |

Status-Werte: `offen` / `geprüft` / `umgesetzt` / `verworfen`.
