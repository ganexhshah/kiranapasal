import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Modal bottom sheet to create and save a new product inventory category.
class CreateCategorySheet extends StatefulWidget {
  const CreateCategorySheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const CreateCategorySheet(),
    );
  }

  @override
  State<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<CreateCategorySheet> {
  final _controller = TextEditingController();
  int _selectedIconIndex = 0;

  final List<IconData> _icons = const [
    LucideIcons.package,
    LucideIcons.shoppingBag,
    LucideIcons.coffee,
    LucideIcons.apple,
    LucideIcons.utensils,
    LucideIcons.sparkles,
    LucideIcons.tag,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
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

              Text(
                'Create Category',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                ),
              ),
              const Gap(14),

              // Category Name Field
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.darkText),
                  decoration: const InputDecoration(
                    hintText: 'Category name (e.g. Dairy, Spices)...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                ),
              ),
              const Gap(14),

              Text(
                'Choose Icon',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel),
              ),
              const Gap(8),

              // Icon selector row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_icons.length, (i) {
                  final isSelected = i == _selectedIconIndex;
                  return InkWell(
                    onTap: () => setState(() => _selectedIconIndex = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        _icons[i],
                        size: 20,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                    ),
                  );
                }),
              ),
              const Gap(18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: colors.darkText)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = _controller.text.trim();
                        if (name.isNotEmpty) {
                          Navigator.pop(context, name);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Category', style: TextStyle(fontWeight: FontWeight.w700)),
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

