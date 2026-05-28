enum EquipmentCategory { spiess, kasse, sonstiges }

class EquipmentData {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double price;
  final double qualityBonus;
  final int capacityBonus;
  final double speedBonus;
  final double ingredientSavingBonus;
  final EquipmentCategory category;
  final String? unlocksProductId;

  /// Zusätzlich freigeschaltete Produkte (über das primäre `unlocksProductId`
  /// hinaus). Z.B. Fritteuse schaltet Pommes + Döner-Box frei.
  final List<String> additionalUnlocks;

  const EquipmentData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.price,
    required this.qualityBonus,
    this.capacityBonus = 0,
    this.speedBonus = 0.0,
    this.ingredientSavingBonus = 0.0,
    required this.category,
    this.unlocksProductId,
    this.additionalUnlocks = const [],
  });

  /// Alle Produkte die dieses Equipment freischaltet.
  List<String> get allUnlockedProducts {
    final result = <String>[...additionalUnlocks];
    if (unlocksProductId != null) result.insert(0, unlocksProductId!);
    return result;
  }
}

class ShopEquipment {
  final String equipmentId;

  const ShopEquipment({required this.equipmentId});

  Map<String, dynamic> toJson() => {'equipmentId': equipmentId};

  factory ShopEquipment.fromJson(Map<String, dynamic> j) =>
      ShopEquipment(equipmentId: j['equipmentId'] as String);
}
