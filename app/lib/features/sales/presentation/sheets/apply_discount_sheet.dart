import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';

enum DiscountType { fixed, percentage }

class DiscountResult {
  final DiscountType type;
  final double value;
  final double calculatedAmount;

  const DiscountResult({
    required this.type,
    required this.value,
    required this.calculatedAmount,
  });
}

/// Modal bottom sheet to apply a fixed or percentage discount to the current sale.
class ApplyDiscountSheet extends StatefulWidget {
  const ApplyDiscountSheet({
    super.key,
    required this.subtotal,
  });

  final double subtotal;

  static Future<DiscountResult?> show(
    BuildContext context, {
    required double subtotal,
  }) {
    return showModalBottomSheet<DiscountResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ApplyDiscountSheet(subtotal: subtotal),
    );
  }

  @override
  State<ApplyDiscountSheet> createState() => _ApplyDiscountSheetState();
}

class _ApplyDiscountSheetState extends State<ApplyDiscountSheet> {
  DiscountType _type = DiscountType.percentage;
  final TextEditingController _controller = TextEditingController();
  double _value = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _calculatedAmount {
    if (_type == DiscountType.percentage) {
      return (widget.subtotal * _value / 100).clamp(0, widget.subtotal);
    }
    return _value.clamp(0, widget.subtotal);
  }

  void _selectPreset(double val) {
    setState(() {
      _value = val;
      _controller.text = val == val.roundToDouble() ? val.toInt().toString() : val.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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

              Text(
                'Apply Discount',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                ),
              ),
              const Gap(14),

              // Segmented Toggle: Percentage (%) vs Fixed (Rs.)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = DiscountType.percentage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _type == DiscountType.percentage ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _type == DiscountType.percentage
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Percentage (%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _type == DiscountType.percentage ? FontWeight.w700 : FontWeight.w500,
                              color: _type == DiscountType.percentage ? const Color(0xFF2563EB) : colors.inputLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = DiscountType.fixed),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _type == DiscountType.fixed ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _type == DiscountType.fixed
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Fixed Amount (Rs.)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _type == DiscountType.fixed ? FontWeight.w700 : FontWeight.w500,
                              color: _type == DiscountType.fixed ? const Color(0xFF2563EB) : colors.inputLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(14),

              // Value Input Field
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: _type == DiscountType.percentage ? 'e.g. 10' : 'e.g. 50',
                    prefixText: _type == DiscountType.percentage ? '' : 'Rs. ',
                    suffixText: _type == DiscountType.percentage ? '%' : '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0;
                    setState(() => _value = parsed);
                  },
                ),
              ),
              const Gap(10),

              // Quick Presets
              Row(
                children: (_type == DiscountType.percentage ? [5.0, 10.0, 15.0, 20.0] : [20.0, 50.0, 100.0, 200.0])
                    .map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _selectPreset(preset),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _type == DiscountType.percentage ? '${preset.toInt()}%' : 'Rs. ${preset.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.darkText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(16),

              // Discount Preview & Apply
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You Save',
                          style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                        ),
                        Text(
                          'Rs. ${_calculatedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        DiscountResult(
                          type: _type,
                          value: _value,
                          calculatedAmount: _calculatedAmount,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Apply Discount', style: TextStyle(fontWeight: FontWeight.w700)),
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

