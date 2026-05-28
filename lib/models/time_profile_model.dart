// Tageszeit-Profile pro Standort-Typ.
//
// Ein Imbiss in der Fußgängerzone hat einen klassischen Mittag-Peak,
// ein Laden im Club-Viertel boomt nachts. Hier definieren wir Stunden-
// Multiplikatoren (0..2.0), die in der Engine zur Kundenstrom-Berechnung
// genutzt werden.
//
// Index 0 = 10 Uhr, Index 13 = 23 Uhr (14 Stunden Betrieb).
// Siehe kDailyOpenHours = 14.

/// Standort-Persönlichkeit. Wird beim Eröffnen einer Filiale vergeben
/// und entscheidet, welches Tageszeit-Profil greift.
enum LocationPersonality {
  /// Büro/Innenstadt — starker Mittag-Peak, abends ruhig.
  business,

  /// Studenten-Viertel — Mittag UND Abend, schwache Vormittage.
  university,

  /// Touristen/Hauptstraße — ganztags konstant hoch.
  touristic,

  /// Wohngebiet — Mittag mittelmäßig, Abend stark (Familien).
  residential,

  /// Club/Trendbezirk — explodiert nach 22 Uhr, Mittag durchschnittlich.
  nightlife,

  /// Bahnhof — durchgehend Fluktuation, kein extremer Peak.
  transit,
}

extension LocationPersonalityLabel on LocationPersonality {
  String get label {
    switch (this) {
      case LocationPersonality.business:
        return 'Bürogegend';
      case LocationPersonality.university:
        return 'Uni-Viertel';
      case LocationPersonality.touristic:
        return 'Touristisch';
      case LocationPersonality.residential:
        return 'Wohngebiet';
      case LocationPersonality.nightlife:
        return 'Ausgehviertel';
      case LocationPersonality.transit:
        return 'Verkehrsknoten';
    }
  }

  String get emoji {
    switch (this) {
      case LocationPersonality.business:
        return '🏢';
      case LocationPersonality.university:
        return '🎓';
      case LocationPersonality.touristic:
        return '📸';
      case LocationPersonality.residential:
        return '🏘️';
      case LocationPersonality.nightlife:
        return '🌃';
      case LocationPersonality.transit:
        return '🚉';
    }
  }

  String get description {
    switch (this) {
      case LocationPersonality.business:
        return 'Starker Mittag-Peak (12-14h). Abends tot.';
      case LocationPersonality.university:
        return 'Mittag + Abend stark. Studenten-Vibe.';
      case LocationPersonality.touristic:
        return 'Konstant hoch ganztags. Stabil.';
      case LocationPersonality.residential:
        return 'Familien-Abendessen. Wochenende Top.';
      case LocationPersonality.nightlife:
        return 'Nacht-Crowd! Boomt nach 22 Uhr.';
      case LocationPersonality.transit:
        return 'Konstanter Strom, kein extremer Peak.';
    }
  }
}

/// Stunden-Multiplikatoren 10-24 Uhr (14 Werte).
/// Durchschnitt der Werte sollte ≈ 1.0 ergeben, damit der
/// Gesamttagesumsatz nicht völlig verzerrt wird.
class TimeProfile {
  /// 14 Werte (10h..23h), jeweils 0..2.0
  final List<double> hourlyFactors;

  /// Wochentag-Modifikator (Mo..So, 7 Werte)
  final List<double> weekdayFactors;

  const TimeProfile({
    required this.hourlyFactors,
    required this.weekdayFactors,
  });

  /// Faktor für Tag-Index (day modulo 7) + Stunden-Index (0..13)
  double factor({required int weekday, required int hourSlot}) {
    final h = hourSlot.clamp(0, hourlyFactors.length - 1);
    final w = weekday.clamp(0, weekdayFactors.length - 1);
    return hourlyFactors[h] * weekdayFactors[w];
  }

  /// Durchschnitt eines Tages → für Tages-Berechnungen
  double dailyAverage(int weekday) {
    final w = weekday.clamp(0, weekdayFactors.length - 1);
    final sum = hourlyFactors.fold(0.0, (s, h) => s + h);
    return (sum / hourlyFactors.length) * weekdayFactors[w];
  }
}

/// Vordefinierte Profile pro [LocationPersonality].
/// Stunde 0 = 10 Uhr ... Stunde 13 = 23 Uhr.
const Map<LocationPersonality, TimeProfile> kTimeProfiles = {
  // Mo, Di, Mi, Do, Fr, Sa, So
  LocationPersonality.business: TimeProfile(
    //         10   11   12   13   14   15   16   17   18   19   20   21   22   23
    hourlyFactors: [
      0.4,
      0.7,
      1.6,
      1.9,
      1.4,
      0.9,
      0.8,
      0.9,
      1.0,
      0.8,
      0.5,
      0.3,
      0.2,
      0.1
    ],
    // Wochenende stark schwach (Büros zu)
    weekdayFactors: [1.10, 1.10, 1.10, 1.10, 1.20, 0.40, 0.30],
  ),
  LocationPersonality.university: TimeProfile(
    hourlyFactors: [
      0.3,
      0.5,
      1.4,
      1.5,
      1.2,
      0.9,
      0.8,
      0.9,
      1.1,
      1.3,
      1.4,
      1.5,
      1.4,
      1.0
    ],
    // Donnerstag (Studi-Party!) + Freitag stark
    weekdayFactors: [0.85, 0.95, 1.00, 1.30, 1.25, 1.00, 0.70],
  ),
  LocationPersonality.touristic: TimeProfile(
    hourlyFactors: [
      0.7,
      1.0,
      1.2,
      1.3,
      1.2,
      1.0,
      1.0,
      1.1,
      1.3,
      1.4,
      1.3,
      1.0,
      0.8,
      0.6
    ],
    weekdayFactors: [0.90, 0.90, 0.95, 1.00, 1.15, 1.30, 1.25],
  ),
  LocationPersonality.residential: TimeProfile(
    hourlyFactors: [
      0.3,
      0.4,
      0.8,
      0.9,
      0.7,
      0.6,
      0.8,
      1.1,
      1.5,
      1.6,
      1.3,
      0.9,
      0.6,
      0.3
    ],
    weekdayFactors: [0.85, 0.85, 0.90, 0.95, 1.10, 1.30, 1.30],
  ),
  LocationPersonality.nightlife: TimeProfile(
    hourlyFactors: [
      0.2,
      0.3,
      0.8,
      0.9,
      0.7,
      0.6,
      0.7,
      0.8,
      0.9,
      1.0,
      1.2,
      1.5,
      1.9,
      2.0
    ],
    // Fr+Sa explodieren, Wochenmitte schwach
    weekdayFactors: [0.50, 0.60, 0.65, 0.80, 1.50, 1.80, 1.10],
  ),
  LocationPersonality.transit: TimeProfile(
    hourlyFactors: [
      0.8,
      1.0,
      1.2,
      1.1,
      1.0,
      1.0,
      1.1,
      1.3,
      1.2,
      1.0,
      0.9,
      0.9,
      0.8,
      0.6
    ],
    weekdayFactors: [1.05, 1.05, 1.05, 1.05, 1.10, 0.90, 0.75],
  ),
};
