import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../sales/domain/models/customer.dart';
import '../../../sales/presentation/sheets/add_edit_customer_sheet.dart';
import '../../../sales/presentation/sheets/customer_actions_sheet.dart';
import '../../../sales/presentation/sheets/customer_credit_limit_sheet.dart';
import '../../../sales/presentation/sheets/receive_udhar_payment_sheet.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_stats_row.dart';
import '../../../parties/presentation/screens/party_details_screen.dart';

/// Clean, modern Customer Management Screen connected directly to real backend data.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'With Udhar', 'Settled'

  List<Customer> get _customers => AppDataRepository.instance.customers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDataRepository.instance.refreshAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addNewCustomer() async {
    final newCustomer = await AddEditCustomerSheet.show(context);
    if (newCustomer != null && mounted) {
      await AppDataRepository.instance.addCustomer(newCustomer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Customer "${newCustomer.name}" added successfully')),
        );
      }
    }
  }

  Future<void> _editCustomer(Customer customer) async {
    final updated =
        await AddEditCustomerSheet.show(context, customer: customer);
    if (updated != null && mounted) {
      await AppDataRepository.instance.updateCustomer(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer "${updated.name}" updated')),
        );
      }
    }
  }

  Future<void> _receivePayment(Customer customer) async {
    final result =
        await ReceiveUdharPaymentSheet.show(context, customer: customer);
    if (result != null && mounted) {
      await AppDataRepository.instance.receiveUdharPayment(
        customerId: customer.id,
        amount: result.amount,
        paymentMethod: result.paymentMethod,
        note: result.note,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Received Rs. ${result.amount.toInt()} from ${customer.name}')),
        );
      }
    }
  }

  Future<void> _openContactPicker() async {
    final contact = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Select Contact',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('A')),
              title: const Text('Aayush Karki'),
              subtitle: const Text('9841000000'),
              onTap: () => Navigator.pop(ctx, {
                'name': 'Aayush Karki',
                'phone': '9841000000',
              }),
            ),
          ],
        ),
      ),
    );

    if (contact != null && mounted) {
      final newCustomer = await AddEditCustomerSheet.show(
        context,
        initialName: contact['name'],
        initialPhone: contact['phone'],
      );
      if (newCustomer != null && mounted) {
        await AppDataRepository.instance.addCustomer(newCustomer);
      }
    }
  }

  Future<void> _viewCustomerDetails(Customer customer) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => PartyDetailsScreen.customer(customer),
      ),
    );
    if (result is Customer && mounted) {
      await AppDataRepository.instance.updateCustomer(result);
    }
  }

  Future<void> _editCreditLimit(Customer customer) async {
    final newLimit = await CustomerCreditLimitSheet.show(
      context,
      customer: customer,
    );
    if (newLimit != null && mounted) {
      await AppDataRepository.instance
          .updateCustomer(customer.copyWith(creditLimit: newLimit));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Credit limit updated to Rs. ${newLimit.toInt()}')),
        );
      }
    }
  }

  Future<void> _openCustomerActions(Customer customer) async {
    final action = await CustomerActionsSheet.show(
      context,
      customer: customer,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case CustomerActionType.recordPayment:
        _receivePayment(customer);
        break;
      case CustomerActionType.viewProfile:
      case CustomerActionType.viewLedger:
        _viewCustomerDetails(customer);
        break;
      case CustomerActionType.editDetails:
        _editCustomer(customer);
        break;
      case CustomerActionType.setCreditLimit:
        _editCreditLimit(customer);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final colors = context.colors;

        final filteredCustomers = _customers.where((c) {
          if (c.isWalkIn) return false;
          final matchesSearch = _searchQuery.isEmpty ||
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.phone.contains(_searchQuery);
          if (!matchesSearch) return false;

          switch (_selectedFilter) {
            case 'With Udhar':
              return c.udharBalance > 0;
            case 'Settled':
              return c.udharBalance == 0;
            default:
              return true;
          }
        }).toList();

        final totalUdhar =
            _customers.fold<double>(0, (sum, c) => sum + c.udharBalance);
        final customersWithUdhar =
            _customers.where((c) => c.udharBalance > 0).length;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 56.0,
            titleSpacing: 0,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon:
                  Icon(LucideIcons.arrowLeft, size: 20, color: colors.darkText),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              splashRadius: 20,
            ),
            title: Text(
              'Customers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.darkText,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.contactRound, size: 20, color: colors.darkText),
                tooltip: 'Import from Contacts',
                onPressed: _openContactPicker,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  onPressed: _addNewCustomer,
                  icon: const Icon(LucideIcons.plus, size: 15),
                  label: const Text('Add',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              CustomerStatsRow(
                totalCustomers: _customers.where((c) => !c.isWalkIn).length,
                totalUdhar: totalUdhar,
                customersWithUdhar: customersWithUdhar,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search customer by name or phone...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search,
                        size: 17, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _filterChip('All', 'All'),
                    const Gap(8),
                    _filterChip('With Udhar', 'With Udhar'),
                    const Gap(8),
                    _filterChip('Settled', 'Settled'),
                  ],
                ),
              ),
              const Gap(8),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await AppDataRepository.instance.refreshAll();
                  },
                  child: AppDataRepository.instance.isLoading && _customers.isEmpty
                      ? const TransactionListSkeleton(itemCount: 6)
                      : filteredCustomers.isEmpty
                          ? ListView(
                              children: [
                                const Gap(60),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.users,
                                          size: 40, color: Colors.grey.shade400),
                                      const Gap(8),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'No customers added yet'
                                            : 'No matching customers found',
                                        style: TextStyle(
                                            fontSize: 13.5, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: filteredCustomers.length + 1,
                              separatorBuilder: (context, index) => const Gap(8),
                              itemBuilder: (context, index) {
                                if (index == filteredCustomers.length) {
                                  return const AppBottomLoader(hasMore: false);
                                }
                                final customer = filteredCustomers[index];
                                return CustomerCard(
                                  customer: customer,
                                  onTap: () => _viewCustomerDetails(customer),
                                  onReceivePayment: () => _receivePayment(customer),
                                  onMoreOptions: () => _openCustomerActions(customer),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
