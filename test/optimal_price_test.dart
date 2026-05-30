import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

double _revAt(double price, double base) =>
    GameEngine.priceDemandFactor(price: price, basePrice: base) * price;

void main() {
  test('revenueOptimalPrice liegt im plausiblen Bereich', () {
    for (final p in kAllProducts) {
      final opt = GameEngine.revenueOptimalPrice(p.basePrice);
      expect(opt, greaterThanOrEqualTo(p.basePrice * 0.5 - 0.01));
      expect(opt, lessThanOrEqualTo(p.basePrice * 2.0 + 0.01));
      expect(opt.isFinite, isTrue);
    }
  });

  test('Optimaler Preis bringt mind. so viel Umsatz/Stück wie der Basispreis',
      () {
    for (final p in kAllProducts) {
      final opt = GameEngine.revenueOptimalPrice(p.basePrice);
      expect(_revAt(opt, p.basePrice),
          greaterThanOrEqualTo(_revAt(p.basePrice, p.basePrice) - 0.001));
    }
  });
}
