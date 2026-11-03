import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/product_settings_service.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../sheets/create_category_sheet.dart';
import '../sheets/unit_picker_sheet.dart';

/// Clean, lineless Product Settings screen matching the modern Kirana Products theme.
/// Controls inventory rules, safety stock thresholds, tax, units, and barcode scanning.
class ProductSettingsScreen extends StatefulWidget {
  const ProductSettingsScreen({super.key});

  @override
  State<ProductSettingsScreen> createState() => _ProductSettingsScreenState();
}

class _ProductSettingsScreenState extends State<ProductSettingsScreen> {
  final ProductSettingsService _settings = ProductSettingsService.instance;
  bool _isSyncing = false;

  final List<String> _commonUnits = const [
    'pkt',
    'pcs',
    'kg',
    'ltr',
    'gm',
    'box',
    'dz',
    'bora',
    'can',
    'btl',
  ];

  final List<double> _taxRates = const [0.0, 5.0, 10.0, 13.0];
  final List<String> _barcodeSizes = const [
    '50 x 30 mm (Standard)',
    '38 x 25 mm (Compact)',
    '40 x 28 mm (Jewelry/Small)',
  ];

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDefaultUnit() async {
    final picked = await UnitPickerSheet.show(
      context,
      title: 'Select Default Selling Unit',
      units: _commonUnits,
      selectedUnit: _settings.defaultUnit,
    );
    if (picked != null && picked.isNotEmpty && mounted) {
      await _settings.updateSettings(defaultUnit: picked);
      _showFeedback('Default unit updated to $picked');
    }
  }

