import 'dart:math';

import '../core/constants.dart';
import '../models/difficulty_model.dart';
import '../models/employee_model.dart';
import '../models/game_state.dart';
import '../models/hr_manager_model.dart';

class HrEngine {
  static final Random _rng = Random();

  static const int _kDefaultHrCandidates = 3;

  static const Map<HrManagerArchetype, (double, double)> _kSalaryBands = {
    HrManagerArchetype.talentScout: (180, 300),
    HrManagerArchetype.costOptimizer: (80, 170),
    HrManagerArchetype.processManager: (120, 220),
    HrManagerArchetype.premiumRecruiter: (350, 600),
    HrManagerArchetype.trainingCoach: (100, 200),
  };

  static const List<String> _kHrNames = [
    'Ayla Demir',
    'Murat Kaya',
    'Selin Aslan',
    'Deniz Arslan',
    'Lara Yilmaz',
    'Berk Can',
    'Ece Toprak',
    'Hakan Öz',
    'Nisa Usta',
    'Emir Gür',
    'Leyla Acar',
    'Sinan Kurt',
  ];

  static const HrArchetypeBase _kNeutralArchetype = HrArchetypeBase(
    quality: 1.0,
    salary: 1.0,
    speed: 1.0,
    special: 1.0,
    junior: 1.0,
    training: 1.0,
  );

  static HrRecruitmentModifiers recruitmentModifiers(GameState state) {
    final difficulty = state.difficulty.modifiers;
    final strategy = kHrStrategyModifiers[state.hrStrategy]!;
    final manager = state.hrManager;
    final archetype = manager == null
        ? _kNeutralArchetype
        : (kHrArchetypeBase[manager.archetype] ?? _kNeutralArchetype);

    final talentN = _normalizedStat(manager?.talentSense ?? 5);
    final networkN = _normalizedStat(manager?.network ?? 5);
    final negotiationN = _normalizedStat(manager?.negotiation ?? 5);
    final speedN = _normalizedStat(manager?.speed ?? 5);
    final trainingN = _normalizedStat(manager?.training ?? 5);

    final quality = (difficulty.candidateQualityMultiplier *
            strategy.candidateQualityMultiplier *
            archetype.quality *
            (1.0 + talentN * 0.16 + networkN * 0.07))
        .clamp(0.65, 1.65);
    final salary = (difficulty.candidateSalaryMultiplier *
            strategy.candidateSalaryMultiplier *
            archetype.salary *
            (1.0 - negotiationN * 0.12))
        .clamp(0.72, 1.55);
    final speed = (difficulty.hrRecruitmentSpeedMultiplier *
            strategy.refreshSpeedMultiplier *
            archetype.speed *
            (1.0 + speedN * 0.20))
        .clamp(0.55, 2.10);
    final poolSize = (difficulty.hrRecruitmentSpeedMultiplier *
            strategy.poolSizeMultiplier *
            archetype.speed *
            (1.0 + speedN * 0.15))
        .clamp(0.60, 2.20);

    final special = ((manager == null ? 0.03 : 0.07) *
            strategy.specialCandidateChance *
            archetype.special *
            (1.0 + networkN * 0.65))
        .clamp(0.02, 0.40);
    final junior = (0.18 *
            strategy.juniorPotentialChance *
            archetype.junior *
            (1.0 + trainingN * 0.45))
        .clamp(0.08, 0.65);

    final autoHireAggressiveness = (difficulty.hrRecruitmentSpeedMultiplier *
            strategy.autoHireAggressivenessMultiplier *
            archetype.speed *
            (1.0 + speedN * 0.20))
        .clamp(0.55, 2.30);
    final autoHireReserve = (strategy.autoHireReserveMultiplier *
            (1.0 - negotiationN * 0.12) *
            (1.0 - speedN * 0.06))
        .clamp(0.65, 1.35);

    final trainingGrowth = (strategy.trainingGrowthMultiplier *
            archetype.training *
            (1.0 + trainingN * 0.28))
        .clamp(0.80, 1.85);

    return HrRecruitmentModifiers(
      poolSizeMultiplier: poolSize,
      refreshSpeedMultiplier: speed,
      candidateQualityMultiplier: quality,
      candidateSalaryMultiplier: salary,
      specialCandidateChance: special,
      juniorPotentialChance: junior,
      autoHireAggressivenessMultiplier: autoHireAggressiveness,
      autoHireReserveMultiplier: autoHireReserve,
      trainingGrowthMultiplier: trainingGrowth,
    );
  }

  static int poolRefreshIntervalDays(GameState state) {
    final hr = recruitmentModifiers(state);
    return (7 / hr.refreshSpeedMultiplier).round().clamp(2, 14);
  }

  static double poolRefreshCost(GameState state) {
    final hr = recruitmentModifiers(state);
    return (500 / hr.refreshSpeedMultiplier).clamp(220.0, 1200.0);
  }

