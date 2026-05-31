import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

Shop _shop(String id) {
  final menu = kAllProducts
      .where((p) => p.isDefault)
      .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
      .toList();
  return Shop(
    id: id,
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

GameState _state({int day = 50, int shops = 1, double cash = 100000}) {
  return GameState.initial(
          companyName: 'T', founderName: 'K', startCash: cash)
      .copyWith(
    currentDay: day,
    shops: [for (var i = 0; i < shops; i++) _shop('s$i')],
  );
}

void main() {
  group('Einkaufsvertrag / Preisbindung', () {
    test('Ohne Vertrag entspricht der effektive Index dem Marktindex', () {
      final s = _state();
      expect(GameEngine.effectiveIngredientIndex(s, 50),
          GameEngine.ingredientPriceIndex(50));
    });

    test('Abschluss friert den Marktindex ein und zieht die Gebühr ab', () {
      final s = _state(day: 50);
      final fee = GameEngine.supplyContractFee(s, 30);
      final after = GameEngine.signSupplyContract(s, 30);

      expect(after.supplyContractUntilDay, 80);
      expect(after.supplyContractIndex,
          closeTo(GameEngine.ingredientPriceIndex(50), 0.0001));
      expect(after.cash, closeTo(s.cash - fee, 0.01));
    });

    test('Während der Laufzeit gilt der eingefrorene Index, danach der Markt',
        () {
      final s = _state(day: 50);
      final after = GameEngine.signSupplyContract(s, 30); // bis Tag 80
      // Während der Bindung:
      expect(GameEngine.effectiveIngredientIndex(after, 70),
          after.supplyContractIndex);
      // Nach Ablauf wieder Markt:
      expect(GameEngine.effectiveIngredientIndex(after, 90),
          GameEngine.ingredientPriceIndex(90));
    });

    test('Während der Bindung gilt immer der Lock; an teuren Tagen schützt er',
        () {
      final s = _state(day: 50);
      final after = GameEngine.signSupplyContract(s, 60);
      final locked = after.supplyContractIndex;
      var sawProtection = false;
      for (var d = s.currentDay; d <= after.supplyContractUntilDay; d++) {
        // Invariante: im Fenster gilt immer der eingefrorene Index.
        expect(GameEngine.effectiveIngredientIndex(after, d), locked,
            reason: 'Tag $d');
        if (GameEngine.ingredientPriceIndex(d) > locked + 0.001) {
          sawProtection = true; // mind. ein Tag, an dem der Lock günstiger ist
        }
      }
      expect(sawProtection, isTrue);
    });

    test('Ohne genug Cash passiert nichts', () {
      final s = _state(day: 50, cash: 50);
      final after = GameEngine.signSupplyContract(s, 30);
      expect(after.supplyContractUntilDay, 0);
      expect(after.cash, 50);
    });

    test('Gebühr ist mindestens 200 € und steigt mit der Empire-Größe', () {
      final one = _state(shops: 1);
      final many = _state(shops: 12);
      final feeOne = GameEngine.supplyContractFee(one, 30);
      final feeMany = GameEngine.supplyContractFee(many, 30);
      expect(feeOne, greaterThanOrEqualTo(200.0));
      expect(feeMany, greaterThan(feeOne));
    });

    test('Alt-Save ohne Vertragsfelder lädt sicher mit Defaults', () {
      final loaded = GameState.fromJson(<String, dynamic>{
        'companyName': 'Alt',
        'founderName': 'K',
        'cash': 5000,
        'currentDay': 12,
      });
      expect(loaded.supplyContractUntilDay, 0);
      expect(loaded.supplyContractIndex, 1.0);
    });

    test('toJson/fromJson erhält den aktiven Vertrag', () {
      final signed = GameEngine.signSupplyContract(_state(day: 50), 30);
      final round = GameState.fromJson(signed.toJson());
      expect(round.supplyContractUntilDay, signed.supplyContractUntilDay);
      expect(round.supplyContractIndex,
          closeTo(signed.supplyContractIndex, 0.0001));
    });
  });

  group('Inflations-Hinweis im Dashboard', () {
    bool hasHint(GameState s) =>
        GameEngine.shopAlerts(s).any((a) => a.message.contains('Preisbindung'));

    test('Hoher Index ohne Vertrag erzeugt Preisbindungs-Hinweis', () {
      // Tag 800: Drift gedeckelt (+15 %), Index immer >= ~1.10.
      expect(hasHint(_state(day: 800)), isTrue);
    });

    test('Mit aktivem Vertrag erscheint kein Hinweis', () {
      final signed = GameEngine.signSupplyContract(_state(day: 800), 60);
      expect(hasHint(signed), isFalse);
    });

    test('In der Schonfrist (frühe Tage) kein Hinweis', () {
      expect(hasHint(_state(day: 3)), isFalse);
    });
  });
}
