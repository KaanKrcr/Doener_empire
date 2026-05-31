import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/core/constants.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/time_profile_model.dart';
import 'package:doener_empire/services/location_engine.dart';

void main() {
  test('City map exposes all configured location templates for a city', () {
    final city = kAllCities.firstWhere((c) => c.id == 'fulda');
    final mapLocations = LocationEngine.locationsFor(city);
    final templates = kLocationTemplates[city.tier]!;

    expect(mapLocations, hasLength(templates.length));
    expect(mapLocations.first.label, templates.first.name);
    expect(mapLocations.first.footTrafficFor(city), greaterThan(0));
    expect(mapLocations.first.weeklyRentFor(city), greaterThan(0));
    expect(mapLocations.first.attractivenessScore(city), inInclusiveRange(0, 100));
  });

  test('City map summary aggregates only shops in selected city', () {
    final city = kAllCities.firstWhere((c) => c.id == 'fulda');
    final otherCity = kAllCities.firstWhere((c) => c.id == 'berlin');
    final state = GameState.initial(
      companyName: 'Test Döner',
      founderName: 'Kaan',
      startCash: 50000,
    ).copyWith(
      shops: [
        Shop(
          id: 'fulda-shop',
          name: 'Test Döner',
          cityId: city.id,
          locationName: 'Marktplatz',
          footTraffic: 1200,
          weeklyRent: 900,
          menu: const [],
          equipment: const [],
          employees: const [],
          dayOpened: 1,
          reputation: 4.2,
          personality: LocationPersonality.touristic,
        ),
        Shop(
          id: 'berlin-shop',
          name: 'Test Döner',
          cityId: otherCity.id,
          locationName: 'Top-Lage Mitte',
          footTraffic: 9000,
          weeklyRent: 7000,
          menu: const [],
          equipment: const [],
          employees: const [],
          dayOpened: 1,
          reputation: 2.0,
          personality: LocationPersonality.touristic,
        ),
      ],
    );

    final summary = LocationEngine.summarize(city, state.shops);

    expect(summary.shopCount, 1);
    expect(summary.totalFootTraffic, 1200);
    expect(summary.weeklyRent, 900);
    expect(summary.avgReputation, 4.2);
  });
}
