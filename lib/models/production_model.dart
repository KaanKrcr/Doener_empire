/// Vertikale Integration: Eigene Produktionsanlagen.
///
/// Eine ProductionFacility ist eine zentrale Anlage, die einen bestimmten
/// Rohstoff (Fleisch, Brot, Gemüse) für die eigenen Filialen produziert
/// UND optional an Konkurrenten verkauft (B2B-Umsatz).
///
/// Effekte:
/// - Senkt Zutaten-Kosten in den eigenen Filialen (je nach Kapazität)
/// - Generiert eigenen Umsatz aus B2B-Verkäufen
/// - Hat tägliche Betriebskosten (Strom, Wartung, Personal)
enum ProductionType {
  fleisch, // Eigene Döner-Fleisch-Produktion
  brot, // Eigene Bäckerei (Fladen, Dürüm)
  gemuese, // Eigener Gemüse-Großhandel
}

extension ProductionTypeLabel on ProductionType {
  String get label {
    switch (this) {
      case ProductionType.fleisch:
        return 'Fleisch-Fabrik';
      case ProductionType.brot:
        return 'Bäckerei';
      case ProductionType.gemuese:
        return 'Gemüse-Großhandel';
    }
  }

  String get emoji {
    switch (this) {
      case ProductionType.fleisch:
        return '🥩';
      case ProductionType.brot:
        return '🥖';
      case ProductionType.gemuese:
        return '🥬';
    }
  }

  String get description {
    switch (this) {
      case ProductionType.fleisch:
        return 'Eigene Hähnchen-/Lamm-Verarbeitung. Senkt Fleisch-Kosten in Filialen.';
      case ProductionType.brot:
        return 'Eigene Fladen- und Dürüm-Bäckerei. Frisch und günstiger.';
      case ProductionType.gemuese:
        return 'Direkte Gemüse-Lieferung. Senkt Frische-Kosten.';
    }
  }

  /// Welcher Anteil der Zutaten-Kosten wird durch diese Anlage abgedeckt?
  /// (Fleisch ist der teuerste Anteil)
  double get costShareCovered {
    switch (this) {
      case ProductionType.fleisch:
        return 0.55;
      case ProductionType.brot:
        return 0.20;
      case ProductionType.gemuese:
        return 0.25;
    }
  }
}

/// Tier-Stufen — größere Anlagen versorgen mehr Filialen
enum FacilityTier {
  klein, // bis 5 Filialen, Anschaffung günstig
  mittel, // bis 15 Filialen
  gross, // bis 30 Filialen
  industrie, // unbegrenzt
}

extension FacilityTierLabel on FacilityTier {
  String get label {
    switch (this) {
      case FacilityTier.klein:
        return 'Klein';
      case FacilityTier.mittel:
        return 'Mittel';
      case FacilityTier.gross:
        return 'Groß';
      case FacilityTier.industrie:
        return 'Industriell';
    }
  }

  /// Wie viele Filialen kann diese Anlage maximal versorgen?
  int get maxShops {
    switch (this) {
      case FacilityTier.klein:
        return 5;
      case FacilityTier.mittel:
        return 15;
      case FacilityTier.gross:
        return 30;
      case FacilityTier.industrie:
        return 999;
    }
  }

  /// Kosten-Reduktion auf Zutaten (additiv mit Equipment-Saving)
  /// klein: -20%, mittel: -30%, gross: -40%, industrie: -50%
  double get ingredientSaving {
    switch (this) {
      case FacilityTier.klein:
        return 0.20;
      case FacilityTier.mittel:
        return 0.30;
      case FacilityTier.gross:
        return 0.40;
      case FacilityTier.industrie:
        return 0.50;
    }
  }
}

/// Daten-Klasse für eine Produktionsanlage-Bauvorlage.
class FacilityTemplate {
  final ProductionType type;
  final FacilityTier tier;
  final double buildCost;
  final double dailyOperatingCost;

  /// Tägliches B2B-Umsatz-Potenzial (wird teilweise auf Konkurrenten verkauft)
  final double b2bRevenuePerDay;

  const FacilityTemplate({
    required this.type,
    required this.tier,
    required this.buildCost,
    required this.dailyOperatingCost,
    required this.b2bRevenuePerDay,
  });
}

/// Eine GEBAUTE Produktionsanlage im Spielstand.
class ProductionFacility {
  final String id;
  final ProductionType type;
  final FacilityTier tier;
  final int dayBuilt;

  const ProductionFacility({
    required this.id,
    required this.type,
    required this.tier,
    required this.dayBuilt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'tier': tier.name,
        'dayBuilt': dayBuilt,
      };

  factory ProductionFacility.fromJson(Map<String, dynamic> j) =>
      ProductionFacility(
        id: j['id'] as String,
        type: ProductionType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => ProductionType.fleisch,
        ),
        tier: FacilityTier.values.firstWhere(
          (t) => t.name == j['tier'],
          orElse: () => FacilityTier.klein,
        ),
        dayBuilt: (j['dayBuilt'] as num).toInt(),
      );
}

/// Verfügbare Bau-Vorlagen.
const List<FacilityTemplate> kAllFacilityTemplates = [
  // Fleisch
  FacilityTemplate(
    type: ProductionType.fleisch,
    tier: FacilityTier.klein,
    buildCost: 80000,
    dailyOperatingCost: 250,
    b2bRevenuePerDay: 300,
  ),
  FacilityTemplate(
    type: ProductionType.fleisch,
    tier: FacilityTier.mittel,
    buildCost: 200000,
    dailyOperatingCost: 500,
    b2bRevenuePerDay: 800,
  ),
  FacilityTemplate(
    type: ProductionType.fleisch,
    tier: FacilityTier.gross,
    buildCost: 500000,
    dailyOperatingCost: 900,
    b2bRevenuePerDay: 1800,
  ),
  FacilityTemplate(
    type: ProductionType.fleisch,
    tier: FacilityTier.industrie,
    buildCost: 1200000,
    dailyOperatingCost: 1500,
    b2bRevenuePerDay: 4000,
  ),

  // Brot
  FacilityTemplate(
    type: ProductionType.brot,
    tier: FacilityTier.klein,
    buildCost: 35000,
    dailyOperatingCost: 120,
    b2bRevenuePerDay: 150,
  ),
  FacilityTemplate(
    type: ProductionType.brot,
    tier: FacilityTier.mittel,
    buildCost: 90000,
    dailyOperatingCost: 240,
    b2bRevenuePerDay: 400,
  ),
  FacilityTemplate(
    type: ProductionType.brot,
    tier: FacilityTier.gross,
    buildCost: 240000,
    dailyOperatingCost: 450,
    b2bRevenuePerDay: 900,
  ),

  // Gemüse
  FacilityTemplate(
    type: ProductionType.gemuese,
    tier: FacilityTier.klein,
    buildCost: 25000,
    dailyOperatingCost: 90,
    b2bRevenuePerDay: 120,
  ),
  FacilityTemplate(
    type: ProductionType.gemuese,
    tier: FacilityTier.mittel,
    buildCost: 70000,
    dailyOperatingCost: 180,
    b2bRevenuePerDay: 320,
  ),
  FacilityTemplate(
    type: ProductionType.gemuese,
    tier: FacilityTier.gross,
    buildCost: 180000,
    dailyOperatingCost: 350,
    b2bRevenuePerDay: 750,
  ),
];
