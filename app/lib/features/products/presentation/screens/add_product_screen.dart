import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_lazy_image.dart';
import '../../domain/models/product.dart';
import '../sheets/barcode_scanner_sheet.dart';
import '../sheets/category_picker_sheet.dart';
import '../sheets/date_picker_sheet.dart';
import '../sheets/image_source_picker_sheet.dart';

/// Clean, seamless, boxless screen to quickly add or edit store products.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    this.initialProduct,
  });

  final Product? initialProduct;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _stockController;

  // Optional Controllers
  late final TextEditingController _lowStockThresholdController;
  late final TextEditingController _conversionUnitController;
  late final TextEditingController _descriptionController;

  // State
  String? _selectedCategory;
  String _selectedUnit = 'pcs';
  String? _imageUrl;
  DateTime? _expiryDate;
  bool _enableLowStockAlert = true;
  bool _isSaving = false;
  bool _isAdvancedExpanded = false;
  late final String _initialSnapshot;

  final List<String> _quickCategories = const [
    'Grains',
    'Oils',
    'Pulses',
    'Spices',
    'Dairy',
    'Snacks',
    'Beverages',
    'Personal Care',
    'Cleaning',
  ];

  final List<String> _stockUnits = const [
    'pcs',
    'pkt',
    'kg',
    'ltr',
    'box',
    'bag',
    'bottle',
    'bundle',
    'gm',
    'ml',
    'can',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;

    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p != null ? (p.barcode.isNotEmpty ? p.barcode : p.sku) : '');
    _sellingPriceController = TextEditingController(
      text: p != null && p.price > 0 ? (p.price == p.price.roundToDouble() ? p.price.toInt().toString() : p.price.toString()) : '',
    );
    _purchasePriceController = TextEditingController(
      text: p != null && p.purchasePrice > 0 ? (p.purchasePrice == p.purchasePrice.roundToDouble() ? p.purchasePrice.toInt().toString() : p.purchasePrice.toString()) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? (p.stock == p.stock.roundToDouble() ? p.stock.toInt().toString() : p.stock.toString()) : '1',
    );

    _lowStockThresholdController = TextEditingController(
      text: p != null ? p.lowStockThreshold.toInt().toString() : '5',
    );
    _conversionUnitController = TextEditingController(text: p?.purchaseUnit ?? 'Sack');
    _descriptionController = TextEditingController(text: p?.description ?? '');

    _selectedCategory = p?.category ?? 'Grains';
    _selectedUnit = p?.stockUnit ?? 'pcs';
    if (!_stockUnits.contains(_selectedUnit)) {
      _selectedUnit = 'pcs';
    }
    _imageUrl = p?.imageUrl;
    _expiryDate = p?.expiryDate;
    _enableLowStockAlert = p?.enableLowStockAlert ?? true;

    _sellingPriceController.addListener(_onPriceChanged);
    _purchasePriceController.addListener(_onPriceChanged);

    // Baseline for "did the user type anything", so backing out of an untouched
    // edit form does not nag, but a half-filled form is never thrown away.
    _initialSnapshot = _snapshot();
  }

  String _snapshot() => [
        _nameController.text,
        _barcodeController.text,
        _sellingPriceController.text,
        _purchasePriceController.text,
        _stockController.text,
        _descriptionController.text,
        _expiryDate?.toIso8601String() ?? '',
        _selectedCategory,
        _selectedUnit,
      ].join('|');

  bool get _hasUnsavedInput => _snapshot() != _initialSnapshot;

  Future<void> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard product?'),
        content: const Text('Your changes will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _onPriceChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _sellingPriceController.removeListener(_onPriceChanged);
    _purchasePriceController.removeListener(_onPriceChanged);
    _nameController.dispose();
    _barcodeController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _lowStockThresholdController.dispose();
    _conversionUnitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _generateBarcode() {
    final prefix = _selectedCategory != null && _selectedCategory!.length >= 3
        ? _selectedCategory!.substring(0, 3).toUpperCase()
        : 'PRD';
    final randomNum = 1000 + (DateTime.now().millisecond % 9000);
    setState(() {
      _barcodeController.text = '$prefix$randomNum';
    });
  }

  Future<void> _scanBarcode() async {
    final scanned = await BarcodeScannerSheet.show(context);
    if (scanned != null && scanned.trim().isNotEmpty && mounted) {
      setState(() {
        _barcodeController.text = scanned.trim();
      });
    }
  }

  Future<void> _pickImage() async {
    final selectedImage = await ImageSourcePickerSheet.show(
      context,
      currentImageUrl: _imageUrl,
      title: 'Choose Product Photo',
    );
    if (selectedImage != null && mounted) {
      setState(() {
        _imageUrl = selectedImage.isEmpty ? null : selectedImage;
      });
    }
  }

  Future<void> _pickCategoryMore() async {
    final selected = await CategoryPickerSheet.show(
      context,
      selectedCategory: _selectedCategory,
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final selected = await DatePickerSheet.show(
      context,
      initialDate: _expiryDate,
    );
    // A null result means the sheet was dismissed; never wipe an existing date.
    if (selected != null && mounted) {
      setState(() => _expiryDate = selected);
    }
  }

  Future<void> _saveProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showToast('Please enter a product name', isError: true);
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      _showToast('Please select a category', isError: true);
      return;
    }

    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    if (sellingPrice <= 0) {
      _showToast('Please enter a valid selling price', isError: true);
      return;
    }

    final stock = double.tryParse(_stockController.text.trim()) ?? 0.0;
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final lowStockThreshold = double.tryParse(_lowStockThresholdController.text.trim()) ?? 5.0;
    final barcode = _barcodeController.text.trim().isNotEmpty
        ? _barcodeController.text.trim()
        : 'PRD${DateTime.now().millisecondsSinceEpoch % 100000}';

    setState(() => _isSaving = true);

    try {
      final isEdit = widget.initialProduct != null;
      final productId = widget.initialProduct?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      double profitPercent = 0.0;
      if (purchasePrice > 0) {
        profitPercent = ((sellingPrice - purchasePrice) / purchasePrice) * 100;
      }

      final product = Product(
        id: productId,
        name: name,
        category: _selectedCategory!,
        sku: barcode,
        barcode: barcode,
        description: _descriptionController.text.trim(),
        price: sellingPrice,
        priceUnit: _selectedUnit,
        purchasePrice: purchasePrice,
        purchaseUnit: _conversionUnitController.text.trim().isNotEmpty ? _conversionUnitController.text.trim() : 'Sack',
        stock: stock,
        stockUnit: _selectedUnit,
        lowStockThreshold: lowStockThreshold,
        enableLowStockAlert: _enableLowStockAlert,
        expiryDate: _expiryDate,
        imageUrl: _imageUrl,
        profitMarginPercent: profitPercent > 0 ? profitPercent : 25.0,
      );

      final success = isEdit
          ? await AppDataRepository.instance.updateProduct(product)
          : await AppDataRepository.instance.addProduct(product);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          _showToast(isEdit ? '$name updated!' : '$name added successfully!');
          Navigator.of(context).pop(product);
        } else {
          _showToast(
            AppDataRepository.instance.lastError ?? 'Failed to save product on server',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast('Failed to save product: $e', isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEdit = widget.initialProduct != null;

    final selling = double.tryParse(_sellingPriceController.text.trim());
    final purchase = double.tryParse(_purchasePriceController.text.trim());
    final hasProfitInfo = selling != null && selling > 0 && purchase != null && purchase > 0;
    final profitVal = hasProfitInfo ? (selling - purchase) : 0.0;
    final profitPercent = (hasProfitInfo && purchase > 0) ? (profitVal / purchase * 100) : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: !_hasUnsavedInput,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _confirmDiscard();
        },
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
            isEdit ? 'Edit Product' : 'Add Product',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.darkText,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Clean Circular Avatar with Camera Button (Matches Profile Screen)
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                InkWell(
                                  onTap: _pickImage,
                                  borderRadius: BorderRadius.circular(44),
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: _imageUrl != null && _imageUrl!.isNotEmpty
                                        ? AppLazyImage(
                                            imageUrl: _imageUrl!,
                                            width: 88,
                                            height: 88,
                                            isCircle: true,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            LucideIcons.package,
                                            size: 34,
                                            color: Color(0xFF94A3B8),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _pickImage,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Text(
                                _imageUrl != null ? 'Change photo' : 'Add photo',
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
                      const Gap(22),

                      // 2. Product Name
                      _buildFieldLabel('Product Name *'),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                        decoration: _inputDecoration(
                          hint: 'e.g. Basmati Rice, Sunflower Oil, Soap',
                          prefixIcon: LucideIcons.shoppingBag,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a product name';
                          }
                          return null;
                        },
                      ),
                      const Gap(18),

                      // 3. Category (Smooth Lineless Chips)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel('Category *'),
                          GestureDetector(
                            onTap: _pickCategoryMore,
                            child: const Text(
                              'View all >',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _quickCategories.map((cat) {
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Gap(18),

                      // 4. Selling & Cost Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Selling Price *'),
                                TextFormField(
                                  controller: _sellingPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                                  decoration: _inputDecoration(
                                    hint: '0.00',
                                    prefixText: 'Rs. ',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final numVal = double.tryParse(val.trim());
                                    if (numVal == null || numVal <= 0) {
                                      return 'Invalid price';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Cost Price'),
                                TextFormField(
                                  controller: _purchasePriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                                  decoration: _inputDecoration(
                                    hint: '0.00',
                                    prefixText: 'Rs. ',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Clean inline profit margin info (Zero box borders)
                      if (hasProfitInfo) ...[
                        const Gap(6),
                        Row(
                          children: [
                            Icon(
                              profitVal >= 0 ? LucideIcons.trendingUp : LucideIcons.alertTriangle,
                              size: 14,
                              color: profitVal >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                            const Gap(6),
                            Text(
                              profitVal >= 0
                                  ? 'Estimated profit: Rs. ${profitVal.toStringAsFixed(2)} (${profitPercent.toStringAsFixed(1)}% margin)'
                                  : 'Warning: Selling below cost price (-Rs. ${(-profitVal).toStringAsFixed(2)})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: profitVal >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Gap(18),

                      // 5. Stock Quantity & Unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Available Stock *'),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                                  decoration: _inputDecoration(
                                    hint: '10',
                                    prefixIcon: LucideIcons.layers,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Gap(14),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Unit'),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _stockUnits.contains(_selectedUnit) ? _selectedUnit : _stockUnits.first,
                                      isExpanded: true,
                                      icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                      items: _stockUnits.map((u) {
                                        return DropdownMenuItem<String>(
                                          value: u,
                                          child: Text(u),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedUnit = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(18),

                      // 6. Barcode / SKU
                      _buildFieldLabel('Barcode / SKU (Optional)'),
                      TextFormField(
                        controller: _barcodeController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Scan or generate barcode',
                          prefixIcon: LucideIcons.scanLine,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.sparkles, size: 18, color: AppColors.primary),
                                tooltip: 'Auto Generate',
                                splashRadius: 18,
                                onPressed: _generateBarcode,
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.camera, size: 18, color: Color(0xFF64748B)),
                                tooltip: 'Scan Barcode',
                                splashRadius: 18,
                                onPressed: _scanBarcode,
                              ),
                              const Gap(4),
                            ],
                          ),
                        ),
                      ),
                      const Gap(22),

                      // 7. More Options Accordion (Clean, zero borders/boxes)
                      InkWell(
                        onTap: () => setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                _isAdvancedExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const Gap(6),
                              Text(
                                'More Options (Expiry, Alert & Notes)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_isAdvancedExpanded) ...[
                        const Gap(14),

                        // Expiry Date
                        _buildFieldLabel('Expiry Date'),
                        InkWell(
                          onTap: _pickExpiryDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF64748B)),
                                const Gap(10),
                                Text(
                                  _expiryDate != null
                                      ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                                      : 'Select expiry date',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: _expiryDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                    fontWeight: _expiryDate != null ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                const Spacer(),
                                if (_expiryDate != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _expiryDate = null),
                                    child: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
                                  )
                                else
                                  const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ),
                        const Gap(16),

                        // Low Stock Alert
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Low Stock Alert',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'Notify when stock runs below threshold',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _enableLowStockAlert,
                              activeTrackColor: AppColors.primary,
                              activeThumbColor: Colors.white,
                              onChanged: (val) => setState(() => _enableLowStockAlert = val),
                            ),
                          ],
                        ),
                        if (_enableLowStockAlert) ...[
                          const Gap(8),
                          _buildFieldLabel('Alert Threshold (Quantity)'),
                          TextFormField(
                            controller: _lowStockThresholdController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 14),
                            decoration: _inputDecoration(
                              hint: '5',
                              prefixIcon: LucideIcons.alertCircle,
                            ),
                          ),
                        ],
                        const Gap(16),

                        // Description / Notes
                        _buildFieldLabel('Notes / Description'),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 14),
                          decoration: _inputDecoration(
                            hint: 'Any notes, rack location, or details...',
                          ),
                        ),
                      ],
                      const Gap(24),
                    ],
                  ),
                ),
              ),

              // 8. Pinned Bottom Action Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: AppColors.primary.withAlpha(120),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEdit ? LucideIcons.check : LucideIcons.plusCircle,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const Gap(8),
                                Text(
                                  isEdit ? 'Update Product' : 'Save Product',
                                  style: const TextStyle(
                                    fontSize: 15.5,
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
      ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B))
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
