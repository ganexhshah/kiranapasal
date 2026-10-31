import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

class CategoryOption {
  final String name;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const CategoryOption({
    required this.name,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

/// Lineless bottom sheet modal to search and select a product category.
class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    super.key,
    this.selectedCategory,
  });

  final String? selectedCategory;

  static Future<String?> show(
    BuildContext context, {
    String? selectedCategory,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => CategoryPickerSheet(
        selectedCategory: selectedCategory,
      ),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  final _searchController = TextEditingController();
  final _newCategoryController = TextEditingController();

  final List<CategoryOption> _defaultCategories = const [
    CategoryOption(
      name: 'Grains',
      icon: LucideIcons.wheat,
      color: Color(0xFF0866FF),
      backgroundColor: Color(0xFFE8F1FF),
    ),
    CategoryOption(
      name: 'Snacks',
      icon: LucideIcons.cookie,
      color: Color(0xFFF59E0B),
      backgroundColor: Color(0xFFFFF4E6),
    ),
    CategoryOption(
      name: 'Beverages',
      icon: LucideIcons.coffee,
      color: Color(0xFF7C3AED),
      backgroundColor: Color(0xFFF4EEFF),
    ),
    CategoryOption(
      name: 'Daily Needs',
      icon: LucideIcons.shoppingBag,
      color: Color(0xFF10B981),
      backgroundColor: Color(0xFFE6F8F0),
    ),
    CategoryOption(
      name: 'Household',
      icon: LucideIcons.home,
      color: Color(0xFF0D9488),
      backgroundColor: Color(0xFFE0F7F6),
    ),
    CategoryOption(
      name: 'Dairy',
      icon: LucideIcons.milk,
      color: Color(0xFF2563EB),
      backgroundColor: Color(0xFFEFF6FF),
    ),
    CategoryOption(
      name: 'Spices',
      icon: LucideIcons.flame,
      color: Color(0xFFEF4444),
      backgroundColor: Color(0xFFFEECEC),
    ),
    CategoryOption(
      name: 'Bakery',
      icon: LucideIcons.cake,
      color: Color(0xFFD97706),
      backgroundColor: Color(0xFFFEF3C7),
    ),
    CategoryOption(
      name: 'Personal Care',
      icon: LucideIcons.heart,
      color: Color(0xFFDB2777),
      backgroundColor: Color(0xFFFCE7F3),
    ),
  ];

  late List<CategoryOption> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List.from(_defaultCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  List<CategoryOption> get _filteredCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  void _addNewCategory() {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a category name first')),
      );
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filteredCategories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                      'Select Category',
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
              const Gap(8),

              // Search Input using AuthTextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AuthTextField(
                  label: 'Search Categories',
                  hintText: 'e.g. Grains, Snacks...',
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: colors.inputLabel,
                  ),
                ),
              ),
              const Gap(12),

              // Category List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Gap(6),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = widget.selectedCategory?.toLowerCase() == item.name.toLowerCase();

                    return InkWell(
                      onTap: () => Navigator.pop(context, item.name),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F1FF) : const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: item.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  item.icon,
                                  color: item.color,
                                  size: 16,
                                ),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                item.name,
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

              // Add Custom Category Bar using AuthTextField
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AuthTextField(
                        label: 'Custom Category',
                        hintText: 'Type category name...',
                        controller: _newCategoryController,
                        prefixIcon: Icon(
                          LucideIcons.plusCircle,
                          size: 18,
                          color: colors.inputLabel,
                        ),
                      ),
                    ),
                    const Gap(10),
                    ElevatedButton(
                      onPressed: _addNewCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add',
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

