import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/achievement_model.dart';

void main() {
  test('Achievement-IDs sind eindeutig', () {
    final ids = kAllAchievements.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('Neue Trophäen sind vorhanden und prüfbar', () {
    final ids = kAllAchievements.map((a) => a.id).toSet();
    for (final id in [
      'five_star_shop',
      'fifty_employees',
      'hundred_days',
      'cash_500k',
    ]) {
      expect(ids, contains(id));
    }
    // cash_500k wird bei 500k erfüllt, nicht darunter
    final cash500 = kAllAchievements.firstWhere((a) => a.id == 'cash_500k');
    expect(cash500.check(0, 0, 0, 499999, 0, 0, 0, 0, 0), isFalse);
    expect(cash500.check(0, 0, 0, 500000, 0, 0, 0, 0, 0), isTrue);
  });
}
