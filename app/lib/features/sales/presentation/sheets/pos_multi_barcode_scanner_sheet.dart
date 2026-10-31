import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../products/presentation/widgets/product_thumbnail.dart';
import '../../domain/models/cart_item.dart';
import 'checkout_sheet.dart';

/// Clean Kirana POS Continuous Barcode Scanner with:
/// - Native app theme (no neon styling)
/// - Always-on multi-item scanning
/// - Duplicate scan protection (warns cashier before adding duplicate items)
/// - Direct "Checkout" action straight from the scanner
class POSMultiBarcodeScannerSheet extends StatefulWidget {
  const POSMultiBarcodeScannerSheet({
    super.key,
    this.initialCart = const [],
  });

  final List<CartItem> initialCart;

  static Future<List<CartItem>?> show(
    BuildContext context, {
    List<CartItem> initialCart = const [],
  }) {
    return showModalBottomSheet<List<CartItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => POSMultiBarcodeScannerSheet(
        initialCart: initialCart,
      ),
    );
  }

  @override
  State<POSMultiBarcodeScannerSheet> createState() =>
      _POSMultiBarcodeScannerSheetState();
}

class _POSMultiBarcodeScannerSheetState
    extends State<POSMultiBarcodeScannerSheet> {
  final _manualController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late List<CartItem> _cartItems;
  bool _isTorchOn = false;
  bool _isPromptOpen = false;

  String? _lastScannedBarcode;
  DateTime? _lastScanTime;

  Product? _recentScannedProduct;
  String? _unfoundBarcode;

  @override
  void initState() {
    super.initState();
    _cartItems = List<CartItem>.from(widget.initialCart);
  }

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _cartItems.fold<double>(0.0, (sum, it) => sum + it.totalPrice);

  int get _totalUnitsCount =>
      _cartItems.fold<int>(0, (sum, it) => sum + it.quantity.toInt());

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(1);
  }

  // --- Real-Time Scan Processor with Duplicate Warning ---
  Future<void> _handleBarcode(String rawCode) async {
    if (_isPromptOpen) return;
    final cleanCode = rawCode.trim();
    if (cleanCode.isEmpty) return;

    final now = DateTime.now();
    // Guard against rapid duplicate sensor firing on same frame (< 1000ms)
    if (_lastScannedBarcode == cleanCode && _lastScanTime != null) {
      final diff = now.difference(_lastScanTime!).inMilliseconds;
      if (diff < 1000) return;
    }

    _lastScannedBarcode = cleanCode;
    _lastScanTime = now;

    // 1. Audio & Haptic Feedback
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);

    // 2. Lookup Product
    final product =
        await AppDataRepository.instance.findProductByBarcode(cleanCode);

    if (!mounted) return;

    if (product != null) {
      final existingIndex = _cartItems.indexWhere(
        (it) => it.product.id == product.id && it.unit == product.priceUnit,
      );

      // If the product is ALREADY in the basket, warn the cashier before adding!
      if (existingIndex >= 0) {
        final existingItem = _cartItems[existingIndex];
        _showDuplicateWarning(product, existingItem, existingIndex);
      } else {
        // First time scanned: add directly to basket
        setState(() {
          final newItem = CartItem(
            product: product,
            unit: product.priceUnit,
            quantity: 1.0,
            unitPrice: product.price,
          );
          _cartItems.insert(0, newItem);
          _recentScannedProduct = product;
          _unfoundBarcode = null;
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _unfoundBarcode = cleanCode;
        _recentScannedProduct = null;
      });
    }
  }

  // --- Duplicate Warning Sheet ---
  Future<void> _showDuplicateWarning(
    Product product,
    CartItem existingItem,
    int index,
  ) async {
    _isPromptOpen = true;
    HapticFeedback.heavyImpact();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(14),
                // Warning icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.triangleAlert,
                        size: 22,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Already Scanned',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Current quantity: ${_formatQty(existingItem.quantity)} ${existingItem.unit}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                // Product preview card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      ProductThumbnail(
                        imageUrl: product.imageUrl,
                        category: product.category,
                        size: 40,
                        borderRadius: 8,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(2),
                            Text(
                              'Rs. ${product.price.toStringAsFixed(2)} / ${product.priceUnit}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Qty: ${_formatQty(existingItem.quantity)}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0866FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(18),
                // Actions: Add Another vs Cancel
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Skip / Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            final updated = existingItem.copyWith(
                              quantity: existingItem.quantity + 1.0,
                            );
                            _cartItems[index] = updated;
                            if (index != 0) {
                              final moved = _cartItems.removeAt(index);
                              _cartItems.insert(0, moved);
                            }
                            _recentScannedProduct = product;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0866FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add Another (+1)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    _isPromptOpen = false;
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.trim().isNotEmpty) {
      _handleBarcode(barcode);
    }
  }

  void _submitManual() {
    final code = _manualController.text.trim();
    if (code.isNotEmpty) {
      _manualController.clear();
      _handleBarcode(code);
    }
  }

  void _updateQuantity(int index, double delta) {
    setState(() {
      final item = _cartItems[index];
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = item.copyWith(quantity: newQty);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _recentScannedProduct = null;
      _unfoundBarcode = null;
    });
  }

  // --- Direct Checkout Action ---
  Future<void> _proceedDirectToCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one product before checkout'),
        ),
      );
      return;
    }

    final allProducts = AppDataRepository.instance.products;
    final completed = await CheckoutSheet.show(
      context,
      items: _cartItems,
      allProducts: allProducts,
    );

    if (completed == true && mounted) {
      // Completed sale: return empty list to clear POS screen
      Navigator.pop(context, const <CartItem>[]);
    }
  }

  Future<void> _openAddProductWithBarcode(String barcode) async {
    final newProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
    if (newProduct != null && mounted) {
      _handleBarcode(
        newProduct.barcode.isNotEmpty ? newProduct.barcode : newProduct.sku,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context, _cartItems),
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        tooltip: 'Back',
                      ),
                      const Gap(4),
                      Text(
                        'Barcode Scanner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.darkText,
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0866FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_totalUnitsCount in basket',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0866FF),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Flashlight Button
                      IconButton(
                        onPressed: () async {
                          await _scannerController.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                        icon: Icon(
                          _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                          size: 19,
                          color: _isTorchOn
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF64748B),
                        ),
                        tooltip: 'Flashlight',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Camera Viewfinder (Theme styled, non-neon)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return const Center(
                          child: Text(
                            'Camera unavailable. Use manual entry below.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        );
                      },
                    ),

                    // Clean Viewfinder Reticle
                    Container(
                      width: 180,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF0866FF),
                          width: 1.8,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // Recent scan confirmation badge
                    if (_recentScannedProduct != null)
                      Positioned(
                        bottom: 8,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF065F46),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.check, size: 14, color: Colors.white),
                              const Gap(6),
                              Expanded(
                                child: Text(
                                  'Added: ${_recentScannedProduct!.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs. ${_recentScannedProduct!.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_unfoundBarcode != null)
                      Positioned(
                        bottom: 8,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF78350F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.circleAlert, size: 14, color: Color(0xFFFBBF24)),
                              const Gap(6),
                              Expanded(
                                child: Text(
                                  'Barcode "$_unfoundBarcode" not found',
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () => _openAddProductWithBarcode(_unfoundBarcode!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Add Item',
                                    style: TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const Gap(8),

            // 3. Clean Manual Entry
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _manualController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitManual(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Enter barcode or SKU...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: colors.inputLabel.withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(LucideIcons.barcode, size: 16, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF0866FF), width: 1.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _submitManual,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0866FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(8),

            // 4. Basket List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scanned Items (${_cartItems.length})',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.darkText,
                    ),
                  ),
                  if (_cartItems.isNotEmpty)
                    InkWell(
                      onTap: _clearCart,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(6),

            // 5. Scanned Items List
            Expanded(
              child: _cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.packageOpen, size: 28, color: colors.inputBorder),
                          const Gap(6),
                          Text(
                            'No items scanned yet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.inputLabel,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      itemCount: _cartItems.length,
                      separatorBuilder: (_, _) => const Gap(6),
                      itemBuilder: (ctx, index) {
                        final item = _cartItems[index];

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              ProductThumbnail(
                                imageUrl: item.product.imageUrl,
                                category: item.product.category,
                                size: 36,
                                borderRadius: 6,
                              ),
                              const Gap(10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colors.darkText,
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${item.unitPrice.toStringAsFixed(2)} / ${item.unit}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.inputLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _updateQuantity(index, -1.0),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        child: Icon(LucideIcons.minus, size: 13, color: Color(0xFF475569)),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        _formatQty(item.quantity),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: colors.darkText,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _updateQuantity(index, 1.0),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        child: Icon(LucideIcons.plus, size: 13, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(10),
                              // Total & Delete
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0866FF),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _removeItem(index),
                                    child: const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(LucideIcons.trash2, size: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 6. Direct Checkout Bottom Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_totalUnitsCount Items',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.inputLabel,
                          ),
                        ),
                        Text(
                          'Rs. ${_totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: colors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  // Secondary: Return to Cart
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, _cartItems),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Cart',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  const Gap(8),
                  // Primary: Direct Checkout
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      onPressed: _cartItems.isEmpty ? null : _proceedDirectToCheckout,
                      icon: const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                      label: const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0866FF),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
