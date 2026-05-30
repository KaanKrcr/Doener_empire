import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/services/game_engine.dart';

void main() {
  test('buildWeeklyReport: null vor der ersten vollen Woche', () {
    final s = GameState.initial(
        companyName: 'T', founderName: 'K', startCash: 15000);
    expect(GameEngine.buildWeeklyReport(s), isNull);
  });

  test('buildWeeklyReport: Summen + Wachstum gegenüber Vorwoche', () {
    final history = <DailyRecord>[
      // Vorwoche (Tage 1-7): Gewinn je 200
      for (var d = 1; d <= 7; d++)
        DailyRecord(day: d, revenue: 800, costs: 600, customers: 40),
      // Letzte Woche (Tage 8-14): Gewinn je 400
      for (var d = 8; d <= 14; d++)
        DailyRecord(day: d, revenue: 1000, costs: 600, customers: 50),
    ];
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(history: history, currentDay: 15);

    final r = GameEngine.buildWeeklyReport(s)!;
    expect(r.revenue, closeTo(7000, 0.01)); // 7 × 1000
    expect(r.profit, closeTo(2800, 0.01)); // 7 × 400
    expect(r.customers, 350); // 7 × 50
    expect(r.bestDayRevenue, closeTo(1000, 0.01));
    // Vorwoche 1400 → Wachstum +100 %
    expect(r.profitGrowthPct, closeTo(100, 0.01));
  });
}
