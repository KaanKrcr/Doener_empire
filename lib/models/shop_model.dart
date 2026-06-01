import 'product_model.dart';
import 'equipment_model.dart';
import 'employee_model.dart';
import 'marketing_model.dart';
import 'time_profile_model.dart';

enum ShopSizeTier { klein, mittel, gross, flagship }

class ShopSizeTierConfig {
  final int employeeCap;
  final double capacityMultiplier;
  final double upgradeCost;
  final double rentMultiplier;
  final double moraleDeltaOnUpgrade;

  const ShopSizeTierConfig({
    required this.employeeCap,
    required this.capacityMultiplier,
    required this.upgradeCost,
    required this.rentMultiplier,
    required this.moraleDeltaOnUpgrade,
  });
}

const Map<ShopSizeTier, ShopSizeTierConfig> kShopSizeTierConfig = {
  ShopSizeTier.klein: ShopSizeTierConfig(
    employeeCap: 3,
    capacityMultiplier: 1.00,
    upgradeCost: 0,
    rentMultiplier: 1.00,
    moraleDeltaOnUpgrade: 0,
  ),
  ShopSizeTier.mittel: ShopSizeTierConfig(
    employeeCap: 5,
    capacityMultiplier: 1.35,
    upgradeCost: 8000,
    rentMultiplier: 1.25,
    moraleDeltaOnUpgrade: -0.02,
  ),
  ShopSizeTier.gross: ShopSizeTierConfig(
    employeeCap: 8,
    capacityMultiplier: 1.75,
    upgradeCost: 25000,
    rentMultiplier: 1.60,
    moraleDeltaOnUpgrade: -0.05,
  ),
  ShopSizeTier.flagship: ShopSizeTierConfig(
    employeeCap: 12,
    capacityMultiplier: 2.20,
    upgradeCost: 70000,
    rentMultiplier: 2.10,
    moraleDeltaOnUpgrade: -0.08,
  ),
};

extension ShopSizeTierX on ShopSizeTier {
  String get label => switch (this) {
        ShopSizeTier.klein => 'Klein',
        ShopSizeTier.mittel => 'Mittel',
        ShopSizeTier.gross => 'Groß',
        ShopSizeTier.flagship => 'Flagship',
      };

  ShopSizeTier? get nextTier {
    final nextIndex = index + 1;
    if (nextIndex >= ShopSizeTier.values.length) return null;
    return ShopSizeTier.values[nextIndex];
  }

  static ShopSizeTier fromJsonValue(String? value) {
    for (final tier in ShopSizeTier.values) {
      if (tier.name == value) return tier;
    }
    return ShopSizeTier.klein;
  }

  static ShopSizeTier fromLegacyExpansionLevel(int level) {
    final normalized = level.clamp(0, ShopSizeTier.values.length - 1);
    return ShopSizeTier.values[normalized];
  }
}

class Shop {
  final String id;
  final String name; // Konzern-/Kettenname
  final String? customName; // optionaler individueller Filialname
  final String cityId;
  final String locationName;
  final int footTraffic;
  final double weeklyRent;
  final bool isOpen;
  final List<ShopProduct> menu;
  final List<ShopEquipment> equipment;
  final List<Employee> employees;
  final double reputation; // 0.0 – 5.0
  final int dayOpened;
  final List<ActiveCampaign> activeCampaigns;
  final LocationPersonality personality;
  final List<String> upgradeIds;
  final bool autoHire; // HR-Manager stellt automatisch bei Engpass ein
  final String? originalCompetitorName; // ehemals welcher Konkurrent
  final bool wasAcquired; // stammt aus einer Übernahme
  final double morale; // Team-Moral 0.2..1.0 (0.75 = neutral)
  final double regulars; // Stammkunden-Anteil 0..0.5 (0 = neutral)
  final ShopSizeTier sizeTier;

  const Shop({
    required this.id,
    required this.name,
    this.customName,
    required this.cityId,
    required this.locationName,
    required this.footTraffic,
    required this.weeklyRent,
    this.isOpen = true,
    required this.menu,
    required this.equipment,
    required this.employees,
    this.reputation = 3.0,
    required this.dayOpened,
    this.activeCampaigns = const [],
    this.personality = LocationPersonality.touristic,
    this.upgradeIds = const [],
    this.autoHire = false,
    this.originalCompetitorName,
    this.wasAcquired = false,
    this.morale = 0.75,
    this.regulars = 0.0,
    this.sizeTier = ShopSizeTier.klein,
  });

  bool hasUpgrade(String upgradeId) => upgradeIds.contains(upgradeId);

  double get dailyRent => weeklyRent / 7.0;

  bool get hasCustomName => customName != null && customName!.trim().isNotEmpty;

  /// Legacy-Alias für bestehende Aufrufer. 0..3 entspricht klein..flagship.
  int get expansionLevel => sizeTier.index;

  /// Primäre Anzeige in Listen/Karten.
  String get displayName =>
      hasCustomName ? '$name - ${customName!.trim()}' : name;

  /// Sekundäre Branding-Zeile.
  String get brandingHint => hasCustomName ? name : locationName;

