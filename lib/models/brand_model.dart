/// Markenbekanntheit + Stadt-Reputation.
///
/// Während [Shop.reputation] die *lokale* Sterne-Bewertung einer einzelnen
/// Filiale ist (Tripadvisor/Google-mäßig), beschreiben die folgenden Werte
/// die *Marke* als Ganzes:
///
/// * [brandAwareness]  – Wie bekannt ist die Kette deutschlandweit? (0..100)
///                       Bringt einen Boost in NEUEN Städten.
/// * [cityReputation]  – Stadt-spezifische Bekanntheit (0..100, pro City-ID)
///                       Boostet Kunden in dieser Stadt.
///
/// Brand-Awareness wächst LANGSAM (Marketing-Kampagnen, virale Events,
/// erfolgreiche Mission-Completions), die City-Reputation wächst pro Filiale
/// schneller, hat aber ein niedrigeres Plateau.
class BrandStats {
  /// Deutschlandweite Markenbekanntheit (0..100)
  final double brandAwareness;

  /// Stadt-spezifische Bekanntheit, key = cityId
  final Map<String, double> cityReputation;

  const BrandStats({
    this.brandAwareness = 5.0,
    this.cityReputation = const {},
  });

  BrandStats copyWith({
    double? brandAwareness,
    Map<String, double>? cityReputation,
  }) {
    return BrandStats(
      brandAwareness: brandAwareness ?? this.brandAwareness,
      cityReputation: cityReputation ?? this.cityReputation,
    );
  }

  /// Reputation in einer bestimmten Stadt (0..100).
  /// Liefert 0 wenn die Stadt noch keinen Eintrag hat.
  double inCity(String cityId) => cityReputation[cityId] ?? 0;

  /// Kombinierter Faktor (0.85 .. 1.45) für den Kundenstrom in einer Stadt.
  /// Brand-Awareness wirkt schwächer (überall), City-Rep stärker (lokal).
  double customerMultiplier(String cityId) {
    final brandPart = 0.05 * (brandAwareness / 100); // max +5%
    final cityPart = 0.40 * (inCity(cityId) / 100); // max +40%
    return (1.0 + brandPart + cityPart).clamp(0.85, 1.45);
  }

  /// Brand-Tier-Label zur Anzeige im UI.
  String get tierLabel {
    if (brandAwareness >= 80) return 'Legendär 👑';
    if (brandAwareness >= 60) return 'Weithin bekannt';
    if (brandAwareness >= 40) return 'Etablierte Marke';
    if (brandAwareness >= 20) return 'Bekannt';
    if (brandAwareness >= 5) return 'Aufstrebend';
    return 'Unbekannt';
  }

  /// Anzeige-Sterne (1..5) abgeleitet aus brandAwareness
  int get tierStars {
    if (brandAwareness >= 80) return 5;
    if (brandAwareness >= 60) return 4;
    if (brandAwareness >= 40) return 3;
    if (brandAwareness >= 20) return 2;
    return 1;
  }

  Map<String, dynamic> toJson() => {
        'brandAwareness': brandAwareness,
        'cityReputation': cityReputation,
      };

  factory BrandStats.fromJson(Map<String, dynamic> j) {
    final cityMap = <String, double>{};
    final raw = j['cityReputation'] as Map?;
    if (raw != null) {
      raw.forEach((k, v) {
        cityMap[k as String] = (v as num).toDouble();
      });
    }
    return BrandStats(
      brandAwareness: (j['brandAwareness'] as num?)?.toDouble() ?? 5.0,
      cityReputation: cityMap,
    );
  }
}
