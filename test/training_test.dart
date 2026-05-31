import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:doener_empire/services/hr_engine.dart';

Employee _emp({int speed = 4}) => Employee(
      id: 'e1',
      typeId: kEmployeeTypes.first.id,
      name: 'Ali',
      speed: speed,
      friendliness: 4,
      reliability: 4,
      experience: 4,
      salaryPerDay: 80,
    );

GameState _stateWith(Employee emp, {double cash = 100000}) {
  final shop = Shop(
    id: 'shop1',
    name: 'T',
    cityId: 'fulda',
    locationName: 'Markt',
    footTraffic: 2000,
    weeklyRent: 700,
    menu: const [],
    equipment: const [],
    employees: [emp],
    dayOpened: 1,
    reputation: 4.0,
  );
  return GameState.initial(companyName: 'T', founderName: 'K', startCash: cash)
      .copyWith(shops: [shop]);
}

void main() {
  group('Bezahltes Training', () {
    test('Kurs hebt gewählten Stat um 1 und zieht Cash ab', () {
      final state = _stateWith(_emp(speed: 4));
      final cost =
          HrEngine.trainingCost(state, state.shops.first.employees.first,
              EmployeeSkill.speed);

      final after = GameEngine.trainEmployee(
          state, 'shop1', 'e1', EmployeeSkill.speed);

      expect(after.shops.first.employees.first.speed, 5);
      expect(after.cash, closeTo(state.cash - cost, 0.01));
      // Andere Stats unverändert
      expect(after.shops.first.employees.first.friendliness, 4);
    });

    test('Ohne genug Cash passiert nichts', () {
      final emp = _emp(speed: 4);
      final state = _stateWith(emp, cash: 10);
      final after = GameEngine.trainEmployee(
          state, 'shop1', 'e1', EmployeeSkill.speed);
      expect(after.shops.first.employees.first.speed, 4);
      expect(after.cash, 10);
    });

    test('Stat bei 10 ist nicht weiter trainierbar', () {
      final emp = _emp().copyWith(experience: 10);
      final state = _stateWith(emp);
      expect(HrEngine.canTrain(emp, EmployeeSkill.experience), isFalse);
      final after = GameEngine.trainEmployee(
          state, 'shop1', 'e1', EmployeeSkill.experience);
      expect(after.shops.first.employees.first.experience, 10);
      expect(after.cash, state.cash); // kein Abzug
    });

    test('Kosten steigen mit der Zielstufe', () {
      final lowState = _stateWith(_emp(speed: 2));
      final highState = _stateWith(_emp(speed: 8));
      final low = HrEngine.trainingCost(
          lowState, lowState.shops.first.employees.first, EmployeeSkill.speed);
      final high = HrEngine.trainingCost(highState,
          highState.shops.first.employees.first, EmployeeSkill.speed);
      expect(high, greaterThan(low));
    });
  });
}
