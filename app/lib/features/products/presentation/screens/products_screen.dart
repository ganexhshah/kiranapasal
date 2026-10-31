import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../dashboard/dashboard.dart';
import '../../../more/more.dart';
import '../../../parties/parties.dart';
import '../../../sales/presentation/screens/sales_screen.dart';
import '../../domain/models/product.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/inventory_summary_cards.dart';
import '../widgets/product_list_item.dart';
import '../widgets/product_search_bar.dart';
import '../widgets/products_header.dart';
import '../widgets/products_list_header.dart';
import 'add_product_screen.dart';
import 'barcode_products_screen.dart';
import 'low_stock_screen.dart';
import 'product_details_screen.dart';
import '../sheets/adjust_stock_sheet.dart';
import '../sheets/barcode_scanner_sheet.dart';
import '../sheets/delete_confirmation_sheet.dart';
import '../sheets/print_barcode_sheet.dart';

/// Complete Products screen connected directly to real inventory data and backend repository.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  int _navIndex = 1; // Products tab is index 1

  List<String> get _categories => AppDataRepository.instance.categories;
  List<Product> get _allProducts => AppDataRepository.instance.products;

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

  void _onSearchChanged(String val) {
    setState(() {});
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    final selectedCat = _selectedCategory.toLowerCase();
    final isAll = _selectedCategory == 'All';

    return _allProducts.where((p) {
      if (!isAll && p.category.toLowerCase() != selectedCat) {
        return false;
      }
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showAddProductDialog() async {
    final newProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (newProduct != null && mounted) {
      setState(() {
        _searchController.clear();
        _selectedCategory = 'All';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newProduct.name} added successfully!'),
          backgroundColor: const Color(0xFF10B981),
          action: SnackBarAction(
            label: 'Print Barcode',
            textColor: Colors.white,
            onPressed: () {
              PrintBarcodeSheet.show(context, product: newProduct);
            },
          ),
        ),
      );
    }
  }

  void _openBarcodeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BarcodeProductsScreen()),
    );
  }

  void _showSettingsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product Settings tapped'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SalesScreen()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PartiesScreen()),
      );
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MoreScreen()),
      );
    } else {
      setState(() => _navIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final products = _filteredProducts;

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
            body: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // 1. Pinned Header (Standardized 56px height, consistent status notch gap)
                    Container(
                      height: 56.0,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: ProductsHeader(
                        title: 'Products',
                        onBarcodeTap: _openBarcodeScreen,
                        onAddTap: _showAddProductDialog,
                        onSettingsTap: _showSettingsDialog,
                      ),
                    ),

                    // 2. Scrollable Body with Drag-to-Refresh & Sliver Virtualization
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: RefreshIndicator(
                          color: const Color(0xFF0066FF),
                          backgroundColor: Colors.white,
                          onRefresh: () async {
                            await AppDataRepository.instance.refreshAll(force: true);
                          },
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Search Bar with Barcode Scanner Icon
                                      ProductSearchBar(
                                        controller: _searchController,
                                        onChanged: _onSearchChanged,
                                        onScanBarcodeTap: () async {
                                          final barcode = await BarcodeScannerSheet.show(context);
                                          if (barcode != null && barcode.isNotEmpty && mounted) {
                                            setState(() {
                                              _searchController.text = barcode;
                                            });
                                          }
                                        },
                                      ),
                                      const Gap(14),

                                      // Horizontal Category Filter Chips
                                      CategoryFilterChips(
                                        categories: _categories,
                                        selectedCategory: _selectedCategory,
                                        onCategorySelected: (cat) {
                                          setState(() => _selectedCategory = cat);
                                        },
                                      ),
                                      const Gap(10),

                                      // Inventory Summary 2-Card Row (Total Products & Low Stock Items)
                                      InventorySummaryCards(
                                        totalProducts: '${_allProducts.length}',
                                        lowStockItems:
                                            '${AppDataRepository.instance.lowStockProducts.length}',
                                        onTotalProductsTap: () {
                                          setState(() => _selectedCategory = 'All');
                                        },
                                        onLowStockItemsTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LowStockScreen()),
                                          );
                                        },
                                      ),
                                      const Gap(12),

                                      // Products Table Column Headers
                                      const ProductsListHeader(),
                                      const Gap(6),
                                    ],
                                  ),
                                ),
                              ),

                              // Products List, Skeleton, or Empty State
                              if (AppDataRepository.instance.isLoading && _allProducts.isEmpty)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => const Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: ShimmerBlock(height: 60, borderRadius: 12),
                                      ),
                                      childCount: 6,
                                    ),
                                  ),
                                )
                              else if (AppDataRepository.instance.lastError != null &&
                                  _allProducts.isEmpty)
                                SliverPadding(
                                  padding: const EdgeInsets.only(top: 40),
                                  sliver: SliverToBoxAdapter(
                                    child: AppErrorState(
                                      onRetry: () => AppDataRepository.instance
                                          .refreshAll(force: true),
                                    ),
                                  ),
                                )
                              else if (products.isEmpty)
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                                  sliver: SliverToBoxAdapter(
                                    child: AppEmptyState(
                                      icon: LucideIcons.packageOpen,
                                      title: _searchController.text.trim().isNotEmpty || _selectedCategory != 'All'
                                          ? 'No products found'
                                          : 'No products yet',
                                      description: _searchController.text.trim().isNotEmpty || _selectedCategory != 'All'
                                          ? 'Try a different search term or category.'
                                          : 'Add your first product to start selling.',
                                      actionLabel: _searchController.text.trim().isNotEmpty || _selectedCategory != 'All'
                                          ? 'Clear Filters'
                                          : 'Add Product',
                                      onActionTap: () {
                                        if (_searchController.text.trim().isNotEmpty || _selectedCategory != 'All') {
                                          setState(() {
                                            _searchController.clear();
                                            _selectedCategory = 'All';
                                          });
                                        } else {
                                          _showAddProductDialog();
                                        }
                                      },
                                    ),
                                  ),
                                )
                              else ...[
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                                  sliver: SliverList.separated(
                                    itemCount: products.length,
                                    separatorBuilder: (context, index) =>
                                        const Gap(6),
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return ProductListItem(
                                        product: product,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductDetailsScreen(
                                                product: product,
                                                onProductUpdated: (updated) {
                                                  AppDataRepository.instance
                                                      .updateProduct(updated);
                                                },
                                                onProductDeleted: () {
                                                  AppDataRepository.instance
                                                      .deleteProduct(product.id);
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                        onEdit: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AddProductScreen(
                                                  initialProduct: product),
                                            ),
                                          );
                                        },
                                        onDelete: () async {
                                          final confirmed =
                                              await DeleteConfirmationSheet.show(
                                            context,
                                            product: product,
                                          );
                                          if (confirmed == true && mounted) {
                                            await AppDataRepository.instance
                                                .deleteProduct(product.id);
                                          }
                                        },
                                        onUpdateStock: () async {
                                          final result =
                                              await AdjustStockSheet.show(
                                            context,
                                            product: product,
                                          );
                                          if (result != null && mounted) {
                                            final diff =
                                                result.newStock - product.stock;
                                            await AppDataRepository.instance
                                                .adjustStock(
                                              productId: product.id,
                                              isAddition: diff > 0,
                                              quantity: diff.abs(),
                                              unit: product.stockUnit,
                                              reason: result.reason,
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: AppBottomLoader(hasMore: false),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: DashboardBottomNav(
              currentIndex: _navIndex,
              onTap: _onBottomNavTap,
            ),
          ),
        );
      },
    );
  }
}
