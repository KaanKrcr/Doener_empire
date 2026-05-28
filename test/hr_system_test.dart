import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/difficulty_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/hr_manager_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/services/corporate_engine.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Shop _shop({
  required String id,
  required String cityId,
  required bool autoHire,
  required List<Employee> employees,
}) {
  return Shop(
    id: id,
    name: 'Shop $id',
    cityId: cityId,
    locationName: 'Test',
    footTraffic: cityId == 'berlin' ? 50000 : 6000,
    weeklyRent: cityId == 'berlin' ? 5000 : 1400,
    menu: kAllProducts
        .where((p) => p.isDefault)
        .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
        .toList(),
    equipment: const [],
    employees: employees,
    dayOpened: 1,
    autoHire: autoHire,
  );
}

Employee _employee(
  String id, {
  double salary = 95,
  int exp = 3,
  double growthPotential = 0.0,
  CandidateOrigin origin = CandidateOrigin.regular,
}) {
  return Employee(
    id: id,
    typeId: kEmployeeTypes.first.id,
    name: id,
    speed: 7,
    friendliness: 7,
    reliability: 7,
    experience: exp,
    salaryPerDay: salary,
    growthPotential: growthPotential,
    origin: origin,
  );
}

HrManager _hr({
  required HrManagerArchetype archetype,
  int talent = 6,
  int network = 6,
  int negotiation = 6,
  int speed = 6,
  int training = 6,
  double salary = 220,
}) {
  return HrManager(
    id: 'hr_1',
    name: 'Test HR',
    archetype: archetype,
    talentSense: talent,
    network: network,
    negotiation: negotiation,
    speed: speed,
    training: training,
    salaryPerDay: salary,
  );
}

void main() {
  test('Alt-Save ohne HR-Felder lädt mit sicheren Defaults', () {
    final state = GameState.initial(
      companyName: 'Legacy HR',
      founderName: 'Tester',
      startCash: 10000,
    );
    final json = state.toJson();
    json.remove('hrManager');
    json.remove('hrStrategy');
    json.remove('hrCandidates');

    final loaded = GameState.fromJson(json);
    expect(loaded.hrManager, isNull);
    expect(loaded.hrStrategy, HrStrategy.balanced);
    expect(loaded.hrCandidates, isEmpty);
  });

  test('HR-Manager verursacht tägliche Konzernkosten', () {
    final state = GameState.initial(
      companyName: 'HR Cost',
      founderName: 'Tester',
      startCash: 10000,
    ).copyWith(
      hrManager: _hr(archetype: HrManagerArchetype.processManager, salary: 400),
      shops: const [],
      currentDay: 4,
    );

    final next = GameEngine.processDay(state);
    expect(next.cash, closeTo(9600, 0.1));
    expect(next.history.last.salaryCosts, closeTo(400, 0.1));
  });

  test('Auto-Hire ist auf easy deutlich aktiver als auf hard', () {
    final pool =
        List.generate(20, (i) => _employee('cand_$i', salary: 80 + i.toDouble()));
    final shop = _shop(
      id: 'target',
      cityId: 'berlin',
      autoHire: true,
      employees: const [],
    );

    final easy = GameState.initial(
      companyName: 'Easy',
      founderName: 'A',
      startCash: 500000,
      difficulty: GameDifficulty.easy,
    ).copyWith(
      shops: [shop],
      employeePool: pool,
      hrStrategy: HrStrategy.fillFast,
    );

    final hard = GameState.initial(
      companyName: 'Hard',
      founderName: 'B',
      startCash: 500000,
      difficulty: GameDifficulty.hard,
    ).copyWith(
      shops: [shop],
      employeePool: pool,
      hrStrategy: HrStrategy.balanced,
    );

    final easyAfter = CorporateEngine.applyAutoHire(easy);
    final hardAfter = CorporateEngine.applyAutoHire(hard);

    final easyHires = easyAfter.shops.first.employees.length;
    final hardHires = hardAfter.shops.first.employees.length;
    expect(easyHires, greaterThan(hardHires));
  });

  test('Training Coach + Train Juniors beschleunigt Erfahrungsaufbau', () {
    final junior = _employee(
      'junior',
      exp: 2,
      origin: CandidateOrigin.juniorPotential,
      growthPotential: 0.25,
    );
    final shop = _shop(
      id: 's1',
      cityId: 'fulda',
      autoHire: false,
      employees: [junior],
    );

    var base = GameState.initial(
      companyName: 'Base',
      founderName: 'A',
      startCash: 50000,
      difficulty: GameDifficulty.normal,
    ).copyWith(shops: [shop]);

    var trained = GameState.initial(
      companyName: 'Trained',
      founderName: 'B',
      startCash: 50000,
      difficulty: GameDifficulty.normal,
    ).copyWith(
      shops: [shop],
      hrManager: _hr(
        archetype: HrManagerArchetype.trainingCoach,
        training: 10,
        speed: 6,
      ),
      hrStrategy: HrStrategy.trainJuniors,
    );

    for (var i = 0; i < 36; i++) {
      base = GameEngine.processDay(base);
      trained = GameEngine.processDay(trained);
    }

    final baseExp = base.shops.first.employees.first.experience;
    final trainedExp = trained.shops.first.employees.first.experience;
    expect(trainedExp, greaterThanOrEqualTo(baseExp + 1));
  });
}
