import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop() {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();
  return Shop(
    id: 'shop1',
    name: 'T',
    cityId: 'fulda',
    locationName: 'Markt',
    footTraffic: 2000,
    weeklyRent: 700,
    menu: menu,
    equipment: const [],
    employees: const [],
    dayOpened: 1,
    reputation: 4.0,
  );
}

void main() {
  group('Zutaten-Preisindex (Inflation)', () {
    test('Schonfrist: erste 7 Tage neutral (Index 1.0)', () {
      expect(GameEngine.ingredientPriceIndex(1), 1.0);
      expect(GameEngine.ingredientPriceIndex(7), 1.0);
    });

    test('Index bleibt im moderaten Band [0.90, 1.22]', () {
      for (var day = 1; day <= 1000; day++) {
        final idx = GameEngine.ingredientPriceIndex(day);
        expect(idx, inInclusiveRange(0.90, 1.22), reason: 'Tag $day');
      }
    });

    test('Langfristiger Aufwärtstrend (Inflation dominiert die Welle)', () {
      double avg(int from, int to) {
        double s = 0;
        for (var d = from; d <= to; d++) {
          s += GameEngine.ingredientPriceIndex(d);
        }
        return s / (to - from + 1);
      }

      // Fenster > eine Wellenperiode (45 Tage), damit der Zyklus sich rausmittelt.
      expect(avg(350, 400), greaterThan(avg(20, 70)));
    });

    test('Zutatenkosten steigen über die Zeit (gleicher Shop/Preise)', () {
      final s =
          GameState.initial(companyName: 'T', founderName: 'K', startCash: 1)
              .copyWith(shops: [_shop()]);
      final shop = s.shops.first;
      final early =
          GameEngine.calculateDailyCostsBreakdown(shop, day: 10, state: s)
              .ingredients;
      final late =
          GameEngine.calculateDailyCostsBreakdown(shop, day: 365, state: s)
              .ingredients;
      expect(late, greaterThan(early));
    });
  });
}
