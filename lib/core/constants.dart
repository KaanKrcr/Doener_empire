import '../models/city_model.dart';
import '../models/product_model.dart';
import '../models/equipment_model.dart';
import '../models/employee_model.dart';
import '../models/marketing_model.dart';
import '../models/time_profile_model.dart';

// ─── Städte ──────────────────────────────────────────────────────────────────

const List<CityData> kAllCities = [
  // ── Kleinstädte (Startstädte, kostenlos) ──
  CityData(
    id: 'fulda',
    name: 'Fulda',
    state: 'Hessen',
    population: 68000,
    tier: CityTier.klein,
    unlockCost: 0,
    rentBase: 1200,
    footTrafficBase: 4500,
    emoji: '🌿',
  ),
  CityData(
    id: 'bayreuth',
    name: 'Bayreuth',
    state: 'Bayern',
    population: 74000,
    tier: CityTier.klein,
    unlockCost: 0,
    rentBase: 1100,
    footTrafficBase: 4800,
    emoji: '🎭',
  ),
  CityData(
    id: 'goettingen',
    name: 'Göttingen',
    state: 'Niedersachsen',
    population: 118000,
    tier: CityTier.klein,
    unlockCost: 0,
    rentBase: 1300,
    footTrafficBase: 6000,
    emoji: '🎓',
  ),

  // ── Mittelstädte (ab 30.000 € Gesamtumsatz) ──
  CityData(
    id: 'augsburg',
    name: 'Augsburg',
    state: 'Bayern',
    population: 300000,
    tier: CityTier.mittel,
    unlockCost: 30000,
    rentBase: 2000,
    footTrafficBase: 10000,
    emoji: '⛪',
  ),
  CityData(
    id: 'muenster',
    name: 'Münster',
    state: 'NRW',
    population: 315000,
    tier: CityTier.mittel,
    unlockCost: 30000,
    rentBase: 1900,
    footTrafficBase: 9500,
    emoji: '🚲',
  ),
  CityData(
    id: 'braunschweig',
    name: 'Braunschweig',
    state: 'Niedersachsen',
    population: 248000,
    tier: CityTier.mittel,
    unlockCost: 50000,
    rentBase: 1700,
    footTrafficBase: 8500,
    emoji: '🦁',
  ),

  // ── Großstädte (ab 150.000 € Gesamtumsatz) ──
  CityData(
    id: 'frankfurt',
    name: 'Frankfurt',
    state: 'Hessen',
    population: 750000,
    tier: CityTier.gross,
    unlockCost: 150000,
    rentBase: 4500,
    footTrafficBase: 22000,
    emoji: '🏦',
  ),
  CityData(
    id: 'koeln',
    name: 'Köln',
    state: 'NRW',
    population: 1080000,
    tier: CityTier.gross,
    unlockCost: 150000,
    rentBase: 4000,
    footTrafficBase: 20000,
    emoji: '⛩️',
  ),
  CityData(
    id: 'stuttgart',
    name: 'Stuttgart',
    state: 'Baden-Württemberg',
    population: 630000,
    tier: CityTier.gross,
    unlockCost: 200000,
    rentBase: 3800,
    footTrafficBase: 18000,
    emoji: '🚗',
  ),
  CityData(
    id: 'duesseldorf',
    name: 'Düsseldorf',
    state: 'NRW',
    population: 620000,
    tier: CityTier.gross,
    unlockCost: 200000,
    rentBase: 4200,
    footTrafficBase: 19000,
    emoji: '👗',
  ),

  // ── Metropolen (ab 500.000 € Gesamtumsatz) ──
  CityData(
    id: 'berlin',
    name: 'Berlin',
    state: 'Berlin',
    population: 3800000,
    tier: CityTier.metropole,
    unlockCost: 500000,
    rentBase: 7000,
    footTrafficBase: 50000,
    emoji: '🐻',
  ),
  CityData(
    id: 'hamburg',
    name: 'Hamburg',
    state: 'Hamburg',
    population: 1800000,
    tier: CityTier.metropole,
    unlockCost: 500000,
    rentBase: 6500,
    footTrafficBase: 40000,
    emoji: '⚓',
  ),
  CityData(
    id: 'muenchen',
    name: 'München',
    state: 'Bayern',
    population: 1500000,
    tier: CityTier.metropole,
    unlockCost: 750000,
    rentBase: 8000,
    footTrafficBase: 45000,
    emoji: '🍺',
  ),
];