  static List<HrManager> generateHrCandidates({
    int count = _kDefaultHrCandidates,
    int daySeed = 0,
  }) {
    final rng = Random(DateTime.now().microsecondsSinceEpoch + daySeed);
    final archetypes = List<HrManagerArchetype>.from(HrManagerArchetype.values)
      ..shuffle(rng);
    final names = List<String>.from(_kHrNames)..shuffle(rng);

    final target = count.clamp(1, HrManagerArchetype.values.length);
    final out = <HrManager>[];
    for (var i = 0; i < target; i++) {
      final archetype = archetypes[i % archetypes.length];
      final name = names[i % names.length];
      out.add(
          _buildHrManager(archetype: archetype, name: name, rng: rng, i: i));
    }
    return out;
  }

  static List<Employee> generateCandidatePool(GameState state) {
    final hr = recruitmentModifiers(state);
    final minCount = (6 * hr.poolSizeMultiplier).round().clamp(4, 15);
    final maxExtra = (3 * hr.poolSizeMultiplier).round().clamp(1, 7);
    final count = minCount + _rng.nextInt(maxExtra + 1);
    return generateCandidatesForRole(state, count: count);
  }

  static List<Employee> generateCandidatesForRole(
    GameState state, {
    required int count,
    EmployeeTypeData? forcedType,
  }) {
    final hr = recruitmentModifiers(state);
    final candidates = <Employee>[];
    final cappedCount = count.clamp(1, 20);
    for (var i = 0; i < cappedCount; i++) {
      final type =
          forcedType ?? kEmployeeTypes[_rng.nextInt(kEmployeeTypes.length)];
      final name = _rng.nextBool()
          ? kMaleNames[_rng.nextInt(kMaleNames.length)]
          : kFemaleNames[_rng.nextInt(kFemaleNames.length)];

      final special = _buildSpecialOrigin(state, hr, forcedType);
      final archetype = _candidateArchetype(special, hr);
      final qualityMultiplier = _qualityMultiplierForOrigin(
        baseQuality: hr.candidateQualityMultiplier,
        origin: special,
      );
      final salaryMultiplier = _salaryMultiplierForOrigin(
        baseSalary: hr.candidateSalaryMultiplier,
        origin: special,
      );
      final growthPotential = _growthPotentialForOrigin(special, hr);

      candidates.add(EmployeeFactory.createCandidate(
        id: 'cand_${DateTime.now().microsecondsSinceEpoch}_$i',
        type: type,
        name: name,
        archetype: archetype,
        qualityMultiplier: qualityMultiplier,
        salaryMultiplier: salaryMultiplier,
        origin: special,
        growthPotential: growthPotential,
      ));
    }
    return candidates;
  }

  static double trainingGrowthMultiplier(GameState state) {
    return recruitmentModifiers(state).trainingGrowthMultiplier;
  }

  static int xpIntervalDays({
    required GameDifficulty difficulty,
    required double trainingGrowthMultiplier,
    required double growthPotential,
  }) {
    final progress = difficulty.modifiers.progressSpeedMultiplier;
    final training =
        (trainingGrowthMultiplier + growthPotential * 0.35).clamp(0.80, 2.20);
    return (30 / (progress * training)).round().clamp(10, 46);
  }

  static String currentEffectSummary(GameState state) {
    final hr = recruitmentModifiers(state);
    final q = ((hr.candidateQualityMultiplier - 1.0) * 100).round();
    final s = ((hr.candidateSalaryMultiplier - 1.0) * 100).round();
    final sp = ((hr.refreshSpeedMultiplier - 1.0) * 100).round();
    final spec = (hr.specialCandidateChance * 100).round();
    final train = ((hr.trainingGrowthMultiplier - 1.0) * 100).round();
    return 'Qualität ${_signedPercent(q)}, Gehalt ${_signedPercent(s)}, '
        'Tempo ${_signedPercent(sp)}, Spezial $spec%, Training ${_signedPercent(train)}';
  }

  static String _signedPercent(int value) {
    if (value > 0) return '+$value%';
    if (value < 0) return '$value%';
    return '0%';
  }

  static CandidateOrigin _buildSpecialOrigin(
    GameState state,
    HrRecruitmentModifiers hr,
    EmployeeTypeData? forcedType,
  ) {
    final roll = _rng.nextDouble();
    if (roll > hr.specialCandidateChance) {
      return CandidateOrigin.regular;
    }

    final manager = state.hrManager;
    if (manager != null &&
        manager.archetype == HrManagerArchetype.trainingCoach &&
        _rng.nextDouble() < 0.45) {
      return CandidateOrigin.juniorPotential;
    }
    if (_rng.nextDouble() < hr.juniorPotentialChance * 0.55) {
      return CandidateOrigin.juniorPotential;
    }
    if (manager != null &&
        manager.archetype == HrManagerArchetype.premiumRecruiter &&
        _rng.nextDouble() < 0.40) {
      return CandidateOrigin.topTalent;
    }
    if (_rng.nextDouble() < 0.24) return CandidateOrigin.hiddenGem;
    if (_rng.nextDouble() < 0.20) return CandidateOrigin.teamContact;
    if (_rng.nextDouble() < 0.18) return CandidateOrigin.exCompetitor;
    if (forcedType != null && _rng.nextDouble() < 0.40) {
      return CandidateOrigin.hiddenGem;
    }
    return CandidateOrigin.topTalent;
  }

