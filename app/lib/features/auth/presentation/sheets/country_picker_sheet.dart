import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

class CountryItem {
  final String name;
  final String dialCode;
  final String flag;
  final String code;

  const CountryItem({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.code,
  });
}

const List<CountryItem> kSupportedCountries = [
  CountryItem(name: 'Nepal', dialCode: '+977', flag: '🇳🇵', code: 'NP'),
  CountryItem(name: 'India', dialCode: '+91', flag: '🇮🇳', code: 'IN'),
  CountryItem(name: 'United States', dialCode: '+1', flag: '🇺🇸', code: 'US'),
  CountryItem(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧', code: 'GB'),
  CountryItem(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪', code: 'AE'),
  CountryItem(name: 'Qatar', dialCode: '+974', flag: '🇶🇦', code: 'QA'),
  CountryItem(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦', code: 'SA'),
  CountryItem(name: 'Malaysia', dialCode: '+60', flag: '🇲🇾', code: 'MY'),
  CountryItem(name: 'Australia', dialCode: '+61', flag: '🇦🇺', code: 'AU'),
  CountryItem(name: 'Japan', dialCode: '+81', flag: '🇯🇵', code: 'JP'),
  CountryItem(name: 'South Korea', dialCode: '+82', flag: '🇰🇷', code: 'KR'),
  CountryItem(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼', code: 'KW'),
  CountryItem(name: 'Canada', dialCode: '+1', flag: '🇨🇦', code: 'CA'),
  CountryItem(name: 'Singapore', dialCode: '+65', flag: '🇸🇬', code: 'SG'),
  CountryItem(name: 'Germany', dialCode: '+49', flag: '🇩🇪', code: 'DE'),
  CountryItem(name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩', code: 'BD'),
  CountryItem(name: 'China', dialCode: '+86', flag: '🇨🇳', code: 'CN'),
];

/// Clean, lineless CountryPickerSheet using the same floating-label input box.
class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({
    super.key,
    required this.selectedDialCode,
    required this.onCountrySelected,
  });

  final String selectedDialCode;
  final ValueChanged<CountryItem> onCountrySelected;

  static Future<CountryItem?> show(
    BuildContext context, {
    required String selectedDialCode,
  }) {
    return showModalBottomSheet<CountryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        // Keep the search results above the keyboard.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CountryPickerSheet(
          selectedDialCode: selectedDialCode,
          onCountrySelected: (country) => Navigator.of(context).pop(country),
        ),
      ),
    );
  }

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CountryItem> _filtered = kSupportedCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCountries);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = kSupportedCountries;
      } else {
        _filtered = kSupportedCountries.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.dialCode.toLowerCase().contains(query) ||
              c.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.inputBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.darkText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colors.inputLabel,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            // Reusable search input field with animated floating label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AuthTextField(
                controller: _searchController,
                label: 'Search Country',
                hintText: 'Search by name or code...',
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 20,
                  color: colors.darkText,
                ),
              ),
            ),
            const Gap(14),

            // Clean list with zero divider lines
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No countries found',
                        style: TextStyle(
                          color: colors.inputLabel,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final country = _filtered[index];
                        // Compare position too: +1 is shared by US and Canada, so
                        // a dial-code-only check highlights both rows.
                        final isSelected =
                            country.dialCode == widget.selectedDialCode &&
                                _filtered.indexWhere((c) =>
                                        c.dialCode == widget.selectedDialCode) ==
                                    index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: isSelected
                                ? colors.secondarySurface.withValues(alpha: 0.7)
                                : Colors.transparent,
                            onTap: () => widget.onCountrySelected(country),
                            leading: Text(
                              country.flag,
                              style: const TextStyle(fontSize: 26),
                            ),
                            title: Text(
                              country.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: colors.darkText,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  country.dialCode,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? colors.primary : colors.inputLabel,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const Gap(8),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colors.primary,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

