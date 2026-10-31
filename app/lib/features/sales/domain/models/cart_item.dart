import '../../../../features/products/domain/models/product.dart';

/// Item in POS sales cart with selected unit, quantity, and pricing.
class CartItem {
  final Product product;
  final String unit;
  final double quantity;
  final double unitPrice;

  const CartItem({
    required this.product,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
  double get total => totalPrice;
  double get rate => unitPrice;

  String get formattedQuantity {
    final isInt = quantity == quantity.roundToDouble();
    final qtyStr = isInt ? quantity.toInt().toString() : quantity.toStringAsFixed(2);
    return '$qtyStr $unit';
  }

  String get formattedTotal {
    final isInt = totalPrice == totalPrice.roundToDouble();
    final totalStr = isInt ? totalPrice.toInt().toString() : totalPrice.toStringAsFixed(2);
    return 'Rs. $totalStr';
  }

  CartItem copyWith({
    Product? product,
    String? unit,
    double? quantity,
    double? unitPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

