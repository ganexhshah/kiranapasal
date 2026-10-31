import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/product.dart';
import 'unit_picker_sheet.dart';

class StockAdjustmentResult {
  final bool isAddition;
  final double quantity;
  final String unit;
  final String reason;
  final String? note;
  final double newStock;

  StockAdjustmentResult({
    required this.isAddition,
    required this.quantity,
    required this.unit,
    required this.reason,
    this.note,
    required this.newStock,
  });
}

/// Responsive, lineless bottom sheet modal allowing users to Add or Remove stock.
/// Reuses [UnitPickerSheet] for unit selection and provides a dedicated sheet for reasons.
class AdjustStockSheet extends StatefulWidget {
  const AdjustStockSheet({
    super.key,
    required this.product,
  });

  final Product product;

  static Future<StockAdjustmentResult?> show(
    BuildContext context, {
    required Product product,
  }) {
    return showModalBottomSheet<StockAdjustmentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => AdjustStockSheet(product: product),
    );
  }

  @override
  State<AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends State<AdjustStockSheet> {
  bool _isAddition = true;
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedUnit;
  late String _selectedReason;

  final List<String> _addReasons = const [
    'Purchase',
    'Customer Return',
    'Inventory Count Correction',
    'Other Addition',
  ];

  final List<String> _removeReasons = const [
    'Damage / Broken',
    'Expired Product',
    'Inventory Discrepancy',
    'Internal Consumption',
    'Other Removal',
  ];

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.product.stockUnit;
    _selectedReason = _addReasons.first;
    _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _enteredQty => double.tryParse(_quantityController.text.trim()) ?? 0.0;

  double get _calculatedNewStock {
    if (_isAddition) {
      return widget.product.stock + _enteredQty;
    } else {
      final res = widget.product.stock - _enteredQty;
      return res < 0 ? 0.0 : res;
    }
  }

  void _onToggleType(bool isAddition) {
    setState(() {
      _isAddition = isAddition;
      _selectedReason = isAddition ? _addReasons.first : _removeReasons.first;
    });
  }

  Future<void> _pickUnit() async {
    final availableUnits = {
      widget.product.stockUnit,
      widget.product.purchaseUnit,
      if (widget.product.stockUnit != 'gram') 'gram',
      if (widget.product.stockUnit != 'kg') 'kg',
      'Carton',
      'Box',
      'Packet',
      'pcs',
      'bundle',
    }.toList();

    final picked = await UnitPickerSheet.show(
      context,
      title: 'Select Stock Unit',
      units: availableUnits,
      selectedUnit: _selectedUnit,
    );

    if (picked != null && picked.trim().isNotEmpty) {
      setState(() => _selectedUnit = picked.trim());
    }
  }

  Future<void> _pickReason() async {
    final reasons = _isAddition ? _addReasons : _removeReasons;

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(14),
                Text(
                  _isAddition ? 'Select Addition Reason' : 'Select Removal Reason',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Gap(12),
                ...reasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return InkWell(
                    onTap: () => Navigator.pop(ctx, reason),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                            size: 18,
                            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF94A3B8),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedReason = picked);
    }
  }

  void _submit() {
    if (_enteredQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity greater than 0')),
      );
      return;
    }

    final result = StockAdjustmentResult(
      isAddition: _isAddition,
      quantity: _enteredQty,
      unit: _selectedUnit,
      reason: _selectedReason,
      note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      newStock: _calculatedNewStock,
    );

    Navigator.pop(context, result);
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              const Gap(12),

              // Title Row (Clean, no unnecessary subtitle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adjust Stock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const Gap(12),

              // 1. Add / Remove Segmented Toggle (Clean, lineless)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onToggleType(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _isAddition ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _isAddition
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.plusCircle,
                                size: 16,
                                color: _isAddition ? const Color(0xFF16A34A) : colors.inputLabel,
                              ),
                              const Gap(6),
                              Text(
                                'Add Stock',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _isAddition ? colors.darkText : colors.inputLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onToggleType(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: !_isAddition ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !_isAddition
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.minusCircle,
                                size: 16,
                                color: !_isAddition ? const Color(0xFFEF4444) : colors.inputLabel,
                              ),
                              const Gap(6),
                              Text(
                                'Remove Stock',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !_isAddition ? colors.darkText : colors.inputLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(14),

              // 2. Quantity & Unit Selector Row (Reusing UnitPickerSheet!)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: AuthTextField(
                      label: _isAddition ? 'Quantity to Add *' : 'Quantity to Remove *',
                      hintText: '0',
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(LucideIcons.layers, size: 18),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.darkText,
                          ),
                        ),
                        const Gap(6),
                        InkWell(
                          onTap: _pickUnit,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedUnit,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: colors.darkText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // 3. Reason Selector Field (Taps to open dedicated Reason Sheet!)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.darkText,
                    ),
                  ),
                  const Gap(6),
                  InkWell(
                    onTap: _pickReason,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAddition ? LucideIcons.plusCircle : LucideIcons.alertCircle,
                            size: 16,
                            color: _isAddition ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                          ),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              _selectedReason,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: colors.darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // 4. Updated Stock Preview Card (Lineless, clean soft card)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Stock',
                          style: TextStyle(fontSize: 12, color: colors.inputLabel),
                        ),
                        Text(
                          '${widget.product.stock.toStringAsFixed(widget.product.stock == widget.product.stock.roundToDouble() ? 0 : 1)} ${widget.product.stockUnit}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.darkText,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isAddition ? 'Stock to Add' : 'Stock to Remove',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isAddition ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          '${_isAddition ? '+' : '-'} ${_enteredQty.toStringAsFixed(_enteredQty == _enteredQty.roundToDouble() ? 0 : 1)} $_selectedUnit',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _isAddition ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Updated Stock Preview',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_calculatedNewStock.toStringAsFixed(_calculatedNewStock == _calculatedNewStock.roundToDouble() ? 0 : 1)} $_selectedUnit',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),

              // 5. Notes / Remarks (Optional)
              AuthTextField(
                label: 'Note (Optional)',
                hintText: 'e.g. Received from Supplier ABC',
                controller: _notesController,
                prefixIcon: const Icon(LucideIcons.fileText, size: 18),
              ),
              const Gap(16),

              // 6. Action Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    _isAddition ? LucideIcons.plusCircle : LucideIcons.minusCircle,
                    size: 17,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isAddition ? 'Confirm Addition' : 'Confirm Removal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAddition ? const Color(0xFF0066FF) : const Color(0xFFEF4444),
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
