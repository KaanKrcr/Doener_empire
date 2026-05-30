/// Konzernweite Zutaten-Qualität pro Produkt.
///
/// Trade-off:
/// * Günstig  → geringere Zutatenkosten, aber Reputation leidet leicht.
/// * Standard → neutral.
/// * Premium  → höhere Zutatenkosten, dafür Reputations-Gewinn.
enum IngredientQuality { budget, standard, premium }

extension IngredientQualityX on IngredientQuality {
  String get label => switch (this) {
        IngredientQuality.budget => 'Günstig',
        IngredientQuality.standard => 'Standard',
        IngredientQuality.premium => 'Premium',
      };

  String get emoji => switch (this) {
        IngredientQuality.budget => '🪙',
        IngredientQuality.standard => '⚖️',
        IngredientQuality.premium => '✨',
      };

  /// Multiplikator auf die Zutatenkosten dieses Produkts.
  double get ingredientMult => switch (this) {
        IngredientQuality.budget => 0.78,
        IngredientQuality.standard => 1.0,
        IngredientQuality.premium => 1.35,
      };

  /// Täglicher Reputations-Beitrag des Qualitätsniveaus.
  double get reputationPerDay => switch (this) {
        IngredientQuality.budget => -0.004,
        IngredientQuality.standard => 0.0,
        IngredientQuality.premium => 0.006,
      };
}

IngredientQuality ingredientQualityFromName(String? name) {
  return IngredientQuality.values.firstWhere(
    (q) => q.name == name,
    orElse: () => IngredientQuality.standard,
  );
}
