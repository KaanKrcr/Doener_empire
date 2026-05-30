import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/review_util.dart';

Shop _shop(double reputation) => Shop(
      id: 'a',
      name: 'Test Döner',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 1000,
      weeklyRent: 700,
      menu: kAllProducts
          .where((p) => p.isDefault)
          .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
          .toList(),
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: reputation,
    );

void main() {
  test('Keine Bewertungen ohne Filialen', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    expect(generateReviews(s), isEmpty);
  });

  test('Bewertungen: gewünschte Anzahl, Sterne 1..5, deterministisch pro Tag', () {
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [_shop(4.0)], currentDay: 10);

    final a = generateReviews(s, count: 5);
    final b = generateReviews(s, count: 5);
    expect(a.length, 5);
    for (final r in a) {
      expect(r.stars, inInclusiveRange(1, 5));
      expect(r.text.trim(), isNotEmpty);
      expect(r.shopName, contains('Test Döner'));
    }
    // deterministisch innerhalb desselben Tages
    expect(a.map((r) => r.text).toList(), b.map((r) => r.text).toList());
  });

  test('Schlechte Reputation → tendenziell niedrigere Sterne', () {
    final good = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [_shop(5.0)], currentDay: 3);
    final bad = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [_shop(1.0)], currentDay: 3);

    final goodAvg =
        generateReviews(good, count: 6).fold<int>(0, (s, r) => s + r.stars) / 6;
    final badAvg =
        generateReviews(bad, count: 6).fold<int>(0, (s, r) => s + r.stars) / 6;
    expect(goodAvg, greaterThan(badAvg));
  });
}
