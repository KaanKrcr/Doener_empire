import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/services/location_engine.dart';

/// Sichert die Grenze zwischen der City-Map (CityMapLocation/LocationEngine)
/// und der kanonischen Filial-Ökonomik: Was die Karte anzeigt, muss exakt dem
/// entsprechen, was beim Eröffnen einer Filiale berechnet wird
/// (siehe open_shop_screen: footTraffic, weeklyRent, deposit).
void main() {
  group('City-Map Ökonomik bleibt konsistent zur Filialöffnung', () {
    test('footTraffic, Miete und Kaution folgen der kanonischen Formel', () {
      for (final city in kAllCities) {
        final templates = kLocationTemplates[city.tier]!;
        for (final t in templates) {
          final loc = LocationEngine.findLocation(city, t.name);
          expect(loc, isNotNull, reason: '${city.id}/${t.name} nicht gefunden');

          // footTraffic = round(footTrafficBase * footTrafficFactor)
          expect(
            loc!.footTrafficFor(city),
            (city.footTrafficBase * t.footTrafficFactor).round(),
            reason: '${city.id}/${t.name} footTraffic',
          );
          // weeklyRent = rentBase * rentFactor
          expect(
            loc.weeklyRentFor(city),
            closeTo(city.rentBase * t.rentFactor, 0.0001),
            reason: '${city.id}/${t.name} weeklyRent',
          );
          // Kaution = 2 Wochenmieten
          expect(
            loc.depositFor(city),
            closeTo(loc.weeklyRentFor(city) * 2, 0.0001),
            reason: '${city.id}/${t.name} deposit',
          );
        }
      }
    });

    test('findLocation löst gültige Namen auf und null bei Unbekanntem', () {
      final fulda = kAllCities.firstWhere((c) => c.id == 'fulda');
      final first = kLocationTemplates[fulda.tier]!.first;
      expect(LocationEngine.findLocation(fulda, first.name)?.label, first.name);
      expect(LocationEngine.findLocation(fulda, 'Gibt-es-nicht'), isNull);
    });

    test('Attraktivität: Top-Lage schlägt Randlage', () {
      final fulda = kAllCities.firstWhere((c) => c.id == 'fulda');
      final markt = LocationEngine.findLocation(fulda, 'Marktplatz')!;
      final rand = LocationEngine.findLocation(fulda, 'Randlage')!;
      expect(
        markt.attractivenessScore(fulda),
        greaterThan(rand.attractivenessScore(fulda)),
      );
    });
  });
}
