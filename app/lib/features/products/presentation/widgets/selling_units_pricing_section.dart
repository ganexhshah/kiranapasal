import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../sheets/unit_picker_sheet.dart';

/// Model representing a selling unit and its corresponding price.
class SellingUnitItem {
  final String id;
  String unit;
  TextEditingController priceController;
  bool isDefault;

  SellingUnitItem({
    required this.id,
    required this.unit,
    required double initialPrice,
    this.isDefault = false,
  }) : priceController = TextEditingController(
          text: initialPrice > 0
              ? (initialPrice == initialPrice.roundToDouble()
                  ? initialPrice.toInt().toString()
                  : initialPrice.toString())
              : '',
        );

  double get price => double.tryParse(priceController.text.trim()) ?? 0.0;
}

/// Reusable Section: "Selling Units & Price" matching the exact screenshot design.
class SellingUnitsPricingSection extends StatefulWidget {
  const SellingUnitsPricingSection({
    super.key,
    required this.units,
    required this.onChanged,
  });

  final List<SellingUnitItem> units;
  final VoidCallback onChanged;

  @override
  State<SellingUnitsPricingSection> createState() => _SellingUnitsPricingSectionState();
}

class _SellingUnitsPricingSectionState extends State<SellingUnitsPricingSection> {
  final List<String> _commonUnits = const [
    'kg',
    'gram',
    'Bora (25 kg)',
    'Bora (50 kg)',
    'Carton',
    'Box',
    'Packet',
    'ltr',
    'ml',
    'pcs',
    'bundle',
  ];

  Future<void> _addNewUnit() async {
    final pickedUnit = await UnitPickerSheet.show(
      context,
      title: 'Add Selling Unit',
      units: _commonUnits,
    );

    if (pickedUnit != null && pickedUnit.trim().isNotEmpty) {
      setState(() {
        widget.units.add(
          SellingUnitItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            unit: pickedUnit.trim(),
            initialPrice: 0.0,
            isDefault: widget.units.isEmpty,
          ),
        );
      });
      widget.onChanged();
    }
  }

  Future<void> _editUnit(int index) async {
    final current = widget.units[index];
    final pickedUnit = await UnitPickerSheet.show(
      context,
      title: 'Change Selling Unit',
      units: _commonUnits,
      selectedUnit: current.unit,
    );

    if (pickedUnit != null && pickedUnit.trim().isNotEmpty) {
      setState(() {
        current.unit = pickedUnit.trim();
      });
      widget.onChanged();
    }
  }

  void _removeUnit(int index) {
    if (widget.units.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one selling unit is required'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final removed = widget.units.removeAt(index);
    if (removed.isDefault && widget.units.isNotEmpty) {
      widget.units.first.isDefault = true;
    }
    setState(() {});
    widget.onChanged();
  }

  void _setDefault(int index) {
    for (int i = 0; i < widget.units.length; i++) {
      widget.units[i].isDefault = (i == index);
    }
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row (Title + Subtitle on Left, "+ Add Unit" Button on Right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selling Units & Price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Add the units you want to sell this product in',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: colors.inputLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(10),

            // "+ Add Unit" Button
            ElevatedButton.icon(
              onPressed: _addNewUnit,
              icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
              label: const Text(
                'Add Unit',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const Gap(14),

        // 2. Selling Unit Rows List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.units.length,
          separatorBuilder: (context, index) => const Gap(10),
          itemBuilder: (context, index) {
            final item = widget.units[index];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag / List Handle Icon (:=)
                Icon(
                  LucideIcons.list,
                  color: const Color(0xFF94A3B8),
                  size: 16,
                ),
                const Gap(6),

                // Unit Selector Box (e.g. "kg", "gram", "Bora (25 kg)")
                Expanded(
                  flex: 4,
                  child: InkWell(
                    onTap: () => _editUnit(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.unit,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronDown,
                            size: 14,
                            color: Color(0xFF475569),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(8),

                // Price Input Box with shaded "Rs." prefix chip
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // "Rs." shaded prefix tag
                        Container(
                          margin: const EdgeInsets.all(3),
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF3FA),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Rs.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        // Number input field
                        Expanded(
                          child: TextField(
                            controller: item.priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => widget.onChanged(),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                            textAlign: TextAlign.start,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              hintText: '0.00',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(8),

                // Dedicated Column for "Default" Pill Badge (Aligned across all rows)
                SizedBox(
                  width: 54,
                  child: item.isDefault
                      ? Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        )
                      : InkWell(
                          onTap: () => _setDefault(index),
                          borderRadius: BorderRadius.circular(6),
                          child: const SizedBox(
                            width: 54,
                            height: 28,
                          ),
                        ),
                ),
                const Gap(4),

                // Red Trash Delete Button (Strictly right-aligned)
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 17,
                    color: Color(0xFFEF4444),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  splashRadius: 16,
                  tooltip: 'Remove Unit',
                  onPressed: () => _removeUnit(index),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

