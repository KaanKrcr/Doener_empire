// Permanente Upgrades auf Filial- und Konzern-Ebene.
library;

enum UpgradeScope { shop, global }

enum UpgradeCategory {
  komfort,
  ambiente,
  service,
  hygiene,
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

const String kGlobalSpiessBasicId = 'doener_spiess_global_basic';
const String kGlobalSpiessStandardId = 'doener_spiess_global_standard';
const String kGlobalSpiessProfiId = 'doener_spiess_global_profi';

const List<String> kGlobalSpiessUpgradeOrder = [
  kGlobalSpiessBasicId,
  kGlobalSpiessStandardId,
  kGlobalSpiessProfiId,
];

class UpgradeData {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final UpgradeCategory category;
  final UpgradeScope scope;
  final double installCost;
  final double monthlyCost;
  final double customerBoost;
  final double reputationPerDay;
  final double avgOrderValueBoost;
  final double brandPerDay;
  final double deliveryRevenueFraction;
  final double deliveryCommissionRate;

  const UpgradeData({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    this.scope = UpgradeScope.shop,
    required this.installCost,
    required this.monthlyCost,
    this.customerBoost = 0,
    this.reputationPerDay = 0,
    this.avgOrderValueBoost = 0,
    this.brandPerDay = 0,
    this.deliveryRevenueFraction = 0,
    this.deliveryCommissionRate = 0,
  });

  double get dailyCost => monthlyCost / 30.0;
  bool get isDelivery => deliveryRevenueFraction > 0;
  bool get isGlobal => scope == UpgradeScope.global;
}

const List<UpgradeData> kShopUpgrades = [
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
    description: 'Im Sommer ein Magnet - frische Kühle macht den Unterschied.',
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
    description: 'Sitzplätze draußen das ganze Jahr - gemütliche Atmosphäre.',
    emoji: '🔥',
    category: UpgradeCategory.komfort,
    installCost: 1800,
    monthlyCost: 240,
    customerBoost: 0.10,
    avgOrderValueBoost: 0.05,
  ),
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
    description: 'Türkische Lampen, Mosaike - instagrammable.',
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
    description: 'Fußball läuft - Gruppen kommen und bestellen mehr.',
    emoji: '📺',
    category: UpgradeCategory.ambiente,
    installCost: 1200,
    monthlyCost: 160,
    customerBoost: 0.07,
    avgOrderValueBoost: 0.08,
  ),
  UpgradeData(
    id: 'kartenzahlung',
    name: 'Kartenzahlung (alle Karten)',
    description: 'Apple Pay, Visa, EC - niemand geht mehr ohne zu zahlen.',
    emoji: '💳',
    category: UpgradeCategory.service,
    installCost: 500,
    monthlyCost: 80,
    customerBoost: 0.04,
    avgOrderValueBoost: 0.06,
  ),
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
    description:
        'Tägliche Profi-Reinigung. Lebensmittelkontrollen lieben dich.',
    emoji: '✨',
    category: UpgradeCategory.hygiene,
    installCost: 200,
    monthlyCost: 560,
    reputationPerDay: 0.015,
    customerBoost: 0.03,
  ),
];

const List<UpgradeData> kGlobalUpgrades = [
  UpgradeData(
    id: kGlobalSpiessBasicId,
    name: 'Döner-Spieß-Netzwerk Basis',
    description:
        'Konzernweiter Spieß-Standard für alle Filialen mit monatlichen Fixkosten.',
    emoji: '🔥',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 1800,
    monthlyCost: 220,
  ),
  UpgradeData(
    id: kGlobalSpiessStandardId,
    name: 'Döner-Spieß-Netzwerk Standard',
    description:
        'Mehr Kapazität und Qualität konzernweit. Ersetzt die Basisstufe.',
    emoji: '🔥',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 4200,
    monthlyCost: 520,
  ),
  UpgradeData(
    id: kGlobalSpiessProfiId,
    name: 'Döner-Spieß-Netzwerk Profi',
    description:
        'Maximale zentrale Spießversorgung für alle Filialen. Ersetzt niedrigere Stufen.',
    emoji: '🔥',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 9800,
    monthlyCost: 980,
  ),
  UpgradeData(
    id: 'lieferdienst',
    name: 'Lieferdienst (Lieferando)',
    description:
        'Zentraler Lieferkanal für alle Filialen. Die Plattform behält 28 % Provision auf Lieferumsätze.',
    emoji: '🛵',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 600,
    monthlyCost: 500,
    customerBoost: 0.18,
    deliveryRevenueFraction: 0.18,
    deliveryCommissionRate: 0.28,
  ),
  UpgradeData(
    id: 'loyalty_app',
    name: 'Stammkunden-App',
    description:
        'Eigene App mit Stempelkarten und Gutscheinen. Einmalig kaufen - gilt für alle Filialen.',
    emoji: '💳',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 8000,
    monthlyCost: 350,
    customerBoost: 0.10,
    reputationPerDay: 0.008,
    brandPerDay: 0.05,
  ),
  UpgradeData(
    id: 'kassensystem_zentral',
    name: 'Zentrales Kassensystem',
    description:
        'Einheitliches POS in allen Filialen - Echtzeitdaten, weniger Fehler. Reduziert Zutatenverschwendung konzernweit.',
    emoji: '🖥️',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 12000,
    monthlyCost: 600,
    avgOrderValueBoost: 0.03,
    reputationPerDay: 0.005,
  ),
  UpgradeData(
    id: 'schulung_online',
    name: 'Online-Schulungsplattform',
    description:
        'Alle Mitarbeiter lernen schneller. Effektiv +10 % Speed und Freundlichkeit in jeder Filiale.',
    emoji: '🎓',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 6000,
    monthlyCost: 250,
    customerBoost: 0.05,
    reputationPerDay: 0.010,
  ),
  UpgradeData(
    id: 'eigen_lieferdienst',
    name: 'Eigene Liefer-App',
    description:
        'Eigene Logistik ohne Provision. Benötigt Lieferdienst in mindestens 3 Filialen. Provision fällt auf 8 %.',
    emoji: '🚀',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 35000,
    monthlyCost: 1200,
    customerBoost: 0.08,
    brandPerDay: 0.04,
  ),
  UpgradeData(
    id: 'social_media_team',
    name: 'Social-Media-Team',
    description:
        'Eigenes Team für TikTok, Instagram & Co. Hält die Marke landesweit präsent.',
    emoji: '📣',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 14000,
    monthlyCost: 700,
    customerBoost: 0.07,
    reputationPerDay: 0.004,
    brandPerDay: 0.06,
  ),
  UpgradeData(
    id: 'bio_zertifikat',
    name: 'Bio-Zertifizierung',
    description:
        'Konzernweites Bio-Siegel. Premium-Image, höherer Bestellwert — aber laufende Audit-Kosten.',
    emoji: '🌿',
    category: UpgradeCategory.hygiene,
    scope: UpgradeScope.global,
    installCost: 10000,
    monthlyCost: 450,
    reputationPerDay: 0.012,
    avgOrderValueBoost: 0.05,
    brandPerDay: 0.02,
  ),
];

const List<UpgradeData> kAllUpgrades = [...kShopUpgrades, ...kGlobalUpgrades];

UpgradeData? upgradeById(String id) {
  try {
    return kAllUpgrades.firstWhere((u) => u.id == id);
  } catch (_) {
    return null;
  }
}
