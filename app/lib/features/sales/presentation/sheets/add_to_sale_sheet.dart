import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/widgets/product_thumbnail.dart';
import '../../domain/models/cart_item.dart';
import 'select_selling_unit_sheet.dart';

/// Modal bottom sheet to select selling unit, quantity, inspect total, and add item to cart.
class AddToSaleSheet extends StatefulWidget {
  const AddToSaleSheet({
    super.key,
    required this.product,
    this.initialQuantity = 1.0,
  });

  final Product product;
  final double initialQuantity;

  static Future<CartItem?> show(
    BuildContext context, {
    required Product product,
    double initialQuantity = 1.0,
  }) {
    return showModalBottomSheet<CartItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddToSaleSheet(
        product: product,
        initialQuantity: initialQuantity,
      ),
    );
  }

  @override
  State<AddToSaleSheet> createState() => _AddToSaleSheetState();
}

class _AddToSaleSheetState extends State<AddToSaleSheet> {
  late double _quantity;
  late String _selectedUnit;
  late double _unitPrice;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _selectedUnit = widget.product.priceUnit;
    _unitPrice = widget.product.price;
    _qtyController = TextEditingController(
      text: _formatQty(_quantity),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }

  void _updateQuantity(double newQty) {
    if (newQty <= 0) return;
    setState(() {
      _quantity = newQty;
      _qtyController.text = _formatQty(_quantity);
    });
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
      setState(() {
        _selectedUnit = unit;
      });
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

              // Product Info Row
              Row(
                children: [
                  ProductThumbnail(
                    imageUrl: widget.product.imageUrl,
                    category: widget.product.category,
                    size: 46,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.darkText,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          '${widget.product.formattedPrice} / ${widget.product.priceUnit} • Stock: ${widget.product.formattedStock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.inputLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Unit & Quantity Control Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Unit selector row
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.inputBorder.withValues(alpha: 0.2),
                              ),
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

                    // Quantity Stepper & Input
                    Row(
                      children: [
                        // Minus Button
                        IconButton(
                          onPressed: _quantity > 1 ? () => _updateQuantity(_quantity - 1) : null,
                          icon: const Icon(LucideIcons.minus, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                            ),
                          ),
                        ),
                        const Gap(10),

                        // Quantity Field
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.inputBorder.withValues(alpha: 0.25),
                              ),
                            ),
                            child: TextField(
                              controller: _qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.darkText,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setState(() => _quantity = parsed);
                                }
                              },
                            ),
                          ),
                        ),
                        const Gap(10),

                        // Plus Button
                        IconButton(
                          onPressed: () => _updateQuantity(_quantity + 1),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),

                    // Quick Step Chips (+0.25, +0.5, +1, +5)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [0.25, 0.5, 1.0, 5.0].map((step) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => _updateQuantity(_quantity + step),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+$step',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.inputLabel,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Total Preview & Add to Cart Action
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.inputLabel,
                          ),
                        ),
                        Text(
                          _formattedTotal,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final item = CartItem(
                        product: widget.product,
                        unit: _selectedUnit,
                        quantity: _quantity,
                        unitPrice: _unitPrice,
                      );
                      Navigator.pop(context, item);
                    },
                    icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

