import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/product.dart';
import 'category_picker_sheet.dart';

/// Modal bottom sheet for quick editing basic product information, with a link to the full Edit screen.
class EditProductSheet extends StatefulWidget {
  const EditProductSheet({
    super.key,
    required this.product,
    this.onOpenFullScreen,
  });

  final Product product;
  final VoidCallback? onOpenFullScreen;

  static Future<Product?> show(
    BuildContext context, {
    required Product product,
    VoidCallback? onOpenFullScreen,
  }) {
    return showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EditProductSheet(
        product: product,
        onOpenFullScreen: onOpenFullScreen,
      ),
    );
  }

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _categoryController = TextEditingController(text: widget.product.category);
    _skuController = TextEditingController(text: widget.product.sku);
    _barcodeController = TextEditingController(text: widget.product.barcode);
    _descriptionController = TextEditingController(text: widget.product.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final picked = await CategoryPickerSheet.show(
      context,
      selectedCategory: _categoryController.text.trim(),
    );
    if (picked != null && picked.trim().isNotEmpty) {
      setState(() {
        _categoryController.text = picked.trim();
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name is required')),
      );
      return;
    }

    final updated = widget.product.copyWith(
      name: name,
      category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.inputBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Product',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.darkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Quick edit product details',
                        style: TextStyle(fontSize: 12, color: colors.inputLabel),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const Gap(16),

              // Full Screen Edit Banner Link
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenFullScreen?.call();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.maximize2, size: 16, color: Color(0xFF2563EB)),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'Need to edit wholesale units or purchase rates? Open Full Edit Screen',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.darkText,
                          ),
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
              const Gap(16),

              // Product Name
              AuthTextField(
                label: 'Product Name *',
                hintText: 'e.g. Basmati Rice 25kg',
                controller: _nameController,
                prefixIcon: const Icon(LucideIcons.package, size: 18),
              ),
              const Gap(12),

              // Category Picker Field
              InkWell(
                onTap: _pickCategory,
                borderRadius: BorderRadius.circular(10),
                child: IgnorePointer(
                  child: AuthTextField(
                    label: 'Category *',
                    hintText: 'Select product category',
                    controller: _categoryController,
                    prefixIcon: const Icon(LucideIcons.tag, size: 18),
                    readOnly: true,
                  ),
                ),
              ),
              const Gap(12),

              // SKU & Barcode in Row
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      label: 'SKU Code',
                      hintText: 'GRN001',
                      controller: _skuController,
                      prefixIcon: const Icon(LucideIcons.hash, size: 18),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: AuthTextField(
                      label: 'Barcode',
                      hintText: '890123...',
                      controller: _barcodeController,
                      prefixIcon: const Icon(LucideIcons.scanLine, size: 18),
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // Description
              AuthTextField(
                label: 'Description',
                hintText: 'Product details, ingredients or origin notes...',
                controller: _descriptionController,
                prefixIcon: const Icon(LucideIcons.alignLeft, size: 18),
                maxLines: 3,
                minLines: 2,
              ),
              const Gap(20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(LucideIcons.check, size: 18, color: Colors.white),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
      ),
    );
  }
}
