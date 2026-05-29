import 'mission_model.dart';

/// Permanenter Konzern-Perk, den ein Kapitel beim Abschluss freischaltet.
/// Wirkt konzernweit und dauerhaft (abgeleitet aus den abgeschlossenen
/// Kapiteln — kein eigenes Speicherfeld nötig).
class CampaignPerk {
  final String title;
  final String emoji;

  /// Additiver Kunden-Multiplikator (0.05 = +5 % Kunden).
  final double customerBoost;

  /// Additiver Bestellwert-Multiplikator (0.05 = +5 % Bestellwert).
  final double avgOrderBoost;

  /// Zusätzliche Zutaten-Ersparnis (0.05 = −5 % Zutatenkosten).
  final double ingredientSaving;

  /// Miet-Ersparnis (0.05 = −5 % Miete).
  final double rentSaving;

  const CampaignPerk({
    required this.title,
    required this.emoji,
    this.customerBoost = 0,
    this.avgOrderBoost = 0,
    this.ingredientSaving = 0,
    this.rentSaving = 0,
  });

  /// Kurzbeschreibung des Effekts für die UI.
  String get effectLabel {
    final parts = <String>[];
    if (customerBoost > 0) parts.add('+${(customerBoost * 100).round()}% Kunden');
    if (avgOrderBoost > 0) {
      parts.add('+${(avgOrderBoost * 100).round()}% Bestellwert');
    }
    if (ingredientSaving > 0) {
      parts.add('−${(ingredientSaving * 100).round()}% Zutaten');
    }
    if (rentSaving > 0) parts.add('−${(rentSaving * 100).round()}% Miete');
    return parts.join(' · ');
  }
}

/// Summiert alle Perks der bereits abgeschlossenen Kapitel zu einem
/// konzernweiten Gesamt-Bonus. Pure Funktion — von der Engine genutzt.
CampaignPerk aggregateCampaignPerks(Iterable<String> completedChapterIds) {
  double cust = 0, aov = 0, ing = 0, rent = 0;
  for (final id in completedChapterIds) {
    final perk = campaignChapterById(id)?.perk;
    if (perk == null) continue;
    cust += perk.customerBoost;
    aov += perk.avgOrderBoost;
    ing += perk.ingredientSaving;
    rent += perk.rentSaving;
  }
  return CampaignPerk(
    title: 'Kampagnen-Boni',
    emoji: '⭐',
    customerBoost: cust,
    avgOrderBoost: aov,
    ingredientSaving: ing,
    rentSaving: rent,
  );
}

/// Story-Kampagne: kapitelbasierter Aufstieg vom kleinen Imbiss zum Imperium.
///
/// Jedes Kapitel hat narrativen Text, mehrere Ziele (nutzen dieselben
/// Bedingungstypen wie Missionen, ausgewertet über die MissionEngine) und eine
/// größere Belohnung. Kapitel werden sequenziell freigeschaltet.
class CampaignObjective {
  final MissionType type;
  final double target;
  final String label;

  /// Optionaler Spezial-Marker (z.B. 'metropole' für Metropolen-Filiale),
  /// damit die Engine die passende Sonderlogik wählt.
  final String? specialId;

  const CampaignObjective({
    required this.type,
    required this.target,
    required this.label,
    this.specialId,
  });
}

class CampaignChapter {
  final String id;
  final int number;
  final String title;
  final String story;
  final String emoji;
  final List<CampaignObjective> objectives;
  final double cashReward;

  /// Kurzer Belohnungs-Flavortext (was der Aufstieg bedeutet).
  final String rewardLabel;

  /// Permanenter Konzern-Perk, der mit dem Kapitel freigeschaltet wird.
  final CampaignPerk? perk;

  const CampaignChapter({
    required this.id,
    required this.number,
    required this.title,
    required this.story,
    required this.emoji,
    required this.objectives,
    required this.cashReward,
    required this.rewardLabel,
    this.perk,
  });
}