// ─── Produkte ─────────────────────────────────────────────────────────────────

const List<ProductData> kAllProducts = [
  ProductData(
    id: 'doener_fladen',
    name: 'Döner im Fladenbrot',
    emoji: '🫓',
    basePrice: 6.50,
    ingredientCostPerUnit: 2.20,
    category: ProductCategory.doener,
    isDefault: true,
  ),
  ProductData(
    id: 'doener_duerum',
    name: 'Dürüm Döner',
    emoji: '🌯',
    basePrice: 7.00,
    ingredientCostPerUnit: 2.40,
    category: ProductCategory.doener,
    isDefault: true,
  ),
  ProductData(
    id: 'veg_doener',
    name: 'Vegetarischer Döner',
    emoji: '🥗',
    basePrice: 6.50,
    ingredientCostPerUnit: 1.80,
    category: ProductCategory.doener,
    isDefault: true,
    requiredEquipmentId: null,
  ),
  ProductData(
    id: 'doenerbox',
    name: 'Döner-Box',
    emoji: '📦',
    basePrice: 9.50,
    ingredientCostPerUnit: 3.50,
    category: ProductCategory.box,
    isDefault: false,
    requiredEquipmentId: 'fritteuse_standard',
  ),
  ProductData(
    id: 'lahmacun',
    name: 'Lahmacun',
    emoji: '🫓',
    basePrice: 4.00,
    ingredientCostPerUnit: 1.20,
    category: ProductCategory.beilage,
    isDefault: false,
    requiredEquipmentId: 'ofen_lahmacun',
  ),
  ProductData(
    id: 'pommes',
    name: 'Pommes',
    emoji: '🍟',
    basePrice: 3.50,
    ingredientCostPerUnit: 0.80,
    category: ProductCategory.beilage,
    isDefault: false,
    requiredEquipmentId: 'fritteuse_standard',
  ),
  ProductData(
    id: 'ayran',
    name: 'Ayran',
    emoji: '🥛',
    basePrice: 2.00,
    ingredientCostPerUnit: 0.50,
    category: ProductCategory.getraenk,
    isDefault: true,
  ),
  ProductData(
    id: 'cola',
    name: 'Cola / Fanta',
    emoji: '🥤',
    basePrice: 2.50,
    ingredientCostPerUnit: 0.80,
    category: ProductCategory.getraenk,
    isDefault: true,
  ),
];

// ─── Equipment ────────────────────────────────────────────────────────────────

