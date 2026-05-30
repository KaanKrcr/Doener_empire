import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/models/employee_model.dart';
import 'package:doener_empire/models/combo_model.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/game_engine.dart';

/// Stresstest: alle neuen Nachfrage-/Kosten-Modifikatoren gleichzeitig aktiv
/// (Tagesspecial, Saison, Kombos, Zutaten-Qualität, Kampagnen-Perks) über
/// 60 Ingame-Tage — Umsatz/Kosten bleiben endlich und nicht-negativ.
void main() {
  test('Alle Systeme zusammen bleiben über 60 Tage stabil', () {
    final shop = Shop(
      id: 'a',
      name: 'T',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 2500,
      weeklyRent: 700,
      // ganzes Sortiment aktiv (inkl. nicht-Default-Produkte)
      menu: kAllProducts
          .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
          .toList(),
      equipment: const [],
      employees: const [
        Employee(
          id: 'e1',
          typeId: 'koch',
          name: 'Profi',
          speed: 7,
          friendliness: 7,
          reliability: 8,
          experience: 7,
          salaryPerDay: 90,
        ),
      ],
      dayOpened: 1,
      reputation: 4.0,
    );

    var state = GameState.initial(
      companyName: 'T',
      founderName: 'K',
      startCash: 50000,
    ).copyWith(
      shops: [shop],
      activeComboIds: kAllCombos.map((c) => c.id).toList(),
      productQuality: {for (final p in kAllProducts) p.id: 'premium'},
      completedChapterIds: const [
        'ch1_traum',
        'ch2_stammkunden',
        'ch3_expansion',
      ],
    );

    for (var day = 1; day <= 60; day++) {
      state = state.copyWith(currentDay: day);
      final stats = GameEngine.calculateShopStats(shop, day: day, state: state);
      final cost = GameEngine.calculateDailyCostsBreakdown(shop,
          day: day, state: state);

      expect(stats.actualRevenue.isFinite, isTrue, reason: 'Tag $day Umsatz');
      expect(stats.actualRevenue, greaterThanOrEqualTo(0));
      expect(cost.total.isFinite, isTrue, reason: 'Tag $day Kosten');
      expect(cost.total, greaterThanOrEqualTo(0));
      expect(cost.ingredients, greaterThanOrEqualTo(0));
      // Liefer-Provision (falls vorhanden) nie über Umsatz
      expect(cost.deliveryCommission,
          lessThanOrEqualTo(stats.actualRevenue + 0.01));
    }
  });
}
