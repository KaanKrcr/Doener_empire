import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Shop _shop({
  ShopSizeTier sizeTier = ShopSizeTier.klein,
  String cityId = 'fulda',
  double weeklyRent = 1200,
  double morale = 0.75,
  List<Employee>? employees,
  List<ShopProduct>? menu,
}) {
  final defaultMenu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();

  return Shop(
    id: 'shop_1',
    name: 'Test',
    cityId: cityId,
    locationName: 'Marktplatz',
    footTraffic: 4000,
    weeklyRent: weeklyRent,
    menu: menu ?? defaultMenu,
    equipment: const [],
    employees: employees ?? const [],
    dayOpened: 1,
    sizeTier: sizeTier,
    morale: morale,
  );
}

GameState _state(Shop shop, {double cash = 50000}) {
  return GameState.initial(
    companyName: 'Test',
    founderName: 'K',
    startCash: cash,
  ).copyWith(shops: [shop]);
}

void main() {
  group('Filialausbau', () {
    test('Mitarbeiter-Cap steigt bei Ausbau von klein auf mittel', () {
      final shop = _shop(sizeTier: ShopSizeTier.klein, cityId: 'berlin');
      final state = _state(shop, cash: 50000);

      final beforeCap = GameEngine.maxEmployeesForShop(shop);
      final after = GameEngine.expandShop(state, shop.id);
      final afterCap = GameEngine.maxEmployeesForShop(after.shops.first);

      expect(beforeCap, 3);
      expect(afterCap, 5);
    });

    test('Klein-Stadt erlaubt durch Ausbau mindestens Cap 5', () {
      final shop = _shop(sizeTier: ShopSizeTier.klein, cityId: 'fulda');
      final state = _state(shop, cash: 50000);

      final after = GameEngine.expandShop(state, shop.id);
      final cap = GameEngine.maxEmployeesForShop(after.shops.first);

      expect(cap, 5);
    });

    test('Ausbau zieht Cash korrekt ab', () {
      final shop = _shop(sizeTier: ShopSizeTier.klein);
      final state = _state(shop, cash: 50000);
      final cost = GameEngine.shopExpansionCost(shop);

      final after = GameEngine.expandShop(state, shop.id);

      expect(after.cash, closeTo(state.cash - cost, 0.001));
    });

    test('Ausbau erhöht weeklyRent persistent genau einmal', () {
      final shop = _shop(sizeTier: ShopSizeTier.klein, weeklyRent: 1200);
      final state = _state(shop, cash: 50000);

      final after = GameEngine.expandShop(state, shop.id);
      final expanded = after.shops.first;

      expect(expanded.weeklyRent, closeTo(1500, 0.001));
      expect(
        GameEngine.calculateDailyCosts(expanded.copyWith(menu: const []),
            state: after),
        closeTo(1500 / 7.0, 0.001),
      );
    });

    test('Ausbau senkt Moral einmalig', () {
      final shop = _shop(sizeTier: ShopSizeTier.klein, morale: 0.75);
      final state = _state(shop, cash: 50000);

      final after = GameEngine.expandShop(state, shop.id);
      final expanded = after.shops.first;

      expect(expanded.morale, closeTo(0.73, 0.0001));

      final costs1 = GameEngine.calculateDailyCosts(expanded, state: after);
      final costs2 = GameEngine.calculateDailyCosts(expanded, state: after);
      expect(costs1, closeTo(costs2, 0.0001));
      expect(expanded.morale, closeTo(0.73, 0.0001));
    });

    test(
        'Kapazitäts-Multiplikator wirkt auf Service-Kapazität, nicht Nachfrage',
        () {
      const employees = [
        Employee(
          id: 'e1',
          typeId: 'doener_meister',
          name: 'Ali',
          speed: 7,
          friendliness: 6,
          reliability: 6,
          experience: 6,
          salaryPerDay: 80,
        ),
      ];
      final shop = _shop(sizeTier: ShopSizeTier.klein, employees: employees);
      final state = _state(shop, cash: 50000);

      final beforeStats = GameEngine.calculateShopStats(shop,
          day: state.currentDay, state: state);
      final afterState = GameEngine.expandShop(state, shop.id);
      final expanded = afterState.shops.first;
      final afterStats = GameEngine.calculateShopStats(
        expanded,
        day: afterState.currentDay,
        state: afterState,
      );

      expect(afterStats.capacity, greaterThan(beforeStats.capacity));
      expect(afterStats.potentialCustomers, beforeStats.potentialCustomers);
    });

    test('Wenn Cash nicht reicht, bleibt State unverändert', () {
      final shop = _shop(sizeTier: ShopSizeTier.klein);
      final poorState = _state(shop, cash: 1000);

      final after = GameEngine.expandShop(poorState, shop.id);

      expect(after.cash, poorState.cash);
      expect(after.shops.first.sizeTier, poorState.shops.first.sizeTier);
      expect(after.shops.first.weeklyRent, poorState.shops.first.weeklyRent);
      expect(after.shops.first.morale, poorState.shops.first.morale);
    });

    test('Max-Stufe kann nicht weiter ausgebaut werden', () {
      final shop = _shop(sizeTier: ShopSizeTier.flagship, weeklyRent: 2520);
      final state = _state(shop, cash: 500000);

      final after = GameEngine.expandShop(state, shop.id);

      expect(after.cash, state.cash);
      expect(after.shops.first.sizeTier, ShopSizeTier.flagship);
      expect(after.shops.first.weeklyRent, state.shops.first.weeklyRent);
    });
  });
}
