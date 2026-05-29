import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/equipment_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/upgrade_model.dart';
import 'package:doener_empire/providers/game_provider.dart';
import 'package:doener_empire/services/corporate_engine.dart';
import 'package:doener_empire/services/game_engine.dart';
import 'package:doener_empire/ui/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaticGameNotifier extends GameNotifier {
  _StaticGameNotifier(this.seed);
  final GameState seed;

  @override
  GameState? build() => seed;
}

Shop _shop({
  required String id,
  required String cityId,
  required bool autoHire,
  List<Employee> employees = const [],
  List<String> upgradeIds = const [],
}) {
  return Shop(
    id: id,
    name: 'Shop $id',
    cityId: cityId,
    locationName: 'Test',
    footTraffic: cityId == 'berlin' ? 50000 : 4500,
    weeklyRent: cityId == 'berlin' ? 5000 : 1200,
    menu: kAllProducts
        .where((p) => p.isDefault)
        .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
        .toList(),
    equipment: const [],
    employees: employees,
    dayOpened: 1,
    autoHire: autoHire,
    upgradeIds: upgradeIds,
  );
}

Employee _employee(String id, {double salary = 120}) {
  final typeId = kEmployeeTypes.first.id;
  return Employee(
    id: id,
    typeId: typeId,
    name: id,
    speed: 8,
    friendliness: 8,
    reliability: 8,
    experience: 8,
    salaryPerDay: salary,
  );
}

