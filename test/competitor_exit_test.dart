import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/competitor_model.dart';
import 'package:doener_empire/services/competitor_engine.dart';

Shop _pShop(String id) => Shop(
      id: id,
      name: 'P',
      cityId: 'fulda',
      locationName: 'L',
      footTraffic: 3000,
      weeklyRent: 700,
      menu: const [],
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 5.0,
    );

Competitor _comp({
  required String id,
  required double rep,
  required int shops,
  double price = 1.0,
  CompetitorPersonality p = CompetitorPersonality.balanced,
}) =>
    Competitor(
      id: id,
      name: id,
      cityId: 'fulda',
      personality: p,
      shopCount: shops,
      reputation: rep,
      priceLevel: price,
      marketShare: 0.1,
    );

GameState _state(List<Shop> shops, List<Competitor> comps) =>
    GameState.initial(companyName: 'T', founderName: 'K', startCash: 1)
        .copyWith(shops: shops, competitors: comps);

List<Competitor> _runDays(GameState start, int days) {
  var state = start;
  for (var i = 0; i < days; i++) {
    final updated = CompetitorEngine.processDay(state);
    state = state.copyWith(
        competitors: updated, currentDay: state.currentDay + 1);
  }
  return state.competitors;
}

void main() {
  group('Konkurrenz-Marktaustritt', () {
    test('Schwacher Konkurrent (nicht letzter) verlässt den Markt', () {
      // Dominante Spielerpräsenz drückt den Marktanteil des Schwachen < 6 %.
      final players = [for (var i = 0; i < 4; i++) _pShop('p$i')];
      final comps = [
        _comp(
            id: 'weak',
            rep: 1.0,
            shops: 1,
            p: CompetitorPersonality.cheapMass),
        _comp(
            id: 'strong',
            rep: 4.0,
            shops: 2,
            price: 1.2,
            p: CompetitorPersonality.premium),
      ];
      final result = _runDays(_state(players, comps), 800);
      expect(result.any((c) => c.id == 'weak'), isFalse,
          reason: 'Schwacher Konkurrent sollte ausgeschieden sein');
      expect(result.any((c) => c.id == 'strong'), isTrue,
          reason: 'Starker Konkurrent bleibt');
    });

    test('Letzter Wettbewerber einer Stadt scheidet nie durch Schwäche aus',
        () {
      final players = [for (var i = 0; i < 6; i++) _pShop('p$i')];
      final result = _runDays(
        _state(players,
            [_comp(id: 'solo', rep: 1.0, shops: 1, p: CompetitorPersonality.cheapMass)]),
        800,
      );
      expect(result.any((c) => c.id == 'solo'), isTrue);
      expect(result.length, 1);
    });

    test('Starker Konkurrent bleibt stabil im Markt', () {
      final result = _runDays(
        _state([_pShop('p0')],
            [_comp(id: 'king', rep: 4.8, shops: 3, price: 1.2, p: CompetitorPersonality.premium)]),
        400,
      );
      expect(result.any((c) => c.id == 'king'), isTrue);
    });
  });
}
