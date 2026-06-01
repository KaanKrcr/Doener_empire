import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/competitor_model.dart';
import 'package:doener_empire/models/difficulty_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/services/competitor_engine.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Shop _shop() {
  return Shop(
    id: 'shop_1',
    name: 'Shop 1',
    cityId: 'berlin',
    locationName: 'Test',
    footTraffic: 30000,
    weeklyRent: 4000,
    menu: kAllProducts
        .where((p) => p.isDefault)
        .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
        .toList(),
    equipment: const [],
    employees: const [],
    reputation: 3.2,
    dayOpened: 1,
  );
}

void main() {
  test('Difficulty-Modifier entsprechen exakt der Spec', () {
    final easy = GameDifficulty.easy.modifiers;
    expect(easy.hrRecruitmentSpeedMultiplier, 1.60);
    expect(easy.candidateQualityMultiplier, 1.25);
    expect(easy.candidateSalaryMultiplier, 0.80);
    expect(easy.competitorAggressivenessMultiplier, 0.60);
    expect(easy.customerPriceSensitivityMultiplier, 0.65);
    expect(easy.progressSpeedMultiplier, 1.35);
    expect(easy.reputationPenaltyMultiplier, 0.60);
    expect(easy.economicPressureMultiplier, 0.75);

    final normal = GameDifficulty.normal.modifiers;
    expect(normal.hrRecruitmentSpeedMultiplier, 1.00);
    expect(normal.candidateQualityMultiplier, 1.00);
    expect(normal.candidateSalaryMultiplier, 1.00);
    expect(normal.competitorAggressivenessMultiplier, 1.00);
    expect(normal.customerPriceSensitivityMultiplier, 1.00);
    expect(normal.progressSpeedMultiplier, 1.00);
    expect(normal.reputationPenaltyMultiplier, 1.00);
    expect(normal.economicPressureMultiplier, 1.00);

    final hard = GameDifficulty.hard.modifiers;
    expect(hard.hrRecruitmentSpeedMultiplier, 0.70);
    expect(hard.candidateQualityMultiplier, 0.85);
    expect(hard.candidateSalaryMultiplier, 1.20);
    expect(hard.competitorAggressivenessMultiplier, 1.40);
    expect(hard.customerPriceSensitivityMultiplier, 1.30);
    expect(hard.progressSpeedMultiplier, 0.80);
    expect(hard.reputationPenaltyMultiplier, 1.30);
    expect(hard.economicPressureMultiplier, 1.25);

    final impossible = GameDifficulty.impossible.modifiers;
    expect(impossible.hrRecruitmentSpeedMultiplier, 0.45);
    expect(impossible.candidateQualityMultiplier, 0.70);
    expect(impossible.candidateSalaryMultiplier, 1.45);
    expect(impossible.competitorAggressivenessMultiplier, 1.90);
    expect(impossible.customerPriceSensitivityMultiplier, 1.65);
    expect(impossible.progressSpeedMultiplier, 0.60);
    expect(impossible.reputationPenaltyMultiplier, 1.70);
    expect(impossible.economicPressureMultiplier, 1.55);
  });

  test('Hard und Impossible sind bei Kerndruckfaktoren über Normal', () {
    final normal = GameDifficulty.normal.modifiers;
    final hard = GameDifficulty.hard.modifiers;
    final impossible = GameDifficulty.impossible.modifiers;

    expect(hard.competitorAggressivenessMultiplier,
        greaterThan(normal.competitorAggressivenessMultiplier));
    expect(impossible.competitorAggressivenessMultiplier,
        greaterThan(normal.competitorAggressivenessMultiplier));

    expect(hard.customerPriceSensitivityMultiplier,
        greaterThan(normal.customerPriceSensitivityMultiplier));
    expect(impossible.customerPriceSensitivityMultiplier,
        greaterThan(normal.customerPriceSensitivityMultiplier));

    expect(hard.economicPressureMultiplier,
        greaterThan(normal.economicPressureMultiplier));
    expect(impossible.economicPressureMultiplier,
        greaterThan(normal.economicPressureMultiplier));
  });

  test('Easy bleibt verzeihender als Normal', () {
    final easy = GameDifficulty.easy.modifiers;
    final normal = GameDifficulty.normal.modifiers;

    expect(easy.competitorAggressivenessMultiplier,
        lessThan(normal.competitorAggressivenessMultiplier));
    expect(easy.customerPriceSensitivityMultiplier,
        lessThan(normal.customerPriceSensitivityMultiplier));
    expect(
        easy.economicPressureMultiplier, lessThan(normal.economicPressureMultiplier));
  });

  test('Alte Saves ohne difficulty laden als normal', () {
    final state = GameState.initial(
      companyName: 'Legacy',
      founderName: 'Tester',
      startCash: 15000,
    );
    final json = state.toJson();
    json.remove('difficulty');

    final loaded = GameState.fromJson(json);
    expect(loaded.difficulty, GameDifficulty.normal);
  });

  test('Kunden reagieren auf Preise je nach Schwierigkeit', () {
    final easyDemand = GameEngine.priceDemandFactor(
      price: 8.8,
      basePrice: 6.5,
      difficulty: GameDifficulty.easy,
    );
    final impossibleDemand = GameEngine.priceDemandFactor(
      price: 8.8,
      basePrice: 6.5,
      difficulty: GameDifficulty.impossible,
    );

    expect(easyDemand, greaterThan(impossibleDemand));
  });

  test('Konkurrenzdruck ist auf impossible spürbar höher als auf easy', () {
    final competitor = Competitor(
      id: 'comp_1',
      name: 'Rival',
      cityId: 'berlin',
      personality: CompetitorPersonality.aggressive,
      shopCount: 3,
      reputation: 3.6,
      priceLevel: 0.9,
    );

    final easyState = GameState.initial(
      companyName: 'Easy',
      founderName: 'A',
      startCash: 15000,
      difficulty: GameDifficulty.easy,
    ).copyWith(
      shops: [_shop()],
      competitors: [competitor],
    );

    final impossibleState = GameState.initial(
      companyName: 'Impossible',
      founderName: 'B',
      startCash: 15000,
      difficulty: GameDifficulty.impossible,
    ).copyWith(
      shops: [_shop()],
      competitors: [competitor],
    );

    final easyPressure =
        CompetitorEngine.competitionPressure(easyState, 'berlin', 3.2);
    final impossiblePressure =
        CompetitorEngine.competitionPressure(impossibleState, 'berlin', 3.2);

    expect(impossiblePressure, lessThan(easyPressure));
  });

  test('Mitarbeiterqualitaet und Gehalt skalieren mit difficulty', () {
    final type = kEmployeeTypes.first;
    var easyScore = 0.0;
    var hardScore = 0.0;
    var easySalary = 0.0;
    var hardSalary = 0.0;

    for (var i = 0; i < 200; i++) {
      final easy = EmployeeFactory.createCandidate(
        id: 'easy_$i',
        type: type,
        name: 'Easy $i',
        qualityMultiplier:
            GameDifficulty.easy.modifiers.candidateQualityMultiplier,
        salaryMultiplier:
            GameDifficulty.easy.modifiers.candidateSalaryMultiplier,
      );
      final hard = EmployeeFactory.createCandidate(
        id: 'hard_$i',
        type: type,
        name: 'Hard $i',
        qualityMultiplier:
            GameDifficulty.hard.modifiers.candidateQualityMultiplier,
        salaryMultiplier:
            GameDifficulty.hard.modifiers.candidateSalaryMultiplier,
      );
      easyScore += easy.overallScore;
      hardScore += hard.overallScore;
      easySalary += easy.salaryPerDay;
      hardSalary += hard.salaryPerDay;
    }

    expect(easyScore / 200, greaterThan(hardScore / 200));
    expect(easySalary / 200, lessThan(hardSalary / 200));
  });

  test(
      'Hard und Impossible unterscheiden sich klarer bei Konkurrenz-Aggressivität',
      () {
    final normalAgg =
        GameDifficulty.normal.modifiers.competitorAggressivenessMultiplier;
    final hardAgg =
        GameDifficulty.hard.modifiers.competitorAggressivenessMultiplier;
    final impossibleAgg =
        GameDifficulty.impossible.modifiers.competitorAggressivenessMultiplier;

    expect(hardAgg, greaterThan(normalAgg + 0.30));
    expect(impossibleAgg, greaterThan(hardAgg + 0.40));
  });

  test('Hard/Impossible halten weniger stabile Monopole als Normal', () {
    GameState simulate(GameDifficulty difficulty, int days) {
      var state = GameState.initial(
        companyName: 'Diff',
        founderName: 'Tester',
        startCash: 15000,
        difficulty: difficulty,
      ).copyWith(
        shops: [_shop()],
        competitors: const [],
      );

      for (var i = 0; i < days; i++) {
        final updated = CompetitorEngine.processDay(state);
        state = state.copyWith(
          competitors: updated,
          currentDay: state.currentDay + 1,
        );
      }
      return state;
    }

    final normal = simulate(GameDifficulty.normal, 500);
    final hard = simulate(GameDifficulty.hard, 500);
    final impossible = simulate(GameDifficulty.impossible, 500);

    int countFor(GameState state) =>
        state.competitors.where((c) => c.cityId == 'berlin').length;

    final normalCount = countFor(normal);
    final hardCount = countFor(hard);
    final impossibleCount = countFor(impossible);

    expect(hardCount, greaterThanOrEqualTo(normalCount));
    expect(impossibleCount, greaterThanOrEqualTo(hardCount));
  });
}
