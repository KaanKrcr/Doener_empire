/// Spiel-Events die am Tagesende zufällig auftreten und dem Spieler
/// echte Entscheidungen abverlangen.
class GameEvent {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final EventCategory category;
  final List<EventChoice> choices;

  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.choices,
  });
}

enum EventCategory { good, bad, neutral, opportunity }

class EventChoice {
  final String label;
  final EventEffect effect;
  final String? requirement; // Optional: nur sichtbar wenn z.B. genug Geld
  final double? cost;

  const EventChoice({
    required this.label,
    required this.effect,
    this.requirement,
    this.cost,
  });
}

class EventEffect {
  final double cashDelta;
  final double reputationDelta;
  final String resultMessage;

  const EventEffect({
    this.cashDelta = 0,
    this.reputationDelta = 0,
    required this.resultMessage,
  });
}

/// Pool an verfügbaren Events. Werden zufällig gezogen mit Gewichtung
/// nach Categories (good/bad/neutral).
const List<GameEvent> kAllEvents = [
  // ── BAD ─────────────────────────────────────────────────────────────
  GameEvent(
    id: 'hygiene_inspection',
    title: 'Lebensmittelkontrolle!',
    description:
        'Ein Lebensmittelkontrolleur steht plötzlich vor der Tür einer deiner Filialen. Was tust du?',
    emoji: '🔍',
    category: EventCategory.bad,
    choices: [
      EventChoice(
        label: 'Ordnungsgemäß empfangen',
        effect: EventEffect(
          cashDelta: -300,
          reputationDelta: 0.1,
          resultMessage:
              'Kleinere Mängel — 300 € Bußgeld, aber die Kontrolle lobt die Sauberkeit.',
        ),
      ),
      EventChoice(
        label: '500 € „Trinkgeld" anbieten',
        effect: EventEffect(
          cashDelta: -500,
          reputationDelta: -0.5,
          resultMessage:
              'Bestechung angenommen — aber das Gerücht macht die Runde. Reputation −0,5.',
        ),
        cost: 500,
      ),
      EventChoice(
        label: 'Kontrolleur ignorieren',
        effect: EventEffect(
          cashDelta: -2000,
          reputationDelta: -0.8,
          resultMessage:
              'Geschäft musste schließen für einen Tag. 2.000 € Strafe, schwerer Reputationsverlust.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'employee_sick',
    title: 'Mitarbeiter krank gemeldet',
    description:
        'Einer deiner Mitarbeiter ist krank. Wie reagierst du?',
    emoji: '🤒',
    category: EventCategory.bad,
    choices: [
      EventChoice(
        label: 'Krankschreibung akzeptieren',
        effect: EventEffect(
          cashDelta: -150,
          reputationDelta: 0.05,
          resultMessage: 'Lohnfortzahlung kostet, aber das Team weiß es zu schätzen.',
        ),
      ),
      EventChoice(
        label: 'Aushilfe für 1 Tag mieten (400 €)',
        effect: EventEffect(
          cashDelta: -400,
          resultMessage: 'Aushilfe gefunden — Tagesbetrieb läuft ohne Einbußen.',
        ),
        cost: 400,
      ),
    ],
  ),
  GameEvent(
    id: 'supplier_problem',
    title: 'Lieferant streikt',
    description:
        'Dein Fleisch-Lieferant kann heute nicht liefern. Was tust du?',
    emoji: '🚛',
    category: EventCategory.bad,
    choices: [
      EventChoice(
        label: 'Notlieferant beauftragen (+50% Kosten)',
        effect: EventEffect(
          cashDelta: -800,
          resultMessage: 'Teurer Notdeal, aber der Laden läuft weiter.',
        ),
        cost: 800,
      ),
      EventChoice(
        label: 'Mit weniger Auswahl arbeiten',
        effect: EventEffect(
          cashDelta: -1200,
          reputationDelta: -0.2,
          resultMessage: 'Kunden enttäuscht — 1.200 € Umsatzverlust.',
        ),
      ),
    ],
  ),

  // ── GOOD / OPPORTUNITY ──────────────────────────────────────────────
  GameEvent(
    id: 'viral_tiktok',
    title: 'Viraler TikTok!',
    description:
        'Ein Influencer hat deinen Imbiss auf TikTok gezeigt — Tausende von Aufrufen! 🎉',
    emoji: '📱',
    category: EventCategory.good,
    choices: [
      EventChoice(
        label: 'Auf der Welle reiten',
        effect: EventEffect(
          cashDelta: 1500,
          reputationDelta: 0.5,
          resultMessage:
              'Viele neue Kunden strömen — Tagesumsatz +1.500 €, Reputation +0,5.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'food_blogger',
    title: 'Food-Blogger anwesend',
    description:
        'Ein bekannter Food-Blogger isst gerade bei dir. Bietest du ihm ein Sonder-Tasting an?',
    emoji: '✍️',
    category: EventCategory.opportunity,
    choices: [
      EventChoice(
        label: 'Sonder-Tasting anbieten (kostenlos)',
        effect: EventEffect(
          cashDelta: -100,
          reputationDelta: 0.4,
          resultMessage:
              'Tolle Bewertung im Blog — Reputation steigt deutlich.',
        ),
      ),
      EventChoice(
        label: 'Normal bedienen',
        effect: EventEffect(
          cashDelta: 20,
          reputationDelta: 0.05,
          resultMessage:
              'Nette Erwähnung im Blog — kleine Reputations-Steigerung.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'football_event',
    title: 'Fußball-WM-Übertragung',
    description:
        'Heute spielt die deutsche Mannschaft. Eine Sport-Bar nebenan fragt nach Catering.',
    emoji: '⚽',
    category: EventCategory.opportunity,
    choices: [
      EventChoice(
        label: 'Großes Catering liefern (Aufwand)',
        effect: EventEffect(
          cashDelta: 2500,
          reputationDelta: 0.2,
          resultMessage:
              'Catering perfekt geliefert — 2.500 € extra Umsatz!',
        ),
      ),
      EventChoice(
        label: 'Klein bleiben',
        effect: EventEffect(
          cashDelta: 300,
          resultMessage: 'Ein paar Walk-ins durch die Sport-Welle.',
        ),
      ),
    ],
  ),

  // ── NEUTRAL / WETTER ────────────────────────────────────────────────
  GameEvent(
    id: 'heatwave',
    title: 'Hitzewelle',
    description:
        '38 °C in der Stadt! Die Leute wollen heute weniger heißen Döner, aber dafür kalte Getränke.',
    emoji: '☀️',
    category: EventCategory.neutral,
    choices: [
      EventChoice(
        label: 'Ayran-Aktion fahren',
        effect: EventEffect(
          cashDelta: 800,
          resultMessage: 'Ayran-Verkauf explodiert — 800 € Extra!',
        ),
      ),
      EventChoice(
        label: 'Normal weitermachen',
        effect: EventEffect(
          cashDelta: -400,
          resultMessage: 'Weniger Kunden bei der Hitze — 400 € weniger.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'rainy_day',
    title: 'Dauerregen',
    description:
        'Den ganzen Tag schüttet es. Wenige Passanten heute.',
    emoji: '🌧️',
    category: EventCategory.neutral,
    choices: [
      EventChoice(
        label: 'Lieferdienst anbieten (300 € Aufbau)',
        effect: EventEffect(
          cashDelta: 600,
          resultMessage: 'Lieferaufträge gleichen den Ausfall aus — +600 € netto.',
        ),
        cost: 300,
      ),
      EventChoice(
        label: 'Personal eher gehen lassen',
        effect: EventEffect(
          cashDelta: -200,
          resultMessage: 'Halber Tag = weniger Lohnkosten, aber auch weniger Umsatz.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'rival_open',
    title: 'Konkurrenz eröffnet nebenan',
    description:
        'Ein neuer Imbiss eröffnet in der Nachbarschaft einer Filiale.',
    emoji: '🆚',
    category: EventCategory.bad,
    choices: [
      EventChoice(
        label: 'Rabatt-Aktion starten',
        effect: EventEffect(
          cashDelta: -500,
          reputationDelta: 0.2,
          resultMessage:
              'Stammkundschaft bleibt dank Aktion treu.',
        ),
      ),
      EventChoice(
        label: 'Qualität betonen, keine Aktion',
        effect: EventEffect(
          cashDelta: -800,
          reputationDelta: -0.1,
          resultMessage:
              'Einige Kunden probieren die Konkurrenz aus — kleiner Verlust.',
        ),
      ),
    ],
  ),
];
