import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Employee _emp(String id) => Employee(
      id: id,
      typeId: kEmployeeTypes.first.id,
      name: 'E$id',
      speed: 6,
      friendliness: 6,
      reliability: 6,
      experience: 6,
      salaryPerDay: 80,
    );

Shop _shop({
  required int footTraffic,
  required List<Employee> emps,
  double morale = 0.75,
}) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();
  return Shop(
    id: 'shop1',
    name: 'T',
    cityId: 'fulda',
    locationName: 'Markt',
    footTraffic: footTraffic,
    weeklyRent: 700,
    menu: menu,
    equipment: const [],
    employees: emps,
    dayOpened: 1,
    reputation: 4.0,
    morale: morale,
  );
}

GameState _state(Shop shop) => GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 1)
    .copyWith(shops: [shop]);

void main() {
  group('Mitarbeiter-Moral', () {
    test('Default-Moral 0.75 ist balance-neutral (Persistenz)', () {
      final loaded = GameState.fromJson(<String, dynamic>{
        'companyName': 'Alt',
        'founderName': 'K',
        'cash': 1000,
        'currentDay': 5,
        'shops': [
          _shop(footTraffic: 2000, emps: [_emp('1')]).toJson()..remove('morale'),
        ],
      });
      expect(loaded.shops.first.morale, 0.75);
    });

    test('Überlastung (Kapazitätsgrenze) senkt die Moral', () {
      // Viel Laufkundschaft, nur 1 Mitarbeiter → kapazitätslimitiert.
      final shop = _shop(footTraffic: 60000, emps: [_emp('1')], morale: 0.75);
      final state = _state(shop);
      final stats =
          GameEngine.calculateShopStats(shop, day: 10, state: state);
      expect(stats.isCapacityLimited, isTrue);
      final newMorale = GameEngine.updateShopMorale(shop, stats);
      expect(newMorale, lessThan(0.75));
    });

    test('Entspannte Auslastung erholt die Moral', () {
      final shop = _shop(footTraffic: 800, emps: [_emp('1'), _emp('2'), _emp('3')], morale: 0.6);
      final state = _state(shop);
      final stats =
          GameEngine.calculateShopStats(shop, day: 10, state: state);
      expect(stats.isCapacityLimited, isFalse);
      final newMorale = GameEngine.updateShopMorale(shop, stats);
      expect(newMorale, greaterThan(0.6));
    });

    test('Ohne Personal bleibt die Moral neutral', () {
      final shop = _shop(footTraffic: 2000, emps: const [], morale: 0.4);
      final state = _state(shop);
      final stats =
          GameEngine.calculateShopStats(shop, day: 10, state: state);
      expect(GameEngine.updateShopMorale(shop, stats), 0.75);
    });

    test('Moral ist auf [0.2, 1.0] begrenzt', () {
      final low = _shop(footTraffic: 60000, emps: [_emp('1')], morale: 0.2);
      final lowState = _state(low);
      final lowStats =
          GameEngine.calculateShopStats(low, day: 10, state: lowState);
      expect(GameEngine.updateShopMorale(low, lowStats),
          greaterThanOrEqualTo(0.2));

      final high = _shop(footTraffic: 500, emps: [_emp('1')], morale: 1.0);
      final highState = _state(high);
      final highStats =
          GameEngine.calculateShopStats(high, day: 10, state: highState);
      expect(GameEngine.updateShopMorale(high, highStats),
          lessThanOrEqualTo(1.0));
    });

    test('Niedrige Moral erzeugt Burnout-Alert', () {
      final shop = _shop(footTraffic: 2000, emps: [_emp('1')], morale: 0.3);
      final alerts = GameEngine.shopAlerts(_state(shop));
      expect(alerts.any((a) => a.message.contains('überlastet')), isTrue);
    });
  });
}
