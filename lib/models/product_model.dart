enum ProductCategory { doener, box, beilage, getraenk }

extension ProductCategoryLabel on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.doener:
        return 'Döner';
      case ProductCategory.box:
        return 'Box';
      case ProductCategory.beilage:
        return 'Beilagen';
      case ProductCategory.getraenk:
        return 'Getränke';
    }
  }
}

class ProductData {
  final String id;
  final String name;
  final String emoji;
  final double basePrice;
  final double ingredientCostPerUnit;
  final ProductCategory category;
  final bool isDefault;
  final String? requiredEquipmentId;

  const ProductData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.basePrice,
    required this.ingredientCostPerUnit,
    required this.category,
    this.isDefault = false,
    this.requiredEquipmentId,
  });
}

// Instanz im Shop: Preis kann vom Spieler angepasst werden
class ShopProduct {
  final String productId;
  double price;
  bool isActive;

  ShopProduct({
    required this.productId,
    required this.price,
    this.isActive = true,
  });

  ShopProduct copyWith({double? price, bool? isActive}) {
    return ShopProduct(
      productId: productId,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'price': price,
        'isActive': isActive,
      };

  factory ShopProduct.fromJson(Map<String, dynamic> j) => ShopProduct(
        productId: j['productId'] as String,
        price: (j['price'] as num).toDouble(),
        isActive: j['isActive'] as bool,
      );
}