const List<EquipmentData> kAllEquipment = [
  // Döner-Spieß (Pflicht)
  EquipmentData(
    id: 'spiess_klein',
    name: 'Döner-Spieß Klein',
    emoji: '🔥',
    description: 'Reicht für kleine Läden. Begrenzte Kapazität.',
    price: 800,
    qualityBonus: 0.15,
    capacityBonus: 40,
    category: EquipmentCategory.spiess,
  ),
  EquipmentData(
    id: 'spiess_standard',
    name: 'Döner-Spieß Standard',
    emoji: '🔥',
    description: 'Gute Kapazität, zuverlässige Qualität.',
    price: 2500,
    qualityBonus: 0.40,
    capacityBonus: 100,
    category: EquipmentCategory.spiess,
  ),
  EquipmentData(
    id: 'spiess_profi',
    name: 'Döner-Spieß Profi',
    emoji: '🔥',
    description: 'Höchste Qualität, maximale Kapazität für Stoßzeiten.',
    price: 7000,
    qualityBonus: 0.80,
    capacityBonus: 200,
    category: EquipmentCategory.spiess,
  ),

  // Kassensystem
  EquipmentData(
    id: 'kasse_basic',
    name: 'Kasse Basic',
    emoji: '🧾',
    description: 'Einfache Kasse. Funktioniert.',
    price: 300,
    qualityBonus: 0.0,
    speedBonus: 0.05,
    category: EquipmentCategory.kasse,
  ),
  EquipmentData(
    id: 'kasse_digital',
    name: 'Digitale Kasse',
    emoji: '💳',
    description: 'Kartenleser, schnellere Abwicklung, Statistiken.',
    price: 1200,
    qualityBonus: 0.05,
    speedBonus: 0.15,
    category: EquipmentCategory.kasse,
  ),

  // Fritteuse
  EquipmentData(
    id: 'fritteuse_standard',
    name: 'Fritteuse',
    emoji: '🍟',
    description: 'Ermöglicht Pommes und Döner-Box im Sortiment.',
    price: 700,
    qualityBonus: 0.10,
    category: EquipmentCategory.sonstiges,
    unlocksProductId: 'pommes',
    additionalUnlocks: ['doenerbox'],
  ),

  // Lahmacun-Ofen
  EquipmentData(
    id: 'ofen_lahmacun',
    name: 'Lahmacun-Ofen',
    emoji: '🔆',
    description: 'Traditioneller Steinofen für authentisches Lahmacun.',
    price: 1500,
    qualityBonus: 0.15,
    category: EquipmentCategory.sonstiges,
    unlocksProductId: 'lahmacun',
  ),

  // Kühlschrank
  EquipmentData(
    id: 'kuehlschrank',
    name: 'Profi-Kühlschrank',
    emoji: '❄️',
    description: 'Spart Zutatenkosten durch bessere Lagerung.',
    price: 600,
    qualityBonus: 0.05,
    ingredientSavingBonus: 0.08,
    category: EquipmentCategory.sonstiges,
  ),
];

// ─── Mitarbeiter-Typen ────────────────────────────────────────────────────────

const List<EmployeeTypeData> kEmployeeTypes = [
  EmployeeTypeData(
    id: 'doener_meister',
    title: 'Döner-Meister',
    emoji: '👨‍🍳',
    description: 'Am Spieß. Qualität und Tempo bestimmen den Ruf.',
    baseSalaryPerDay: 80,
    qualityContribution: 0.40,
    speedContribution: 0.20,
  ),
  EmployeeTypeData(
    id: 'kassierer',
    title: 'Kassierer/in',
    emoji: '💰',
    description: 'Schnelle Abwicklung, weniger Warteschlangen.',
    baseSalaryPerDay: 65,
    qualityContribution: 0.05,
    speedContribution: 0.40,
  ),
  EmployeeTypeData(
    id: 'kuechen_hilfe',
    title: 'Küchenhilfe',
    emoji: '🧑‍🍽️',
    description: 'Unterstützt bei allem, erhöht Gesamtkapazität.',
    baseSalaryPerDay: 55,
    qualityContribution: 0.10,
    speedContribution: 0.25,
  ),
];

// ─── Standort-Vorlagen pro Stadt-Tier ────────────────────────────────────────

