import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

// Bundesland-Zuordnung laut constants: Bayern = bayreuth, augsburg, muenchen;
// Hessen = fulda, frankfurt.
Shop _shop(String cityId) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();
  return Shop(
    id: 's_$cityId',
    name: 'T',
    cityId: cityId,
    locationName: 'L',
    footTraffic: 8000,
    weeklyRent: 700,
    menu: menu,
    equipment: const [],
    employees: const [],
    dayOpened: 1,
    reputation: 4.0,
  );
}

GameState _st(List<Shop> shops) =>
    GameState.initial(companyName: 'T', founderName: 'K', startCash: 1)
        .copyWith(shops: shops);

int _potential(GameState s, String shopId) => GameEngine.calculateShopStats(
      s.shops.firstWhere((x) => x.id == shopId),
      day: 1,
      state: s,
    ).potentialCustomers;

void main() {
  group('Regional-Synergie (Bundesland)', () {
    test('Eine Stadt im Bundesland = kein Bonus', () {
      final single = _potential(_st([_shop('bayreuth')]), 's_bayreuth');
      final crossState = _potential(
          _st([_shop('bayreuth'), _shop('fulda')]), 's_bayreuth');
      // fulda liegt in Hessen → keine Synergie für die Bayern-Filiale.
      expect(crossState, single);
    });

    test('Zweite Stadt im selben Bundesland gibt Synergie', () {
      final single = _potential(_st([_shop('bayreuth')]), 's_bayreuth');
      final twoBavaria = _potential(
          _st([_shop('bayreuth'), _shop('augsburg')]), 's_bayreuth');
      expect(twoBavaria, greaterThan(single));
    });

    test('Mehr Städte im Bundesland = mehr Synergie (gestaffelt)', () {
      final two = _potential(
          _st([_shop('bayreuth'), _shop('augsburg')]), 's_bayreuth');
      final three = _potential(
          _st([_shop('bayreuth'), _shop('augsburg'), _shop('muenchen')]),
          's_bayreuth');
      expect(three, greaterThan(two));
    });

    test('Synergie gilt für alle Filialen im selben Bundesland', () {
      final state = _st([_shop('bayreuth'), _shop('augsburg')]);
      final singleAugsburg = _potential(_st([_shop('augsburg')]), 's_augsburg');
      expect(_potential(state, 's_augsburg'), greaterThan(singleAugsburg));
    });
  });
}
