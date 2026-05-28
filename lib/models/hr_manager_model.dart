enum HrManagerArchetype {
  talentScout,
  costOptimizer,
  processManager,
  premiumRecruiter,
  trainingCoach,
}

enum HrStrategy {
  balanced,
  saveCosts,
  prioritizeQuality,
  fillFast,
  trainJuniors,
}

class HrManager {
  final String id;
  final String name;
  final HrManagerArchetype archetype;
  final int talentSense; // 1..10
  final int network; // 1..10
  final int negotiation; // 1..10
  final int speed; // 1..10
  final int training; // 1..10
  final double salaryPerDay;
  final int level;
  final int xp;

  const HrManager({
    required this.id,
    required this.name,
    required this.archetype,
    required this.talentSense,
    required this.network,
    required this.negotiation,
    required this.speed,
    required this.training,
    required this.salaryPerDay,
    this.level = 1,
    this.xp = 0,
  });

  HrManager copyWith({
    int? talentSense,
    int? network,
    int? negotiation,
    int? speed,
    int? training,
    double? salaryPerDay,
    int? level,
    int? xp,
  }) {
    return HrManager(
      id: id,
      name: name,
      archetype: archetype,
      talentSense: talentSense ?? this.talentSense,
      network: network ?? this.network,
      negotiation: negotiation ?? this.negotiation,
      speed: speed ?? this.speed,
      training: training ?? this.training,
      salaryPerDay: salaryPerDay ?? this.salaryPerDay,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'archetype': archetype.name,
        'talentSense': talentSense,
        'network': network,
        'negotiation': negotiation,
        'speed': speed,
        'training': training,
        'salaryPerDay': salaryPerDay,
        'level': level,
        'xp': xp,
      };

  factory HrManager.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double asDouble(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      if (v is String) {
        return double.tryParse(v.replaceAll(',', '.')) ?? fallback;
      }
      return fallback;
    }

    final rawArchetype = j['archetype'] as String?;
    final archetype = HrManagerArchetype.values.firstWhere(
      (a) => a.name == rawArchetype,
      orElse: () => HrManagerArchetype.processManager,
    );

    return HrManager(
      id: (j['id'] ?? '') as String,
      name: (j['name'] ?? 'HR Manager') as String,
      archetype: archetype,
      talentSense: asInt(j['talentSense'], 5).clamp(1, 10),
      network: asInt(j['network'], 5).clamp(1, 10),
      negotiation: asInt(j['negotiation'], 5).clamp(1, 10),
      speed: asInt(j['speed'], 5).clamp(1, 10),
      training: asInt(j['training'], 5).clamp(1, 10),
      salaryPerDay: asDouble(j['salaryPerDay'], 180.0),
      level: asInt(j['level'], 1).clamp(1, 50),
      xp: asInt(j['xp'], 0).clamp(0, 1000000),
    );
  }
}

class HrRecruitmentModifiers {
  final double poolSizeMultiplier;
  final double refreshSpeedMultiplier;
  final double candidateQualityMultiplier;
  final double candidateSalaryMultiplier;
  final double specialCandidateChance;
  final double juniorPotentialChance;
  final double autoHireAggressivenessMultiplier;
  final double autoHireReserveMultiplier;
  final double trainingGrowthMultiplier;

  const HrRecruitmentModifiers({
    required this.poolSizeMultiplier,
    required this.refreshSpeedMultiplier,
    required this.candidateQualityMultiplier,
    required this.candidateSalaryMultiplier,
    required this.specialCandidateChance,
    required this.juniorPotentialChance,
    required this.autoHireAggressivenessMultiplier,
    required this.autoHireReserveMultiplier,
    required this.trainingGrowthMultiplier,
  });
}

class HrArchetypeBase {
  final double quality;
  final double salary;
  final double speed;
  final double special;
  final double junior;
  final double training;

  const HrArchetypeBase({
    required this.quality,
    required this.salary,
    required this.speed,
    required this.special,
    required this.junior,
    required this.training,
  });
}

const Map<HrManagerArchetype, HrArchetypeBase> kHrArchetypeBase = {
  HrManagerArchetype.talentScout: HrArchetypeBase(
    quality: 1.12,
    salary: 1.04,
    speed: 1.00,
    special: 1.18,
    junior: 1.00,
    training: 1.02,
  ),
  HrManagerArchetype.costOptimizer: HrArchetypeBase(
    quality: 0.94,
    salary: 0.90,
    speed: 1.00,
    special: 0.95,
    junior: 1.08,
    training: 1.05,
  ),
  HrManagerArchetype.processManager: HrArchetypeBase(
    quality: 1.00,
    salary: 0.98,
    speed: 1.16,
    special: 1.00,
    junior: 1.00,
    training: 1.00,
  ),
  HrManagerArchetype.premiumRecruiter: HrArchetypeBase(
    quality: 1.20,
    salary: 1.18,
    speed: 1.04,
    special: 1.45,
    junior: 0.92,
    training: 0.98,
  ),
  HrManagerArchetype.trainingCoach: HrArchetypeBase(
    quality: 0.98,
    salary: 0.96,
    speed: 0.98,
    special: 1.02,
    junior: 1.30,
    training: 1.20,
  ),
};

