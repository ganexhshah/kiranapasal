import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';

class TaxResult {
  final double ratePercent;
  final double calculatedAmount;
  final String label;

  const TaxResult({
    required this.ratePercent,
    required this.calculatedAmount,
    required this.label,
  });
}

/// Modal bottom sheet to configure and apply VAT / sales tax to checkout.
class AddTaxSheet extends StatefulWidget {
  const AddTaxSheet({
    super.key,
    required this.taxableBase,
    this.initialRate = 13.0,
  });

  final double taxableBase;
  final double initialRate;

  static Future<TaxResult?> show(
    BuildContext context, {
    required double taxableBase,
    double initialRate = 13.0,
  }) {
    return showModalBottomSheet<TaxResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddTaxSheet(
        taxableBase: taxableBase,
        initialRate: initialRate,
      ),
    );
  }

  @override
  State<AddTaxSheet> createState() => _AddTaxSheetState();
}

class _AddTaxSheetState extends State<AddTaxSheet> {
  late double _ratePercent;
  late final TextEditingController _customRateController;

  final List<double> _presetRates = const [13.0, 5.0, 10.0, 0.0];

  @override
  void initState() {
    super.initState();
    _ratePercent = widget.initialRate;
    _customRateController = TextEditingController(
      text: _ratePercent == _ratePercent.roundToDouble()
          ? _ratePercent.toInt().toString()
          : _ratePercent.toString(),
    );
  }

  @override
  void dispose() {
    _customRateController.dispose();
    super.dispose();
  }

  double get _taxAmount => (widget.taxableBase * _ratePercent / 100);

  String _formatAmount(double amt) {
    final isInt = amt == amt.roundToDouble();
    return isInt ? amt.toInt().toString() : amt.toStringAsFixed(2);
  }

  void _selectRate(double rate) {
    setState(() {
      _ratePercent = rate;
      _customRateController.text = rate == rate.roundToDouble() ? rate.toInt().toString() : rate.toString();
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apply Tax / VAT',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                    ),
                  ),
                  if (_ratePercent > 0)
                    TextButton(
                      onPressed: () => _selectRate(0),
                      child: const Text(
                        'Remove Tax',
                        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const Gap(14),

              // Taxable Base Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Taxable Amount',
                      style: TextStyle(fontSize: 13, color: colors.inputLabel),
                    ),
                    Text(
                      'Rs. ${_formatAmount(widget.taxableBase)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.darkText),
                    ),
                  ],
                ),
              ),
              const Gap(14),

              Text(
                'Tax Rate (%)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel),
              ),
              const Gap(8),

              // Preset Rate Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetRates.map((rate) {
                  final isSelected = rate == _ratePercent;
                  final label = rate == 13.0
                      ? '13% (VAT)'
                      : rate == 0.0
                          ? '0% (Exempt)'
                          : '${rate.toInt()}%';

                  return InkWell(
                    onTap: () => _selectRate(rate),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : colors.darkText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(14),

              // Custom Rate Field
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _customRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.darkText),
                  decoration: const InputDecoration(
                    suffixText: '%',
                    hintText: 'Custom tax percentage...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0;
                    setState(() => _ratePercent = parsed.clamp(0, 100));
                  },
                ),
              ),
              const Gap(16),

              // Tax Preview Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calculated Tax (${_formatAmount(_ratePercent)}%)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0066FF)),
                    ),
                    Text(
                      'Rs. ${_formatAmount(_taxAmount)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0066FF)),
                    ),
                  ],
                ),
              ),
              const Gap(18),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final label = _ratePercent == 13.0 ? 'VAT (13%)' : 'Tax (${_formatAmount(_ratePercent)}%)';
                    Navigator.pop(
                      context,
                      TaxResult(
                        ratePercent: _ratePercent,
                        calculatedAmount: _taxAmount,
                        label: _ratePercent > 0 ? label : '',
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply Tax', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

