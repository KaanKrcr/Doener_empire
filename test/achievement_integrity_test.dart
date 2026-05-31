import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/achievement_model.dart';
import 'package:doener_empire/models/game_state.dart';

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
    GameState withCash(double c) =>
        GameState.initial(companyName: 'T', founderName: 'K', startCash: c);
    expect(cash500.check(withCash(499999)), isFalse);
    expect(cash500.check(withCash(500000)), isTrue);
  });

  test('Neue System-Trophäen prüfen Prestige und Einkaufsvertrag', () {
    final base =
        GameState.initial(companyName: 'T', founderName: 'K', startCash: 1000);
    final franchise = kAllAchievements.firstWhere((a) => a.id == 'first_franchise');
    final hedge = kAllAchievements.firstWhere((a) => a.id == 'hedge_master');

    expect(franchise.check(base), isFalse);
    expect(franchise.check(base.copyWith(prestigePoints: 1)), isTrue);
    expect(hedge.check(base), isFalse);
    expect(hedge.check(base.copyWith(supplyContractUntilDay: 30)), isTrue);
  });
}
