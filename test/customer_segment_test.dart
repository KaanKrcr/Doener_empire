import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/time_profile_model.dart';
import 'package:doener_empire/models/customer_segment_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop(LocationPersonality personality, {double priceFactor = 1.0}) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) =>
          ShopProduct(productId: p.id, price: p.basePrice * priceFactor))
      .toList();
  return Shop(
    id: 'shop_${personality.name}',
    name: 'T',
    cityId: 'fulda',
    locationName: 'Test',
    footTraffic: 2000,
    weeklyRent: 700,
    menu: menu,
    equipment: const [],
    employees: const [],
    dayOpened: 1,
    reputation: 4.0,
    personality: personality,
  );
}

void main() {
  group('Kundensegmente – Stammdaten', () {
    test('Jeder Standort-Mix summiert sich auf 1.0', () {
      for (final p in LocationPersonality.values) {
        final sum =
            segmentMixFor(p).values.fold<double>(0, (s, w) => s + w);
        expect(sum, closeTo(1.0, 0.0001), reason: '$p');
      }
    });

    test('Bonwert-Multiplikatoren sind im Mittel ~1.0 (balance-neutral)', () {
      final values =
          kCustomerSegments.values.map((d) => d.avgOrderMultiplier).toList();
      final mean = values.fold<double>(0, (s, v) => s + v) / values.length;
      expect(mean, closeTo(1.0, 0.02));
    });

    test('Studenten sind preissensibler als Feinschmecker', () {
      expect(
        CustomerSegment.students.data.priceSensitivity,
        greaterThan(CustomerSegment.gourmets.data.priceSensitivity),
      );
    });

    test('Uni-Viertel ist preissensibler als Bürogegend', () {
      expect(
        segmentPriceSensitivity(LocationPersonality.university),
        greaterThan(segmentPriceSensitivity(LocationPersonality.business)),
      );
    });

    test('Wohngebiet hat höheren Bonwert als Uni-Viertel', () {
      expect(
        segmentAvgOrderMultiplier(LocationPersonality.residential),
        greaterThan(segmentAvgOrderMultiplier(LocationPersonality.university)),
      );
    });
  });

  group('Kundensegmente – Wirkung in der Engine', () {
    test('priceDemandFactor: höhere Segment-Sensibilität dämpft bei Überpreis',
        () {
      final low = GameEngine.priceDemandFactor(
          price: 10, basePrice: 7, segmentSensitivity: 0.7);
      final high = GameEngine.priceDemandFactor(
          price: 10, basePrice: 7, segmentSensitivity: 1.35);
      expect(high, lessThan(low));
    });

    test('Familien-Standort hat höheren Bonwert als Studenten-Standort', () {
      final state =
          GameState.initial(companyName: 'T', founderName: 'K', startCash: 1);
      final residential = GameEngine.calculateShopStats(
          _shop(LocationPersonality.residential),
          day: 1,
          state: state);
      final university = GameEngine.calculateShopStats(
          _shop(LocationPersonality.university),
          day: 1,
          state: state);
      expect(residential.avgOrderValue,
          greaterThan(university.avgOrderValue));
    });

    test('Bei Überpreis verliert der sensible Standort mehr Kundschaft', () {
      final state =
          GameState.initial(companyName: 'T', founderName: 'K', startCash: 1);
      // 60% über Basispreis – Überpreis-Bereich.
      final sensitive = GameEngine.calculateShopStats(
          _shop(LocationPersonality.university, priceFactor: 1.6),
          day: 1,
          state: state);
      final relaxed = GameEngine.calculateShopStats(
          _shop(LocationPersonality.business, priceFactor: 1.6),
          day: 1,
          state: state);
      expect(sensitive.actualCustomers, lessThan(relaxed.actualCustomers));
    });
  });
}
