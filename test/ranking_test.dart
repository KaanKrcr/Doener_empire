import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop(String id, int footTraffic, double rent) => Shop(
      id: id,
      name: 'T',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: footTraffic,
      weeklyRent: rent,
      menu: kAllProducts
          .where((p) => p.isDefault)
          .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
          .toList(),
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 3.5,
    );

void main() {
  test('shopsByProfit ist absteigend nach Gewinn sortiert', () {
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 50000)
        .copyWith(shops: [
      _shop('klein', 200, 4000),
      _shop('gross', 2500, 500),
      _shop('mittel', 800, 1200),
    ]);

    final ranked = GameEngine.shopsByProfit(s);
    expect(ranked.length, 3);
    for (var i = 1; i < ranked.length; i++) {
      expect(ranked[i - 1].profit, greaterThanOrEqualTo(ranked[i].profit));
    }
    // Die große Filiale mit niedriger Miete sollte vorne liegen
    expect(ranked.first.shop.id, 'gross');
  });
}
