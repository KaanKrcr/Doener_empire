import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/difficulty_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:doener_empire/services/share_util.dart';

GameState _state({double totalRevenue = 0, int prestige = 0}) {
  return GameState.initial(
    companyName: 'Kaan-Imbiss',
    founderName: 'Kaan',
    startCash: 15000,
    difficulty: GameDifficulty.hard,
    prestigePoints: prestige,
  ).copyWith(totalRevenue: totalRevenue);
}

Shop _shop() {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();
  return Shop(
    id: 's1',
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
  group('Prestige – Berechnung', () {
    test('Prestige-Punkte = Gesamtumsatz / 1 Mio (abgerundet)', () {
      expect(GameEngine.prestigePointsEarned(_state(totalRevenue: 0)), 0);
      expect(GameEngine.prestigePointsEarned(_state(totalRevenue: 999999)), 0);
      expect(GameEngine.prestigePointsEarned(_state(totalRevenue: 1000000)), 1);
      expect(GameEngine.prestigePointsEarned(_state(totalRevenue: 3500000)), 3);
    });

    test('Franchise erst ab 1 Mio Gesamtumsatz möglich', () {
      expect(GameEngine.canFoundFranchise(_state(totalRevenue: 500000)),
          isFalse);
      expect(GameEngine.canFoundFranchise(_state(totalRevenue: 1200000)),
          isTrue);
    });

    test('Kunden-Bonus skaliert mit Punkten und ist bei 0.30 gedeckelt', () {
      expect(GameEngine.prestigeCustomerBonus(_state(prestige: 0)), 0.0);
      expect(GameEngine.prestigeCustomerBonus(_state(prestige: 5)),
          closeTo(0.10, 0.0001));
      expect(GameEngine.prestigeCustomerBonus(_state(prestige: 100)), 0.30);
    });

    test('Startkapital steigt mit Prestige', () {
      expect(GameEngine.prestigeStartCash(0), kStartingCash);
      expect(GameEngine.prestigeStartCash(3), kStartingCash + 30000);
    });
  });

  group('Prestige – Franchise-Neugründung', () {
    test('Unter der Schwelle bleibt der Stand unverändert', () {
      final s = _state(totalRevenue: 200000);
      expect(identical(GameEngine.foundFranchise(s), s), isTrue);
    });

    test('Neugründung setzt zurück, akkumuliert Punkte, erhöht Startkapital', () {
      final s = _state(totalRevenue: 3000000, prestige: 2)
          .copyWith(shops: [_shop()], currentDay: 120);
      final after = GameEngine.foundFranchise(s);

      // 2 (alt) + 3 (3 Mio) = 5 Punkte
      expect(after.prestigePoints, 5);
      expect(after.cash, GameEngine.prestigeStartCash(5));
      expect(after.currentDay, 1);
      expect(after.shops, isEmpty);
      expect(after.totalRevenue, 0);
      // Identität & Schwierigkeit bleiben erhalten
      expect(after.companyName, 'Kaan-Imbiss');
      expect(after.difficulty, GameDifficulty.hard);
    });
  });

  group('Prestige – Wirkung auf Nachfrage', () {
    test('Prestige erhöht das Kundenpotenzial', () {
      final base = _state(prestige: 0).copyWith(shops: [_shop()]);
      final prestiged = _state(prestige: 10).copyWith(shops: [_shop()]);
      final withoutP = GameEngine.calculateShopStats(base.shops.first,
          day: 1, state: base);
      final withP = GameEngine.calculateShopStats(prestiged.shops.first,
          day: 1, state: prestiged);
      expect(withP.potentialCustomers,
          greaterThan(withoutP.potentialCustomers));
    });
  });

  group('Prestige – Persistenz', () {
    test('Alt-Save ohne Feld lädt mit 0 Prestige', () {
      final loaded = GameState.fromJson(<String, dynamic>{
        'companyName': 'Alt',
        'founderName': 'K',
        'cash': 1000,
        'currentDay': 5,
      });
      expect(loaded.prestigePoints, 0);
    });

    test('toJson/fromJson erhält Prestige', () {
      final s = _state(prestige: 7);
      expect(GameState.fromJson(s.toJson()).prestigePoints, 7);
    });
  });

  group('Prestige – Teilen', () {
    test('Share-Text zeigt Prestige-Stufe nur ab Stufe 1', () {
      expect(empireSummaryText(_state(prestige: 0)), isNot(contains('Prestige-Stufe')));
      expect(empireSummaryText(_state(prestige: 4)), contains('Prestige-Stufe 4'));
    });
  });
}
