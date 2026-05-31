import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/competitor_model.dart';
import 'package:doener_empire/services/competitor_engine.dart';

Shop _shop(String cityId) => Shop(
      id: 'p_$cityId',
      name: 'P',
      cityId: cityId,
      locationName: 'L',
      footTraffic: 3000,
      weeklyRent: 700,
      menu: const [],
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 4.0,
    );

Competitor _strong(String cityId) => Competitor(
      id: 'strong_$cityId',
      name: 'Stark',
      cityId: cityId,
      personality: CompetitorPersonality.premium,
      shopCount: 3,
      reputation: 4.5,
      priceLevel: 1.2,
      marketShare: 0.3,
    );

GameState _st(List<Shop> shops, List<Competitor> comps) =>
    GameState.initial(companyName: 'T', founderName: 'K', startCash: 1)
        .copyWith(shops: shops, competitors: comps);

List<Competitor> _runDays(GameState start, int days) {
  var state = start;
  for (var i = 0; i < days; i++) {
    final updated = CompetitorEngine.processDay(state);
    state =
        state.copyWith(competitors: updated, currentDay: state.currentDay + 1);
  }
  return state.competitors;
}

void main() {
  group('Konkurrenz-Neueintritt', () {
    test('Spieler-Stadt unter Sättigung zieht neue Konkurrenz an', () {
      // fulda (Kleinstadt, Cap 1), Spieler präsent, aber 0 Konkurrenten.
      final result = _runDays(_st([_shop('fulda')], const []), 400);
      final fulda = result.where((c) => c.cityId == 'fulda').length;
      expect(fulda, greaterThanOrEqualTo(1), reason: 'Neueintritt erwartet');
      expect(fulda, lessThanOrEqualTo(1), reason: 'Cap der Kleinstadt = 1');
    });

    test('Keine Konkurrenz in Städten ohne Spielerpräsenz', () {
      final result = _runDays(_st([_shop('fulda')], const []), 400);
      expect(result.where((c) => c.cityId == 'berlin'), isEmpty);
    });

    test('Bei erreichter Sättigung kein weiterer Eintritt', () {
      // fulda Cap 1, bereits ein starker (nicht ausscheidender) Konkurrent.
      final result =
          _runDays(_st([_shop('fulda')], [_strong('fulda')]), 300);
      expect(result.where((c) => c.cityId == 'fulda').length, 1);
    });
  });
}