const Map<HrStrategy, HrRecruitmentModifiers> kHrStrategyModifiers = {
  HrStrategy.balanced: HrRecruitmentModifiers(
    poolSizeMultiplier: 1.00,
    refreshSpeedMultiplier: 1.00,
    candidateQualityMultiplier: 1.00,
    candidateSalaryMultiplier: 1.00,
    specialCandidateChance: 1.00,
    juniorPotentialChance: 1.00,
    autoHireAggressivenessMultiplier: 1.00,
    autoHireReserveMultiplier: 1.00,
    trainingGrowthMultiplier: 1.00,
  ),
  HrStrategy.saveCosts: HrRecruitmentModifiers(
    poolSizeMultiplier: 1.00,
    refreshSpeedMultiplier: 1.05,
    candidateQualityMultiplier: 0.94,
    candidateSalaryMultiplier: 0.90,
    specialCandidateChance: 0.90,
    juniorPotentialChance: 1.12,
    autoHireAggressivenessMultiplier: 0.92,
    autoHireReserveMultiplier: 1.08,
    trainingGrowthMultiplier: 1.04,
  ),
  HrStrategy.prioritizeQuality: HrRecruitmentModifiers(
    poolSizeMultiplier: 0.92,
    refreshSpeedMultiplier: 0.95,
    candidateQualityMultiplier: 1.14,
    candidateSalaryMultiplier: 1.14,
    specialCandidateChance: 1.25,
    juniorPotentialChance: 0.85,
    autoHireAggressivenessMultiplier: 0.90,
    autoHireReserveMultiplier: 1.12,
    trainingGrowthMultiplier: 1.03,
  ),
  HrStrategy.fillFast: HrRecruitmentModifiers(
    poolSizeMultiplier: 1.22,
    refreshSpeedMultiplier: 1.20,
    candidateQualityMultiplier: 0.92,
    candidateSalaryMultiplier: 0.98,
    specialCandidateChance: 0.95,
    juniorPotentialChance: 1.05,
    autoHireAggressivenessMultiplier: 1.30,
    autoHireReserveMultiplier: 0.82,
    trainingGrowthMultiplier: 0.98,
  ),
  HrStrategy.trainJuniors: HrRecruitmentModifiers(
    poolSizeMultiplier: 1.08,
    refreshSpeedMultiplier: 1.04,
    candidateQualityMultiplier: 0.90,
    candidateSalaryMultiplier: 0.88,
    specialCandidateChance: 1.10,
    juniorPotentialChance: 1.45,
    autoHireAggressivenessMultiplier: 1.06,
    autoHireReserveMultiplier: 0.95,
    trainingGrowthMultiplier: 1.22,
  ),
};

extension HrManagerArchetypeX on HrManagerArchetype {
  String get label {
    switch (this) {
      case HrManagerArchetype.talentScout:
        return 'Talent Scout';
      case HrManagerArchetype.costOptimizer:
        return 'Cost Optimizer';
      case HrManagerArchetype.processManager:
        return 'Process Manager';
      case HrManagerArchetype.premiumRecruiter:
        return 'Premium Recruiter';
      case HrManagerArchetype.trainingCoach:
        return 'Training Coach';
    }
  }

  String get shortDescription {
    switch (this) {
      case HrManagerArchetype.talentScout:
        return 'Findet häufiger starke Talente und Geheimtipps.';
      case HrManagerArchetype.costOptimizer:
        return 'Drückt Gehälter und hält Recruiting effizient.';
      case HrManagerArchetype.processManager:
        return 'Besetzt offene Stellen verlässlich und schnell.';
      case HrManagerArchetype.premiumRecruiter:
        return 'Bringt seltene Top-Kandidaten aus dem Netzwerk.';
      case HrManagerArchetype.trainingCoach:
        return 'Fokussiert auf Nachwuchs mit starkem Entwicklungspfad.';
    }
  }
}

extension HrStrategyX on HrStrategy {
  String get label {
    switch (this) {
      case HrStrategy.balanced:
        return 'Balanced';
      case HrStrategy.saveCosts:
        return 'Save Costs';
      case HrStrategy.prioritizeQuality:
        return 'Prioritize Quality';
      case HrStrategy.fillFast:
        return 'Fill Fast';
      case HrStrategy.trainJuniors:
        return 'Train Juniors';
    }
  }

  String get shortDescription {
    switch (this) {
      case HrStrategy.balanced:
        return 'Ausgewogen zwischen Kosten, Qualität und Tempo.';
      case HrStrategy.saveCosts:
        return 'Günstiger rekrutieren, etwas weniger Top-Qualität.';
      case HrStrategy.prioritizeQuality:
        return 'Bessere Kandidaten, dafür teurer und etwas langsamer.';
      case HrStrategy.fillFast:
        return 'Stellen schnell besetzen, Qualität schwankt stärker.';
      case HrStrategy.trainJuniors:
        return 'Mehr günstige Juniors mit besserer Entwicklung.';
    }
  }
}

HrStrategy hrStrategyFromName(String? raw) {
  if (raw == null) return HrStrategy.balanced;
  for (final s in HrStrategy.values) {
    if (s.name == raw) return s;
  }
  return HrStrategy.balanced;
}
