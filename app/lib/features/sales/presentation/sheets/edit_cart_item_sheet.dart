import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../products/presentation/widgets/product_thumbnail.dart';
import '../../domain/models/cart_item.dart';
import 'select_selling_unit_sheet.dart';

/// Modal bottom sheet allowing editing of an existing item in the sales cart.
class EditCartItemSheet extends StatefulWidget {
  const EditCartItemSheet({
    super.key,
    required this.item,
  });

  final CartItem item;

  static Future<CartItem?> show(
    BuildContext context, {
    required CartItem item,
  }) {
    return showModalBottomSheet<CartItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EditCartItemSheet(item: item),
    );
  }

  @override
  State<EditCartItemSheet> createState() => _EditCartItemSheetState();
}

class _EditCartItemSheetState extends State<EditCartItemSheet> {
  late double _quantity;
  late String _selectedUnit;
  late double _unitPrice;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _selectedUnit = widget.item.unit;
    _unitPrice = widget.item.unitPrice;
    _qtyController = TextEditingController(text: _formatVal(_quantity));
    _priceController = TextEditingController(text: _formatVal(_unitPrice));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _formatVal(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString();
  }

  double get _lineTotal => _quantity * _unitPrice;

  String get _formattedTotal {
    final isInt = _lineTotal == _lineTotal.roundToDouble();
    final val = isInt ? _lineTotal.toInt().toString() : _lineTotal.toStringAsFixed(2);
    return 'Rs. $val';
  }

  Future<void> _changeUnit() async {
    final unit = await SelectSellingUnitSheet.show(
      context,
      currentUnit: _selectedUnit,
    );
    if (unit != null && mounted) {
      setState(() => _selectedUnit = unit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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

              // Title & Delete Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Cart Item',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Return empty item or null with delete flag (quantity = 0 indicates deletion)
                      Navigator.pop(
                        context,
                        widget.item.copyWith(quantity: 0),
                      );
                    },
                    icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Remove Item',
                  ),
                ],
              ),
              const Gap(12),

              // Product Info
              Row(
                children: [
                  ProductThumbnail(
                    imageUrl: widget.item.product.imageUrl,
                    category: widget.item.product.category,
                    size: 44,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      widget.item.product.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Unit Selector Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selling Unit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.darkText,
                    ),
                  ),
                  InkWell(
                    onTap: _changeUnit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedUnit,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const Gap(4),
                          const Icon(
                            LucideIcons.chevronDown,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),

              // Quantity Input
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.inputLabel,
                ),
              ),
              const Gap(6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.darkText,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setState(() => _quantity = parsed);
                    }
                  },
                ),
              ),
              const Gap(14),

              // Unit Price Input
              Text(
                'Unit Price (Rs.)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.inputLabel,
                ),
              ),
              const Gap(6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.darkText,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed >= 0) {
                      setState(() => _unitPrice = parsed);
                    }
                  },
                ),
              ),
              const Gap(20),

              // Total & Update Button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Line Total',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.inputLabel,
                          ),
                        ),
                        Text(
                          _formattedTotal,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final updated = widget.item.copyWith(
                        unit: _selectedUnit,
                        quantity: _quantity,
                        unitPrice: _unitPrice,
                      );
                      Navigator.pop(context, updated);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Update Item',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

