import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/combo_model.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop(String id, List<String> productIds) => Shop(
      id: id,
      name: 'T',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 2500,
      weeklyRent: 700,
      menu: productIds
          .map((pid) => ShopProduct(productId: pid, price: 6.0))
          .toList(),
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 4.0,
    );

GameState _state(Shop shop, {List<String> combos = const []}) =>
    GameState.initial(companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [shop], activeComboIds: combos);

void main() {
  test('shopSupportsCombo: nur wenn alle Produkte geführt werden', () {
    final mittag = comboById('mittagsmenu')!; // doener_fladen + pommes + cola
    final withAll = _shop('a', ['doener_fladen', 'pommes', 'cola', 'ayran']);
    final without = _shop('b', ['doener_fladen', 'cola', 'ayran']); // keine Pommes
    expect(GameEngine.shopSupportsCombo(withAll, mittag), isTrue);
    expect(GameEngine.shopSupportsCombo(without, mittag), isFalse);
  });

  test('Aktives Kombo erhöht den Umsatz in unterstützenden Filialen', () {
    final shop = _shop('a', ['doener_fladen', 'pommes', 'cola', 'ayran']);
    final base = _state(shop);
    final withCombo = _state(shop, combos: ['mittagsmenu']);

    final r0 = GameEngine.calculateDailyRevenue(shop,
        day: base.currentDay, state: base);
    final r1 = GameEngine.calculateDailyRevenue(shop,
        day: withCombo.currentDay, state: withCombo);
    expect(r1, greaterThan(r0));
  });

  test('Kombo ohne passende Produkte wirkt nicht auf den Umsatz', () {
    final shop = _shop('b', ['doener_fladen', 'cola', 'ayran']); // keine Pommes
    final base = _state(shop);
    final withCombo = _state(shop, combos: ['mittagsmenu']);

    final r0 = GameEngine.calculateDailyRevenue(shop,
        day: base.currentDay, state: base);
    final r1 = GameEngine.calculateDailyRevenue(shop,
        day: withCombo.currentDay, state: withCombo);
    expect(r1, closeTo(r0, 0.001));
  });

  test('Aktive Kombos verursachen konzernweite Tagespauschale', () {
    final shop = _shop('a', ['doener_fladen', 'pommes', 'cola']);
    final s = _state(shop, combos: ['mittagsmenu']);
    expect(GameEngine.activeComboDailyCost(s),
        closeTo(comboById('mittagsmenu')!.dailyCost, 0.001));
    expect(GameEngine.activeComboDailyCost(_state(shop)), 0);
  });
}
