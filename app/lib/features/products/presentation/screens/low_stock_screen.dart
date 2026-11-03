import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../sales/presentation/sheets/record_purchase_sheet.dart';
import '../../domain/models/product.dart';
import '../sheets/adjust_stock_sheet.dart';
import '../sheets/low_stock_alert_sheet.dart';
import '../widgets/product_thumbnail.dart';
import 'product_details_screen.dart';

/// Low stock inventory model containing supplier and deficit information.
class LowStockItemData {
  Product product;
  final String supplierName;
  final String supplierPhone;
  final double estimatedReorderCost;

  LowStockItemData({
    required this.product,
    required this.supplierName,
    required this.supplierPhone,
    required this.estimatedReorderCost,
  });

  double get deficit =>
      (product.lowStockThreshold - product.stock).clamp(0.0, 99999.0);
  bool get isOutOfStock => product.stock <= 0;
}

/// Comprehensive, lineless Low Stock Items screen for inventory monitoring,
/// quick restocking, alert threshold management, and supplier reordering.
class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Out of Stock', 'Critical (<5)'
  String _categoryFilter = 'All'; // 'All', 'Daily Needs', 'Grains', 'Snacks', 'Beverages'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDataRepository.instance.refreshAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LowStockItemData> get _items {
    final suppliers = AppDataRepository.instance.suppliers;
    final defaultSupplier = suppliers.isNotEmpty ? suppliers.first : null;

    return AppDataRepository.instance.lowStockProducts.map((p) {
      return LowStockItemData(
        product: p,
        supplierName: defaultSupplier?.name ?? 'Wholesale Supplier',
        supplierPhone: defaultSupplier?.phone ?? '',
        estimatedReorderCost:
            (p.lowStockThreshold - p.stock).clamp(0.0, 99999.0) * p.purchasePrice,
      );
    }).toList();
  }

  List<LowStockItemData> get _filteredItems {
    return _items.where((item) {
      // Status filter
      if (_statusFilter == 'Out of Stock' && !item.isOutOfStock) {
        return false;
      }
      if (_statusFilter == 'Critical (<5)' && item.product.stock >= 5) {
        return false;
      }

      // Category filter
      if (_categoryFilter != 'All' && item.product.category != _categoryFilter) {
        return false;
      }

      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.product.name.toLowerCase().contains(q);
        final matchSku = item.product.sku.toLowerCase().contains(q);
        final matchSupplier = item.supplierName.toLowerCase().contains(q);
        return matchName || matchSku || matchSupplier;
      }

      return true;
    }).toList();
  }

  void _openAdjustStock(LowStockItemData item) async {
    final result = await AdjustStockSheet.show(
      context,
      product: item.product,
    );

    if (result != null && mounted) {
      await AppDataRepository.instance.adjustStock(
        productId: item.product.id,
        isAddition: result.isAddition,
        quantity: result.quantity,
        unit: result.unit,
        reason: result.reason,
        note: result.note,
      );

      setState(() {
        final newStock = result.isAddition
            ? item.product.stock + result.quantity
            : (item.product.stock - result.quantity).clamp(0.0, 999999.0);
        item.product = item.product.copyWith(stock: newStock);
      });

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restocked ${item.product.name}. New stock: ${item.product.formattedStock}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openSetThreshold(LowStockItemData item) async {
    final result = await LowStockAlertSheet.show(
      context,
      initialEnabled: item.product.enableLowStockAlert,
      initialThreshold: item.product.lowStockThreshold,
      initialUnit: item.product.stockUnit,
      availableUnits: [item.product.stockUnit, 'pcs', 'kg', 'pkt', 'box'],
    );

    if (result != null && mounted) {
      await AppDataRepository.instance.updateLowStockThreshold(
        productId: item.product.id,
        threshold: result.threshold,
        enabled: result.enabled,
      );

      setState(() {
        item.product = item.product.copyWith(
          enableLowStockAlert: result.enabled,
          lowStockThreshold: result.threshold,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated threshold for ${item.product.name} to ${result.threshold.toInt()} ${item.product.stockUnit}'),
          ),
        );
      }
    }
  }

  void _callSupplier(LowStockItemData item) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.phoneCall, color: Colors.white, size: 16),
            const Gap(10),
            Text('Calling ${item.supplierName} (${item.supplierPhone})...'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _recordPurchaseOrder() async {
    await RecordPurchaseSheet.show(context);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filteredItems;

    final outOfStockCount = _items.where((i) => i.isOutOfStock).length;
    final totalDeficitCost = _items.fold<double>(0, (sum, i) => sum + i.estimatedReorderCost);

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
              // Lineless Top Bar
              AppTopBar(
                title: 'Low Stock Items',
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.bellRing, size: 20, color: Color(0xFF475569)),
                    tooltip: 'Stock Alerts',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Low stock notifications active')),
                      );
                    },
                  ),
                ],
              ),

              // Scrollable Body with Drag-to-Refresh & Sliver Virtualization
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await AppDataRepository.instance.refreshAll(force: true);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Warning Alert Banner (Red/Amber Modern)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(LucideIcons.triangleAlert, size: 18, color: Color(0xFFDC2626)),
                                    ),
                                    const Gap(12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_items.length} items require attention',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF991B1B),
                                            ),
                                          ),
                                          const Gap(2),
                                          const Text(
                                            'Stock levels are below minimum safety threshold. Restock soon to prevent lost customer sales.',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFFB91C1C),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(12),

                              // KPI Summary Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _kpiCard(
                                      label: 'Low Stock',
                                      value: '${_items.length} Items',
                                      color: const Color(0xFFD97706),
                                      bgColor: const Color(0xFFFEF3C7),
                                      icon: LucideIcons.packageOpen,
                                    ),
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    child: _kpiCard(
                                      label: 'Out of Stock',
                                      value: '$outOfStockCount Items',
                                      color: const Color(0xFFDC2626),
                                      bgColor: const Color(0xFFFEE2E2),
                                      icon: LucideIcons.circleAlert,
                                    ),
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    child: _kpiCard(
                                      label: 'Est. Reorder',
                                      value: 'Rs. ${(totalDeficitCost / 1000).toStringAsFixed(1)}k',
                                      color: const Color(0xFF2563EB),
                                      bgColor: const Color(0xFFDBEAFE),
                                      icon: LucideIcons.shoppingBag,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(14),

                              // Search Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                  style: const TextStyle(fontSize: 13.5),
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(LucideIcons.x, size: 14),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    hintText: 'Search low stock product, SKU, or supplier...',
                                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                              const Gap(12),

                              // Status & Category Filter Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _chip('All (${_items.length})', _statusFilter == 'All', () {
                                      setState(() => _statusFilter = 'All');
                                    }),
                                    const Gap(6),
                                    _chip('Out of Stock ($outOfStockCount)', _statusFilter == 'Out of Stock', () {
                                      setState(() => _statusFilter = 'Out of Stock');
                                    }),
                                    const Gap(6),
                                    _chip('Critical (<5)', _statusFilter == 'Critical (<5)', () {
                                      setState(() => _statusFilter = 'Critical (<5)');
                                    }),
                                    const Gap(12),
                                    Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                                    const Gap(12),
                                    _chip('All Categories', _categoryFilter == 'All', () {
                                      setState(() => _categoryFilter = 'All');
                                    }),
                                    const Gap(6),
                                    _chip('Daily Needs', _categoryFilter == 'Daily Needs', () {
                                      setState(() => _categoryFilter = 'Daily Needs');
                                    }),
                                    const Gap(6),
                                    _chip('Grains', _categoryFilter == 'Grains', () {
                                      setState(() => _categoryFilter = 'Grains');
                                    }),
                                    const Gap(6),
                                    _chip('Snacks', _categoryFilter == 'Snacks', () {
                                      setState(() => _categoryFilter = 'Snacks');
                                    }),
                                    const Gap(6),
                                    _chip('Beverages', _categoryFilter == 'Beverages', () {
                                      setState(() => _categoryFilter = 'Beverages');
                                    }),
                                  ],
                                ),
                              ),
                              const Gap(16),

                              // Section Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Products to Restock (${filtered.length})',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.darkText,
                                    ),
                                  ),
                                  const Text(
                                    'Tap for product details',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                              const Gap(10),
                            ],
                          ),
                        ),
                      ),

                      // Products List with Skeletons
                      if (AppDataRepository.instance.isLoading && filtered.isEmpty)
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: TransactionListSkeleton(itemCount: 4),
                          ),
                        )
                      else if (filtered.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Column(
                                children: [
                                  Icon(LucideIcons.packageCheck, size: 36, color: Color(0xFF10B981)),
                                  Gap(10),
                                  Text('No matching low stock items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                                  Gap(4),
                                  Text('All inventory items are well-stocked for selected filters', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const Gap(10),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildLowStockCard(item);
                            },
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12, bottom: 20),
                            child: AppBottomLoader(hasMore: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Restock Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _recordPurchaseOrder,
                    icon: const Icon(LucideIcons.truck, size: 18, color: Colors.white),
                    label: const Text(
                      'Record Bulk Purchase / Restock',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 11, color: color),
              ),
            ],
          ),
          const Gap(4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockCard(LowStockItemData item) {
    final colors = context.colors;
    final p = item.product;
    final isOut = item.isOutOfStock;
    final stockRatio = (p.stock / p.lowStockThreshold).clamp(0.0, 1.0);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              product: p,
              onProductUpdated: (updated) {
                setState(() => item.product = updated);
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Product Thumbnail, Details, and Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(imageUrl: p.imageUrl, size: 48),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: colors.darkText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOut ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOut ? 'OUT OF STOCK' : 'LOW STOCK',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(2),
                      Text(
                        '${p.category} • SKU: ${p.sku}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(12),

            // Stock Progress Bar & Deficit indicator
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Current Stock: ',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          Text(
                            p.formattedStock,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Threshold: ${p.lowStockThreshold.toInt()} ${p.stockUnit}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Gap(6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: stockRatio,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOut
                            ? const Color(0xFFDC2626)
                            : (stockRatio < 0.3 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B)),
                      ),
                    ),
                  ),
                  const Gap(6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Deficit: ${item.deficit.toInt()} ${p.stockUnit} needed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                      const Gap(8),
                      Flexible(
                        child: Text(
                          'Est. Restock: Rs. ${item.estimatedReorderCost.toInt()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(10),

            // Supplier Information & Quick Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.truck, size: 12, color: Color(0xFF64748B)),
                      const Gap(5),
                      Expanded(
                        child: Text(
                          item.supplierName,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Call Supplier shortcut
                    InkWell(
                      onTap: () => _callSupplier(item),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.phone, size: 11, color: Color(0xFF2563EB)),
                            Gap(4),
                            Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                    ),
                    const Gap(6),

                    // Set threshold shortcut
                    InkWell(
                      onTap: () => _openSetThreshold(item),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.sliders, size: 11, color: Color(0xFF475569)),
                            Gap(4),
                            Text('Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          ],
                        ),
                      ),
                    ),
                    const Gap(6),

                    // Adjust Stock / Quick Restock Button
                    InkWell(
                      onTap: () => _openAdjustStock(item),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.plus, size: 12, color: Colors.white),
                            Gap(4),
                            Text('Restock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

