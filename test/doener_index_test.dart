import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:doener_empire/services/share_util.dart';

Shop _shopWithDoenerPrice(double price) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(
            productId: p.id,
            price: p.category == ProductCategory.doener ? price : p.basePrice,
          ))
      .toList();
  return Shop(
    id: 'shop1',
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

void main() {
  group('Döner-Index', () {
    test('Ohne Filialen ist der Ø-Döner-Preis null', () {
      final s =
          GameState.initial(companyName: 'T', founderName: 'K', startCash: 1);
      expect(GameEngine.playerAvgDoenerPrice(s), isNull);
    });

    test('Mittelt nur Döner-Produkte (keine Getränke/Beilagen)', () {
      final s = GameState.initial(
              companyName: 'T', founderName: 'K', startCash: 1)
          .copyWith(shops: [_shopWithDoenerPrice(7.50)]);
      final avg = GameEngine.playerAvgDoenerPrice(s);
      expect(avg, isNotNull);
      // Alle Döner auf 7,50 € → Schnitt exakt 7,50.
      expect(avg!, closeTo(7.50, 0.001));
    });

    test('Share-Text nennt den Vergleich zum Bundesschnitt', () {
      final cheap = GameState.initial(
              companyName: 'Test-Imbiss', founderName: 'K', startCash: 1)
          .copyWith(shops: [_shopWithDoenerPrice(5.00)]);
      final text = empireSummaryText(cheap);
      expect(text, contains('Bundesschnitt'));
      expect(text, contains('unter')); // 5,00 < 8,03
      expect(text, contains('#Döner-Index'));
    });

    test('Teurer Spieler wird als "über" dem Schnitt ausgewiesen', () {
      final dear = GameState.initial(
              companyName: 'Test-Imbiss', founderName: 'K', startCash: 1)
          .copyWith(shops: [_shopWithDoenerPrice(10.00)]);
      final text = empireSummaryText(dear);
      expect(text, contains('über'));
    });
  });
}
