import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central service managing product and inventory settings with local persistent preferences.
class ProductSettingsService extends ChangeNotifier {
  static final ProductSettingsService instance = ProductSettingsService._internal();
  ProductSettingsService._internal();

  // Stock & Inventory Alerts
  int _lowStockThreshold = 5;
  bool _enableLowStockAlerts = true;
  bool _allowNegativeStockSales = true;
  bool _hideOutOfStockInPOS = false;

  // Pricing, Units & Tax
  String _defaultUnit = 'pkt';
  bool _priceIncludesTax = true;
  double _defaultTaxRate = 0.0;
  bool _allowPriceEditAtPOS = true;

  // Barcode & Scanning
  bool _autoGenerateBarcode = true;
  bool _continuousBarcodeScan = true;
  String _barcodeLabelSize = '50 x 30 mm';

  // Getters
  int get lowStockThreshold => _lowStockThreshold;
  bool get enableLowStockAlerts => _enableLowStockAlerts;
  bool get allowNegativeStockSales => _allowNegativeStockSales;
  bool get hideOutOfStockInPOS => _hideOutOfStockInPOS;

  String get defaultUnit => _defaultUnit;
  bool get priceIncludesTax => _priceIncludesTax;
  double get defaultTaxRate => _defaultTaxRate;
  bool get allowPriceEditAtPOS => _allowPriceEditAtPOS;

  bool get autoGenerateBarcode => _autoGenerateBarcode;
  bool get continuousBarcodeScan => _continuousBarcodeScan;
  String get barcodeLabelSize => _barcodeLabelSize;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lowStockThreshold = prefs.getInt('product_low_stock_threshold') ?? 5;
    _enableLowStockAlerts = prefs.getBool('product_enable_low_stock_alerts') ?? true;
    _allowNegativeStockSales = prefs.getBool('product_allow_negative_stock') ?? true;
    _hideOutOfStockInPOS = prefs.getBool('product_hide_out_of_stock_pos') ?? false;

    _defaultUnit = prefs.getString('product_default_unit') ?? 'pkt';
    _priceIncludesTax = prefs.getBool('product_price_includes_tax') ?? true;
    _defaultTaxRate = prefs.getDouble('product_default_tax_rate') ?? 0.0;
    _allowPriceEditAtPOS = prefs.getBool('product_allow_price_edit_pos') ?? true;

    _autoGenerateBarcode = prefs.getBool('product_auto_generate_barcode') ?? true;
    _continuousBarcodeScan = prefs.getBool('product_continuous_barcode_scan') ?? true;
    _barcodeLabelSize = prefs.getString('product_barcode_label_size') ?? '50 x 30 mm';

    notifyListeners();
  }

  Future<void> updateSettings({
    int? lowStockThreshold,
    bool? enableLowStockAlerts,
    bool? allowNegativeStockSales,
    bool? hideOutOfStockInPOS,
    String? defaultUnit,
    bool? priceIncludesTax,
    double? defaultTaxRate,
    bool? allowPriceEditAtPOS,
    bool? autoGenerateBarcode,
    bool? continuousBarcodeScan,
    String? barcodeLabelSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (lowStockThreshold != null) {
      _lowStockThreshold = lowStockThreshold;
      await prefs.setInt('product_low_stock_threshold', lowStockThreshold);
    }
    if (enableLowStockAlerts != null) {
      _enableLowStockAlerts = enableLowStockAlerts;
      await prefs.setBool('product_enable_low_stock_alerts', enableLowStockAlerts);
    }
    if (allowNegativeStockSales != null) {
      _allowNegativeStockSales = allowNegativeStockSales;
      await prefs.setBool('product_allow_negative_stock', allowNegativeStockSales);
    }
    if (hideOutOfStockInPOS != null) {
      _hideOutOfStockInPOS = hideOutOfStockInPOS;
      await prefs.setBool('product_hide_out_of_stock_pos', hideOutOfStockInPOS);
    }

    if (defaultUnit != null) {
      _defaultUnit = defaultUnit;
      await prefs.setString('product_default_unit', defaultUnit);
    }
    if (priceIncludesTax != null) {
      _priceIncludesTax = priceIncludesTax;
      await prefs.setBool('product_price_includes_tax', priceIncludesTax);
    }
    if (defaultTaxRate != null) {
      _defaultTaxRate = defaultTaxRate;
      await prefs.setDouble('product_default_tax_rate', defaultTaxRate);
    }
    if (allowPriceEditAtPOS != null) {
      _allowPriceEditAtPOS = allowPriceEditAtPOS;
      await prefs.setBool('product_allow_price_edit_pos', allowPriceEditAtPOS);
    }

    if (autoGenerateBarcode != null) {
      _autoGenerateBarcode = autoGenerateBarcode;
      await prefs.setBool('product_auto_generate_barcode', autoGenerateBarcode);
    }
    if (continuousBarcodeScan != null) {
      _continuousBarcodeScan = continuousBarcodeScan;
      await prefs.setBool('product_continuous_barcode_scan', continuousBarcodeScan);
    }
    if (barcodeLabelSize != null) {
      _barcodeLabelSize = barcodeLabelSize;
      await prefs.setString('product_barcode_label_size', barcodeLabelSize);
    }

    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('product_low_stock_threshold');
    await prefs.remove('product_enable_low_stock_alerts');
    await prefs.remove('product_allow_negative_stock');
    await prefs.remove('product_hide_out_of_stock_pos');
    await prefs.remove('product_default_unit');
    await prefs.remove('product_price_includes_tax');
    await prefs.remove('product_default_tax_rate');
    await prefs.remove('product_allow_price_edit_pos');
    await prefs.remove('product_auto_generate_barcode');
    await prefs.remove('product_continuous_barcode_scan');
    await prefs.remove('product_barcode_label_size');

    _lowStockThreshold = 5;
    _enableLowStockAlerts = true;
    _allowNegativeStockSales = true;
    _hideOutOfStockInPOS = false;
    _defaultUnit = 'pkt';
    _priceIncludesTax = true;
    _defaultTaxRate = 0.0;
    _allowPriceEditAtPOS = true;
    _autoGenerateBarcode = true;
    _continuousBarcodeScan = true;
    _barcodeLabelSize = '50 x 30 mm';

    notifyListeners();
  }
}