const Map<CityTier, List<LocationTemplate>> kLocationTemplates = {
  CityTier.klein: [
    LocationTemplate(
      name: 'Marktplatz',
      footTrafficFactor: 1.2,
      rentFactor: 1.3,
      personality: LocationPersonality.touristic,
    ),
    LocationTemplate(
      name: 'Hauptstraße',
      footTrafficFactor: 1.0,
      rentFactor: 1.0,
      personality: LocationPersonality.business,
    ),
    LocationTemplate(
      name: 'Bahnhofsnähe',
      footTrafficFactor: 0.9,
      rentFactor: 0.9,
      personality: LocationPersonality.transit,
    ),
    LocationTemplate(
      name: 'Randlage',
      footTrafficFactor: 0.5,
      rentFactor: 0.6,
      personality: LocationPersonality.residential,
    ),
  ],
  CityTier.mittel: [
    LocationTemplate(
      name: 'Fußgängerzone',
      footTrafficFactor: 1.4,
      rentFactor: 1.6,
      personality: LocationPersonality.touristic,
    ),
    LocationTemplate(
      name: 'Einkaufszentrum',
      footTrafficFactor: 1.3,
      rentFactor: 1.5,
      personality: LocationPersonality.business,
    ),
    LocationTemplate(
      name: 'Bahnhof',
      footTrafficFactor: 1.1,
      rentFactor: 1.2,
      personality: LocationPersonality.transit,
    ),
    LocationTemplate(
      name: 'Wohnviertel',
      footTrafficFactor: 0.7,
      rentFactor: 0.8,
      personality: LocationPersonality.residential,
    ),
  ],
  CityTier.gross: [
    LocationTemplate(
      name: 'Innenstadt-Premium',
      footTrafficFactor: 1.6,
      rentFactor: 2.0,
      personality: LocationPersonality.business,
    ),
    LocationTemplate(
      name: 'Shoppingcenter',
      footTrafficFactor: 1.4,
      rentFactor: 1.7,
      personality: LocationPersonality.touristic,
    ),
    LocationTemplate(
      name: 'Uni-Viertel',
      footTrafficFactor: 1.2,
      rentFactor: 1.3,
      personality: LocationPersonality.university,
    ),
    LocationTemplate(
      name: 'Stadtrand',
      footTrafficFactor: 0.8,
      rentFactor: 0.9,
      personality: LocationPersonality.residential,
    ),
  ],
  CityTier.metropole: [
    LocationTemplate(
      name: 'Top-Lage Mitte',
      footTrafficFactor: 2.0,
      rentFactor: 2.8,
      personality: LocationPersonality.touristic,
    ),
    LocationTemplate(
      name: 'Touristenviertel',
      footTrafficFactor: 1.8,
      rentFactor: 2.4,
      personality: LocationPersonality.touristic,
    ),
    LocationTemplate(
      name: 'Businessviertel',
      footTrafficFactor: 1.5,
      rentFactor: 2.0,
      personality: LocationPersonality.business,
    ),
    LocationTemplate(
      name: 'Trendbezirk',
      footTrafficFactor: 1.3,
      rentFactor: 1.8,
      personality: LocationPersonality.nightlife,
    ),
  ],
};

// ─── Marketing-Kampagnen ─────────────────────────────────────────────────────