void main() {
  group('1) Alt-Save-Kompatibilität', () {
    test('GameState lädt, wenn deliveryCommissionCosts in History fehlt', () {
      final state = GameState.initial(
        companyName: 'SaveTest',
        founderName: 'Tester',
        startCash: 12345,
      ).copyWith(
        history: const [
          DailyRecord(
            day: 1,
            revenue: 1000,
            costs: 700,
            rentCosts: 100,
            salaryCosts: 200,
            ingredientCosts: 300,
          ),
        ],
      );

      final json = state.toJson();
      final history = (json['history'] as List).cast<Map<String, dynamic>>();
      history.first.remove('deliveryCommissionCosts');
      json['history'] = history;

      final loaded = GameState.fromJson(json);
      expect(loaded.history.first.deliveryCommissionCosts, 0);
    });

    test('Legacy-Shop-Lieferdienst wird beim Laden auf global migriert', () {
      final legacyShop = _shop(
        id: 'legacy',
        cityId: 'berlin',
        autoHire: false,
        upgradeIds: const ['lieferdienst'],
      );
      final state = GameState.initial(
        companyName: 'Legacy',
        founderName: 'Tester',
        startCash: 20000,
      ).copyWith(
        shops: [legacyShop],
        globalUpgradeIds: const [],
      );

      final loaded = GameState.fromJson(state.toJson());
      expect(loaded.globalUpgradeIds.contains('lieferdienst'), isTrue);
      expect(loaded.shops.first.upgradeIds.contains('lieferdienst'), isFalse);
    });

    test('Fehlender vegetarischer Döner wird bei Alt-Save nachgetragen', () {
      final partialMenu = kAllProducts
          .where((p) => p.isDefault && p.id != 'veg_doener')
          .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
          .toList();

      final legacyShop = Shop(
        id: 'legacy_no_veg',
        name: 'Legacy',
        cityId: 'berlin',
        locationName: 'Test',
        footTraffic: 50000,
        weeklyRent: 5000,
        menu: partialMenu,
        equipment: const [],
        employees: const [],
        dayOpened: 1,
        autoHire: false,
      );

      final state = GameState.initial(
        companyName: 'LegacyMenu',
        founderName: 'Tester',
        startCash: 20000,
      ).copyWith(shops: [legacyShop]);

      final loaded = GameState.fromJson(state.toJson());
      final loadedMenuIds =
          loaded.shops.first.menu.map((m) => m.productId).toSet();
      expect(loadedMenuIds.contains('veg_doener'), isTrue);
    });

    test('Legacy-Döner-Spieß-Equipment wird auf globales Upgrade migriert', () {
      final shop = _shop(
        id: 'legacy_spiess',
        cityId: 'berlin',
        autoHire: false,
      ).copyWith(
        equipment: const [ShopEquipment(equipmentId: 'spiess_profi')],
      );

      final state = GameState.initial(
        companyName: 'LegacySpiess',
        founderName: 'Tester',
        startCash: 50000,
      ).copyWith(
        shops: [shop],
        globalUpgradeIds: const [],
      );

      final loaded = GameState.fromJson(state.toJson());
      final loadedShop = loaded.shops.first;

      expect(
        loadedShop.equipment.any((e) => e.equipmentId.startsWith('spiess_')),
        isFalse,
      );
      expect(loaded.globalUpgradeIds.contains(kGlobalSpiessProfiId), isTrue);
    });

    test('Kostenlose Startstädte bleiben bei Alt-Save freigeschaltet', () {
      final state = GameState.initial(
        companyName: 'LegacyCities',
        founderName: 'Tester',
        startCash: 10000,
      );
      final json = state.toJson();
      json['unlockedCityIds'] = <String>[];

      final loaded = GameState.fromJson(json);

      expect(loaded.unlockedCityIds.contains('fulda'), isTrue);
      expect(loaded.unlockedCityIds.contains('bayreuth'), isTrue);
      expect(loaded.unlockedCityIds.contains('goettingen'), isTrue);
    });
  });

  group('2) Lieferdienst Tageslogik', () {
    test(
        'Umsatz bleibt nicht-negativ, Provision separat, Nettogewinn sinkt über Kosten',
        () {
      final noDeliveryShop = _shop(
        id: 'base',
        cityId: 'berlin',
        autoHire: false,
      );
      final deliveryShop = _shop(
        id: 'del',
        cityId: 'berlin',
        autoHire: false,
        upgradeIds: const ['lieferdienst'],
      );

      final baseState = GameState.initial(
        companyName: 'Base',
        founderName: 'A',
        startCash: 100000,
      ).copyWith(shops: [noDeliveryShop], currentDay: 5);

      final delState = GameState.initial(
        companyName: 'Del',
        founderName: 'B',
        startCash: 100000,
      ).copyWith(shops: [deliveryShop], currentDay: 5);

      // Mehrere Tagesabschlüsse simulieren
      var rolling = delState;
      for (var i = 0; i < 3; i++) {
        rolling = GameEngine.processDay(rolling);
      }
      final delRecord = rolling.history.last;

      final baseRevenue = GameEngine.calculateDailyRevenue(noDeliveryShop,
          day: 5, state: baseState);
      final delRevenue = GameEngine.calculateDailyRevenue(deliveryShop,
          day: 5, state: delState);
      final delBreakdown = GameEngine.calculateDailyCostsBreakdown(
        deliveryShop,
        day: 5,
        state: delState,
      );

      expect(baseRevenue, greaterThanOrEqualTo(0));
      expect(delRevenue, greaterThanOrEqualTo(0));
      expect(delBreakdown.deliveryCommission, greaterThan(0));
      expect(delRecord.deliveryCommissionCosts, greaterThan(0));
      // Umsatz wird nicht durch Kosten "negativ gemacht"
      expect(delRecord.revenue, greaterThanOrEqualTo(0));
      // Kosten enthalten die Provision
      expect(
        delRecord.costs,
        closeTo(
          delRecord.rentCosts +
              delRecord.salaryCosts +
              delRecord.ingredientCosts +
              delRecord.deliveryCommissionCosts +
              GameEngine.globalUpgradeDailyCost(delState),
          0.01,
        ),
      );
    });
  });

  group('3) Delivery-App-Gating', () {
    test('Unter 3 Lieferdienst-Filialen gesperrt, ab 3 entsperrt', () {
      final under3 = GameState.initial(
        companyName: 'Under3',
        founderName: 'A',
        startCash: 1000000,
      ).copyWith(
        shops: [
          _shop(
              id: 'a',
              cityId: 'berlin',
              autoHire: false,
              upgradeIds: const ['lieferdienst']),
          _shop(
              id: 'b',
              cityId: 'berlin',
              autoHire: false,
              upgradeIds: const ['lieferdienst']),
        ],
      );
      final at3 = under3.copyWith(
        shops: [
          ...under3.shops,
          _shop(
              id: 'c',
              cityId: 'berlin',
              autoHire: false,
              upgradeIds: const ['lieferdienst']),
        ],
      );

      expect(GameEngine.canUnlockOwnDeliveryApp(under3), isFalse);
      expect(GameEngine.canUnlockOwnDeliveryApp(at3), isTrue);

      final ownApp =
          kGlobalUpgrades.firstWhere((u) => u.id == 'eigen_lieferdienst');
      final lockedBuy = GameEngine.buyUpgrade(under3, '', ownApp);
      final unlockedBuy = GameEngine.buyUpgrade(at3, '', ownApp);

      expect(
          lockedBuy.globalUpgradeIds.contains('eigen_lieferdienst'), isFalse);
      expect(
          unlockedBuy.globalUpgradeIds.contains('eigen_lieferdienst'), isTrue);
    });
  });

  group('4) Auto-Hire-Verhalten', () {
    test('Kleine/große Filiale: Hires, Cash und Pool-Verlauf erfassbar', () {
      final smallShop = _shop(id: 'small', cityId: 'fulda', autoHire: true);
      final largeShop = _shop(id: 'large', cityId: 'berlin', autoHire: true);
      final pool = List.generate(
          8, (i) => _employee('cand_$i', salary: 100 + i.toDouble()));

      final state = GameState.initial(
        companyName: 'AutoHire',
        founderName: 'Tester',
        startCash: 10000,
      ).copyWith(
        shops: [smallShop, largeShop],
        employeePool: pool,
      );

      final after = CorporateEngine.applyAutoHire(state);
      final smallAfter = after.shops.firstWhere((s) => s.id == 'small');
      final largeAfter = after.shops.firstWhere((s) => s.id == 'large');

      final smallHires = smallAfter.employees.length;
      final largeHires = largeAfter.employees.length;
      final cashDelta = state.cash - after.cash;
      final poolDelta = state.employeePool.length - after.employeePool.length;

      expect(smallHires,
          inInclusiveRange(0, GameEngine.maxEmployeesForShop(smallShop)));
      expect(largeHires,
          inInclusiveRange(0, GameEngine.maxEmployeesForShop(largeShop)));
      expect(cashDelta, greaterThanOrEqualTo(0));
      expect(poolDelta, greaterThanOrEqualTo(0));
    });

    test('Leerer Pool wird nicht automatisch unbegrenzt aufgefüllt', () {
      final largeShop =
          _shop(id: 'large_empty', cityId: 'berlin', autoHire: true);
      final state = GameState.initial(
        companyName: 'AutoHirePool',
        founderName: 'Tester',
        startCash: 10000,
      ).copyWith(
        shops: [largeShop],
        employeePool: const [],
      );

      final after = CorporateEngine.applyAutoHire(state);
      final largeAfter = after.shops.firstWhere((s) => s.id == 'large_empty');

      expect(largeAfter.employees.length, 0);
      expect(after.cash, state.cash);
    });
  });

  group('5) Corporate-Tab Stabilität', () {
    testWidgets('Konzern-Tab rendert ohne NoSuchMethodError', (tester) async {
      final seeded = GameState.initial(
        companyName: 'Corp',
        founderName: 'Tester',
        startCash: 50000,
      ).copyWith(
        shops: [
          _shop(id: 'corp_1', cityId: 'berlin', autoHire: false),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameProvider.overrideWith(() => _StaticGameNotifier(seeded)),
            navIndexProvider.overrideWith((ref) => 3),
          ],
          child: const MaterialApp(home: MainScaffold()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Konzern'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
