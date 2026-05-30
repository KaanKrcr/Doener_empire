import 'difficulty_model.dart';

/// Start-Szenarien für Wiederspielwert. Jedes setzt Startkapital, Schwierigkeit,
/// Tutorial und optional einen Startkredit.
class Scenario {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double startCash;
  final GameDifficulty difficulty;
  final bool tutorialEnabled;
  final double startingLoan;

  const Scenario({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.startCash,
    required this.difficulty,
    required this.tutorialEnabled,
    this.startingLoan = 0,
  });
}

const List<Scenario> kScenarios = [
  Scenario(
    id: 'classic',
    name: 'Klassischer Start',
    emoji: '🥙',
    description: 'Der normale Einstieg mit 15.000 € Startkapital.',
    startCash: 15000,
    difficulty: GameDifficulty.normal,
    tutorialEnabled: true,
  ),
  Scenario(
    id: 'schuldenstart',
    name: 'Schuldenstart',
    emoji: '💳',
    description:
        '25.000 € Kapital, aber 20.000 € Bankkredit im Nacken. Schnell '
        'profitabel werden!',
    startCash: 25000,
    difficulty: GameDifficulty.hard,
    tutorialEnabled: false,
    startingLoan: 20000,
  ),
  Scenario(
    id: 'hardcore',
    name: 'Hardcore',
    emoji: '🔥',
    description: 'Nur 6.000 € Startkapital, harte Schwierigkeit, kein Tutorial.',
    startCash: 6000,
    difficulty: GameDifficulty.hard,
    tutorialEnabled: false,
  ),
  Scenario(
    id: 'highroller',
    name: 'High-Roller',
    emoji: '💎',
    description:
        '60.000 € Startkapital — aber gnadenlose Schwierigkeit. Expandiere '
        'aggressiv.',
    startCash: 60000,
    difficulty: GameDifficulty.impossible,
    tutorialEnabled: false,
  ),
];
