import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/branding_model.dart';
import 'package:doener_empire/models/game_state.dart';

void main() {
  test('Klassik ist immer freigeschaltet, Skins brauchen Trophäen', () {
    final klassik = brandThemeById('klassik');
    expect(klassik.unlocked(<String>{}), isTrue);

    final gold = brandThemeById('gold'); // braucht cash_250k
    expect(gold.unlockAchievementId, isNotNull);
    expect(gold.unlocked(<String>{}), isFalse);
    expect(gold.unlocked({gold.unlockAchievementId!}), isTrue);
  });

  test('brandThemeById fällt auf Klassik zurück', () {
    expect(brandThemeById('gibtsnicht').id, 'klassik');
  });

  test('activeThemeId: Default + Save-Round-Trip', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    expect(s.activeThemeId, 'klassik');

    final themed = s.copyWith(activeThemeId: 'neon');
    final restored = GameState.fromJson(themed.toJson());
    expect(restored.activeThemeId, 'neon');
  });

  test('Alte Saves ohne activeThemeId laden als Klassik', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    final json = s.toJson()..remove('activeThemeId');
    final restored = GameState.fromJson(json);
    expect(restored.activeThemeId, 'klassik');
  });
}
