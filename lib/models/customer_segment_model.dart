import 'time_profile_model.dart';

/// Kundensegmente, aus denen sich die Laufkundschaft einer Filiale zusammensetzt.
///
/// Der Mix hängt von der [LocationPersonality] des Standorts ab (siehe
/// [kSegmentMix]) und moduliert zwei Dinge in der Nachfrageberechnung:
/// * Preissensibilität — wie stark zu hohe Preise die Kundschaft abschrecken.
/// * Durchschnittlicher Bonwert — wie viel pro Besuch ausgegeben wird.
enum CustomerSegment {
  /// Studenten — knappes Budget, jagen Rabatte, geben wenig pro Besuch aus.
  students,

  /// Familien — kaufen für mehrere Personen, hoher Bonwert, moderat preisbewusst.
  families,

  /// Feinschmecker — wollen Qualität, kaum preissensibel, geben gern mehr aus.
  gourmets,

  /// Mittagshektiker — Berufstätige in Eile, kaum Zeit zum Preisvergleich.
  lunchRush,
}

class CustomerSegmentData {
  final String label;
  final String emoji;

  /// Preissensibilität: >1.0 = reagiert stärker auf zu hohe Preise, ~1.0 neutral.
  final double priceSensitivity;

  /// Bonwert-Multiplikator (Ausgabe pro Besuch), ~1.0 neutral.
  final double avgOrderMultiplier;

  const CustomerSegmentData({
    required this.label,
    required this.emoji,
    required this.priceSensitivity,
    required this.avgOrderMultiplier,
  });
}

/// Stammdaten je Segment. Die Bonwert-Multiplikatoren sind so gewählt, dass ihr
/// ungewichteter Mittel ≈ 1.0 liegt — die Segmente verschieben also die Balance
/// pro Standort, ohne den Gesamtumsatz systematisch anzuheben.
const Map<CustomerSegment, CustomerSegmentData> kCustomerSegments = {
  CustomerSegment.students: CustomerSegmentData(
    label: 'Studenten',
    emoji: '🎓',
    priceSensitivity: 1.35,
    avgOrderMultiplier: 0.80,
  ),
  CustomerSegment.families: CustomerSegmentData(
    label: 'Familien',
    emoji: '👨‍👩‍👧',
    priceSensitivity: 1.05,
    avgOrderMultiplier: 1.15,
  ),
  CustomerSegment.gourmets: CustomerSegmentData(
    label: 'Feinschmecker',
    emoji: '🍷',
    priceSensitivity: 0.70,
    avgOrderMultiplier: 1.15,
  ),
  CustomerSegment.lunchRush: CustomerSegmentData(
    label: 'Mittagshektik',
    emoji: '⏱️',
    priceSensitivity: 0.85,
    avgOrderMultiplier: 0.90,
  ),
};

extension CustomerSegmentInfo on CustomerSegment {
  CustomerSegmentData get data => kCustomerSegments[this]!;
}

/// Kundschafts-Mix einer Filiale, abgeleitet aus ihrer Standort-Persönlichkeit.
/// Die Gewichte je Standort summieren sich auf 1.0.
const Map<LocationPersonality, Map<CustomerSegment, double>> kSegmentMix = {
  LocationPersonality.business: {
    CustomerSegment.lunchRush: 0.50,
    CustomerSegment.gourmets: 0.20,
    CustomerSegment.families: 0.20,
    CustomerSegment.students: 0.10,
  },
  LocationPersonality.university: {
    CustomerSegment.students: 0.60,
    CustomerSegment.lunchRush: 0.20,
    CustomerSegment.families: 0.10,
    CustomerSegment.gourmets: 0.10,
  },
  LocationPersonality.touristic: {
    CustomerSegment.gourmets: 0.30,
    CustomerSegment.families: 0.30,
    CustomerSegment.lunchRush: 0.20,
    CustomerSegment.students: 0.20,
  },
  LocationPersonality.residential: {
    CustomerSegment.families: 0.55,
    CustomerSegment.gourmets: 0.20,
    CustomerSegment.students: 0.15,
    CustomerSegment.lunchRush: 0.10,
  },
  LocationPersonality.nightlife: {
    CustomerSegment.students: 0.45,
    CustomerSegment.gourmets: 0.30,
    CustomerSegment.lunchRush: 0.15,
    CustomerSegment.families: 0.10,
  },
  LocationPersonality.transit: {
    CustomerSegment.lunchRush: 0.50,
    CustomerSegment.students: 0.25,
    CustomerSegment.families: 0.15,
    CustomerSegment.gourmets: 0.10,
  },
};

/// Liefert den Segment-Mix für einen Standort (mit Fallback auf touristic).
Map<CustomerSegment, double> segmentMixFor(LocationPersonality personality) =>
    kSegmentMix[personality] ?? kSegmentMix[LocationPersonality.touristic]!;

/// Gewichtete Preissensibilität der Kundschaft eines Standorts (~1.0 neutral).
double segmentPriceSensitivity(LocationPersonality personality) {
  double sum = 0;
  segmentMixFor(personality)
      .forEach((seg, w) => sum += seg.data.priceSensitivity * w);
  return sum;
}

/// Gewichteter Bonwert-Multiplikator der Kundschaft eines Standorts (~1.0).
double segmentAvgOrderMultiplier(LocationPersonality personality) {
  double sum = 0;
  segmentMixFor(personality)
      .forEach((seg, w) => sum += seg.data.avgOrderMultiplier * w);
  return sum;
}

/// Kurzbeschreibung der dominierenden Segmente (Top 2), z. B. für die UI.
String segmentSummary(LocationPersonality personality) {
  final mix = segmentMixFor(personality).entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return mix
      .take(2)
      .map((e) => '${e.key.data.emoji} ${e.key.data.label}')
      .join(' · ');
}
