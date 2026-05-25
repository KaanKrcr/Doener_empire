/// Spiel-Events die am Tagesende zufällig auftreten und dem Spieler
/// echte Entscheidungen abverlangen.
///
/// Events haben:
/// * eine Kategorie (good/bad/neutral/opportunity)
/// * 2-3 Choice-Optionen mit klaren Konsequenzen
/// * optional Anforderungen (z.B. minShops, hasMetropolitan)
/// * teilweise mehrtägige Auswirkungen (über brand/reputation)
class GameEvent {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final EventCategory category;
  final List<EventChoice> choices;
  final EventRequirements requirements;
  final EventWeight weight;

  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.choices,
    this.requirements = const EventRequirements(),
    this.weight = EventWeight.normal,
  });
}

enum EventCategory { good, bad, neutral, opportunity }

enum EventWeight { rare, normal, common }

class EventRequirements {
  final int minShops;
  final int minDay;
  final double minCash;
  final bool needsMetropolitanShop;

  const EventRequirements({
    this.minShops = 1,
    this.minDay = 0,
    this.minCash = 0,
    this.needsMetropolitanShop = false,
  });
}

class EventChoice {
  final String label;
  final EventEffect effect;
  final double? cost;

  const EventChoice({
    required this.label,
    required this.effect,
    this.cost,
  });
}

class EventEffect {
  final double cashDelta;
  final double reputationDelta;       // wirkt auf ALLE Filialen
  final double brandAwarenessDelta;   // wirkt auf Marken-Bekanntheit
  final String resultMessage;

  const EventEffect({
    this.cashDelta = 0,
    this.reputationDelta = 0,
    this.brandAwarenessDelta = 0,
    required this.resultMessage,
  });
}

