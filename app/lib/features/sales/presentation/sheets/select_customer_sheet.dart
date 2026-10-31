import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/customer.dart';
import 'add_customer_sheet.dart';

/// Modal bottom sheet allowing selection of an existing customer or continuing as walk-in.
class SelectCustomerSheet extends StatefulWidget {
  const SelectCustomerSheet({
    super.key,
    this.selectedCustomerId,
  });

  final String? selectedCustomerId;

  static Future<Customer?> show(
    BuildContext context, {
    String? selectedCustomerId,
  }) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SelectCustomerSheet(selectedCustomerId: selectedCustomerId),
    );
  }

  @override
  State<SelectCustomerSheet> createState() => _SelectCustomerSheetState();
}

class _SelectCustomerSheetState extends State<SelectCustomerSheet> {
  List<Customer> get _customers => [
        Customer.walkIn,
        ...AppDataRepository.instance.customers.where((c) => !c.isWalkIn),
      ];
  String _searchQuery = '';

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery);
    }).toList();
  }

  Future<void> _addNewCustomer() async {
    final newCust = await AddCustomerSheet.show(context);
    if (newCust != null && mounted) {
      await AppDataRepository.instance.addCustomer(newCust);
      if (mounted) {
        Navigator.pop(context, newCust);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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

            // Header Row with "+ Add Customer"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Customer',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNewCustomer,
                  icon: const Icon(LucideIcons.userPlus, size: 15, color: Color(0xFF0066FF)),
                  label: const Text(
                    'Add Customer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),

            // Search Bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(fontSize: 13.5, color: colors.darkText),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.inputLabel),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const Gap(12),

            // Customer List
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filteredCustomers.length,
                separatorBuilder: (ctx, i) => const Gap(8),
                itemBuilder: (ctx, index) {
                  final customer = _filteredCustomers[index];
                  final isSelected = customer.id == widget.selectedCustomerId;

                  return InkWell(
                    onTap: () => Navigator.pop(context, customer),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF0066FF), width: 1.2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0066FF)
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              customer.isWalkIn ? LucideIcons.userCheck : LucideIcons.user,
                              size: 18,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.darkText,
                                  ),
                                ),
                                if (customer.phone.isNotEmpty) ...[
                                  const Gap(2),
                                  Text(
                                    customer.phone,
                                    style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (customer.udharBalance > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Udhar: Rs. ${customer.udharBalance.toInt()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
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

