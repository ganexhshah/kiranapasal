import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../../../more/more.dart';
import '../../../parties/parties.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../products/presentation/widgets/category_filter_chips.dart';
import '../../../products/presentation/widgets/product_search_bar.dart';
import '../../domain/models/cart_item.dart';
import '../sheets/add_sale_note_sheet.dart';
import '../sheets/add_to_sale_sheet.dart';
import '../sheets/apply_discount_sheet.dart';
import '../sheets/checkout_sheet.dart';
import '../sheets/clear_cart_confirmation_sheet.dart';
import '../sheets/pos_actions_sheet.dart';
import '../sheets/pos_multi_barcode_scanner_sheet.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/pos_header.dart';
import '../widgets/pos_product_card.dart';

/// Complete POS / New Sale screen connected directly to real inventory data and backend repository.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final int _navIndex = 2; // Sales tab is active (index 2)
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _categories => AppDataRepository.instance.categories;
  List<Product> get _allProducts => AppDataRepository.instance.products;
  final List<CartItem> _cartItems = [];
  double _posDiscount = 0;
  String _posNote = '';

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

  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    final cat = _selectedCategory.toLowerCase();
    final isAll = _selectedCategory == 'All';

    return _allProducts.where((p) {
      if (!isAll && p.category.toLowerCase() != cat) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openBarcodeScanner() async {
    final updatedCart = await POSMultiBarcodeScannerSheet.show(
      context,
      initialCart: _cartItems,
    );
    if (updatedCart != null && mounted) {
      setState(() {
        _cartItems.clear();
        _cartItems.addAll(updatedCart);
      });
      if (_cartItems.isNotEmpty) {
        final totalUnits = _cartItems.fold<int>(0, (sum, it) => sum + it.quantity.toInt());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart updated: $totalUnits items in sale'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openPOSActions() async {
    final action = await POSActionsSheet.show(context);
    if (action == null || !mounted) return;

    switch (action) {
      case POSActionType.scanBarcode:
        _openBarcodeScanner();
        break;
      case POSActionType.applyDiscount:
        final subtotal =
            _cartItems.fold<double>(0, (sum, it) => sum + it.totalPrice);
        if (subtotal <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add items to the cart before applying a discount')),
          );
          break;
        }
        final discount = await ApplyDiscountSheet.show(context, subtotal: subtotal);
        if (discount == null || !mounted) break;
        setState(() => _posDiscount = discount.calculatedAmount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Discount of Rs. ${formatAmount(discount.calculatedAmount)} will be applied at checkout',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        break;
      case POSActionType.addNote:
        final note = await AddSaleNoteSheet.show(context);
        if (note == null || !mounted) break;
        setState(() => _posNote = note);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(note.isEmpty ? 'Sale note cleared' : 'Sale note saved for this bill'),
          ),
        );
        break;
      case POSActionType.clearCart:
        _confirmClearCart();
        break;
    }
  }

  Future<void> _confirmClearCart() async {
    if (_cartItems.isEmpty) return;
    final confirmed = await ClearCartConfirmationSheet.show(
      context,
      itemCount: _cartItems.length,
    );
    if (confirmed && mounted) {
      setState(() => _cartItems.clear());
    }
  }

  Future<void> _openAddToSaleSheet(Product product) async {
    final item = await AddToSaleSheet.show(context, product: product);
    if (item != null && mounted) {
      setState(() {
        final existingIndex = _cartItems.indexWhere(
          (it) => it.product.id == item.product.id && it.unit == item.unit,
        );
        if (existingIndex >= 0) {
          final existing = _cartItems[existingIndex];
          _cartItems[existingIndex] = existing.copyWith(
            quantity: existing.quantity + item.quantity,
          );
        } else {
          _cartItems.add(item);
        }
      });
    }
  }

  Future<void> _openCheckout() async {
    if (_cartItems.isEmpty) return;
    final completed = await CheckoutSheet.show(
      context,
      items: _cartItems,
      allProducts: _allProducts,
      initialDiscount: _posDiscount,
      initialNote: _posNote,
    );
    if (completed == true && mounted) {
      setState(() {
        _cartItems.clear();
        _posDiscount = 0;
        _posNote = '';
      });
    } else if (mounted) {
      setState(() {});
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
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: PopScope(
              canPop: _cartItems.isEmpty,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                final navigator = Navigator.of(context);
                final leave = await ClearCartConfirmationSheet.show(
                  context,
                  itemCount: _cartItems.length,
                );
                if (!mounted) return;
                if (leave) navigator.pop();
              },
              child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 1. Top Bar Header
                  POSHeader(
                    onScanTap: _openBarcodeScanner,
                    onActionsTap: _openPOSActions,
                  ),

                  // 2. Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ProductSearchBar(
                      controller: _searchController,
                      hintText: 'Search product name, SKU or scan barcode...',
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      onScanBarcodeTap: _openBarcodeScanner,
                    ),
                  ),
                  const Gap(10),

                  // 3. Category Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CategoryFilterChips(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                  const Gap(12),

                  // 4. Products Grid with Pull-to-Refresh & Shimmer Skeletons
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF0066FF),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await AppDataRepository.instance.refreshAll();
                      },
                      child: AppDataRepository.instance.isLoading && products.isEmpty
                          ? const SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(16, 2, 16, 16),
                              child: ProductGridSkeleton(
                                itemCount: 6,
                                crossAxisCount: 3,
                                childAspectRatio: 0.68,
                              ),
                            )
                          : products.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const Gap(80),
                                    Center(
                                      child: Text(
                                        _searchQuery.isNotEmpty ||
                                                _selectedCategory != 'All'
                                            ? 'No products match this search or category'
                                            : 'No products in inventory yet',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.colors.inputLabel,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.68,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder: (ctx, index) {
                                    final product = products[index];
                                    return POSProductCard(
                                      product: product,
                                      onAddToCart: () => _openAddToSaleSheet(product),
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ),
              ),
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CartBottomBar(
                  items: _cartItems,
                  onCheckout: _openCheckout,
                  onClearCart: _confirmClearCart,
                ),
                DashboardBottomNav(
                  currentIndex: _navIndex,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pop(context);
                    } else if (index == 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => const ProductsScreen()),
                      );
                    } else if (index == 3) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => const PartiesScreen()),
                      );
                    } else if (index == 4) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => const MoreScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
