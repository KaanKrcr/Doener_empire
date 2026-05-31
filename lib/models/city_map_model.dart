import 'package:flutter/widgets.dart';

import 'city_model.dart';
import 'time_profile_model.dart';

/// Visuelle und wirtschaftliche Beschreibung eines Standort-Hotspots auf der
/// neuen City-Map. Die eigentliche Simulation bleibt bei [LocationTemplate],
/// diese Klasse ergänzt nur Karte, Position und spielbare Lesbarkeit.
class CityMapLocation {
  final String id;
  final String label;
  final String icon;
  final Offset mapPosition;
  final LocationTemplate template;
  final String audience;
  final String risk;
  final String recommendation;

  const CityMapLocation({
    required this.id,
    required this.label,
    required this.icon,
    required this.mapPosition,
    required this.template,
    required this.audience,
    required this.risk,
    required this.recommendation,
  });

  double get footTrafficFactor => template.footTrafficFactor;
  double get rentFactor => template.rentFactor;
  LocationPersonality get personality => template.personality;

  int footTrafficFor(CityData city) =>
      (city.footTrafficBase * template.footTrafficFactor).round();

  double weeklyRentFor(CityData city) => city.rentBase * template.rentFactor;

  double depositFor(CityData city) => weeklyRentFor(city) * 2;

  /// Ein kompakter Score für schnelle Standort-Vergleiche auf der Karte.
  /// Höherer Laufkundschaftsfaktor ist gut, höherer Mietfaktor drückt den Wert.
  double attractivenessScore(CityData city) {
    final traffic = footTrafficFor(city) / city.footTrafficBase;
    final rent = weeklyRentFor(city) / city.rentBase;
    return ((traffic * 70) + ((2.2 - rent).clamp(0.0, 2.2) * 20))
        .clamp(0.0, 100.0)
        .toDouble();
  }
}
