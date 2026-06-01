enum GameDifficulty {
  easy,
  normal,
  hard,
  impossible,
}

class DifficultyModifiers {
  final double hrRecruitmentSpeedMultiplier;
  final double candidateQualityMultiplier;
  final double candidateSalaryMultiplier;
  final double competitorAggressivenessMultiplier;
  final double customerPriceSensitivityMultiplier;
  final double progressSpeedMultiplier;
  final double reputationPenaltyMultiplier;
  final double economicPressureMultiplier;

  const DifficultyModifiers({
    required this.hrRecruitmentSpeedMultiplier,
    required this.candidateQualityMultiplier,
    required this.candidateSalaryMultiplier,
    required this.competitorAggressivenessMultiplier,
    required this.customerPriceSensitivityMultiplier,
    required this.progressSpeedMultiplier,
    required this.reputationPenaltyMultiplier,
    required this.economicPressureMultiplier,
  });
}

const Map<GameDifficulty, DifficultyModifiers> kDifficultyModifiers = {
  GameDifficulty.easy: DifficultyModifiers(
    hrRecruitmentSpeedMultiplier: 1.60,
    candidateQualityMultiplier: 1.25,
    candidateSalaryMultiplier: 0.80,
    competitorAggressivenessMultiplier: 0.60,
    customerPriceSensitivityMultiplier: 0.65,
    progressSpeedMultiplier: 1.35,
    reputationPenaltyMultiplier: 0.60,
    economicPressureMultiplier: 0.75,
  ),
  GameDifficulty.normal: DifficultyModifiers(
    hrRecruitmentSpeedMultiplier: 1.00,
    candidateQualityMultiplier: 1.00,
    candidateSalaryMultiplier: 1.00,
    competitorAggressivenessMultiplier: 1.00,
    customerPriceSensitivityMultiplier: 1.00,
    progressSpeedMultiplier: 1.00,
    reputationPenaltyMultiplier: 1.00,
    economicPressureMultiplier: 1.00,
  ),
  GameDifficulty.hard: DifficultyModifiers(
    hrRecruitmentSpeedMultiplier: 0.70,
    candidateQualityMultiplier: 0.85,
    candidateSalaryMultiplier: 1.20,
    competitorAggressivenessMultiplier: 1.40,
    customerPriceSensitivityMultiplier: 1.30,
    progressSpeedMultiplier: 0.80,
    reputationPenaltyMultiplier: 1.30,
    economicPressureMultiplier: 1.25,
  ),
  GameDifficulty.impossible: DifficultyModifiers(
    hrRecruitmentSpeedMultiplier: 0.45,
    candidateQualityMultiplier: 0.70,
    candidateSalaryMultiplier: 1.45,
    competitorAggressivenessMultiplier: 1.90,
    customerPriceSensitivityMultiplier: 1.65,
    progressSpeedMultiplier: 0.60,
    reputationPenaltyMultiplier: 1.70,
    economicPressureMultiplier: 1.55,
  ),
};

extension GameDifficultyX on GameDifficulty {
  DifficultyModifiers get modifiers =>
      kDifficultyModifiers[this] ??
      kDifficultyModifiers[GameDifficulty.normal]!;

  String get label {
    switch (this) {
      case GameDifficulty.easy:
        return 'Einfach';
      case GameDifficulty.normal:
        return 'Mittel / Normal';
      case GameDifficulty.hard:
        return 'Schwer';
      case GameDifficulty.impossible:
        return 'Unmöglich';
    }
  }

  String get shortDescription {
    switch (this) {
      case GameDifficulty.easy:
        return 'Mehr Bewerber, billigere Löhne, verzeihende Kunden und schwächere Konkurrenz.';
      case GameDifficulty.normal:
        return 'Ausgewogenes Standard-Balancing.';
      case GameDifficulty.hard:
        return 'Teurere Löhne, preissensiblere Kunden und aktivere Konkurrenz.';
      case GameDifficulty.impossible:
        return 'Harter Kostendruck, langsamer Fortschritt und aggressive Konkurrenz.';
    }
  }
}

GameDifficulty gameDifficultyFromName(String? raw) {
  if (raw == null) return GameDifficulty.normal;
  for (final value in GameDifficulty.values) {
    if (value.name == raw) return value;
  }
  return GameDifficulty.normal;
}
