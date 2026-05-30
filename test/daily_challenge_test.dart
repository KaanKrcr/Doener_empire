import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/services/game_engine.dart';

void main() {
  test('dailyChallenge ist deterministisch und rotiert', () {
    expect(GameEngine.dailyChallenge(5).type,
        GameEngine.dailyChallenge(5).type);
    final types = {
      for (var d = 0; d < ChallengeType.values.length; d++)
        GameEngine.dailyChallenge(d).type
    };
    expect(types.length, ChallengeType.values.length);
  });

  test('moreCustomers: erfüllt nur wenn mehr als gestern', () {
    const c = DailyChallenge(type: ChallengeType.moreCustomers, reward: 500);
    const yesterday =
        DailyRecord(day: 1, revenue: 0, costs: 0, customers: 100);
    expect(
        GameEngine.isChallengeMet(c,
            customersToday: 120,
            revenueToday: 0,
            profitToday: 0,
            yesterday: yesterday,
            anyShopLoss: false),
        isTrue);
    expect(
        GameEngine.isChallengeMet(c,
            customersToday: 80,
            revenueToday: 0,
            profitToday: 0,
            yesterday: yesterday,
            anyShopLoss: false),
        isFalse);
    // ohne Gestern nicht erfüllbar
    expect(
        GameEngine.isChallengeMet(c,
            customersToday: 999,
            revenueToday: 0,
            profitToday: 0,
            yesterday: null,
            anyShopLoss: false),
        isFalse);
  });

  test('allProfitable: erfüllt wenn keine Filiale Verlust macht', () {
    const c = DailyChallenge(type: ChallengeType.allProfitable, reward: 500);
    expect(
        GameEngine.isChallengeMet(c,
            customersToday: 0,
            revenueToday: 0,
            profitToday: 0,
            yesterday: null,
            anyShopLoss: false),
        isTrue);
    expect(
        GameEngine.isChallengeMet(c,
            customersToday: 0,
            revenueToday: 0,
            profitToday: 0,
            yesterday: null,
            anyShopLoss: true),
        isFalse);
  });
}
