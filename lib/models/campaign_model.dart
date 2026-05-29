import 'mission_model.dart';

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

  const CampaignChapter({
    required this.id,
    required this.number,
    required this.title,
    required this.story,
    required this.emoji,
    required this.objectives,
    required this.cashReward,
    required this.rewardLabel,
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
  ),
  CampaignChapter(
    id: 'ch6_imperium',
    number: 6,
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
  ),
];

CampaignChapter? campaignChapterById(String id) {
  for (final c in kCampaignChapters) {
    if (c.id == id) return c;
  }
  return null;
}
