import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../sales/domain/models/supplier.dart';
import '../../../sales/presentation/sheets/add_edit_supplier_sheet.dart';
import '../../../sales/presentation/sheets/purchase_payment_sheet.dart';
import '../../../sales/presentation/sheets/record_purchase_sheet.dart';
import '../widgets/supplier_card.dart';
import '../widgets/supplier_stats_row.dart';
import '../../../parties/presentation/screens/party_details_screen.dart';

/// Clean, modern Supplier / Vendor Management Screen connected directly to real backend data.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'With Balance', 'Settled'

  List<Supplier> get _suppliers => AppDataRepository.instance.suppliers;

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

  Future<void> _addNewSupplier() async {
    final newSupplier = await AddEditSupplierSheet.show(context);
    if (newSupplier != null && mounted) {
      await AppDataRepository.instance.addSupplier(newSupplier);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Supplier "${newSupplier.name}" added successfully')),
        );
      }
    }
  }

  Future<void> _editSupplier(Supplier supplier) async {
    final updated =
        await AddEditSupplierSheet.show(context, supplier: supplier);
    if (updated != null && mounted) {
      await AppDataRepository.instance.updateSupplier(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Supplier "${updated.name}" updated')),
        );
      }
    }
  }

  Future<void> _recordPurchase(Supplier supplier) async {
    final purchase =
        await RecordPurchaseSheet.show(context, initialSupplier: supplier);
    if (purchase != null && mounted) {
      await AppDataRepository.instance.recordPurchase(
        supplierId: supplier.id,
        supplierName: supplier.name,
        items: [
          {
            'product_name': purchase.productName,
            'quantity': purchase.quantity,
            'purchase_price': purchase.unitCost,
            'subtotal': purchase.totalAmount,
          }
        ],
        totalAmount: purchase.totalAmount,
        paymentMethod: purchase.paymentMethod,
        isCredit: purchase.isCredit,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Purchase of Rs. ${purchase.totalAmount.toInt()} recorded for ${supplier.name}')),
        );
      }
    }
  }

  Future<void> _paySupplier(Supplier supplier) async {
    final payment =
        await PurchasePaymentSheet.show(context, supplier: supplier);
    if (payment != null && mounted) {
      await AppDataRepository.instance.recordSupplierPayment(
        supplierId: supplier.id,
        amount: payment.amount,
        paymentMethod: payment.paymentMethod,
        note: payment.note,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Paid Rs. ${payment.amount.toInt()} to ${supplier.name}')),
        );
      }
    }
  }

  Future<void> _viewSupplierDetails(Supplier supplier) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => PartyDetailsScreen.supplier(supplier),
      ),
    );
    if (result is Supplier && mounted) {
      await AppDataRepository.instance.updateSupplier(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final colors = context.colors;

        final filteredSuppliers = _suppliers.where((s) {
          final matchesSearch = _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.phone.contains(_searchQuery) ||
              s.panNumber.contains(_searchQuery);
          if (!matchesSearch) return false;

          switch (_selectedFilter) {
            case 'With Balance':
              return s.outstandingBalance > 0;
            case 'Settled':
              return s.outstandingBalance == 0;
            default:
              return true;
          }
        }).toList();

        final totalOutstanding =
            _suppliers.fold<double>(0, (sum, s) => sum + s.outstandingBalance);
        final suppliersWithBalance =
            _suppliers.where((s) => s.outstandingBalance > 0).length;

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
              'Suppliers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.darkText,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  onPressed: _addNewSupplier,
                  icon: const Icon(LucideIcons.plus, size: 15),
                  label: const Text('Add',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
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
              SupplierStatsRow(
                totalSuppliers: _suppliers.length,
                totalPayable: totalOutstanding,
                suppliersWithBalance: suppliersWithBalance,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search supplier by name, phone, PAN...',
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
                    _filterChip('With Balance', 'With Balance'),
                    const Gap(8),
                    _filterChip('Settled', 'Settled'),
                  ],
                ),
              ),
              const Gap(8),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0066FF),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await AppDataRepository.instance.refreshAll();
                  },
                  child: AppDataRepository.instance.isLoading && filteredSuppliers.isEmpty
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 20),
                          child: TransactionListSkeleton(itemCount: 5),
                        )
                      : filteredSuppliers.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const Gap(60),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.truck, size: 40, color: Colors.grey.shade400),
                                      const Gap(8),
                                      Text(
                                        _searchQuery.isEmpty ? 'No suppliers added yet' : 'No matching suppliers found',
                                        style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: filteredSuppliers.length + 1,
                              separatorBuilder: (context, index) => const Gap(8),
                              itemBuilder: (context, index) {
                                if (index == filteredSuppliers.length) {
                                  return const AppBottomLoader(hasMore: false);
                                }
                                final supplier = filteredSuppliers[index];
                                return SupplierCard(
                                  supplier: supplier,
                                  onTap: () => _viewSupplierDetails(supplier),
                                  onPaySupplier: () => _paySupplier(supplier),
                                  onRecordPurchase: () => _recordPurchase(supplier),
                                  onMoreOptions: () => _editSupplier(supplier),
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
              isSelected ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
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
