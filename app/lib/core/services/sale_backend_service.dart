import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';

class SaleBackendService {
  final ApiClient _client = ApiClient.instance;

  /// Process POS Sale Checkout
  Future<ApiResponse<Map<String, dynamic>>> checkoutSale({
    String? customerId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    double discountAmount = 0,
    double taxAmount = 0,
    required double grandTotal,
    required String paymentMethod,
    double cashTendered = 0,
    double changeReturned = 0,
    double udharAmount = 0,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'items': items,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'cash_tendered': cashTendered,
      'change_returned': changeReturned,
      'udhar_amount': udharAmount,
    };
    if (customerId != null) body['customer_id'] = customerId;
    if (note != null) body['note'] = note;

    return _client.post<Map<String, dynamic>>(
      ApiConfig.sales,
      body: body,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Fetch Bills list (defaults to today, or specific date in yyyy-MM-dd format)
  Future<ApiResponse<List<dynamic>>> getTodayBills({String? paymentMethod, String? date}) async {
    final query = <String, dynamic>{
      if (paymentMethod != null && paymentMethod != 'All') 'payment_method': paymentMethod,
      if (date != null && date.isNotEmpty) 'date': date,
    };

    return _client.get<List<dynamic>>(
      ApiConfig.todayBills,
      queryParameters: query,
      fromData: (data) => data as List<dynamic>,
    );
  }

  /// Fetch detailed view for a single invoice/receipt
  Future<ApiResponse<Map<String, dynamic>>> getSaleDetails(String receiptNumber) async {
    return _client.get<Map<String, dynamic>>(
      '${ApiConfig.sales}/$receiptNumber',
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Void / Cancel invoice
  Future<ApiResponse<Map<String, dynamic>>> cancelSale({
    required String receiptNumber,
    required String reason,
  }) async {
    return _client.post<Map<String, dynamic>>(
      '${ApiConfig.sales}/$receiptNumber/cancel',
      body: {'reason': reason},
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Fetch all transactions ledger history
  Future<ApiResponse<Map<String, dynamic>>> getTransactions({int limit = 50}) async {
    return _client.get<Map<String, dynamic>>(
      ApiConfig.transactions,
      queryParameters: {'limit': limit},
      fromData: (data) => data as Map<String, dynamic>,
    );
  }
}
