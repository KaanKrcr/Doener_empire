import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

void main() {
  test('Produkt-Profitabilität: leer ohne Filialen', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    expect(GameEngine.productProfitBreakdown(s), isEmpty);
  });

  test('Produkt-Profitabilität: liefert Produkte, nach Gewinn sortiert', () {
    final menu = kAllProducts
        .where((p) => p.isDefault)
        .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
        .toList();
    final shop = Shop(
      id: 'a',
      name: 'T',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 2000,
      weeklyRent: 700,
      menu: menu,
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 4.0,
    );
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [shop]);

    final breakdown = GameEngine.productProfitBreakdown(s);
    expect(breakdown, isNotEmpty);

    // absteigend nach Gewinn sortiert
    for (var i = 1; i < breakdown.length; i++) {
      expect(breakdown[i - 1].profit, greaterThanOrEqualTo(breakdown[i].profit));
    }
    // Marge plausibel (0..1), Umsatz >= Zutatenkosten
    for (final p in breakdown) {
      expect(p.margin, inInclusiveRange(0.0, 1.0));
      expect(p.revenue, greaterThanOrEqualTo(p.ingredientCost));
    }
  });
}