  static String _candidateArchetype(
    CandidateOrigin origin,
    HrRecruitmentModifiers hr,
  ) {
    switch (origin) {
      case CandidateOrigin.hiddenGem:
        return _rng.nextBool() ? 'balanced' : 'veteran';
      case CandidateOrigin.topTalent:
        return 'veteran';
      case CandidateOrigin.juniorPotential:
        return 'rookie';
      case CandidateOrigin.exCompetitor:
        return _rng.nextDouble() < 0.6 ? 'veteran' : 'balanced';
      case CandidateOrigin.teamContact:
        return 'balanced';
      case CandidateOrigin.regular:
        if (hr.candidateQualityMultiplier < 0.95 && _rng.nextDouble() < 0.35) {
          return 'rookie';
        }
        return _rng.nextDouble() < 0.30 ? 'veteran' : 'balanced';
    }
  }

  static double _qualityMultiplierForOrigin({
    required double baseQuality,
    required CandidateOrigin origin,
  }) {
    final byOrigin = switch (origin) {
      CandidateOrigin.regular => 1.00,
      CandidateOrigin.hiddenGem => 1.10,
      CandidateOrigin.topTalent => 1.22,
      CandidateOrigin.juniorPotential => 0.84,
      CandidateOrigin.exCompetitor => 1.12,
      CandidateOrigin.teamContact => 1.04,
    };
    return (baseQuality * byOrigin).clamp(0.60, 1.90);
  }

  static double _salaryMultiplierForOrigin({
    required double baseSalary,
    required CandidateOrigin origin,
  }) {
    final byOrigin = switch (origin) {
      CandidateOrigin.regular => 1.00,
      CandidateOrigin.hiddenGem => 0.90,
      CandidateOrigin.topTalent => 1.20,
      CandidateOrigin.juniorPotential => 0.78,
      CandidateOrigin.exCompetitor => 1.18,
      CandidateOrigin.teamContact => 0.95,
    };
    return (baseSalary * byOrigin).clamp(0.60, 1.90);
  }

  static double _growthPotentialForOrigin(
    CandidateOrigin origin,
    HrRecruitmentModifiers hr,
  ) {
    final originBonus = switch (origin) {
      CandidateOrigin.regular => 0.00,
      CandidateOrigin.hiddenGem => 0.05,
      CandidateOrigin.topTalent => 0.03,
      CandidateOrigin.juniorPotential => 0.25,
      CandidateOrigin.exCompetitor => 0.04,
      CandidateOrigin.teamContact => 0.08,
    };
    final trainingBonus =
        ((hr.trainingGrowthMultiplier - 1.0) * 0.20).clamp(0.0, 0.20);
    return (originBonus + trainingBonus).clamp(0.0, 0.45);
  }

  static HrManager _buildHrManager({
    required HrManagerArchetype archetype,
    required String name,
    required Random rng,
    required int i,
  }) {
    final salaryBand = _kSalaryBands[archetype] ?? (120.0, 220.0);
    final salary =
        salaryBand.$1 + rng.nextDouble() * (salaryBand.$2 - salaryBand.$1);
    final stats = _statSeedFor(archetype, rng);

    return HrManager(
      id: 'hr_${DateTime.now().microsecondsSinceEpoch}_$i',
      name: name,
      archetype: archetype,
      talentSense: stats.$1,
      network: stats.$2,
      negotiation: stats.$3,
      speed: stats.$4,
      training: stats.$5,
      salaryPerDay: double.parse(salary.toStringAsFixed(2)),
      level: 1,
      xp: 0,
    );
  }

  static (int, int, int, int, int) _statSeedFor(
    HrManagerArchetype archetype,
    Random rng,
  ) {
    int v(int min, int max) => min + rng.nextInt((max - min) + 1);
    switch (archetype) {
      case HrManagerArchetype.talentScout:
        return (v(7, 10), v(6, 9), v(4, 7), v(5, 8), v(4, 7));
      case HrManagerArchetype.costOptimizer:
        return (v(4, 7), v(4, 7), v(7, 10), v(5, 8), v(5, 8));
      case HrManagerArchetype.processManager:
        return (v(5, 8), v(4, 7), v(5, 8), v(7, 10), v(4, 7));
      case HrManagerArchetype.premiumRecruiter:
        return (v(8, 10), v(8, 10), v(4, 7), v(4, 7), v(3, 6));
      case HrManagerArchetype.trainingCoach:
        return (v(4, 7), v(5, 8), v(5, 8), v(4, 7), v(8, 10));
    }
  }

  static double _normalizedStat(int value) {
    return ((value.clamp(1, 10) - 5) / 5).clamp(-1.0, 1.0);
  }
}
