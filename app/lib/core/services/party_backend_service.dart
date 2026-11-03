import '../../features/sales/domain/models/customer.dart';
import '../../features/sales/domain/models/supplier.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';

class PartyBackendService {
  final ApiClient _client = ApiClient.instance;

  /// Fetch Customers directory
  Future<ApiResponse<Map<String, dynamic>>> getCustomers({
    String? search,
    bool? udharOnly,
    int page = 1,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
      if (udharOnly == true) 'udhar_only': true,
    };

    return _client.get<Map<String, dynamic>>(
      ApiConfig.customers,
      queryParameters: query,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Create a new Customer
  Future<ApiResponse<Map<String, dynamic>>> createCustomer(Map<String, dynamic> data) async {
    return _client.post<Map<String, dynamic>>(
      ApiConfig.customers,
      body: data,
      fromData: (res) => res as Map<String, dynamic>,
    );
  }

  /// Update an existing Customer
  Future<ApiResponse<Map<String, dynamic>>> updateCustomer(String customerId, Map<String, dynamic> data) async {
    return _client.put<Map<String, dynamic>>(
      '${ApiConfig.customers}/$customerId',
      body: data,
      fromData: (res) => res as Map<String, dynamic>,
    );
  }

  /// Record Udhar debt repayment
  Future<ApiResponse<Map<String, dynamic>>> receiveCustomerPayment({
    required String customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNo,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'payment_method': paymentMethod,
    };
    if (referenceNo != null) body['reference_no'] = referenceNo;
    if (note != null) body['note'] = note;

    return _client.post<Map<String, dynamic>>(
      '${ApiConfig.customers}/$customerId/receive-payment',
      body: body,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Fetch Suppliers directory
  Future<ApiResponse<Map<String, dynamic>>> getSuppliers({
    String? search,
    int page = 1,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    return _client.get<Map<String, dynamic>>(
      ApiConfig.suppliers,
      queryParameters: query,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Create a new Supplier
  Future<ApiResponse<Map<String, dynamic>>> createSupplier(Map<String, dynamic> data) async {
    return _client.post<Map<String, dynamic>>(
      ApiConfig.suppliers,
      body: data,
      fromData: (res) => res as Map<String, dynamic>,
    );
  }

  /// Update an existing Supplier
  Future<ApiResponse<Map<String, dynamic>>> updateSupplier(String supplierId, Map<String, dynamic> data) async {
    return _client.put<Map<String, dynamic>>(
      '${ApiConfig.suppliers}/$supplierId',
      body: data,
      fromData: (res) => res as Map<String, dynamic>,
    );
  }

  /// Record Supplier Inventory Purchase
  Future<ApiResponse<Map<String, dynamic>>> recordPurchase({
    required String supplierId,
    required String billNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required bool isPaid,
    String? paymentMethod,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'supplier_id': supplierId,
      'bill_number': billNumber,
      'items': items,
      'total_amount': totalAmount,
      'is_paid': isPaid,
    };
    if (paymentMethod != null) body['payment_method'] = paymentMethod;
    if (note != null) body['note'] = note;

    return _client.post<Map<String, dynamic>>(
      ApiConfig.purchases,
      body: body,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Settle Supplier payment
  Future<ApiResponse<Map<String, dynamic>>> makeSupplierPayment({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? referenceNo,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'payment_method': paymentMethod,
    };
    if (referenceNo != null) body['reference_no'] = referenceNo;
    if (note != null) body['note'] = note;

    return _client.post<Map<String, dynamic>>(
      '${ApiConfig.suppliers}/$supplierId/make-payment',
      body: body,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Convenience method to fetch customers domain list directly
  Future<List<Customer>> fetchCustomers() async {
    try {
      final res = await getCustomers();
      if (res.success && res.data != null) {
        final list = (res.data!['data'] ?? res.data!['customers']) as List<dynamic>? ?? [];
        return list.map((c) => Customer.fromJson(c as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Convenience method to fetch suppliers domain list directly
  Future<List<Supplier>> fetchSuppliers() async {
    try {
      final res = await getSuppliers();
      if (res.success && res.data != null) {
        final list = (res.data!['data'] ?? res.data!['suppliers']) as List<dynamic>? ?? [];
        return list.map((s) => Supplier.fromJson(s as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}