  Future<void> _pickTaxRate() async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              const Text(
                'Select Default VAT Rate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Gap(12),
              ..._taxRates.map((rate) {
                final isSelected = _settings.defaultTaxRate == rate;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                  title: Text(
                    rate == 0.0 ? '0% (Exempt)' : '${rate.toInt()}% (${rate == 13.0 ? "Nepal Standard VAT" : "Reduced"})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: isSelected ? const Icon(LucideIcons.check, size: 18, color: Color(0xFF2563EB)) : null,
                  onTap: () => Navigator.pop(ctx, rate),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      await _settings.updateSettings(defaultTaxRate: picked);
      _showFeedback('Default tax rate set to ${picked.toInt()}%');
    }
  }

  Future<void> _pickBarcodeSize() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              const Text(
                'Select Thermal Label Size',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Gap(12),
              ..._barcodeSizes.map((size) {
                final isSelected = _settings.barcodeLabelSize == size;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                  title: Text(
                    size,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: isSelected ? const Icon(LucideIcons.check, size: 18, color: Color(0xFF2563EB)) : null,
                  onTap: () => Navigator.pop(ctx, size),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      await _settings.updateSettings(barcodeLabelSize: picked);
      _showFeedback('Barcode sticker size updated');
    }
  }

  Future<void> _promptCustomThreshold() async {
    final controller = TextEditingController(text: '${_settings.lowStockThreshold}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Low Stock Threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter units quantity',
            suffixText: 'units',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _settings.updateSettings(lowStockThreshold: result);
      _showFeedback('Low stock threshold set to $result units');
    }
  }

  Future<void> _syncProducts() async {
    setState(() => _isSyncing = true);
    try {
      await AppDataRepository.instance.refreshAll(force: true);
      _showFeedback('Catalog refreshed successfully');
    } catch (e) {
      _showFeedback('Failed to refresh catalog: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _resetDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Product Settings?'),
        content: const Text(
          'This will restore default low stock thresholds, standard unit (pkt), and default scanner preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _settings.resetToDefaults();
      _showFeedback('Product settings reset to defaults');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_settings, AppDataRepository.instance]),
      builder: (context, _) {
        final repo = AppDataRepository.instance;
        final products = repo.products;
        final lowStock = repo.lowStockProducts;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Top Bar matching Products theme
                  AppTopBar(
                    title: 'Product Settings',
                    actions: [
                      IconButton(
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : const Icon(LucideIcons.refreshCw, size: 19, color: Color(0xFF0F172A)),
                        tooltip: 'Re-sync Catalog',
                        onPressed: _isSyncing ? null : _syncProducts,
                      ),
                    ],
                  ),

                  // Scrollable Body
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await AppDataRepository.instance.refreshAll(force: true);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
                        children: [
                          // 1. Inventory Summary Row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: Text(
                                  'Inventory Snapshot',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const Gap(6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F1FF),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(LucideIcons.package, size: 18, color: Color(0xFF2563EB)),
                                          ),
                                          const Gap(10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${products.length}',
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const Text(
                                                  'Total Products',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEECEC),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(LucideIcons.triangleAlert, size: 18, color: Color(0xFFEF4444)),
                                          ),
                                          const Gap(10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${lowStock.length}',
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                ),
                                                const Text(
                                                  'Low Stock Items',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Gap(18),

                          // 2. Stock & Alert Rules
                          _buildSectionCard(
                            sectionTitle: 'Stock & Alert Rules',
                            children: [
                              // Low stock threshold selector
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Low Stock Warning Threshold',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${_settings.lowStockThreshold} units',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(10),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          for (final count in [3, 5, 10, 15, 20])
                                            Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: InkWell(
                                                onTap: () => _settings.updateSettings(lowStockThreshold: count),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _settings.lowStockThreshold == count
                                                        ? const Color(0xFF2563EB)
                                                        : Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '$count units',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: _settings.lowStockThreshold == count
                                                          ? Colors.white
                                                          : const Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          InkWell(
                                            onTap: _promptCustomThreshold,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(LucideIcons.pencil, size: 11, color: Color(0xFF475569)),
                                                  Gap(4),
                                                  Text(
                                                    'Custom',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF475569),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Enable low stock alerts
                              SwitchListTile.adaptive(
                                value: _settings.enableLowStockAlerts,
                                activeTrackColor: const Color(0xFF2563EB),
                                onChanged: (val) => _settings.updateSettings(enableLowStockAlerts: val),
                                title: const Text(
                                  'Low Stock Alerts',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Allow negative stock sales
                              SwitchListTile.adaptive(
                                value: _settings.allowNegativeStockSales,
                                activeTrackColor: const Color(0xFF2563EB),
                                onChanged: (val) => _settings.updateSettings(allowNegativeStockSales: val),
                                title: const Text(
                                  'Allow Selling Out-of-Stock Items',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Hide out of stock items in POS
                              SwitchListTile.adaptive(
                                value: _settings.hideOutOfStockInPOS,
                                activeTrackColor: const Color(0xFF2563EB),
                                onChanged: (val) => _settings.updateSettings(hideOutOfStockInPOS: val),
                                title: const Text(
                                  'Hide Out-of-Stock in POS',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),
                            ],
                          ),
                          const Gap(18),

                          // 3. Units, Pricing & Tax
                          _buildSectionCard(
                            sectionTitle: 'Units, Pricing & Tax',
                            children: [
                              // Default selling unit
                              ListTile(
                                onTap: _pickDefaultUnit,
                                title: const Text(
                                  'Default Selling Unit',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _settings.defaultUnit.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const Gap(4),
                                    const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Prices Include VAT
                              SwitchListTile.adaptive(
                                value: _settings.priceIncludesTax,
                                activeTrackColor: const Color(0xFF2563EB),
                                onChanged: (val) => _settings.updateSettings(priceIncludesTax: val),
                                title: const Text(
                                  'Prices Include Tax / VAT (MRP)',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Default Tax Rate
                              ListTile(
                                onTap: _pickTaxRate,
                                title: const Text(
                                  'Default VAT Rate',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _settings.defaultTaxRate == 0 ? '0% (Exempt)' : '${_settings.defaultTaxRate.toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const Gap(4),
                                    const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Allow price edit at checkout
                              SwitchListTile.adaptive(
                                value: _settings.allowPriceEditAtPOS,
                                activeTrackColor: const Color(0xFF2563EB),
                                onChanged: (val) => _settings.updateSettings(allowPriceEditAtPOS: val),
                                title: const Text(
                                  'Allow Price Adjustment at Checkout',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),
                            ],
                          ),
                          const Gap(18),

                          // 4. Barcode & Scanning Preferences
                          _buildSectionCard(
                            sectionTitle: 'Barcode & Scanning',
                            children: [
                              // Auto-generate barcodes
                              SwitchListTile.adaptive(
                                value: _settings.autoGenerateBarcode,
                                activeTrackColor: const Color(0xFF2563EB),
                                onChanged: (val) => _settings.updateSettings(autoGenerateBarcode: val),
                                title: const Text(
                                  'Auto-Generate Barcode & SKU',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Continuous scan mode
                              SwitchListTile.adaptive(
                                value: _settings.continuousBarcodeScan,
                                activeTrackColor: const Color(0xFF2563EB),
                                onChanged: (val) => _settings.updateSettings(continuousBarcodeScan: val),
                                title: const Text(
                                  'Continuous Quick Scan Mode',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Barcode label size
                              ListTile(
                                onTap: _pickBarcodeSize,
                                title: const Text(
                                  'Barcode Sticker Print Size',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _settings.barcodeLabelSize.split(' ').first,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const Gap(4),
                                    const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),
                            ],
                          ),
                          const Gap(18),

                          // 5. Category & Catalog Management
                          _buildSectionCard(
                            sectionTitle: 'Catalog Actions',
                            children: [
                              // Category manager tile
                              ListTile(
                                onTap: () async {
                                  final created = await CreateCategorySheet.show(context);
                                  if (created != null && mounted) {
                                    _showFeedback('Category "$created" added');
                                  }
                                },
                                leading: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(LucideIcons.folderPlus, size: 17, color: Color(0xFF2563EB)),
                                ),
                                title: const Text(
                                  'Add / Manage Categories',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                subtitle: Text(
                                  '${repo.categories.length} categories',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                                trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),

                              // Re-sync catalog tile
                              ListTile(
                                onTap: _isSyncing ? null : _syncProducts,
                                leading: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: _isSyncing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF2563EB),
                                          ),
                                        )
                                      : const Icon(LucideIcons.refreshCw, size: 17, color: Color(0xFF2563EB)),
                                ),
                                title: const Text(
                                  'Re-sync Product Catalog',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),
                            ],
                          ),
                          const Gap(24),

                          // Reset to Defaults Button
                          Center(
                            child: TextButton.icon(
                              onPressed: _resetDefaults,
                              icon: const Icon(LucideIcons.rotateCcw, size: 15, color: Color(0xFFDC2626)),
                              label: const Text(
                                'Reset Settings to Defaults',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                          const Gap(16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String sectionTitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ),
        const Gap(6),
        Material(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