const List<MarketingCampaign> kAllCampaigns = [
  // ── EINSTIEG: günstig, kurz ─────────────────────────────────────────
  MarketingCampaign(
    id: 'flyer_local',
    name: 'Flyer-Aktion',
    description:
        'Bedruckte Flyer in der Nachbarschaft verteilen lassen. Klein aber wirkungsvoll.',
    emoji: '📄',
    cost: 400,
    durationDays: 3,
    scope: MarketingScope.shop,
    customerBoost: 0.15,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'lunch_deal',
    name: 'Mittagsangebot',
    description:
        'Spezial-Menü zur Mittagszeit — mehr Kunden, leicht geringere Marge.',
    emoji: '🍽️',
    cost: 0,
    durationDays: 7,
    scope: MarketingScope.shop,
    customerBoost: 0.25,
    avgOrderValueMod: -0.10,
    risk: MarketingRisk.low,
  ),

  // ── MITTLERE STUFE: Social Media ───────────────────────────────────
  MarketingCampaign(
    id: 'social_media',
    name: 'Social-Media-Boost',
    description:
        'Instagram & TikTok Anzeigen. Erreicht jüngeres Publikum, baut Marke auf.',
    emoji: '📱',
    cost: 1500,
    durationDays: 5,
    scope: MarketingScope.shop,
    customerBoost: 0.30,
    reputationBoostPerDay: 0.08,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'two_for_one',
    name: '2-für-1-Aktion',
    description:
        'Riesiger Andrang, aber halbe Marge pro Verkauf. Riskanter Kunden-Magnet.',
    emoji: '🎟️',
    cost: 200,
    durationDays: 2,
    scope: MarketingScope.shop,
    customerBoost: 0.80,
    avgOrderValueMod: -0.40,
    reputationBoostPerDay: 0.05,
    risk: MarketingRisk.medium,
  ),

  // ── HOCHWERTIG: Influencer + Radio ─────────────────────────────────
  MarketingCampaign(
    id: 'food_influencer',
    name: 'Influencer-Kooperation',
    description:
        'Bekannter Food-Blogger besucht deine Filiale. Chance auf viralen Hit, aber teuer.',
    emoji: '⭐',
    cost: 3500,
    durationDays: 4,
    scope: MarketingScope.shop,
    customerBoost: 0.50,
    reputationBoostOnce: 0.3,
    reputationBoostPerDay: 0.05,
    viralChance: 0.20,
    risk: MarketingRisk.medium,
  ),
  MarketingCampaign(
    id: 'radio_spot',
    name: 'Radio-Spot',
    description:
        'Lokaler Radio-Sender bewirbt deinen Imbiss. Breite Reichweite, beständig.',
    emoji: '📻',
    cost: 5000,
    durationDays: 7,
    scope: MarketingScope.shop,
    customerBoost: 0.35,
    reputationBoostPerDay: 0.04,
    risk: MarketingRisk.low,
  ),

  // ── PREMIUM: Langzeit-Investitionen ────────────────────────────────
  MarketingCampaign(
    id: 'stadtfest_sponsor',
    name: 'Stadtfest-Sponsoring',
    description:
        'Großes Image-Investment: Logo überall sichtbar. Langer Reputations-Schub.',
    emoji: '🏟️',
    cost: 8000,
    durationDays: 14,
    scope: MarketingScope.shop,
    customerBoost: 0.25,
    reputationBoostOnce: 0.5,
    reputationBoostPerDay: 0.03,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'happy_hour',
    name: 'Happy Hour',
    description:
        'Rabatt zur Randzeit füllt den Laden — mehr Andrang, etwas weniger Marge.',
    emoji: '⏰',
    cost: 300,
    durationDays: 5,
    scope: MarketingScope.shop,
    customerBoost: 0.20,
    avgOrderValueMod: -0.08,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'gewinnspiel',
    name: 'Gewinnspiel',
    description:
        'Verlosung eines Gratis-Döner-Jahres. Viral-Potenzial, gut für die Marke.',
    emoji: '🎁',
    cost: 2500,
    durationDays: 10,
    scope: MarketingScope.shop,
    customerBoost: 0.22,
    reputationBoostPerDay: 0.03,
    brandAwarenessDelta: 0.4,
    viralChance: 0.20,
    risk: MarketingRisk.medium,
  ),
];

// ─── Stadtweite Marketing-Kampagnen ──────────────────────────────────────────
// Wirken auf alle Filialen einer Stadt (customerBoost, reputation, brand).

