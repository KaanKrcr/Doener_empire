import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/competitor_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop(String cityId) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();
  return Shop(
    id: 'shop_$cityId',
    name: 'T',
    cityId: cityId,
    locationName: 'Markt',
    footTraffic: 2000,
    weeklyRent: 700,
    menu: menu,
    equipment: const [],
    employees: const [],
    dayOpened: 1,
    reputation: 3.0,
  );
}

Competitor _comp(
  String cityId, {
  String id = 'c1',
  double rep = 4.0,
  int shops = 2,
}) =>
    Competitor(
      id: id,
      name: 'Rivale',
      cityId: cityId,
      personality: CompetitorPersonality.balanced,
      shopCount: shops,
      reputation: rep,
      priceLevel: 1.0,
      marketShare: 0.2,
    );

GameState _state({
  required List<Shop> shops,
  required List<Competitor> comps,
  double cash = 500000,
}) {
  return GameState.initial(companyName: 'T', founderName: 'K', startCash: cash)
      .copyWith(shops: shops, competitors: comps);
}

void main() {
  group('Konkurrenz-Übernahme', () {
    test('Kaufpreis ist im Band und steigt mit der Stärke', () {
      final weak = _comp('fulda', rep: 2.0, shops: 1);
      final strong = _comp('fulda', rep: 5.0, shops: 5);
      final cw = GameEngine.competitorBuyoutCost(weak);
      final cs = GameEngine.competitorBuyoutCost(strong);
      expect(cw, inInclusiveRange(5000.0, 500000.0));
      expect(cs, greaterThan(cw));
    });

    test('Nur möglich mit eigener Filiale in der Stadt', () {
      final c = _comp('fulda');
      final ohneFiliale = _state(shops: [_shop('bayreuth')], comps: [c]);
      final mitFiliale = _state(shops: [_shop('fulda')], comps: [c]);
      expect(GameEngine.canBuyoutCompetitor(ohneFiliale, c), isFalse);
      expect(GameEngine.canBuyoutCompetitor(mitFiliale, c), isTrue);
    });

    test('Zu wenig Cash → nicht möglich', () {
      final c = _comp('fulda');
      final s = _state(shops: [_shop('fulda')], comps: [c], cash: 100);
      expect(GameEngine.canBuyoutCompetitor(s, c), isFalse);
    });

    test('Zu wenig Cash lässt den State unverändert', () {
      final c = _comp('fulda', shops: 2, rep: 4.5);
      final s = _state(shops: [_shop('fulda')], comps: [c], cash: 1000);

      final after = GameEngine.buyoutCompetitor(s, c.id);

      expect(after.cash, s.cash);
      expect(after.competitors.length, s.competitors.length);
      expect(after.shops.length, s.shops.length);
    });

    test('Übernahme entfernt Konkurrent, zieht Cash ab, hebt Marke & Ruf', () {
      final c = _comp('fulda');
      final s = _state(shops: [_shop('fulda')], comps: [c]);
      final cost = GameEngine.competitorBuyoutCost(c);
      final brandBefore = s.brand.brandAwareness;
      final repBefore = s.shops.first.reputation;

      final after = GameEngine.buyoutCompetitor(s, 'c1');

      expect(after.competitors.any((x) => x.id == 'c1'), isFalse);
      expect(after.cash, closeTo(s.cash - cost, 0.01));
      expect(after.brand.brandAwareness, greaterThan(brandBefore));
      expect(after.shops.first.reputation, greaterThan(repBefore));
      expect(after.shops.length, s.shops.length + c.shopCount);
    });

    test('Übernahme fügt Filialen gemäß competitor.shopCount hinzu', () {
      final c = _comp('fulda', shops: 3);
      final s = _state(shops: [_shop('fulda')], comps: [c]);

      final after = GameEngine.buyoutCompetitor(s, c.id);

      expect(after.shops.length, s.shops.length + 3);
      expect(after.competitors.any((x) => x.id == c.id), isFalse);
      final acquired = after.shops.where((shop) => shop.wasAcquired).toList();
      expect(acquired.length, 3);
      for (final shop in acquired) {
        expect(shop.cityId, c.cityId);
        expect(shop.name, s.companyName);
        expect(shop.originalCompetitorName, c.name);
        expect(shop.wasAcquired, isTrue);
        expect(shop.menu.isNotEmpty, isTrue);
        expect(shop.equipment, isEmpty);
        expect(shop.employees, isEmpty);
        expect(shop.reputation, closeTo(c.reputation * 0.7, 0.0001));
      }
    });

    test('Ruf-Boost gilt nur in der betroffenen Stadt', () {
      final c = _comp('fulda');
      final s = _state(shops: [_shop('fulda'), _shop('bayreuth')], comps: [c]);
      final after = GameEngine.buyoutCompetitor(s, 'c1');
      final fulda = after.shops.firstWhere((x) => x.cityId == 'fulda');
      final bayreuth = after.shops.firstWhere((x) => x.cityId == 'bayreuth');
      expect(fulda.reputation, greaterThan(3.0));
      expect(bayreuth.reputation, 3.0); // unverändert
    });

    test('Ohne Filiale in der Stadt bleibt alles unverändert', () {
      final c = _comp('fulda');
      final s = _state(shops: [_shop('bayreuth')], comps: [c]);
      final after = GameEngine.buyoutCompetitor(s, 'c1');
      expect(after.competitors.length, 1);
      expect(after.cash, s.cash);
    });
  });
}
