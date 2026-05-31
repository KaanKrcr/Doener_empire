import 'package:flutter/widgets.dart';

import '../core/constants.dart';
import '../models/city_map_model.dart';
import '../models/city_model.dart';
import '../models/shop_model.dart';
import '../models/time_profile_model.dart';

class CityMapSummary {
  final int shopCount;
  final int totalFootTraffic;
  final double weeklyRent;
  final double avgReputation;

  const CityMapSummary({
    required this.shopCount,
    required this.totalFootTraffic,
    required this.weeklyRent,
    required this.avgReputation,
  });

  bool get hasPresence => shopCount > 0;
}

/// Adapter zwischen bestehenden Listen-Standorten und der neuen City-Map.
/// Keine Seiteneffekte: sicher für Tests und UI-Prognosen.
class LocationEngine {
  const LocationEngine._();

  static List<CityMapLocation> locationsFor(CityData city) {
    final templates = kLocationTemplates[city.tier] ??
        kLocationTemplates[CityTier.klein] ??
        const <LocationTemplate>[];
    return List.generate(templates.length, (index) {
      final template = templates[index];
      final meta = _metaFor(template.personality, template.name);
      return CityMapLocation(
        id: '${city.id}_${_slug(template.name)}',
        label: template.name,
        icon: meta.icon,
        mapPosition: _positionFor(index, templates.length),
        template: template,
        audience: meta.audience,
        risk: meta.risk,
        recommendation: meta.recommendation,
      );
    });
  }

  static CityMapLocation? findLocation(CityData city, String locationName) {
    for (final location in locationsFor(city)) {
      if (location.template.name == locationName ||
          location.label == locationName) {
        return location;
      }
    }
    return null;
  }

  static CityMapSummary summarize(CityData city, List<Shop> allShops) {
    final shops = allShops.where((shop) => shop.cityId == city.id).toList();
    final reputation = shops.isEmpty
        ? 0.0
        : shops.fold<double>(0, (sum, shop) => sum + shop.reputation) /
            shops.length;
    return CityMapSummary(
      shopCount: shops.length,
      totalFootTraffic: shops.fold<int>(0, (sum, shop) => sum + shop.footTraffic),
      weeklyRent: shops.fold<double>(0, (sum, shop) => sum + shop.weeklyRent),
      avgReputation: reputation,
    );
  }

  static ({String icon, String audience, String risk, String recommendation})
      _metaFor(LocationPersonality personality, String name) {
    switch (personality) {
      case LocationPersonality.business:
        return (
          icon: '🏢',
          audience: 'Büroarbeiter & Pendler',
          risk: 'Hohe Mittagsspitzen, Personalengpässe werden teuer.',
          recommendation: 'Premium-Preis + schnelle Kasse funktionieren hier gut.',
        );
      case LocationPersonality.transit:
        return (
          icon: '🚉',
          audience: 'Pendler & Laufkundschaft',
          risk: 'Wenig Loyalität: Wartezeit kostet sofort Kunden.',
          recommendation: 'Kapazität und günstige Klassiker priorisieren.',
        );
      case LocationPersonality.residential:
        return (
          icon: '🏘️',
          audience: 'Stammkunden & Familien',
          risk: 'Weniger Laufkundschaft, Wachstum braucht Reputation.',
          recommendation: 'Qualität, faire Preise und lokale Flyer stärken Stammkunden.',
        );
      case LocationPersonality.university:
        return (
          icon: '🎓',
          audience: 'Studierende',
          risk: 'Preissensibel, Rabatte drücken die Marge.',
          recommendation: 'Combos, Social Media und günstige Dürüm-Angebote testen.',
        );
      case LocationPersonality.nightlife:
        return (
          icon: '🌙',
          audience: 'Nachtschwärmer',
          risk: 'Starke Abendspitzen, schwächere Tagesauslastung.',
          recommendation: 'Späte Öffnung, Getränke und Boxen pushen.',
        );
      case LocationPersonality.touristic:
        return (
          icon: name.toLowerCase().contains('shopping') ? '🛍️' : '📍',
          audience: 'Touristen & gemischte Laufkundschaft',
          risk: 'Teure Lage: Miete muss durch hohen Durchsatz getragen werden.',
          recommendation: 'Sichtbares Marketing und solide Qualität zahlen sich aus.',
        );
    }
  }

  static Offset _positionFor(int index, int count) {
    const presets = [
      Offset(0.20, 0.68),
      Offset(0.42, 0.42),
      Offset(0.66, 0.62),
      Offset(0.78, 0.30),
      Offset(0.28, 0.24),
      Offset(0.54, 0.78),
    ];
    if (index < presets.length) return presets[index];
    final t = count <= 1 ? 0.0 : index / (count - 1);
    return Offset(
      0.18 + 0.64 * t,
      0.25 + 0.45 * ((index % 2) == 0 ? 1.0 : 0.0),
    );
  }

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