/// Die Story-Kampagne in Reihenfolge. Kapitel N wird erst aktiv, wenn N-1
/// abgeschlossen ist.
const List<CampaignChapter> kCampaignChapters = [
  CampaignChapter(
    id: 'ch1_traum',
    number: 1,
    title: 'Der Traum vom eigenen Spieß',
    story:
        'Jahrelang hast du in fremden Läden gestanden und zugesehen, wie andere '
        'das große Geld machten. Heute ist Schluss damit. Mit deinen Ersparnissen '
        'eröffnest du deinen ersten eigenen Döner-Imbiss. Der erste Schritt zu '
        'deinem Imperium.',
    emoji: '🌱',
    objectives: [
      CampaignObjective(
        type: MissionType.openFirstShop,
        target: 1,
        label: 'Eröffne deine erste Filiale',
      ),
    ],
    cashReward: 1500,
    rewardLabel: 'Startkapital für die Zukunft',
    perk: CampaignPerk(
      title: 'Gründer-Instinkt',
      emoji: '🔥',
      customerBoost: 0.03,
    ),
  ),
  CampaignChapter(
    id: 'ch2_stammkunden',
    number: 2,
    title: 'Erste Stammkunden',
    story:
        'Die Leute reden über deinen Laden. Doch allein schaffst du den Ansturm '
        'nicht. Es wird Zeit, ein Team aufzubauen und dir einen guten Ruf in der '
        'Stadt zu erarbeiten.',
    emoji: '🤝',
    objectives: [
      CampaignObjective(
        type: MissionType.hireEmployees,
        target: 2,
        label: 'Stelle 2 Mitarbeiter ein',
      ),
      CampaignObjective(
        type: MissionType.reputationLevel,
        target: 3.5,
        label: 'Erreiche 3,5 ⭐ Reputation',
      ),
    ],
    cashReward: 3500,
    rewardLabel: 'Dein Name hat jetzt Gewicht',
    perk: CampaignPerk(
      title: 'Treue Stammkunden',
      emoji: '❤️',
      avgOrderBoost: 0.04,
    ),
  ),
  CampaignChapter(
    id: 'ch3_expansion',
    number: 3,
    title: 'Über die Stadtgrenze',
    story:
        'Eine Filiale reicht dir nicht mehr. Du witterst Chancen in anderen '
        'Städten. Bau eine kleine Kette auf und erschließe einen neuen Markt.',
    emoji: '🗺️',
    objectives: [
      CampaignObjective(
        type: MissionType.shopCount,
        target: 3,
        label: 'Betreibe 3 Filialen',
      ),
      CampaignObjective(
        type: MissionType.unlockCity,
        target: 1,
        label: 'Schalte eine neue Stadt frei',
      ),
    ],
    cashReward: 7000,
    rewardLabel: 'Expansion in vollem Gange',
    perk: CampaignPerk(
      title: 'Mengenrabatt',
      emoji: '📦',
      ingredientSaving: 0.04,
    ),
  ),
  CampaignChapter(
    id: 'ch4_marke',
    number: 4,
    title: 'Eine Marke entsteht',
    story:
        'Aus dem Imbiss wird ein Unternehmen. Filiale für Filiale wächst dein '
        'Einfluss — und dein Kontostand. Zeit, richtig Kapital aufzubauen.',
    emoji: '🏷️',
    objectives: [
      CampaignObjective(
        type: MissionType.reachCash,
        target: 50000,
        label: 'Erreiche 50.000 € Kapital',
      ),
      CampaignObjective(
        type: MissionType.shopCount,
        target: 5,
        label: 'Betreibe 5 Filialen',
      ),
    ],
    cashReward: 15000,
    rewardLabel: 'Eine echte Marke',
    perk: CampaignPerk(
      title: 'Markenzug',
      emoji: '🧲',
      customerBoost: 0.05,
    ),
  ),
  CampaignChapter(
    id: 'ch5_grossstadt',
    number: 5,
    title: 'Der Sprung in die Großstadt',
    story:
        'Die wahre Bühne sind die Metropolen. Teure Mieten, harte Konkurrenz — '
        'aber auch gewaltige Laufkundschaft. Wer es hier schafft, schafft es '
        'überall.',
    emoji: '🌆',
    objectives: [
      CampaignObjective(
        type: MissionType.shopCount,
        target: 1,
        label: 'Eröffne eine Filiale in einer Metropole',
        specialId: 'metropole',
      ),
      CampaignObjective(
        type: MissionType.reputationLevel,
        target: 4.2,
        label: 'Erreiche 4,2 ⭐ Reputation',
      ),
    ],
    cashReward: 30000,
    rewardLabel: 'Angekommen in der ersten Liga',
    perk: CampaignPerk(
      title: 'Premium-Lagen',
      emoji: '💎',
      avgOrderBoost: 0.05,
    ),
  ),
  CampaignChapter(
    id: 'ch6_boerse',
    number: 6,
    title: 'Börsen-Legende',
    story:
        'Dein Unternehmen ist zu groß für deine Hosentasche. Investoren klopfen '
        'an. Wag den Börsengang und mach deine Marke deutschlandweit bekannt — '
        'jetzt spielst du in der Liga der Großen.',
    emoji: '📈',
    objectives: [
      CampaignObjective(
        type: MissionType.companyPublic,
        target: 1,
        label: 'Führe den Börsengang (IPO) durch',
      ),
      CampaignObjective(
        type: MissionType.brandAwareness,
        target: 40,
        label: 'Erreiche 40 Markenbekanntheit',
      ),
    ],
    cashReward: 40000,
    rewardLabel: 'An der Börse notiert',
    perk: CampaignPerk(
      title: 'Verhandlungsmacht',
      emoji: '🤵',
      rentSaving: 0.05,
    ),
  ),
  CampaignChapter(
    id: 'ch7_markt',
    number: 7,
    title: 'Marktbeherrschung',
    story:
        'Konkurrenz? Die kaufst du einfach auf. Übernimm rivalisierende Läden '
        'und festige deine Vormachtstellung, bis dir niemand mehr das Wasser '
        'reichen kann.',
    emoji: '🤝',
    objectives: [
      CampaignObjective(
        type: MissionType.acquiredShops,
        target: 2,
        label: 'Übernimm 2 Konkurrenz-Filialen',
      ),
      CampaignObjective(
        type: MissionType.reachCash,
        target: 120000,
        label: 'Erreiche 120.000 € Kapital',
      ),
    ],
    cashReward: 50000,
    rewardLabel: 'Unangefochtener Marktführer',
    perk: CampaignPerk(
      title: 'Lieferantenmacht',
      emoji: '🚚',
      ingredientSaving: 0.06,
    ),
  ),
  CampaignChapter(
    id: 'ch6_imperium',
    number: 8,
    title: 'Döner-Imperium',
    story:
        'Vom kleinen Spieß zum landesweiten Imperium. Dein Name steht für Döner '
        'in ganz Deutschland. Krön dein Lebenswerk und schreib Geschichte.',
    emoji: '👑',
    objectives: [
      CampaignObjective(
        type: MissionType.reachCash,
        target: 150000,
        label: 'Erreiche 150.000 € Kapital',
      ),
      CampaignObjective(
        type: MissionType.shopCount,
        target: 8,
        label: 'Betreibe 8 Filialen',
      ),
      CampaignObjective(
        type: MissionType.daysSurvived,
        target: 40,
        label: 'Überlebe 40 Tage',
      ),
    ],
    cashReward: 75000,
    rewardLabel: 'Döner-Legende 👑',
    perk: CampaignPerk(
      title: 'Legendäre Marke',
      emoji: '👑',
      customerBoost: 0.08,
    ),
  ),
];

CampaignChapter? campaignChapterById(String id) {
  for (final c in kCampaignChapters) {
    if (c.id == id) return c;
  }
  return null;
}
