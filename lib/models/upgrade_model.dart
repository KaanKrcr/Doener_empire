/// Permanente Shop-Upgrades.
///
/// Anders als Equipment (das primär Capacity/Quality boostet) oder Marketing
/// (das ZEITLICH BEGRENZT ist), sind Upgrades dauerhafte Veränderungen am
/// Komfort der Filiale. Sie ziehen mehr Kunden an, kosten aber laufend
/// monatlich Geld (täglicher Anteil = monatlich / 30).
///
/// Beispiele: Gratis-WLAN, lizenzierte Musik, Klimaanlage, Stammkunden-App.
enum UpgradeCategory {
  komfort,    // WLAN, Klimaanlage, Heizung → Komfort
  ambiente,   // Musik, Deko, Beleuchtung → Atmosphäre
  service,    // Stammkunden-App, Lieferdienst → Service
  hygiene,    // Premium-Reinigung, Bio-Zutaten → Image
}

extension UpgradeCategoryLabel on UpgradeCategory {
  String get label {
    switch (this) {
      case UpgradeCategory.komfort:
        return 'Komfort';
      case UpgradeCategory.ambiente:
        return 'Ambiente';
      case UpgradeCategory.service:
        return 'Service';
      case UpgradeCategory.hygiene:
        return 'Hygiene';
    }
  }
}

class UpgradeData {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final UpgradeCategory category;

  /// Einmalige Anschaffungskosten
  final double installCost;

  /// Monatliche laufende Kosten (Lizenz, Wartung, Strom etc.)
  /// Wird auf täglich umgerechnet: monthlyCost / 30
  final double monthlyCost;

  /// Multiplikator auf die Kundenanzahl (0.05 = +5%)
  final double customerBoost;

  /// Reputations-Boost-pro-Tag (langsamer Aufbau)
  final double reputationPerDay;

  /// Boost für den Bestellwert (z.B. Premium-Image rechtfertigt höhere Preise)
  final double avgOrderValueBoost;

  /// Boost für Markenbekanntheit (kleiner stetiger Effekt)
  final double brandPerDay;

  const UpgradeData({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.installCost,
    required this.monthlyCost,
    this.customerBoost = 0,
    this.reputationPerDay = 0,
    this.avgOrderValueBoost = 0,
    this.brandPerDay = 0,
  });

  /// Tageskosten = monatlich / 30
  double get dailyCost => monthlyCost / 30.0;
}

/// Vordefinierte Upgrades.
const List<UpgradeData> kAllUpgrades = [
  // ── KOMFORT ──────────────────────────────────────────────────────────
  UpgradeData(
    id: 'wifi',
    name: 'Gratis-WLAN',
    description: 'Stammkunden bleiben länger sitzen, neue Kunden kommen rein.',
    emoji: '📶',
    category: UpgradeCategory.komfort,
    installCost: 800,
    monthlyCost: 90,
    customerBoost: 0.06,
    reputationPerDay: 0.005,
  ),
  UpgradeData(
    id: 'klima',
    name: 'Klimaanlage',
    description: 'Im Sommer ein Magnet — frische Kühle macht den Unterschied.',
    emoji: '❄️',
    category: UpgradeCategory.komfort,
    installCost: 2500,
    monthlyCost: 360,
    customerBoost: 0.08,
    reputationPerDay: 0.008,
  ),
  UpgradeData(
    id: 'heizpilz',
    name: 'Außenbereich + Heizpilze',
    description: 'Sitzplätze draußen das ganze Jahr — gemütliche Atmosphäre.',
    emoji: '🔥',
    category: UpgradeCategory.komfort,
    installCost: 1800,
    monthlyCost: 240,
    customerBoost: 0.10,
    avgOrderValueBoost: 0.05,
  ),

  // ── AMBIENTE ─────────────────────────────────────────────────────────
  UpgradeData(
    id: 'musik',
    name: 'Lizenzierte Musik (GEMA)',
    description: 'Türkische + deutsche Hits, legal abgespielt. Stimmung pur.',
    emoji: '🎶',
    category: UpgradeCategory.ambiente,
    installCost: 400,
    monthlyCost: 120,
    customerBoost: 0.05,
    reputationPerDay: 0.006,
  ),
  UpgradeData(
    id: 'deko_premium',
    name: 'Premium-Inneneinrichtung',
    description: 'Türkische Lampen, Mosaike — instagrammable.',
    emoji: '🪔',
    category: UpgradeCategory.ambiente,
    installCost: 3500,
    monthlyCost: 100,
    customerBoost: 0.08,
    reputationPerDay: 0.010,
    brandPerDay: 0.02,
  ),
  UpgradeData(
    id: 'tv_sport',
    name: 'TV mit Sportübertragung',
    description: 'Fußball läuft → Männer-Gruppen kommen, bestellen mehr.',
    emoji: '📺',
    category: UpgradeCategory.ambiente,
    installCost: 1200,
    monthlyCost: 160,
    customerBoost: 0.07,
    avgOrderValueBoost: 0.08,
  ),

  // ── SERVICE ──────────────────────────────────────────────────────────
  UpgradeData(
    id: 'loyalty_app',
    name: 'Stammkunden-App',
    description: 'Eigene App mit Stempelkarten und Gutscheinen. Dauerhafte Treue.',
    emoji: '💳',
    category: UpgradeCategory.service,
    installCost: 4000,
    monthlyCost: 180,
    customerBoost: 0.12,
    reputationPerDay: 0.008,
    brandPerDay: 0.03,
  ),
  UpgradeData(
    id: 'lieferdienst',
    name: 'Lieferdienst (Lieferando)',
    description: 'Bestellungen auch von zu Hause — neue Zielgruppe.',
    emoji: '🛵',
    category: UpgradeCategory.service,
    installCost: 600,
    monthlyCost: 500,
    customerBoost: 0.18,
    avgOrderValueBoost: -0.05,
  ),
  UpgradeData(
    id: 'kartenzahlung',
    name: 'Kartenzahlung (alle Karten)',
    description: 'Apple Pay, Visa, EC — niemand geht mehr ohne zu zahlen.',
    emoji: '💳',
    category: UpgradeCategory.service,
    installCost: 500,
    monthlyCost: 80,
    customerBoost: 0.04,
    avgOrderValueBoost: 0.06,
  ),

  // ── HYGIENE ──────────────────────────────────────────────────────────
  UpgradeData(
    id: 'bio_zutaten',
    name: 'Bio-Zutaten',
    description: 'Bio-Fleisch und -Gemüse. Höhere Marge möglich, aber teurer.',
    emoji: '🥦',
    category: UpgradeCategory.hygiene,
    installCost: 0,
    monthlyCost: 700,
    customerBoost: 0.06,
    avgOrderValueBoost: 0.15,
    reputationPerDay: 0.012,
  ),
  UpgradeData(
    id: 'premium_reinigung',
    name: 'Premium-Reinigungsservice',
    description: 'Tägliche Profi-Reinigung. Lebensmittelkontrollen lieben dich.',
    emoji: '✨',
    category: UpgradeCategory.hygiene,
    installCost: 200,
    monthlyCost: 560,
    reputationPerDay: 0.015,
    customerBoost: 0.03,
  ),
];

/// Lookup
UpgradeData? upgradeById(String id) {
  try {
    return kAllUpgrades.firstWhere((u) => u.id == id);
  } catch (_) {
    return null;
  }
}
