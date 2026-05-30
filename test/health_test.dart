import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

List<ShopProduct> _menu() => kAllProducts
    .where((p) => p.isDefault)
    .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
    .toList();

void main() {
  test('Ohne Filialen: neutraler Score', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    expect(GameEngine.healthScore(s).score, 50);
  });

  test('Gesundes Unternehmen → hoher Score', () {
    final shop = Shop(
      id: 'a',
      name: 'T',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 3000,
      weeklyRent: 500,
      menu: _menu(),
      equipment: const [],
      employees: const [
        Employee(
          id: 'e1',
          typeId: 'koch',
          name: 'Profi',
          speed: 8,
          friendliness: 8,
          reliability: 9,
          experience: 8,
          salaryPerDay: 90,
        ),
      ],
      dayOpened: 1,
      reputation: 4.6,
    );
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 200000)
        .copyWith(shops: [shop]);
    expect(GameEngine.healthScore(s).score, greaterThan(60));
  });

  test('Kriselndes Unternehmen → niedriger Score', () {
    final shop = Shop(
      id: 'b',
      name: 'T',
      cityId: 'fulda',
      locationName: 'Randlage',
      footTraffic: 30,
      weeklyRent: 8000,
      menu: _menu(),
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 1.5,
    );
    final loan = Loan(
      id: 'l1',
      amount: 60000,
      interestRate: 0.1,
      durationDays: 180,
      dayTaken: 1,
    );
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 800)
        .copyWith(shops: [shop], loans: [loan]);
    expect(GameEngine.healthScore(s).score, lessThan(40));
  });
}
