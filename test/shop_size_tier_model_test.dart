import 'package:doener_empire/models/shop_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Alte Shop-JSONs ohne sizeTier laden als klein', () {
    final legacyJson = {
      'id': 's1',
      'name': 'Demo',
      'customName': null,
      'cityId': 'fulda',
      'locationName': 'Marktplatz',
      'footTraffic': 2000,
      'weeklyRent': 1200,
      'isOpen': true,
      'menu': <Map<String, dynamic>>[],
      'equipment': <Map<String, dynamic>>[],
      'employees': <Map<String, dynamic>>[],
      'reputation': 3.0,
      'dayOpened': 1,
      'activeCampaigns': <Map<String, dynamic>>[],
      'personality': 'touristic',
      'upgradeIds': <String>[],
      'autoHire': false,
      'originalCompetitorName': null,
      'wasAcquired': false,
      'morale': 0.75,
      'regulars': 0.0,
      'expansionLevel': 0,
    };

    final shop = Shop.fromJson(legacyJson);
    expect(shop.sizeTier, ShopSizeTier.klein);
  });

  test('copyWith(sizeTier: ...) funktioniert inkl. JSON-Roundtrip', () {
    const base = Shop(
      id: 's1',
      name: 'Demo',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 2000,
      weeklyRent: 1200,
      menu: [],
      equipment: [],
      employees: [],
      dayOpened: 1,
      sizeTier: ShopSizeTier.klein,
    );

    final upgraded = base.copyWith(sizeTier: ShopSizeTier.mittel);
    expect(upgraded.sizeTier, ShopSizeTier.mittel);

    final reloaded = Shop.fromJson(upgraded.toJson());
    expect(reloaded.sizeTier, ShopSizeTier.mittel);
  });
}
