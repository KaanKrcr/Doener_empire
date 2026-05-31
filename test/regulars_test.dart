import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Employee _charmer() => const Employee(
      id: 'c1',
      typeId: 'kassierer',
      name: 'Charme',
      speed: 5,
      friendliness: 9,
      reliability: 6,
      experience: 5,
      salaryPerDay: 70,
      traits: [PersonalityTrait.charmer],
    );

Shop _shop({
  required double reputation,
  double regulars = 0.0,
  bool isOpen = true,
  bool charmer = false,
  int footTraffic = 3000,
  bool withMenu = false,
}) {
  final menu = withMenu
      ? kAllProducts
          .where((p) => p.isDefault)
          .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
          .toList()
      : const <ShopProduct>[];
  return Shop(
    id: 's1',
    name: 'T',
    cityId: 'fulda',
    locationName: 'Markt',
    footTraffic: footTraffic,
    weeklyRent: 700,
    menu: menu,
    equipment: const [],
    employees: charmer ? [_charmer()] : const [],
    dayOpened: 1,
    reputation: reputation,
    isOpen: isOpen,
    regulars: regulars,
  );
}

void main() {
  group('Stammkunden – Aufbau & Abbau', () {
    test('Hohe Reputation baut Stammkunden auf', () {
      final next = GameEngine.updateRegulars(_shop(reputation: 5.0));
      expect(next, greaterThan(0.0));
    });

    test('Konvergiert gegen das Maximum, ohne es zu überschreiten', () {
      var shop = _shop(reputation: 5.0);
      for (var i = 0; i < 100; i++) {
        shop = shop.copyWith(regulars: GameEngine.updateRegulars(shop));
      }
      expect(shop.regulars, closeTo(GameEngine.kMaxRegulars, 0.01));
      expect(shop.regulars, lessThanOrEqualTo(GameEngine.kMaxRegulars));
    });

    test('Niedrige Reputation baut Stammkunden ab', () {
      final next =
          GameEngine.updateRegulars(_shop(reputation: 2.0, regulars: 0.4));
      expect(next, lessThan(0.4));
    });

    test('Geschlossene Filiale verliert Stammkunden', () {
      final next = GameEngine.updateRegulars(
          _shop(reputation: 5.0, regulars: 0.3, isOpen: false));
      expect(next, lessThan(0.3));
    });

    test('Charmante Mitarbeiter beschleunigen den Aufbau', () {
      final base =
          GameEngine.updateRegulars(_shop(reputation: 5.0, regulars: 0.1));
      final charmed = GameEngine.updateRegulars(
          _shop(reputation: 5.0, regulars: 0.1, charmer: true));
      expect(charmed, greaterThan(base));
    });
  });

  group('Stammkunden – Wirkung & Persistenz', () {
    test('Stammkunden erhöhen das Kundenpotenzial', () {
      final state =
          GameState.initial(companyName: 'T', founderName: 'K', startCash: 1);
      final without = GameEngine.calculateShopStats(
          _shop(reputation: 4.0, regulars: 0.0, withMenu: true),
          day: 1,
          state: state);
      final withReg = GameEngine.calculateShopStats(
          _shop(reputation: 4.0, regulars: 0.5, withMenu: true),
          day: 1,
          state: state);
      expect(withReg.potentialCustomers,
          greaterThan(without.potentialCustomers));
    });

    test('Alt-Save ohne Feld lädt mit 0 Stammkunden; Round-Trip erhält Wert',
        () {
      final legacy = Shop.fromJson(<String, dynamic>{
        'id': 'x',
        'name': 'T',
        'cityId': 'fulda',
        'locationName': 'L',
        'footTraffic': 2000,
        'weeklyRent': 700,
        'isOpen': true,
        'menu': const [],
        'equipment': const [],
        'employees': const [],
        'reputation': 4.0,
        'dayOpened': 1,
      });
      expect(legacy.regulars, 0.0);

      final round = Shop.fromJson(_shop(reputation: 4.0, regulars: 0.3).toJson());
      expect(round.regulars, closeTo(0.3, 0.0001));
    });
  });
}
