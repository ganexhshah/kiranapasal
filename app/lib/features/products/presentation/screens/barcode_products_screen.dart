import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_lazy_image.dart';
import '../../domain/models/product.dart';
import '../sheets/multi_product_print_barcode_sheet.dart';

/// Screen to view inventory products, select items, adjust label copies, and batch print or export barcodes to PDF.
class BarcodeProductsScreen extends StatefulWidget {
  const BarcodeProductsScreen({super.key});

  @override
  State<BarcodeProductsScreen> createState() => _BarcodeProductsScreenState();
}

class _BarcodeProductsScreenState extends State<BarcodeProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  // Map of productId -> copies to print
  final Map<String, int> _selectedProductCopies = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    // Start with nothing selected: printing labels must be an explicit choice,
    // otherwise opening this screen silently queues up 16 labels.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    final query = _searchController.text.trim().toLowerCase();
    return products.where((p) {
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProductCopies.containsKey(productId)) {
        _selectedProductCopies.remove(productId);
      } else {
        _selectedProductCopies[productId] = 1;
      }
    });
  }

  void _incrementCopies(String productId) {
    setState(() {
      final current = _selectedProductCopies[productId] ?? 0;
      _selectedProductCopies[productId] = current + 1;
    });
  }

  void _decrementCopies(String productId) {
    setState(() {
      final current = _selectedProductCopies[productId] ?? 0;
      if (current <= 1) {
        _selectedProductCopies.remove(productId);
      } else {
        _selectedProductCopies[productId] = current - 1;
      }
    });
  }

  void _selectAll(List<Product> filtered) {
    setState(() {
      for (final p in filtered) {
        if (!_selectedProductCopies.containsKey(p.id)) {
          _selectedProductCopies[p.id] = 1;
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedProductCopies.clear();
    });
  }

  void _setCopiesToAll(int count) {
    setState(() {
      for (final key in _selectedProductCopies.keys.toList()) {
        _selectedProductCopies[key] = count;
      }
    });
  }

  void _openPrintSheet(List<Product> allProducts) {
    if (_selectedProductCopies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product to print barcodes'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final productMap = {for (var p in allProducts) p.id: p};
    final List<BarcodePrintItem> items = [];

    _selectedProductCopies.forEach((id, copies) {
      final prod = productMap[id];
      if (prod != null && copies > 0) {
        items.add(BarcodePrintItem(product: prod, copies: copies));
      }
    });

    if (items.isEmpty) return;

    MultiProductPrintBarcodeSheet.show(context, items: items);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final allProducts = AppDataRepository.instance.products;
        final filteredProducts = _getFilteredProducts(allProducts);
        final categories = AppDataRepository.instance.categories;

        final selectedCount = _selectedProductCopies.length;
        final totalLabelsCount = _selectedProductCopies.values.fold(0, (sum, c) => sum + c);
        final allFilteredSelected = filteredProducts.isNotEmpty &&
            filteredProducts.every((p) => _selectedProductCopies.containsKey(p.id));

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              toolbarHeight: 56.0,
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: colors.darkText, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Barcode Labels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.darkText,
                  letterSpacing: -0.3,
                ),
              ),
              centerTitle: false,
              actions: [
                TextButton(
                  onPressed: () {
                    if (allFilteredSelected) {
                      _deselectAll();
                    } else {
                      _selectAll(filteredProducts);
                    }
                  },
                  child: Text(
                    allFilteredSelected ? 'Deselect All' : 'Select All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Gap(8),
              ],
            ),
            body: Column(
              children: [
                // 1. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search products by name or code...',
                      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF64748B)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
                      ),
                    ),
                  ),
                ),

                // 2. Horizontal Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedCategory = cat);
                          },
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: AppColors.primary,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Gap(8),

                // 3. Selection Summary & Quick Multiplier
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFF8FAFC),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              size: 16,
                              color: selectedCount > 0 ? AppColors.primary : const Color(0xFF94A3B8),
                            ),
                            const Gap(6),
                            Flexible(
                              child: Text(
                                '$selectedCount Selected ($totalLabelsCount Labels)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: selectedCount > 0 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      if (selectedCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _setCopiesToAll(1),
                              child: const Text(
                                'Set 1',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                            const Gap(10),
                            GestureDetector(
                              onTap: () => _setCopiesToAll(5),
                              child: const Text(
                                'Set 5',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                            const Gap(10),
                            GestureDetector(
                              onTap: () => _setCopiesToAll(10),
                              child: const Text(
                                'Set 10',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // 4. Products List
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(LucideIcons.packageSearch, size: 48, color: Color(0xFFCBD5E1)),
                              Gap(12),
                              Text(
                                'No matching products found',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, _) => const Divider(
                            color: Color(0xFFF1F5F9),
                            height: 1,
                            indent: 56,
                          ),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isSelected = _selectedProductCopies.containsKey(product.id);
                            final copies = _selectedProductCopies[product.id] ?? 0;
                            final barcodeCode = product.sku.isNotEmpty ? product.sku : product.id;

                            return InkWell(
                              onTap: () => _toggleProductSelection(product.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    // Circular Selection Checkbox
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const Gap(12),

                                    // Thumbnail Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                          ? AppLazyImage(
                                              imageUrl: product.imageUrl!,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 44,
                                              height: 44,
                                              color: const Color(0xFFF1F5F9),
                                              child: const Icon(LucideIcons.package, size: 20, color: Color(0xFF94A3B8)),
                                            ),
                                    ),
                                    const Gap(12),

                                    // Product Info & Barcode
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Gap(2),
                                          Row(
                                            children: [
                                              Text(
                                                'Rs. ${product.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const Gap(8),
                                              Expanded(
                                                child: Text(
                                                  'Code: $barcodeCode',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Gap(4),
                                          // Mini Barcode visualization
                                          BarcodeWidget(
                                            barcode: Barcode.code128(),
                                            data: barcodeCode,
                                            width: 90,
                                            height: 18,
                                            drawText: false,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity Stepper (Copies)
                                    if (isSelected)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(LucideIcons.minusCircle, size: 20, color: Color(0xFF64748B)),
                                            splashRadius: 18,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: () => _decrementCopies(product.id),
                                          ),
                                          Container(
                                            constraints: const BoxConstraints(minWidth: 24),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$copies',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(LucideIcons.plusCircle, size: 20, color: AppColors.primary),
                                            splashRadius: 18,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: () => _incrementCopies(product.id),
                                          ),
                                        ],
                                      )
                                    else
                                      TextButton(
                                        onPressed: () => _toggleProductSelection(product.id),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          '+ Add',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 5. Bottom Pinned Print Action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: Colors.white,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedCount > 0 ? () => _openPrintSheet(allProducts) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          disabledForegroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.printer, size: 18, color: Colors.white),
                            const Gap(8),
                            Text(
                              selectedCount > 0
                                  ? 'Print Barcodes ($totalLabelsCount Total)'
                                  : 'Select Products to Print',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

