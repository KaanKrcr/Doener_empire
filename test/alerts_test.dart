import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

List<ShopProduct> _defaultMenu() => kAllProducts
    .where((p) => p.isDefault)
    .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
    .toList();

void main() {
  test('Verlustreiche Filiale erzeugt Danger-Alert', () {
    // Hohe Miete, keine Mitarbeiter, niedrige Laufkundschaft → Verlust
    final shop = Shop(
      id: 'a',
      name: 'T',
      cityId: 'fulda',
      locationName: 'Randlage',
      footTraffic: 30,
      weeklyRent: 7000,
      menu: _defaultMenu(),
      equipment: const [],
      employees: const [],
      dayOpened: 1,
      reputation: 3.0,
    );
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 15000)
        .copyWith(shops: [shop]);
    final alerts = GameEngine.shopAlerts(s);
    expect(alerts.any((a) => a.level == AlertLevel.danger && a.shopId == 'a'),
        isTrue);
  });

  test('Gesunde profitable Filiale erzeugt keinen Filial-Alert', () {
    final shop = Shop(
      id: 'b',
      name: 'T',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 3000,
      weeklyRent: 500,
      menu: _defaultMenu(),
      equipment: const [],
      employees: const [
        Employee(
          id: 'e1',
          typeId: 'koch',
          name: 'Profi',
          speed: 8,
          friendliness: 8,
          reliability: 9,
          experience: 8,
          salaryPerDay: 90,
        ),
      ],
      dayOpened: 1,
      reputation: 4.5,
    );
    final s = GameState.initial(
            companyName: 'T', founderName: 'K', startCash: 500000)
        .copyWith(shops: [shop]);
    final alerts = GameEngine.shopAlerts(s);
    expect(alerts.where((a) => a.shopId == 'b'), isEmpty);
  });
}
