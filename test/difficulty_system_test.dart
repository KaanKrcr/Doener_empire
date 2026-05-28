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
}