/// Vollständiger Event-Pool. Wird beim Tagesabschluss gewichtet gezogen.
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
        label: '500 € "Trinkgeld" anbieten',
        effect: EventEffect(
          cashDelta: -500,
          reputationDelta: -0.5,
          brandAwarenessDelta: -2.0,
          resultMessage:
              'Bestechung angenommen — aber das Gerücht macht die Runde. Reputation und Marke leiden.',
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
    weight: EventWeight.common,
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
      EventChoice(
        label: 'Selbst einspringen',
        effect: EventEffect(
          cashDelta: 100,
          reputationDelta: -0.05,
          resultMessage: 'Du sparst Geld, aber bist erschöpft — Service leidet leicht.',
        ),
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
  GameEvent(
    id: 'meat_price_shock',
    title: 'Fleischpreis-Schock',
    description:
        'Die Lammfleisch-Preise sind diese Woche um 30% gestiegen. Wie reagierst du?',
    emoji: '📈',
    category: EventCategory.bad,
    requirements: EventRequirements(minDay: 20),
    choices: [
      EventChoice(
        label: 'Preise erhöhen (+0,50 €)',
        effect: EventEffect(
          cashDelta: 0,
          reputationDelta: -0.10,
          resultMessage: 'Kunden grummeln, aber Margen bleiben stabil.',
        ),
      ),
      EventChoice(
        label: 'Marge schlucken',
        effect: EventEffect(
          cashDelta: -1500,
          reputationDelta: 0.10,
          resultMessage: 'Stammkunden danken es — aber das tut weh.',
        ),
      ),
      EventChoice(
        label: 'Auf günstigeres Hähnchen umsteigen',
        effect: EventEffect(
          cashDelta: 500,
          reputationDelta: -0.20,
          resultMessage: 'Geld gespart, aber Connaisseure schmecken den Unterschied.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'bad_review',
    title: 'Vernichtende Online-Bewertung',
    description:
        'Ein Kunde hat einen wütenden Google-Review hinterlassen ("schlimmster Döner meines Lebens"). Wie gehst du damit um?',
    emoji: '⚠️',
    category: EventCategory.bad,
    choices: [
      EventChoice(
        label: 'Professionell antworten + Gutschein anbieten',
        effect: EventEffect(
          cashDelta: -50,
          reputationDelta: 0.10,
          resultMessage:
              'Andere Kunden sehen deine ruhige Reaktion — Vertrauensgewinn.',
        ),
      ),
      EventChoice(
        label: 'Zurückkeilen ("Lügner!")',
        effect: EventEffect(
          cashDelta: 0,
          reputationDelta: -0.40,
          brandAwarenessDelta: 3.0,
          resultMessage: 'Shitstorm. Mehr Bekanntheit — aber peinliche.',
        ),
      ),
      EventChoice(
        label: 'Ignorieren',
        effect: EventEffect(
          cashDelta: 0,
          reputationDelta: -0.15,
          resultMessage: 'Der Review bleibt stehen und schreckt einige ab.',
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
    weight: EventWeight.rare,
    choices: [
      EventChoice(
        label: 'Auf der Welle reiten',
        effect: EventEffect(
          cashDelta: 1500,
          reputationDelta: 0.5,
          brandAwarenessDelta: 5.0,
          resultMessage:
              'Viele neue Kunden strömen — Tagesumsatz +1.500 €, Marke deutlich bekannter.',
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
          brandAwarenessDelta: 2.0,
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
  GameEvent(
    id: 'newspaper_feature',
    title: 'Lokalzeitung will Story',
    description:
        'Die lokale Zeitung will eine Story über Familienbetriebe machen. Du bist im Gespräch.',
    emoji: '📰',
    category: EventCategory.opportunity,
    requirements: EventRequirements(minDay: 10),
    choices: [
      EventChoice(
        label: 'Familien-Story erzählen',
        effect: EventEffect(
          reputationDelta: 0.3,
          brandAwarenessDelta: 4.0,
          resultMessage:
              'Touching Porträt erscheint. Stadt-Reputation deutlich gesteigert.',
        ),
      ),
      EventChoice(
        label: 'Höflich ablehnen (keine Zeit)',
        effect: EventEffect(
          resultMessage: 'Kein Risiko, keine Belohnung.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'wedding_catering',
    title: 'Hochzeit-Catering-Anfrage',
    description:
        'Stammkunde fragt: kannst du seine Hochzeit (200 Gäste) catern?',
    emoji: '💒',
    category: EventCategory.opportunity,
    requirements: EventRequirements(minShops: 2),
    choices: [
      EventChoice(
        label: 'Annehmen — Vorbereitung 3.000 €',
        effect: EventEffect(
          cashDelta: 5500,
          reputationDelta: 0.4,
          brandAwarenessDelta: 3.0,
          resultMessage:
              'Catering erfolgreich! 8.500 € brutto, abzgl. Kosten = +5.500 €.',
        ),
        cost: 3000,
      ),
      EventChoice(
        label: 'Höflich absagen',
        effect: EventEffect(
          resultMessage: 'Kunde versteht — keine Schäden.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'star_chef_visit',
    title: 'Sterne-Koch besucht',
    description:
        'Ein bekannter TV-Koch isst inkognito bei dir — und gibt sich danach zu erkennen!',
    emoji: '👨‍🍳',
    category: EventCategory.good,
    weight: EventWeight.rare,
    requirements: EventRequirements(minShops: 3, minDay: 30),
    choices: [
      EventChoice(
        label: 'Gemeinsames Foto + Social-Post',
        effect: EventEffect(
          reputationDelta: 0.5,
          brandAwarenessDelta: 8.0,
          resultMessage:
              'Foto geht durch die Decke. Marke bundesweit bekannter!',
        ),
      ),
      EventChoice(
        label: 'Diskret bleiben',
        effect: EventEffect(
          reputationDelta: 0.2,
          resultMessage: 'Klassische Diskretion — der Koch empfiehlt dich privat weiter.',
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
    weight: EventWeight.common,
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
    weight: EventWeight.common,
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
    id: 'oktoberfest',
    title: 'Stadtfest am Wochenende',
    description:
        'In deiner Stadt findet ein großes Volksfest statt. Massen sind unterwegs!',
    emoji: '🎪',
    category: EventCategory.opportunity,
    choices: [
      EventChoice(
        label: 'Pop-up-Stand aufstellen (1.500 €)',
        effect: EventEffect(
          cashDelta: 3800,
          reputationDelta: 0.2,
          resultMessage: 'Pop-up erfolgreich! +3.800 € netto durch das Fest.',
        ),
        cost: 1500,
      ),
      EventChoice(
        label: 'Normal bleiben, Walk-ins mitnehmen',
        effect: EventEffect(
          cashDelta: 800,
          resultMessage: '800 € extra durch Spontan-Besucher.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'employee_quit_threat',
    title: 'Mitarbeiter droht zu kündigen',
    description:
        'Dein bester Mitarbeiter hat ein Angebot von der Konkurrenz.',
    emoji: '😤',
    category: EventCategory.bad,
    requirements: EventRequirements(minShops: 2, minDay: 15),
    choices: [
      EventChoice(
        label: 'Gehaltserhöhung anbieten (500 € jetzt)',
        effect: EventEffect(
          cashDelta: -500,
          reputationDelta: 0.05,
          resultMessage: 'Mitarbeiter bleibt. Loyalität gesichert.',
        ),
        cost: 500,
      ),
      EventChoice(
        label: 'Loslassen — Glückwunsch zur neuen Stelle',
        effect: EventEffect(
          cashDelta: 0,
          reputationDelta: -0.15,
          resultMessage: 'Du verlierst Erfahrung. Andere Mitarbeiter sind nervös.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'vegan_trend',
    title: 'Veganer-Trend in der Stadt',
    description:
        'Lokale Medien feiern den Vegan-Trend. Stadt-Reputation für Imbisse mit veganem Angebot steigt.',
    emoji: '🥗',
    category: EventCategory.opportunity,
    requirements: EventRequirements(minDay: 14),
    choices: [
      EventChoice(
        label: 'Vegane Karte erweitern (800 € Marketing)',
        effect: EventEffect(
          cashDelta: -800,
          reputationDelta: 0.35,
          brandAwarenessDelta: 2.5,
          resultMessage: 'Trendsetter-Image! Hippe Kundschaft kommt.',
        ),
        cost: 800,
      ),
      EventChoice(
        label: 'Ignorieren — wir bleiben klassisch',
        effect: EventEffect(
          reputationDelta: -0.05,
          resultMessage: 'Du verpasst die Welle, aber Stammkunden bleiben.',
        ),
      ),
    ],
  ),
  GameEvent(
    id: 'tax_audit',
    title: 'Finanzamt-Prüfung',
    description:
        'Das Finanzamt schaut sich deine Bücher an.',
    emoji: '🧾',
    category: EventCategory.bad,
    requirements: EventRequirements(minDay: 40, minShops: 2),
    choices: [
      EventChoice(
        label: 'Vollständig kooperieren',
        effect: EventEffect(
          cashDelta: -800,
          resultMessage: 'Saubere Bücher — nur Kleinigkeiten zu beanstanden.',
        ),
      ),
      EventChoice(
        label: 'Steuerberater einschalten (1.500 €)',
        effect: EventEffect(
          cashDelta: -1500,
          reputationDelta: 0.10,
          resultMessage: 'Profi findet Optimierungen — und das Image als seriös bleibt erhalten.',
        ),
        cost: 1500,
      ),
    ],
  ),
];
