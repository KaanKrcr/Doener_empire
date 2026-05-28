import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/difficulty_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/hr_manager_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Shop _shop({
  required String id,
  String cityId = 'berlin',
  bool autoHire = false,
  List<Employee> employees = const [],
}) {
  return Shop(
    id: id,
    name: 'E2E $id',
    cityId: cityId,
    locationName: 'E2E Standort',
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

Employee _candidate(String id, {double salary = 95, int exp = 6}) {
  return Employee(
    id: id,
    typeId: kEmployeeTypes.first.id,
    name: id,
    speed: 7,
    friendliness: 7,
    reliability: 7,
    experience: exp,
    salaryPerDay: salary,
  );
}

void main() {
  test('E2E: Lieferdienst bleibt über 50 Tage finanziell plausibel', () {
    var state = GameState.initial(
      companyName: 'Delivery E2E',
      founderName: 'Tester',
      startCash: 500000,
      difficulty: GameDifficulty.normal,
    ).copyWith(
      shops: List.generate(4, (i) => _shop(id: 'delivery_$i')),
      globalUpgradeIds: const ['lieferdienst', 'eigen_lieferdienst'],
      employeePool: const [],
    );

    for (var i = 0; i < 50; i++) {
      state = GameEngine.processDay(state);
      final record = state.history.last;

      expect(record.revenue, greaterThanOrEqualTo(0));
      expect(record.costs, greaterThanOrEqualTo(0));
      expect(record.deliveryCommissionCosts, greaterThan(0));
      expect(record.deliveryCommissionCosts, lessThan(record.revenue));
      expect(
        record.costs,
        closeTo(
          record.rentCosts +
              record.salaryCosts +
              record.ingredientCosts +
              record.deliveryCommissionCosts +
              GameEngine.globalUpgradeDailyCost(state),
          0.01,
        ),
      );
    }
  });

  test('E2E: Auto-Hire skaliert, stoppt am Cap und hält Cash-Reserve', () {
    final shop = _shop(id: 'hr_berlin', autoHire: true);
    final pool = List.generate(
      60,
      (i) => _candidate('candidate_$i', salary: 80 + (i % 10)),
    );

    var state = GameState.initial(
      companyName: 'HR E2E',
      founderName: 'Tester',
      startCash: 500000,
      difficulty: GameDifficulty.easy,
    ).copyWith(
      shops: [shop],
      employeePool: pool,
      hrStrategy: HrStrategy.fillFast,
    );

    var maxHiresInOneDay = 0;
    for (var i = 0; i < 50; i++) {
      final beforeEmployees = state.shops.first.employees.length;
      final beforePool = state.employeePool.length;
      state = GameEngine.processDay(state);
      final afterEmployees = state.shops.first.employees.length;
      final hiresToday = afterEmployees - beforeEmployees;
      if (hiresToday > maxHiresInOneDay) maxHiresInOneDay = hiresToday;

      expect(afterEmployees, lessThanOrEqualTo(GameEngine.maxEmployeesForShop(shop)));
      expect(state.cash, greaterThan(0));
      if (hiresToday > 0) {
        expect(state.employeePool.length, beforePool - hiresToday);
      }
    }

    expect(state.shops.first.employees.length, greaterThan(1));
    expect(maxHiresInOneDay, greaterThan(1));
    expect(state.employeePool.length, lessThan(pool.length));
  });
}
