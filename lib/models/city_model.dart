import 'time_profile_model.dart';

enum CityTier { klein, mittel, gross, metropole }

extension CityTierLabel on CityTier {
  String get label {
    switch (this) {
      case CityTier.klein:
        return 'Kleinstadt';
      case CityTier.mittel:
        return 'Mittelstadt';
      case CityTier.gross:
        return 'Großstadt';
      case CityTier.metropole:
        return 'Metropole';
    }
  }
}

class CityData {
  final String id;
  final String name;
  final String state;
  final int population;
  final CityTier tier;
  final double unlockCost;
  final double rentBase;
  final int footTrafficBase;
  final String emoji;

  const CityData({
    required this.id,
    required this.name,
    required this.state,
    required this.population,
    required this.tier,
    required this.unlockCost,
    required this.rentBase,
    required this.footTrafficBase,
    required this.emoji,
  });
}

class LocationTemplate {
  final String name;
  final double footTrafficFactor;
  final double rentFactor;
  final LocationPersonality personality;

  const LocationTemplate({
    required this.name,
    required this.footTrafficFactor,
    required this.rentFactor,
    this.personality = LocationPersonality.touristic,
  });
}
