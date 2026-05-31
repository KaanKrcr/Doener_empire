import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/time_profile_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Employee _emp(String id, {EmployeeShift shift = EmployeeShift.ganztags}) =>
    Employee(
      id: id,
      typeId: kEmployeeTypes.first.id,
      name: 'E$id',
      speed: 6,
      friendliness: 6,
      reliability: 6,
      experience: 6,
      salaryPerDay: 80,
      shift: shift,
    );

Shop _shop(LocationPersonality personality, List<Employee> emps) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();
  return Shop(
    id: 'shop1',
    name: 'T',
    cityId: 'fulda',
    locationName: 'Test',
    footTraffic: 5000,
    weeklyRent: 700,
    menu: menu,
    equipment: const [],
    employees: emps,
    dayOpened: 1,
    reputation: 4.0,
    personality: personality,
  );
}

void main() {
  group('Schichtplanung – Stoßzeiten', () {
    test('Bürogegend hat Mittag-Peak, Touristisch keinen', () {
      expect(GameEngine.peakShiftForPersonality(LocationPersonality.business),
          EmployeeShift.mittag);
      expect(GameEngine.peakShiftForPersonality(LocationPersonality.touristic),
          isNull);
    });
  });

  group('Schichtplanung – Kapazitäts-Multiplikator', () {
    test('Alle ganztags = neutral (1.0), save-/balance-neutral', () {
      final shop = _shop(LocationPersonality.business,
          [_emp('1'), _emp('2')]);
      expect(GameEngine.shiftCapacityMultiplier(shop), 1.0);
    });

    test('Ausrichtung auf die Stoßzeit erhöht den Multiplikator', () {
      final aligned = _shop(LocationPersonality.business, [
        _emp('1', shift: EmployeeShift.mittag),
        _emp('2', shift: EmployeeShift.mittag),
      ]);
      expect(GameEngine.shiftCapacityMultiplier(aligned), closeTo(1.15, 0.0001));

      final half = _shop(LocationPersonality.business, [
        _emp('1', shift: EmployeeShift.mittag),
        _emp('2', shift: EmployeeShift.ganztags),
      ]);
      expect(GameEngine.shiftCapacityMultiplier(half), closeTo(1.075, 0.0001));
    });

    test('Falsche Schicht bringt keinen Bonus', () {
      final wrong = _shop(LocationPersonality.business,
          [_emp('1', shift: EmployeeShift.abend)]);
      expect(GameEngine.shiftCapacityMultiplier(wrong), 1.0);
    });

    test('Ohne Stoßzeit (touristisch) kein Bonus möglich', () {
      final shop = _shop(LocationPersonality.touristic,
          [_emp('1', shift: EmployeeShift.mittag)]);
      expect(GameEngine.shiftCapacityMultiplier(shop), 1.0);
    });

    test('Korrekte Ausrichtung hebt das Kundenpotenzial', () {
      final state =
          GameState.initial(companyName: 'T', founderName: 'K', startCash: 1);
      final ganztags = _shop(LocationPersonality.business,
          [_emp('1'), _emp('2'), _emp('3')]);
      final aligned = _shop(LocationPersonality.business, [
        _emp('1', shift: EmployeeShift.mittag),
        _emp('2', shift: EmployeeShift.mittag),
        _emp('3', shift: EmployeeShift.mittag),
      ]);
      final capG = GameEngine.calculateShopStats(ganztags, day: 1, state: state);
      final capA = GameEngine.calculateShopStats(aligned, day: 1, state: state);
      expect(capA.capacity, greaterThan(capG.capacity));
    });
  });

  group('Schichtplanung – Persistenz', () {
    test('Schicht überlebt toJson/fromJson, Alt-Save defaultet ganztags', () {
      final e = _emp('1', shift: EmployeeShift.abend);
      expect(Employee.fromJson(e.toJson()).shift, EmployeeShift.abend);

      final legacy = Employee.fromJson(<String, dynamic>{
        'id': 'x',
        'typeId': kEmployeeTypes.first.id,
        'name': 'Alt',
        'speed': 5,
        'friendliness': 5,
        'reliability': 5,
        'experience': 5,
        'salaryPerDay': 70,
      });
      expect(legacy.shift, EmployeeShift.ganztags);
    });
  });
}
