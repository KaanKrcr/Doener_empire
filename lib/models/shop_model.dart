import 'product_model.dart';
import 'equipment_model.dart';
import 'employee_model.dart';
import 'marketing_model.dart';

class Shop {
  final String id;
  final String name;
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

  const Shop({
    required this.id,
    required this.name,
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
  });

  double get dailyRent => weeklyRent / 7.0;

  bool hasEquipment(String equipmentId) =>
      equipment.any((e) => e.equipmentId == equipmentId);

  Shop copyWith({
    String? name,
    bool? isOpen,
    List<ShopProduct>? menu,
    List<ShopEquipment>? equipment,
    List<Employee>? employees,
    double? reputation,
    List<ActiveCampaign>? activeCampaigns,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
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
        'activeCampaigns':
            activeCampaigns.map((c) => c.toJson()).toList(),
      };

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'] as String,
        name: j['name'] as String,
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
                ?.map((e) =>
                    ActiveCampaign.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
