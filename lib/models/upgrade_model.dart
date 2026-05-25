// Permanente Upgrades — Shop-Level und Konzern-Level.
///
/// • [UpgradeScope.shop]   — pro Filiale kaufbar, wirkt nur dort.
/// • [UpgradeScope.global] — einmalig im Konzern-Tab kaufbar,
///                           wirkt automatisch in ALLEN Filialen.
///
/// Delivery-Upgrades (z.B. Lieferando) haben eigene Felder:
/// [deliveryRevenueFraction] und [deliveryCommissionRate].
/// Der Plattform-Anteil wird als separate Kostenposition verbucht,
/// damit Umsatz niemals negativ wird.

enum UpgradeScope { shop, global }

enum UpgradeCategory {
  komfort,   // WLAN, Klimaanlage, Heizung → Komfort
  ambiente,  // Musik, Deko, Beleuchtung  → Atmosphäre
  service,   // Stammkunden-App, Lieferdienst → Service
  hygiene,   // Premium-Reinigung, Bio-Zutaten → Image
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

  /// shop = pro Filiale; global = einmalig für alle Filialen
  final UpgradeScope scope;

  /// Einmalige Anschaffungskosten
  final double installCost;

  /// Monatliche laufende Kosten (Lizenz, Wartung, Strom etc.)
  /// Wird auf täglich umgerechnet: monthlyCost / 30
  final double monthlyCost;

  /// Multiplikator auf die Kundenanzahl (0.05 = +5%)
  final double customerBoost;

  /// Reputations-Boost pro Tag
  final double reputationPerDay;

  /// Boost für den durchschnittlichen Bestellwert
  final double avgOrderValueBoost;

  /// Boost für Markenbekanntheit (kleiner stetiger Effekt)
  final double brandPerDay;

  /// Anteil des Tagesumsatzes, der über eine Liefer-Plattform läuft.
  /// 0.0 = kein Lieferdienst. Z.B. 0.18 = 18 % des Umsatzes via Plattform.
  final double deliveryRevenueFraction;

  /// Provision der Liefer-Plattform (z.B. 0.28 = 28 %).
  /// Gilt nur wenn [deliveryRevenueFraction] > 0.
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

  /// Tageskosten = monatlich / 30
  double get dailyCost => monthlyCost / 30.0;

  /// Hat dieses Upgrade ein Delivery-Kosten-Modell?
  bool get isDelivery => deliveryRevenueFraction > 0;

  /// Ist es ein globales Konzern-Upgrade?
  bool get isGlobal => scope == UpgradeScope.global;
}

// ─── Shop-Level-Upgrades ───────────────────────────────────────────────────

const List<UpgradeData> kShopUpgrades = [
  // ── KOMFORT ──────────────────────────────────────────────────────────────
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

  // ── AMBIENTE ─────────────────────────────────────────────────────────────
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

  // ── SERVICE ──────────────────────────────────────────────────────────────
  UpgradeData(
    id: 'lieferdienst',
    name: 'Lieferdienst (Lieferando)',
    description:
        'Bestellungen auch von zu Hause — neue Zielgruppe erschlossen. '
        'Die Plattform behält 28 % Provision auf Lieferumsätze.',
    emoji: '🛵',
    category: UpgradeCategory.service,
    installCost: 600,
    monthlyCost: 500,
    customerBoost: 0.18,           // +18 % Kunden durch Delivery
    deliveryRevenueFraction: 0.18, // 18 % des Umsatzes laufen über Plattform
    deliveryCommissionRate: 0.28,  // Plattform nimmt 28 % davon
    // avgOrderValueBoost bewusst 0 — Provision wird separat abgezogen
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

  // ── HYGIENE ──────────────────────────────────────────────────────────────
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

// ─── Konzern-Level-Upgrades (global, einmalig für alle Filialen) ───────────

const List<UpgradeData> kGlobalUpgrades = [
  UpgradeData(
    id: 'loyalty_app',
    name: 'Stammkunden-App',
    description:
        'Eigene App mit Stempelkarten und Gutscheinen. '
        'Einmalig kaufen — gilt für alle Filialen.',
    emoji: '💳',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 8000,   // teurer als Shop-Variante, aber deckt alle ab
    monthlyCost: 350,    // monatliche Server/Lizenzkosten
    customerBoost: 0.10,
    reputationPerDay: 0.008,
    brandPerDay: 0.05,
  ),
  UpgradeData(
    id: 'kassensystem_zentral',
    name: 'Zentrales Kassensystem',
    description:
        'Einheitliches POS in allen Filialen — Echtzeitdaten, weniger Fehler. '
        'Reduziert Zutatenverschwendung konzernweit.',
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
        'Alle Mitarbeiter lernen schneller. '
        'Effektiv +10 % Speed & Freundlichkeit in jeder Filiale.',
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
        'Eigene Logistik ohne Provision. Benötigt bereits Lieferando-Einstieg '
        'in mind. 3 Filialen. Provision fällt auf 8 %.',
    emoji: '🚀',
    category: UpgradeCategory.service,
    scope: UpgradeScope.global,
    installCost: 35000,
    monthlyCost: 1200,
    customerBoost: 0.08,
    brandPerDay: 0.04,
    // deliveryCommissionRate: 0.08 wird in der Engine gesondert gehandhabt
    // (überschreibt Lieferando-Rate für Shops mit lieferdienst-Upgrade)
  ),
];

/// Alle Upgrades zusammen (für Legacy-Kompatibilität + Lookup)
const List<UpgradeData> kAllUpgrades = [...kShopUpgrades, ...kGlobalUpgrades];

/// Lookup nach ID — null-safe
UpgradeData? upgradeById(String id) {
  try {
    return kAllUpgrades.firstWhere((u) => u.id == id);
  } catch (_) {
    return null;
  }
}