const List<MarketingCampaign> kCityMarketingCampaigns = [
  MarketingCampaign(
    id: 'city_plakat',
    name: 'Stadtweite Plakate',
    description: 'Plakatwände in der ganzen Stadt — alle Filialen profitieren.',
    emoji: '🪧',
    cost: 3000,
    durationDays: 7,
    scope: MarketingScope.city,
    customerBoost: 0.15,
    reputationBoostPerDay: 0.02,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'city_social',
    name: 'Stadtweite Social-Media-Kampagne',
    description: 'TikTok & Instagram, geotargeted auf die ganze Stadt.',
    emoji: '📲',
    cost: 6000,
    durationDays: 10,
    scope: MarketingScope.city,
    customerBoost: 0.25,
    reputationBoostPerDay: 0.05,
    brandAwarenessDelta: 0.3,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'city_event',
    name: 'Stadt-Event (Pop-Up Stand)',
    description:
        'Eigener Stand auf einem Stadtfest oder Markt — starker Reputations-Boost.',
    emoji: '🎪',
    cost: 5000,
    durationDays: 3,
    scope: MarketingScope.city,
    customerBoost: 0.40,
    reputationBoostOnce: 0.4,
    reputationBoostPerDay: 0.06,
    brandAwarenessDelta: 0.5,
    risk: MarketingRisk.medium,
  ),
  MarketingCampaign(
    id: 'city_radio',
    name: 'Stadtweiter Radio-Spot',
    description: 'Lokaler Radiosender — breite Hörerschaft in der ganzen Stadt.',
    emoji: '📻',
    cost: 8000,
    durationDays: 14,
    scope: MarketingScope.city,
    customerBoost: 0.20,
    reputationBoostPerDay: 0.03,
    brandAwarenessDelta: 0.4,
    risk: MarketingRisk.low,
  ),
];

// ─── Konzernweite Marketing-Kampagnen ─────────────────────────────────────────
// Wirken auf ALLE Filialen + steigern Brand Awareness.

const List<MarketingCampaign> kGlobalMarketingCampaigns = [
  MarketingCampaign(
    id: 'tv_werbung',
    name: 'TV-Werbung (national)',
    description:
        'Nationaler TV-Spot. Massiver Marken-Boost — alle Filialen profitieren.',
    emoji: '📺',
    cost: 25000,
    durationDays: 14,
    scope: MarketingScope.global,
    customerBoost: 0.20,
    reputationBoostPerDay: 0.03,
    brandAwarenessDelta: 1.5,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'influencer_national',
    name: 'Influencer-Kampagne (national)',
    description:
        'Bekannter Food-Influencer mit 500k+ Followern. Viral-Chance hoch.',
    emoji: '⭐',
    cost: 15000,
    durationDays: 7,
    scope: MarketingScope.global,
    customerBoost: 0.30,
    reputationBoostOnce: 0.5,
    reputationBoostPerDay: 0.06,
    brandAwarenessDelta: 2.0,
    viralChance: 0.25,
    risk: MarketingRisk.medium,
  ),
  MarketingCampaign(
    id: 'brand_launch',
    name: 'Marken-Relaunch',
    description:
        'Neues Logo, neues Erscheinungsbild — Premium-Image für alle Filialen.',
    emoji: '🏷️',
    cost: 20000,
    durationDays: 30,
    scope: MarketingScope.global,
    customerBoost: 0.10,
    reputationBoostPerDay: 0.04,
    brandAwarenessDelta: 0.8,
    risk: MarketingRisk.low,
  ),
  MarketingCampaign(
    id: 'treue_programm',
    name: 'Treue-Programm-Kampagne',
    description:
        'Bundesweite Stempelkarten-Aktion. Stammkunden +++ besonders lohnend '
        'wenn Stammkunden-App schon aktiv ist.',
    emoji: '💳',
    cost: 10000,
    durationDays: 21,
    scope: MarketingScope.global,
    customerBoost: 0.12,
    reputationBoostPerDay: 0.05,
    brandAwarenessDelta: 0.5,
    risk: MarketingRisk.low,
  ),
];

/// Alle Kampagnen kombiniert (für Lookup nach ID)
const List<MarketingCampaign> kAllMarketingCampaigns = [
  ...kAllCampaigns,
  ...kCityMarketingCampaigns,
  ...kGlobalMarketingCampaigns,
];

// ─── Startkapital ─────────────────────────────────────────────────────────────

const double kStartingCash = 15000.0; // Startkapital: 15.000 €
const double kTickIntervalSeconds = 3.0; // alle 3 Sek. ein Spieltick (= 1 Spielstunde)
const int kHoursPerDay = 24;
const double kDailyOpenHours = 14.0; // Laden offen von 10-24 Uhr
