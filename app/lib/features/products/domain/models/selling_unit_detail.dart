/// Represents a single selling unit entry in the Product Details conversion table.
class SellingUnitDetail {
  final String id;
  String name;
  String equivalent;
  double price;
  bool isDefault;
  bool isActive;

  SellingUnitDetail({
    required this.id,
    required this.name,
    required this.equivalent,
    required this.price,
    this.isDefault = false,
    this.isActive = true,
  });

  String get formattedPrice {
    final isInt = price == price.roundToDouble();
    final priceStr = isInt ? price.toInt().toString() : price.toStringAsFixed(2);
    return 'Rs. $priceStr';
  }

  SellingUnitDetail copyWith({
    String? id,
    String? name,
    String? equivalent,
    double? price,
    bool? isDefault,
    bool? isActive,
  }) {
    return SellingUnitDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      equivalent: equivalent ?? this.equivalent,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}