  String? get acquiredHint => wasAcquired && originalCompetitorName != null
      ? 'ehemals $originalCompetitorName'
      : null;

  bool hasEquipment(String equipmentId) =>
      equipment.any((e) => e.equipmentId == equipmentId);

  /// Gibt das Zeitprofil dieses Standorts zurück.
  TimeProfile get timeProfile =>
      kTimeProfiles[personality] ??
      kTimeProfiles[LocationPersonality.touristic]!;

  Shop copyWith({
    String? name,
    String? customName,
    bool clearCustomName = false,
    double? weeklyRent,
    bool? isOpen,
    List<ShopProduct>? menu,
    List<ShopEquipment>? equipment,
    List<Employee>? employees,
    double? reputation,
    List<ActiveCampaign>? activeCampaigns,
    LocationPersonality? personality,
    List<String>? upgradeIds,
    bool? autoHire,
    String? originalCompetitorName,
    bool clearOriginalCompetitorName = false,
    bool? wasAcquired,
    double? morale,
    double? regulars,
    ShopSizeTier? sizeTier,
    int? expansionLevel,
  }) {
    final resolvedTier = sizeTier ??
        (expansionLevel != null
            ? ShopSizeTierX.fromLegacyExpansionLevel(expansionLevel)
            : this.sizeTier);

    return Shop(
      id: id,
      name: name ?? this.name,
      customName: clearCustomName ? null : (customName ?? this.customName),
      cityId: cityId,
      locationName: locationName,
      footTraffic: footTraffic,
      weeklyRent: weeklyRent ?? this.weeklyRent,
      isOpen: isOpen ?? this.isOpen,
      menu: menu ?? this.menu,
      equipment: equipment ?? this.equipment,
      employees: employees ?? this.employees,
      reputation: reputation ?? this.reputation,
      dayOpened: dayOpened,
      activeCampaigns: activeCampaigns ?? this.activeCampaigns,
      personality: personality ?? this.personality,
      upgradeIds: upgradeIds ?? this.upgradeIds,
      autoHire: autoHire ?? this.autoHire,
      originalCompetitorName: clearOriginalCompetitorName
          ? null
          : (originalCompetitorName ?? this.originalCompetitorName),
      wasAcquired: wasAcquired ?? this.wasAcquired,
      morale: morale ?? this.morale,
      regulars: regulars ?? this.regulars,
      sizeTier: resolvedTier,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'customName': customName,
        'cityId': cityId,
        'locationName': locationName,
        'footTraffic': footTraffic,
        'weeklyRent': weeklyRent,
        'isOpen': isOpen,
        'menu': menu.map((p) => p.toJson()).toList(),
        'equipment': equipment.map((e) => e.toJson()).toList(),
        'employees': employees.map((e) => e.toJson()).toList(),
        'reputation': reputation,
        'dayOpened': dayOpened,
        'activeCampaigns': activeCampaigns.map((c) => c.toJson()).toList(),
        'personality': personality.name,
        'upgradeIds': upgradeIds,
        'autoHire': autoHire,
        'originalCompetitorName': originalCompetitorName,
        'wasAcquired': wasAcquired,
        'morale': morale,
        'regulars': regulars,
        'sizeTier': sizeTier.name,
        // Legacy-Feld für alte Stände/Tooling.
        'expansionLevel': expansionLevel,
      };

  factory Shop.fromJson(Map<String, dynamic> j) {
    final explicitTier = j['sizeTier'] as String?;
    final legacyLevel = (j['expansionLevel'] as num?)?.toInt() ?? 0;
    final tier = explicitTier != null
        ? ShopSizeTierX.fromJsonValue(explicitTier)
        : ShopSizeTierX.fromLegacyExpansionLevel(legacyLevel);

    return Shop(
      id: j['id'] as String,
      name: j['name'] as String,
      customName: j['customName'] as String?,
      cityId: j['cityId'] as String,
      locationName: j['locationName'] as String,
      footTraffic: j['footTraffic'] as int,
      weeklyRent: (j['weeklyRent'] as num).toDouble(),
      isOpen: j['isOpen'] as bool,
      menu: (j['menu'] as List)
          .map((e) => ShopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      equipment: (j['equipment'] as List)
          .map((e) => ShopEquipment.fromJson(e as Map<String, dynamic>))
          .toList(),
      employees: (j['employees'] as List)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList(),
      reputation: (j['reputation'] as num).toDouble(),
      dayOpened: j['dayOpened'] as int,
      activeCampaigns: (j['activeCampaigns'] as List?)
              ?.map((e) => ActiveCampaign.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      personality: LocationPersonality.values.firstWhere(
        (p) => p.name == (j['personality'] as String?),
        orElse: () => LocationPersonality.touristic,
      ),
      upgradeIds: List<String>.from(j['upgradeIds'] as List? ?? const []),
      autoHire: j['autoHire'] as bool? ?? false,
      originalCompetitorName: j['originalCompetitorName'] as String?,
      wasAcquired: j['wasAcquired'] as bool? ?? false,
      morale: (j['morale'] as num?)?.toDouble() ?? 0.75,
      regulars: (j['regulars'] as num?)?.toDouble() ?? 0.0,
      sizeTier: tier,
    );
  }
}
