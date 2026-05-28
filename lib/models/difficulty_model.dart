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
    hrRecruitmentSpeedMultiplier: 1.40,
    candidateQualityMultiplier: 1.20,
    candidateSalaryMultiplier: 0.85,
    competitorAggressivenessMultiplier: 0.75,
    customerPriceSensitivityMultiplier: 0.75,
    progressSpeedMultiplier: 1.25,
    reputationPenaltyMultiplier: 0.75,
    economicPressureMultiplier: 0.85,
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
    hrRecruitmentSpeedMultiplier: 0.78,
    candidateQualityMultiplier: 0.88,
    candidateSalaryMultiplier: 1.12,
    competitorAggressivenessMultiplier: 1.20,
    customerPriceSensitivityMultiplier: 1.15,
    progressSpeedMultiplier: 0.90,
    reputationPenaltyMultiplier: 1.18,
    economicPressureMultiplier: 1.12,
  ),
  GameDifficulty.impossible: DifficultyModifiers(
    hrRecruitmentSpeedMultiplier: 0.62,
    candidateQualityMultiplier: 0.78,
    candidateSalaryMultiplier: 1.28,
    competitorAggressivenessMultiplier: 1.45,
    customerPriceSensitivityMultiplier: 1.32,
    progressSpeedMultiplier: 0.75,
    reputationPenaltyMultiplier: 1.40,
    economicPressureMultiplier: 1.24,
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
        return 'Aktive HR-Hilfe, günstige Talente und tolerantere Kundschaft.';
      case GameDifficulty.normal:
        return 'Ausgewogenes Standard-Balancing.';
      case GameDifficulty.hard:
        return 'Teurere Talente, aggressivere Konkurrenz und klarere Fehlerfolgen.';
      case GameDifficulty.impossible:
        return 'Hoher Druck, sehr preissensible Kunden und langsamer Fortschritt.';
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
