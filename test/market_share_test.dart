import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/competitor_model.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop(String cityId) => Shop(
      id: 'a',
      name: 'T',
      cityId: cityId,
      locationName: 'Marktplatz',
      footTraffic: 1000,
      weeklyRent: 700,
      menu: const [],
      equipment: const [],
      employees: const [],
      dayOpened: 1,
    );

void main() {
  test('Ohne eigene Filiale: 0 Marktanteil', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    expect(GameEngine.playerMarketShareIn(s, 'fulda'), 0);
  });

  test('Marktanteil = 1 − Konkurrenzanteile, geclamped', () {
    final comp = Competitor(
      id: 'c1',
      name: 'Rivale',
      cityId: 'fulda',
      shopCount: 1,
      reputation: 3.0,
      marketShare: 0.3,
      personality: CompetitorPersonality.values.first,
    );
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [_shop('fulda')], competitors: [comp]);
    expect(GameEngine.playerMarketShareIn(s, 'fulda'), closeTo(0.7, 0.001));
  });
}
