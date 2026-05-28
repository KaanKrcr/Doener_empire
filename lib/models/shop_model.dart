import 'product_model.dart';
import 'equipment_model.dart';
import 'employee_model.dart';
import 'marketing_model.dart';
import 'time_profile_model.dart';

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
  });

  bool hasUpgrade(String upgradeId) => upgradeIds.contains(upgradeId);

  double get dailyRent => weeklyRent / 7.0;

  bool get hasCustomName => customName != null && customName!.trim().isNotEmpty;

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
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      customName: clearCustomName ? null : (customName ?? this.customName),
      cityId: cityId,
      locationName: locationName,
      footTraffic: footTraffic,
      weeklyRent: weeklyRent,
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
      };

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
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
      );
}
