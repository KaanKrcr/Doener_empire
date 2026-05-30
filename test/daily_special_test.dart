import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

void main() {
  test('Tagesspecial ist deterministisch und ein gültiges Produkt', () {
    final validIds = kAllProducts.map((p) => p.id).toSet();
    for (var day = 1; day <= 40; day++) {
      final id = GameEngine.dailySpecialProductId(day);
      expect(validIds, contains(id));
      // deterministisch: gleicher Tag → gleiches Special
      expect(GameEngine.dailySpecialProductId(day), id);
    }
  });

  test('Tagesspecial rotiert über die Tage', () {
    final specials = <String>{};
    for (var day = 0; day < kAllProducts.length; day++) {
      specials.add(GameEngine.dailySpecialProductId(day));
    }
    // über eine volle Rotation werden alle Produkte einmal Special
    expect(specials.length, kAllProducts.length);
  });
}
