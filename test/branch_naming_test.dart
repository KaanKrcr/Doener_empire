import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/competitor_model.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/services/corporate_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Shop _shop({
  required String id,
  required String name,
  String? customName,
}) {
  return Shop(
    id: id,
    name: name,
    customName: customName,
    cityId: 'berlin',
    locationName: 'Innenstadt',
    footTraffic: 50000,
    weeklyRent: 5000,
    menu: kAllProducts
        .where((p) => p.isDefault)
        .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
        .toList(),
    equipment: const [],
    employees: const [],
    dayOpened: 1,
  );
}

void main() {
  test('Legacy-Filialnamen werden auf customName migriert', () {
    final legacy = _shop(id: 's1', name: 'Sultan Berlin');
    final state = GameState.initial(
      companyName: 'Doener Empire',
      founderName: 'Tester',
      startCash: 10000,
    ).copyWith(shops: [legacy]);

    final json = state.toJson();
    final shops = (json['shops'] as List).cast<Map<String, dynamic>>();
    shops[0].remove('customName');
    shops[0]['name'] = 'Sultan Berlin';
    json['shops'] = shops;

    final loaded = GameState.fromJson(json);
    final loadedShop = loaded.shops.first;
    expect(loadedShop.name, 'Doener Empire');
    expect(loadedShop.customName, 'Sultan Berlin');
    expect(loadedShop.displayName, 'Doener Empire - Sultan Berlin');
  });

  test('Aufgekaufte Filialen werden auf Konzernname gebrandet', () {
    final competitor = Competitor(
      id: 'comp1',
      name: 'Rival Grill',
      cityId: 'berlin',
      personality: CompetitorPersonality.balanced,
      shopCount: 2,
      reputation: 3.2,
      priceLevel: 1.0,
    );

    final state = GameState.initial(
      companyName: 'Doener Empire',
      founderName: 'Tester',
      startCash: 1000000,
    ).copyWith(
      competitors: [competitor],
    );

    final after = CorporateEngine.acquireCompetitor(state, competitor);
    final acquired = after.shops.where((s) => s.wasAcquired).toList();

    expect(acquired.length, 2);
    for (final shop in acquired) {
      expect(shop.name, 'Doener Empire');
      expect(shop.wasAcquired, isTrue);
      expect(shop.originalCompetitorName, 'Rival Grill');
    }
  });

  test('displayName nutzt Konzernname und optionalen Filialnamen', () {
    final branded = _shop(id: 'a', name: 'Doener Empire');
    final custom = _shop(
      id: 'b',
      name: 'Doener Empire',
      customName: 'Alexanderplatz',
    );

    expect(branded.displayName, 'Doener Empire');
    expect(custom.displayName, 'Doener Empire - Alexanderplatz');
  });
}
