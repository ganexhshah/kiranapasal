import '../../../../core/utils/parse_utils.dart';

/// Product domain model representing a store inventory item.
class Product {
  final String id;
  final String name;
  final String category;
  final String sku;
  final String barcode;
  final String description;
  final double price;
  final String priceUnit;
  final double purchasePrice;
  final String purchaseUnit;
  final double stock;
  final String stockUnit;
  final String secondaryStock;
  final String conversionText;
  final double lowStockThreshold;
  final bool enableLowStockAlert;
  final DateTime? expiryDate;
  final String? imageUrl;
  final List<String> galleryImages;
  final bool hasSalesHistory;
  final double profitMarginPercent;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    this.barcode = '',
    this.description = '',
    required this.price,
    required this.priceUnit,
    this.purchasePrice = 0.0,
    this.purchaseUnit = 'Bora',
    required this.stock,
    required this.stockUnit,
    this.secondaryStock = '',
    this.conversionText = '',
    this.lowStockThreshold = 5,
    this.enableLowStockAlert = true,
    this.expiryDate,
    this.imageUrl,
    this.galleryImages = const [],
    this.hasSalesHistory = true,
    this.profitMarginPercent = 25.0,
  });

  bool get isLowStock => stock <= lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    String categoryName = 'Daily Needs';
    if (cat is Map) {
      categoryName = cat['name']?.toString() ?? 'Daily Needs';
    } else if (cat != null) {
      categoryName = cat.toString();
    }

    final sPrice = parseDouble(json['selling_price'] ?? json['price']);
    final pPrice = parseDouble(json['purchase_price'] ?? json['purchasePrice']);
    final stockVal = parseDouble(json['stock_quantity'] ?? json['stock']);
    final sUnit = json['selling_unit']?.toString() ??
        json['priceUnit']?.toString() ??
        json['stockUnit']?.toString() ??
        'pkt';
    final pUnit = json['purchase_unit']?.toString() ??
        json['purchaseUnit']?.toString() ??
        'Bora';
    final threshold = parseDouble(json['low_stock_threshold'] ?? json['lowStockThreshold'], 5.0);

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: categoryName,
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: sPrice,
      priceUnit: sUnit,
      purchasePrice: pPrice,
      purchaseUnit: pUnit,
      stock: stockVal,
      stockUnit: sUnit,
      secondaryStock: json['secondary_stock'] != null
          ? '(${json['secondary_stock']} ${json['secondary_unit'] ?? ''})'
          : (json['secondaryStock']?.toString() ?? ''),
      conversionText: json['unit_conversion_factor'] != null
          ? '1 ${json['secondary_unit']} = ${json['unit_conversion_factor']} $sUnit'
          : (json['conversionText']?.toString() ?? ''),
      lowStockThreshold: threshold,
      enableLowStockAlert: json['enable_low_stock_alert'] as bool? ??
          json['enableLowStockAlert'] as bool? ??
          true,
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      profitMarginPercent: parseDouble(json['profit_margin'], 25.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'description': description,
      'selling_price': price,
      'selling_unit': priceUnit,
      'purchase_price': purchasePrice,
      'purchase_unit': purchaseUnit,
      'stock_quantity': stock,
      'low_stock_threshold': lowStockThreshold,
      'enable_low_stock_alert': enableLowStockAlert,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  String get formattedPrice {
    final isInt = price == price.roundToDouble();
    final priceStr = isInt ? price.toInt().toString() : price.toStringAsFixed(2);
    return 'Rs. $priceStr';
  }

  String get formattedPurchasePrice {
    final isInt = purchasePrice == purchasePrice.roundToDouble();
    final priceStr = isInt ? purchasePrice.toInt().toString() : purchasePrice.toStringAsFixed(2);
    return 'Rs. $priceStr';
  }

  String get formattedStock {
    final isInt = stock == stock.roundToDouble();
    final stockStr = isInt ? stock.toInt().toString() : stock.toStringAsFixed(1);
    return '$stockStr $stockUnit';
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? sku,
    String? barcode,
    String? description,
    double? price,
    String? priceUnit,
    double? purchasePrice,
    String? purchaseUnit,
    double? stock,
    String? stockUnit,
    String? secondaryStock,
    String? conversionText,
    double? lowStockThreshold,
    bool? enableLowStockAlert,
    DateTime? expiryDate,
    String? imageUrl,
    List<String>? galleryImages,
    bool? hasSalesHistory,
    double? profitMarginPercent,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      stock: stock ?? this.stock,
      stockUnit: stockUnit ?? this.stockUnit,
      secondaryStock: secondaryStock ?? this.secondaryStock,
      conversionText: conversionText ?? this.conversionText,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      enableLowStockAlert: enableLowStockAlert ?? this.enableLowStockAlert,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      hasSalesHistory: hasSalesHistory ?? this.hasSalesHistory,
      profitMarginPercent: profitMarginPercent ?? this.profitMarginPercent,
    );
  }
}
