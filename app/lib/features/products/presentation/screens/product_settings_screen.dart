import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/product_settings_service.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../sheets/create_category_sheet.dart';
import '../sheets/unit_picker_sheet.dart';

/// Comprehensive settings screen for products, inventory thresholds, tax, and barcode preferences.
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
                'Select Default VAT / Tax Rate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Gap(12),
              ..._taxRates.map((rate) {
                final isSelected = _settings.defaultTaxRate == rate;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                  title: Text(
                    rate == 0.0 ? '0% (Exempt / Grocery)' : '${rate.toInt()}% (${rate == 13.0 ? "Nepal Standard VAT" : "Reduced"})',
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
                'Barcode Label Print Size',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Gap(12),
              ..._barcodeSizes.map((size) {
                final isSelected = _settings.barcodeLabelSize.contains(size.split(' ').first);
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
      _showFeedback('Barcode print size set to $picked');
    }
  }

  Future<void> _promptCustomThreshold() async {
    final controller = TextEditingController(text: _settings.lowStockThreshold.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Low Stock Threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Quantity threshold',
            hintText: 'e.g. 8',
            suffixText: 'units',
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
        final outOfStockCount = products.where((p) => p.stock <= 0).length;
        final totalInventoryValue = products.fold<double>(0.0, (sum, p) => sum + (p.price * p.stock.clamp(0, 999999)));

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Top Bar
                  AppTopBar(
                    title: 'Product Settings',
                    leading: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreVertical, size: 20, color: Color(0xFF0F172A)),
                        onSelected: (val) {
                          if (val == 'reset') _resetDefaults();
                          if (val == 'sync') _syncProducts();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'sync',
                            child: Row(
                              children: [
                                Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFF0F172A)),
                                Gap(10),
                                Text('Re-sync Catalog'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(LucideIcons.rotateCcw, size: 16, color: Color(0xFFDC2626)),
                                Gap(10),
                                Text('Reset Defaults', style: TextStyle(color: Color(0xFFDC2626))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Scrollable Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        // 1. Inventory Overview Snapshot Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Inventory Snapshot',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${products.length} Products',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(6),
                              Text(
                                'Rs. ${totalInventoryValue.toInt()}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Gap(2),
                              const Text(
                                'Est. Total Inventory Retail Value',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                              const Gap(12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _statPill('Low Stock', '${lowStock.length}', const Color(0xFFFDE68A)),
                                    Container(width: 1, height: 16, color: Colors.white24),
                                    _statPill('Out of Stock', '$outOfStockCount', const Color(0xFFFCA5A5)),
                                    Container(width: 1, height: 16, color: Colors.white24),
                                    _statPill('Threshold', '${_settings.lowStockThreshold} units', Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),

                        // 2. Stock & Inventory Alerts
                        _buildSectionCard(
                          title: 'Stock & Alert Rules',
                          icon: LucideIcons.bellRing,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFFFBEB),
                          children: [
                            // Low Stock Threshold selector
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Low Stock Warning Threshold',
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        '${_settings.lowStockThreshold} units',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                  const Gap(4),
                                  const Text(
                                    'Items falling to or below this quantity will trigger low stock indicators and notifications.',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
                                                      : const Color(0xFFF1F5F9),
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
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFCBD5E1)),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(LucideIcons.pencil, size: 11, color: Color(0xFF475569)),
                                                Gap(4),
                                                Text('Custom', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
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
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Enable low stock alerts
                            SwitchListTile.adaptive(
                              value: _settings.enableLowStockAlerts,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (val) => _settings.updateSettings(enableLowStockAlerts: val),
                              title: const Text('Low Stock Alerts & Notifications', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Show visual badges and warnings for depleted goods', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Allow negative stock sales
                            SwitchListTile.adaptive(
                              value: _settings.allowNegativeStockSales,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (val) => _settings.updateSettings(allowNegativeStockSales: val),
                              title: const Text('Allow Selling Out-of-Stock Items', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Cashier can bill products even if stock counter is 0', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Hide out of stock items in POS
                            SwitchListTile.adaptive(
                              value: _settings.hideOutOfStockInPOS,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (val) => _settings.updateSettings(hideOutOfStockInPOS: val),
                              title: const Text('Hide 0-Stock Items in POS Catalog', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Only show available inventory on quick sales screen', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                          ],
                        ),
                        const Gap(16),

                        // 3. Units, Pricing & Tax
                        _buildSectionCard(
                          title: 'Units, Pricing & Tax',
                          icon: LucideIcons.badgePercent,
                          iconColor: const Color(0xFF2563EB),
                          iconBg: const Color(0xFFEFF6FF),
                          children: [
                            // Default selling unit
                            ListTile(
                              onTap: _pickDefaultUnit,
                              title: const Text('Default Selling Unit', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Applied when adding new items or quick billing', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      _settings.defaultUnit.toUpperCase(),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                  const Gap(6),
                                  const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Prices Include VAT
                            SwitchListTile.adaptive(
                              value: _settings.priceIncludesTax,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (val) => _settings.updateSettings(priceIncludesTax: val),
                              title: const Text('Prices Include Tax / VAT (MRP)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Retail shelf prices already include VAT on invoice', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Default Tax Rate
                            ListTile(
                              onTap: _pickTaxRate,
                              title: const Text('Default VAT / Tax Rate', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Applied to taxable products during checkout', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _settings.defaultTaxRate == 0 ? '0% (Exempt)' : '${_settings.defaultTaxRate.toInt()}%',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  const Gap(6),
                                  const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Allow price edit at checkout
                            SwitchListTile.adaptive(
                              value: _settings.allowPriceEditAtPOS,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (val) => _settings.updateSettings(allowPriceEditAtPOS: val),
                              title: const Text('Allow Price Adjustment at Checkout', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Cashier can customize rates on the POS cart item sheet', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                          ],
                        ),
                        const Gap(16),

                        // 4. Barcode & Scanner Preferences
                        _buildSectionCard(
                          title: 'Barcode & Scanning',
                          icon: LucideIcons.barcode,
                          iconColor: const Color(0xFF6366F1),
                          iconBg: const Color(0xFFEEF2FF),
                          children: [
                            // Auto-generate barcodes
                            SwitchListTile.adaptive(
                              value: _settings.autoGenerateBarcode,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (val) => _settings.updateSettings(autoGenerateBarcode: val),
                              title: const Text('Auto-Generate Barcode & SKU', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Creates a 6-digit EAN-style barcode for new products if omitted', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Continuous scan mode
                            SwitchListTile.adaptive(
                              value: _settings.continuousBarcodeScan,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (val) => _settings.updateSettings(continuousBarcodeScan: val),
                              title: const Text('Continuous Quick Scan Mode', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Immediately add item +1 upon barcode beep without popups', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Barcode label size
                            ListTile(
                              onTap: _pickBarcodeSize,
                              title: const Text('Barcode Sticker Print Size', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: const Text('Dimension for thermal barcode printers', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _settings.barcodeLabelSize.split(' ').first,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  const Gap(6),
                                  const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            ),
                          ],
                        ),
                        const Gap(16),

                        // 5. Category & Catalog Management
                        _buildSectionCard(
                          title: 'Catalog Actions',
                          icon: LucideIcons.layoutGrid,
                          iconColor: const Color(0xFF16A34A),
                          iconBg: const Color(0xFFF0FDF4),
                          children: [
                            // Category manager tile
                            ListTile(
                              onTap: () async {
                                final created = await CreateCategorySheet.show(context);
                                if (created != null && mounted) {
                                  _showFeedback('Category "$created" added');
                                }
                              },
                              leading: const Icon(LucideIcons.folderPlus, size: 18, color: Color(0xFF16A34A)),
                              title: const Text('Add / Manage Categories', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              subtitle: Text('${repo.categories.length} active product categories', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Re-sync catalog tile
                            ListTile(
                              onTap: _isSyncing ? null : _syncProducts,
                              leading: _isSyncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                    )
                                  : const Icon(LucideIcons.refreshCw, size: 18, color: Color(0xFF2563EB)),
                              title: Text(
                                _isSyncing ? 'Synchronizing Catalog...' : 'Re-sync Product Catalog',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              ),
                              subtitle: const Text('Pull latest products, prices and stock counts from server', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            ),
                          ],
                        ),
                      ],
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

  Widget _statPill(String label, String value, Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        const Gap(2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<Widget> children,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const Gap(10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }
}
