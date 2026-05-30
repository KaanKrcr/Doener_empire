import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/providers/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('endDay über 35 Tage läuft stabil (Steuer/Challenge/Reports)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    await notifier.startNewGame('Test Döner', 'Kaan');
    notifier.stopTimers(); // kein periodischer Timer im Test

    // Filiale eröffnen (bekommt Default-Menü)
    notifier.openShop(const Shop(
      id: 's1',
      name: 'Test Döner',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 1800,
      weeklyRent: 500,
      menu: [],
      equipment: [],
      employees: [],
      dayOpened: 1,
    ));

    // 35 Tage abschließen — überschreitet Wochen- (7) und Steuer-Grenze (30)
    for (var i = 0; i < 35; i++) {
      notifier.endDay();
    }

    final state = container.read(gameProvider)!;
    expect(state.currentDay, 36); // Start 1 + 35
    expect(state.cash.isFinite, isTrue);
    expect(notifier.lastDayResult, isNotNull);
    // Die Filiale existiert weiterhin
    expect(state.shops.length, 1);
  });
}
