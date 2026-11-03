import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/product_backend_service.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/product.dart';
import '../../domain/models/selling_unit_detail.dart';
import '../../domain/models/stock_history_entry.dart';
import '../sheets/add_edit_selling_unit_sheet.dart';
import '../sheets/adjust_stock_sheet.dart';
import '../sheets/category_picker_sheet.dart';
import '../sheets/date_picker_sheet.dart';
import '../sheets/delete_confirmation_sheet.dart';
import '../sheets/edit_product_sheet.dart';
import '../sheets/image_source_picker_sheet.dart';
import '../sheets/low_stock_alert_sheet.dart';
import '../sheets/print_barcode_sheet.dart';
import '../sheets/product_actions_sheet.dart';
import '../widgets/product_thumbnail.dart';
import 'add_product_screen.dart';

/// Complete Product Details screen matching the mockup with interactive stock adjustments,
/// multi-unit conversion management, quick settings, and stock movement logs.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.onProductUpdated,
    this.onProductDeleted,
  });

  final Product product;
  final ValueChanged<Product>? onProductUpdated;
  final VoidCallback? onProductDeleted;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Product _product;
  int _selectedImageIndex = 0;

  late final List<SellingUnitDetail> _sellingUnits;
  final ProductBackendService _productService = ProductBackendService();
  late List<StockHistoryEntry> _stockHistory;

  @override
  void initState() {
    super.initState();
    _product = widget.product;

    // Dynamically initialized from real product properties
    _sellingUnits = [
      SellingUnitDetail(
        id: 'base_${_product.id}',
        name: _product.stockUnit,
        equivalent: '1 ${_product.stockUnit}',
        price: _product.price > 0 ? _product.price : 100.0,
        isDefault: true,
        isActive: true,
      ),
      if (_product.purchaseUnit.isNotEmpty && _product.purchaseUnit != _product.stockUnit)
        SellingUnitDetail(
          id: 'bulk_${_product.id}',
          name: _product.purchaseUnit,
          equivalent: _product.conversionText.isNotEmpty ? _product.conversionText : '1 ${_product.purchaseUnit}',
          price: _product.purchasePrice > 0 ? _product.purchasePrice : _product.price,
          isDefault: false,
          isActive: true,
        ),
    ];

    _stockHistory = [];
    _loadRealStockHistory();
  }

  Future<void> _loadRealStockHistory() async {
    try {
      final res = await _productService.getStockHistory(_product.id);
      if (res.success && res.data != null && mounted) {
        final list = res.data!;
        setState(() {
          _stockHistory = list.map((item) {
            final map = item as Map<String, dynamic>;
            return StockHistoryEntry(
              id: map['id']?.toString() ?? '',
              title: map['title']?.toString() ?? 'Stock Movement',
              timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
              changeAmount: parseDouble(map['change_amount']),
              unit: map['unit']?.toString() ?? _product.stockUnit,
              balance: parseDouble(map['balance']),
              isAddition: map['is_addition'] as bool? ?? true,
              reason: map['reason']?.toString() ?? '',
            );
          }).toList();
        });
      }
    } catch (_) {}
  }

  List<String> get _galleryList {
    final list = <String>[];
    if (_product.imageUrl != null && _product.imageUrl!.isNotEmpty) {
      list.add(_product.imageUrl!);
    }
    list.addAll(_product.galleryImages);
    return list;
  }

  void _notifyProductChange() {
    widget.onProductUpdated?.call(_product);
  }

  // --- Sheet Invocations ---

  Future<void> _openAdjustStockSheet() async {
    final result = await AdjustStockSheet.show(context, product: _product);
    if (result != null) {
      await AppDataRepository.instance.adjustStock(
        productId: _product.id,
        isAddition: result.isAddition,
        quantity: result.quantity,
        unit: result.unit,
        reason: result.reason,
        note: result.note,
      );

      setState(() {
        _product = _product.copyWith(stock: result.newStock);
      });
      _notifyProductChange();
      _loadRealStockHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock adjusted to ${_product.formattedStock}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _openAddEditSellingUnitSheet([SellingUnitDetail? existing]) async {
    final result = await AddEditSellingUnitSheet.show(
      context,
      initialUnit: existing,
      baseUnit: _product.stockUnit,
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          final idx = _sellingUnits.indexWhere((u) => u.id == existing.id);
          if (idx >= 0) {
            _sellingUnits[idx] = result;
          }
        } else {
          _sellingUnits.add(result);
        }

        if (result.isDefault) {
          for (final u in _sellingUnits) {
            if (u.id != result.id) u.isDefault = false;
          }
          _product = _product.copyWith(price: result.price, priceUnit: result.name);
          _notifyProductChange();
        }
      });
    }
  }

  Future<void> _openEditProductSheet() async {
    final updated = await EditProductSheet.show(
      context,
      product: _product,
      onOpenFullScreen: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddProductScreen(initialProduct: _product),
          ),
        );
      },
    );

    if (updated != null) {
      setState(() => _product = updated);
      _notifyProductChange();
    }
  }

  Future<void> _openLowStockAlertSheet() async {
    final result = await LowStockAlertSheet.show(
      context,
      initialEnabled: _product.enableLowStockAlert,
      initialThreshold: _product.lowStockThreshold,
      initialUnit: _product.stockUnit,
      availableUnits: {_product.stockUnit, _product.purchaseUnit, 'kg', 'gram'}.toList(),
    );

    if (result != null) {
      await AppDataRepository.instance.updateLowStockThreshold(
        productId: _product.id,
        threshold: result.threshold,
        enabled: result.enabled,
      );
      setState(() {
        _product = _product.copyWith(
          enableLowStockAlert: result.enabled,
          lowStockThreshold: result.threshold,
        );
      });
      _notifyProductChange();
    }
  }

  Future<void> _openCategoryPicker() async {
    final picked = await CategoryPickerSheet.show(
      context,
      selectedCategory: _product.category,
    );

    if (picked != null && picked.trim().isNotEmpty) {
      setState(() {
        _product = _product.copyWith(category: picked.trim());
      });
      _notifyProductChange();
    }
  }

  Future<void> _openExpiryDateSheet() async {
    final pickedDate = await DatePickerSheet.show(
      context,
      initialDate: _product.expiryDate,
      canClear: true,
    );

    setState(() {
      _product = _product.copyWith(expiryDate: pickedDate);
    });
    _notifyProductChange();
  }

  Future<void> _openImageGallerySheet() async {
    final picked = await ImageSourcePickerSheet.show(
      context,
      currentImageUrl: _product.imageUrl,
    );

    if (picked != null) {
      setState(() {
        _product = _product.copyWith(
          imageUrl: picked.isEmpty ? null : picked,
        );
      });
      _notifyProductChange();
    }
  }

  Future<void> _openProductActionsSheet() async {
    final action = await ProductActionsSheet.show(context, product: _product);
    if (action == null) return;

    switch (action) {
      case ProductActionType.edit:
        _openEditProductSheet();
        break;
      case ProductActionType.printBarcode:
        if (mounted) PrintBarcodeSheet.show(context, product: _product);
        break;
      case ProductActionType.adjustStock:
        _openAdjustStockSheet();
        break;
      case ProductActionType.manageUnits:
        _openAddEditSellingUnitSheet();
        break;
      case ProductActionType.stockHistory:
        // Scroll to history or show SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Displaying full stock movement history')),
          );
        }
        break;
      case ProductActionType.lowStockAlert:
        _openLowStockAlertSheet();
        break;
      case ProductActionType.expiryDate:
        _openExpiryDateSheet();
        break;
      case ProductActionType.delete:
        if (mounted) _confirmDelete();
        break;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await DeleteConfirmationSheet.show(context, product: _product);
    if (confirmed == true && mounted) {
      widget.onProductDeleted?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final images = _galleryList;
    final activeImage = images.isNotEmpty && _selectedImageIndex < images.length
        ? images[_selectedImageIndex]
        : null;

    final formattedExpiry = _product.expiryDate != null
        ? DateFormat('dd MMM yyyy').format(_product.expiryDate!)
        : 'Not Set';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Bar Header
              _buildTopBar(colors),

              // 2. Scrollable Body with Drag-to-Refresh
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await AppDataRepository.instance.refreshAll();
                    final refreshed = AppDataRepository.instance.products.firstWhere(
                      (p) => p.id == _product.id,
                      orElse: () => _product,
                    );
                    if (mounted) {
                      setState(() => _product = refreshed);
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Hero Card
                        _buildProductHeroCard(colors, activeImage, images),
                        const Gap(14),

                        // 4 KPI Stat Cards Grid
                        _buildKpiStatGrid(colors),
                        const Gap(16),

                        // Units & Conversion Section
                        _buildUnitsAndConversionSection(colors),
                        const Gap(16),

                        // 2x2 Quick Setting Cards
                        _buildQuickSettingCards(colors, formattedExpiry),
                        const Gap(16),

                        // Stock Movement History Section
                        _buildStockHistorySection(colors),
                        const Gap(24),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Persistent Sticky Bottom Action Bar
              _buildBottomActionBar(colors),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub-Widgets ---

  Widget _buildTopBar(AppColorsExtension colors) {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Gap(6),
          Expanded(
            child: Text(
              'Product Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.darkText,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // "Edit" Pill Button (borderless)
          TextButton.icon(
            onPressed: _openEditProductSheet,
            icon: const Icon(LucideIcons.pencil, size: 13, color: Color(0xFF2563EB)),
            label: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEFF6FF),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Gap(6),
          // Overflow 3-dots Menu Button
          IconButton(
            onPressed: _openProductActionsSheet,
            icon: const Icon(LucideIcons.moreVertical, size: 18),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeroCard(
    AppColorsExtension colors,
    String? activeImage,
    List<String> images,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image Display & Thumbnails
          SizedBox(
            width: 104,
            child: Column(
              children: [
                // Main Photo
                GestureDetector(
                  onTap: _openImageGallerySheet,
                  child: ProductThumbnail(
                    imageUrl: activeImage,
                    category: _product.category,
                    size: 104,
                    borderRadius: 12,
                  ),
                ),
                const Gap(8),

                // Thumbnails Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < images.length && i < 2; i++)
                      GestureDetector(
                        onTap: () => setState(() => _selectedImageIndex = i),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: _selectedImageIndex == i
                                ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                                : null,
                          ),
                          child: ProductThumbnail(
                            imageUrl: images[i],
                            category: _product.category,
                            size: 30,
                            borderRadius: 6,
                          ),
                        ),
                      ),
                    // Add Photo (+) Button
                    GestureDetector(
                      onTap: _openImageGallerySheet,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.plus, size: 15, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(14),

          // Right: Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name + In Stock Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _product.name,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: colors.darkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _product.isLowStock
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _product.isLowStock ? 'Low Stock' : 'In Stock',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _product.isLowStock
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),

                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _product.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const Gap(8),

                // Barcode & SKU Row
                Row(
                  children: [
                    const Icon(LucideIcons.barcode, size: 13, color: Color(0xFF64748B)),
                    const Gap(4),
                    Text(
                      _product.sku.isNotEmpty ? _product.sku : 'No SKU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.inputLabel,
                      ),
                    ),
                    const Gap(10),
                    const Icon(LucideIcons.scanLine, size: 13, color: Color(0xFF64748B)),
                    const Gap(4),
                    Expanded(
                      child: Text(
                        _product.barcode.isNotEmpty ? _product.barcode : '8901234567890',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.inputLabel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Gap(6),

                // Description (Clean, concise)
                Text(
                  _product.description.isNotEmpty
                      ? _product.description
                      : 'No description added yet.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.inputLabel,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStatGrid(AppColorsExtension colors) {
    final stockVal = _product.stock == _product.stock.roundToDouble()
        ? _product.stock.toInt().toString()
        : _product.stock.toStringAsFixed(1);

    return Row(
      children: [
        // Total Stock
        Expanded(
          child: _kpiCard(
            colors: colors,
            icon: LucideIcons.box,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFEFF6FF),
            label: 'Total Stock',
            mainValue: '$stockVal ${_product.stockUnit}',
            subValue: _product.secondaryStock.isNotEmpty ? _product.secondaryStock : '',
          ),
        ),
        const Gap(8),

        // Selling Price
        Expanded(
          child: _kpiCard(
            colors: colors,
            icon: LucideIcons.shoppingCart,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFECFDF5),
            label: 'Selling Price',
            mainValue: _product.formattedPrice,
            subValue: '/ ${_product.priceUnit}',
          ),
        ),
        const Gap(8),

        // Purchase Price
        Expanded(
          child: _kpiCard(
            colors: colors,
            icon: LucideIcons.tag,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEF2F2),
            label: 'Purchase Price',
            mainValue: _product.purchasePrice > 0 ? _product.formattedPurchasePrice : 'Not set',
            subValue: _product.purchasePrice > 0 ? '/ ${_product.purchaseUnit}' : 'Add cost price',
          ),
        ),
        const Gap(8),

        // Profit Margin
        Expanded(
          child: _kpiCard(
            colors: colors,
            icon: LucideIcons.trendingUp,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF5F3FF),
            label: 'Profit Margin',
            mainValue: '${_product.profitMarginPercent.toInt()}%',
            subValue: _product.purchasePrice > 0 ? 'per ${_product.priceUnit}' : 'Needs cost price',
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required AppColorsExtension colors,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String mainValue,
    required String subValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.inputLabel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(2),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.darkText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subValue,
            style: TextStyle(fontSize: 9.5, color: colors.inputLabel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsAndConversionSection(AppColorsExtension colors) {
    final conversionText = _product.conversionText.isNotEmpty
        ? _product.conversionText
        : (_product.purchaseUnit.isNotEmpty && _product.stock > 0
            ? '1 ${_product.purchaseUnit} = ${_product.stock.toInt()} ${_product.stockUnit}'
            : 'Not configured');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.scale, size: 16, color: Color(0xFF475569)),
                  const Gap(6),
                  Text(
                    'Units & Conversion',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _openAddEditSellingUnitSheet(),
                icon: const Icon(LucideIcons.settings, size: 13),
                label: const Text('Manage Units', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),

          // Clean Info Banner (without heavy borders and without redundant subtitle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.scale, size: 15, color: Color(0xFF2563EB)),
                const Gap(8),
                Text(
                  conversionText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),

          // Units Table Header (Clean, lineless)
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Selling Unit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.inputLabel),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Equivalent',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.inputLabel),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Price',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.inputLabel),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Status',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.inputLabel),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const Gap(8),

          // Units Table Rows (Lineless, separated by clean vertical spacing)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sellingUnits.length,
            separatorBuilder: (ctx, idx) => const Gap(8),
            itemBuilder: (context, index) {
              final unit = _sellingUnits[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        unit.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        unit.equivalent,
                        style: TextStyle(fontSize: 12, color: colors.inputLabel),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        unit.formattedPrice,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.darkText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: unit.isDefault
                                ? const Color(0xFFDCFCE7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            unit.isDefault ? 'Default' : (unit.isActive ? 'Active' : 'Inactive'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: unit.isDefault
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Row Action 3-dots
                    IconButton(
                      onPressed: () => _openAddEditSellingUnitSheet(unit),
                      icon: const Icon(LucideIcons.moreVertical, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      splashRadius: 14,
                    ),
                  ],
                ),
              );
            },
          ),
          const Gap(10),

          // "+ Add Selling Unit" Clean Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: TextButton.icon(
              onPressed: () => _openAddEditSellingUnitSheet(),
              icon: const Icon(LucideIcons.plus, size: 14, color: Color(0xFF2563EB)),
              label: const Text(
                'Add Selling Unit',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingCards(AppColorsExtension colors, String formattedExpiry) {
    return Column(
      children: [
        Row(
          children: [
            // Current Stock Card
            Expanded(
              child: _quickSettingCard(
                colors: colors,
                icon: LucideIcons.box,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                title: 'Current Stock',
                value: _product.formattedStock,
                subValue: _product.secondaryStock.isNotEmpty ? _product.secondaryStock : '',
                onTap: _openAdjustStockSheet,
              ),
            ),
            const Gap(10),

            // Low Stock Alert Card
            Expanded(
              child: _quickSettingCard(
                colors: colors,
                icon: LucideIcons.bell,
                iconColor: const Color(0xFFEF4444),
                iconBg: const Color(0xFFFEF2F2),
                title: 'Low Stock Alert',
                value: '${_product.lowStockThreshold.toInt()} ${_product.stockUnit}',
                onTap: _openLowStockAlertSheet,
              ),
            ),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            // Category Card
            Expanded(
              child: _quickSettingCard(
                colors: colors,
                icon: LucideIcons.layoutGrid,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF5F3FF),
                title: 'Category',
                value: _product.category,
                onTap: _openCategoryPicker,
              ),
            ),
            const Gap(10),

            // Expiry Date Card
            Expanded(
              child: _quickSettingCard(
                colors: colors,
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFF0F9FF),
                title: 'Expiry Date',
                value: formattedExpiry,
                onTap: _openExpiryDateSheet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickSettingCard({
    required AppColorsExtension colors,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    String? subValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 10.5, color: colors.inputLabel),
                  ),
                  const Gap(1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subValue != null)
                    Text(
                      subValue,
                      style: TextStyle(fontSize: 10, color: colors.inputLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildStockHistorySection(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.history, size: 16, color: Color(0xFF475569)),
                  const Gap(6),
                  Text(
                    'Stock History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Showing all stock history records')),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),

          // History List Items (Lineless, separated by clean vertical spacing)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stockHistory.length,
            separatorBuilder: (ctx, idx) => const Gap(10),
            itemBuilder: (context, index) {
              final item = _stockHistory[index];
              final formattedTime = DateFormat('dd MMM, hh:mm a').format(item.timestamp);

              return Row(
                children: [
                  // Green + or Red - circular icon
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.isAddition
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isAddition ? LucideIcons.plus : LucideIcons.minus,
                      size: 13,
                      color: item.isAddition
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const Gap(10),

                  // Title and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.darkText,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 10, color: colors.inputLabel),
                        ),
                      ],
                    ),
                  ),

                  // Amount Change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.formattedChange,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: item.isAddition
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      if (item.secondaryUnitInfo != null)
                        Text(
                          item.secondaryUnitInfo!,
                          style: TextStyle(fontSize: 9.5, color: colors.inputLabel),
                        ),
                    ],
                  ),
                  const Gap(8),

                  // Clean Balance Badge (without redundant "Balance" label text)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.formattedBalance,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                  ),
                  const Gap(4),

                  // 3-dots
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Details for ${item.title}')),
                      );
                    },
                    icon: const Icon(LucideIcons.moreVertical, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    splashRadius: 12,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Delete Product Button
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
              label: const Text(
                'Delete Product',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Gap(12),

          // Adjust Stock Primary Button
          Expanded(
            flex: 6,
            child: ElevatedButton.icon(
              onPressed: _openAdjustStockSheet,
              icon: const Icon(LucideIcons.packagePlus, size: 17, color: Colors.white),
              label: const Text(
                'Adjust Stock',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
