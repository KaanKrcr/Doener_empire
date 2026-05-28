import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/services/corporate_engine.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Shop _shop({
  required String id,
  required bool autoHire,
  required List<Employee> employees,
  List<String> upgradeIds = const [],
}) {
  return Shop(
    id: id,
    name: 'Shop $id',
    cityId: 'berlin',
    locationName: 'Test',
    footTraffic: 50000,
    weeklyRent: 5000,
    menu: kAllProducts
        .where((p) => p.isDefault)
        .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
        .toList(),
    equipment: const [],
    employees: employees,
    dayOpened: 1,
    autoHire: autoHire,
    upgradeIds: upgradeIds,
  );
}

Employee _employee(String id, {double salary = 120}) {
  final typeId = kEmployeeTypes.first.id;
  return Employee(
    id: id,
    typeId: typeId,
    name: id,
    speed: 8,
    friendliness: 8,
    reliability: 8,
    experience: 8,
    salaryPerDay: salary,
  );
}

void main() {
  test('Lieferprovision wird im Day-End-Record erfasst', () {
    final shop = _shop(
      id: 's1',
      autoHire: false,
      employees: const [],
      upgradeIds: const ['lieferdienst'],
    );
    final state = GameState.initial(
      companyName: 'Doener Test',
      founderName: 'Tester',
      startCash: 100000,
    ).copyWith(
      shops: [shop],
      currentDay: 5,
      employeePool: const [],
    );

    final expected = GameEngine.calculateDailyCostsBreakdown(
      shop,
      day: state.currentDay,
      state: state,
    ).deliveryCommission;
    expect(expected, greaterThan(0));

    final next = GameEngine.processDay(state);
    final record = next.history.last;
    expect(record.deliveryCommissionCosts, closeTo(expected, 0.01));
  });

  test('Auto-Hire bleibt pro Tag begrenzt (2-3 Hires je Filiale)', () {
    final manager = _employee('manager_1');
    final targetWithManager = _shop(
      id: 'target',
      autoHire: true,
      employees: [manager],
    );
    final targetSmall = _shop(
      id: 'target',
      autoHire: true,
      employees: const [],
    );

    final pool = List.generate(12, (i) => _employee('cand_$i'));

    final smallState = GameState.initial(
      companyName: 'Small',
      founderName: 'A',
      startCash: 500000,
    ).copyWith(
      shops: [targetSmall],
      employeePool: pool,
      currentDay: 3,
    );

    final largeOtherShops = List.generate(
      11,
      (i) => _shop(id: 'other_$i', autoHire: false, employees: const []),
    );
    final largeState = GameState.initial(
      companyName: 'Large',
      founderName: 'B',
      startCash: 500000,
    ).copyWith(
      shops: [targetWithManager, ...largeOtherShops],
      employeePool: pool,
      managerEmployeeIds: const ['manager_1'],
      currentDay: 3,
    );

    final smallAfter = CorporateEngine.applyAutoHire(smallState);
    final largeAfter = CorporateEngine.applyAutoHire(largeState);

    final smallHires =
        smallAfter.shops.firstWhere((s) => s.id == 'target').employees.length;
    final largeHires =
        largeAfter.shops.firstWhere((s) => s.id == 'target').employees.length;

    expect(smallHires, inInclusiveRange(1, 2));
    // Mit lokalem Manager in Berlin sind max. 3 Hires/Tag erlaubt.
    expect(largeHires, inInclusiveRange(2, 4));
  });
}
