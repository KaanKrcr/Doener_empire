import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/quality_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop() => Shop(
      id: 'a',
      name: 'T',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 2000,
      weeklyRent: 600,
      menu: kAllProducts
          .where((p) => p.isDefault)
          .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
          .toList(),
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 4.0,
    );

GameState _state(Map<String, String> quality) =>
    GameState.initial(companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [_shop()], productQuality: quality);

void main() {
  test('Premium-Zutaten erhöhen die Zutatenkosten gegenüber Günstig', () {
    final shop = _shop();
    final budgetMap = {for (final p in kAllProducts) p.id: 'budget'};
    final premiumMap = {for (final p in kAllProducts) p.id: 'premium'};

    final budgetState = _state(budgetMap);
    final premiumState = _state(premiumMap);

    final budgetCost = GameEngine.calculateDailyCostsBreakdown(shop,
            day: budgetState.currentDay, state: budgetState)
        .ingredients;
    final premiumCost = GameEngine.calculateDailyCostsBreakdown(shop,
            day: premiumState.currentDay, state: premiumState)
        .ingredients;

    expect(premiumCost, greaterThan(budgetCost));
  });

  test('Qualitäts-Lookup: Default Standard, Save-Round-Trip', () {
    final s = _state({'doener_fladen': 'premium'});
    expect(GameEngine.productQualityOf(s, 'doener_fladen'),
        IngredientQuality.premium);
    expect(GameEngine.productQualityOf(s, 'cola'), IngredientQuality.standard);

    final restored = GameState.fromJson(s.toJson());
    expect(restored.productQuality['doener_fladen'], 'premium');
  });

  test('ingredientQualityFromName fällt auf Standard zurück', () {
    expect(ingredientQualityFromName(null), IngredientQuality.standard);
    expect(ingredientQualityFromName('quatsch'), IngredientQuality.standard);
    expect(ingredientQualityFromName('premium'), IngredientQuality.premium);
  });
}
