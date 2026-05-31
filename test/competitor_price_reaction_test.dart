import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/competitor_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/competitor_engine.dart';

/// Spieler-Filiale in 'fulda', alle Standardprodukte zum [priceFactor] × Basispreis.
Shop _playerShop(double priceFactor) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) =>
          ShopProduct(productId: p.id, price: p.basePrice * priceFactor))
      .toList();
  return Shop(
    id: 'player1',
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

Competitor _comp(CompetitorPersonality p) => Competitor(
      id: 'c_${p.name}',
      name: p.name,
      cityId: 'fulda',
      personality: p,
      priceLevel: 1.0,
      daysSinceLastAction: 9,
    );

/// Lässt die Konkurrenz über [days] Ingame-Tage auf den Spieler reagieren.
List<Competitor> _runDays(GameState start, int days) {
  var state = start;
  for (var i = 0; i < days; i++) {
    final updated = CompetitorEngine.processDay(state);
    state = state.copyWith(competitors: updated, currentDay: state.currentDay + 1);
  }
  return state.competitors;
}

void main() {
  group('Konkurrenz-Preisreaktion', () {
    test('Aggressiv unterbietet den Spieler, Premium setzt sich darüber', () {
      // Spieler auf Basispreis-Niveau (~1.0).
      final comps = [
        _comp(CompetitorPersonality.aggressive),
        _comp(CompetitorPersonality.premium),
        _comp(CompetitorPersonality.cheapMass),
      ];
      final state = GameState.initial(
              companyName: 'T', founderName: 'K', startCash: 100000)
          .copyWith(shops: [_playerShop(1.0)], competitors: comps);

      final result = _runDays(state, 700);
      Competitor byP(CompetitorPersonality p) =>
          result.firstWhere((c) => c.personality == p);

      // Spieler-Niveau ist ~1.0.
      expect(byP(CompetitorPersonality.aggressive).priceLevel, lessThan(0.97),
          reason: 'Aggressiv soll unterbieten');
      expect(byP(CompetitorPersonality.cheapMass).priceLevel, lessThan(0.95),
          reason: 'CheapMass soll deutlich unterbieten');
      expect(byP(CompetitorPersonality.premium).priceLevel, greaterThan(1.05),
          reason: 'Premium soll sich darüber setzen');
    });

    test('Konkurrenz zieht bei hohen Spielerpreisen nach oben', () {
      // Spieler teuer (~1.3 × Basispreis): selbst der Aggressive landet höher
      // als bei günstigem Spieler.
      final cheapPlayer = GameState.initial(
              companyName: 'T', founderName: 'K', startCash: 100000)
          .copyWith(
              shops: [_playerShop(0.8)],
              competitors: [_comp(CompetitorPersonality.aggressive)]);
      final dearPlayer = GameState.initial(
              companyName: 'T', founderName: 'K', startCash: 100000)
          .copyWith(
              shops: [_playerShop(1.3)],
              competitors: [_comp(CompetitorPersonality.aggressive)]);

      final cheapResult = _runDays(cheapPlayer, 700).first.priceLevel;
      final dearResult = _runDays(dearPlayer, 700).first.priceLevel;

      expect(dearResult, greaterThan(cheapResult),
          reason: 'Höhere Spielerpreise → höheres Konkurrenz-Niveau');
    });
  });
}
