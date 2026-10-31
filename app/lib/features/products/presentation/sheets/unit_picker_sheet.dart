import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Lineless bottom sheet modal to select purchase or selling units.
class UnitPickerSheet extends StatefulWidget {
  const UnitPickerSheet({
    super.key,
    required this.title,
    required this.units,
    this.selectedUnit,
  });

  final String title;
  final List<String> units;
  final String? selectedUnit;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> units,
    String? selectedUnit,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => UnitPickerSheet(
        title: title,
        units: units,
        selectedUnit: selectedUnit,
      ),
    );
  }

  @override
  State<UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<UnitPickerSheet> {
  final _customUnitController = TextEditingController();

  @override
  void dispose() {
    _customUnitController.dispose();
    super.dispose();
  }

  void _addCustomUnit() {
    final unit = _customUnitController.text.trim();
    if (unit.isNotEmpty) {
      Navigator.pop(context, unit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              const Gap(12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.inputBorder.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(14),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 20, color: colors.inputLabel),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
              const Gap(10),

              // Units Grid/List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: widget.units.length,
                  separatorBuilder: (context, index) => const Gap(6),
                  itemBuilder: (context, index) {
                    final unit = widget.units[index];
                    final isSelected = widget.selectedUnit?.toLowerCase() == unit.toLowerCase();

                    return InkWell(
                      onTap: () => Navigator.pop(context, unit),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F1FF) : const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.scale,
                              size: 18,
                              color: isSelected ? colors.primary : colors.inputLabel,
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                unit,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? colors.primary : colors.darkText,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                LucideIcons.check,
                                color: colors.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Custom Unit Field using AuthTextField
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AuthTextField(
                        label: 'Custom Unit',
                        hintText: 'e.g. sack, jar, tray...',
                        controller: _customUnitController,
                        prefixIcon: Icon(
                          LucideIcons.scale,
                          size: 18,
                          color: colors.inputLabel,
                        ),
                      ),
                    ),
                    const Gap(10),
                    ElevatedButton(
                      onPressed: _addCustomUnit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Select',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

