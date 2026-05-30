import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/services/game_engine.dart';

void main() {
  test('Keine Steuer ohne History', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    expect(GameEngine.monthlyTaxDue(s), 0);
  });

  test('Steuer = 12% auf positiven Monatsgewinn', () {
    final history = [
      for (var d = 1; d <= 30; d++)
        DailyRecord(day: d, revenue: 1000, costs: 600, customers: 50),
    ];
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(history: history, currentDay: 31);
    // 30 × (1000-600) = 12000 Gewinn → 12% = 1440
    expect(GameEngine.monthlyTaxDue(s), closeTo(1440, 0.01));
  });

  test('Keine Steuer bei Monatsverlust', () {
    final history = [
      for (var d = 1; d <= 30; d++)
        DailyRecord(day: d, revenue: 500, costs: 900, customers: 20),
    ];
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(history: history, currentDay: 31);
    expect(GameEngine.monthlyTaxDue(s), 0);
  });
}
