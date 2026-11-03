import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';

class LowStockAlertResult {
  final bool enabled;
  final double threshold;
  final String unit;

  LowStockAlertResult({
    required this.enabled,
    required this.threshold,
    required this.unit,
  });
}

/// Modal bottom sheet to configure low stock notifications and thresholds.
class LowStockAlertSheet extends StatefulWidget {
  const LowStockAlertSheet({
    super.key,
    required this.initialEnabled,
    required this.initialThreshold,
    required this.initialUnit,
    required this.availableUnits,
  });

  final bool initialEnabled;
  final double initialThreshold;
  final String initialUnit;
  final List<String> availableUnits;

  static Future<LowStockAlertResult?> show(
    BuildContext context, {
    required bool initialEnabled,
    required double initialThreshold,
    required String initialUnit,
    required List<String> availableUnits,
  }) {
    return showModalBottomSheet<LowStockAlertResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LowStockAlertSheet(
        initialEnabled: initialEnabled,
        initialThreshold: initialThreshold,
        initialUnit: initialUnit,
        availableUnits: availableUnits,
      ),
    );
  }

  @override
  State<LowStockAlertSheet> createState() => _LowStockAlertSheetState();
}

class _LowStockAlertSheetState extends State<LowStockAlertSheet> {
  late bool _enabled;
  late final TextEditingController _thresholdController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    final isInt = widget.initialThreshold == widget.initialThreshold.roundToDouble();
    _thresholdController = TextEditingController(
      text: isInt
          ? widget.initialThreshold.toInt().toString()
          : widget.initialThreshold.toString(),
    );
    _selectedUnit = widget.initialUnit;
    _thresholdController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  double get _threshold => double.tryParse(_thresholdController.text.trim()) ?? 0.0;

  void _save() {
    Navigator.pop(
      context,
      LowStockAlertResult(
        enabled: _enabled,
        threshold: _threshold,
        unit: _selectedUnit,
      ),
    );
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
                        'Low Stock Alert',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.darkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Configure inventory warning notifications',
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

              // Enable / Disable Notification Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _enabled ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _enabled ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _enabled ? const Color(0xFFEF4444) : colors.inputBorder.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.bell,
                        size: 20,
                        color: _enabled ? Colors.white : colors.inputLabel,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Low Stock Alerts',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            _enabled
                                ? 'Alerts will be triggered on dashboard'
                                : 'Stock warnings are currently paused',
                            style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enabled,
                      activeThumbColor: const Color(0xFFEF4444),
                      onChanged: (val) => setState(() => _enabled = val),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              if (_enabled) ...[
                // Threshold Quantity and Unit Selector
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: AuthTextField(
                        label: 'Threshold Quantity *',
                        hintText: '5',
                        controller: _thresholdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(LucideIcons.alertTriangle, size: 18),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alert Unit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.darkText,
                            ),
                          ),
                          const Gap(6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.inputBorder.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                isExpanded: true,
                                icon: const Icon(LucideIcons.chevronDown, size: 16),
                                items: widget.availableUnits.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(
                                      u,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.darkText,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedUnit = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(14),

                // Live Preview Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 16, color: Color(0xFF64748B)),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'You will be notified when stock falls below ${_threshold.toStringAsFixed(_threshold == _threshold.roundToDouble() ? 0 : 1)} $_selectedUnit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
              ],

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(LucideIcons.check, size: 18, color: Colors.white),
                  label: const Text(
                    'Save Alert Settings',
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
