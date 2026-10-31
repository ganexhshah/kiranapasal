import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';

class ProductBackendService {
  final ApiClient _client = ApiClient.instance;

  /// Fetch paginated products with optional search and category filters
  Future<ApiResponse<Map<String, dynamic>>> getProducts({
    String? search,
    String? categoryId,
    bool? lowStockOnly,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (lowStockOnly == true) 'low_stock_only': true,
    };

    return _client.get<Map<String, dynamic>>(
      ApiConfig.products,
      queryParameters: queryParams,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Fetch dedicated Low Stock Items with supplier & deficit metrics
  Future<ApiResponse<List<dynamic>>> getLowStockItems() async {
    return _client.get<List<dynamic>>(
      ApiConfig.lowStockInventory,
      fromData: (data) => data as List<dynamic>,
    );
  }

  /// Create a new inventory product
  Future<ApiResponse<Map<String, dynamic>>> createProduct(Map<String, dynamic> productData) async {
    return _client.post<Map<String, dynamic>>(
      ApiConfig.products,
      body: productData,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update an existing inventory product
  Future<ApiResponse<Map<String, dynamic>>> updateProduct(String productId, Map<String, dynamic> productData) async {
    return _client.put<Map<String, dynamic>>(
      '${ApiConfig.products}/$productId',
      body: productData,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Delete a product
  Future<ApiResponse<dynamic>> deleteProduct(String productId) async {
    return _client.delete<dynamic>(
      '${ApiConfig.products}/$productId',
    );
  }

  /// Find product by barcode scanner
  Future<ApiResponse<Map<String, dynamic>>> findByBarcode(String barcode) async {
    return _client.get<Map<String, dynamic>>(
      '${ApiConfig.products}/barcode/$barcode',
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Adjust product physical stock level
  Future<ApiResponse<Map<String, dynamic>>> adjustStock({
    required String productId,
    required bool isAddition,
    required double quantity,
    required String unit,
    required String reason,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'is_addition': isAddition,
      'quantity': quantity,
      'unit': unit,
      'reason': reason,
    };
    if (note != null) body['note'] = note;

    return _client.post<Map<String, dynamic>>(
      '${ApiConfig.products}/$productId/adjust-stock',
      body: body,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update low stock alert threshold
  Future<ApiResponse<Map<String, dynamic>>> updateLowStockAlert({
    required String productId,
    required double threshold,
    required bool enabled,
  }) async {
    return _client.put<Map<String, dynamic>>(
      '${ApiConfig.products}/$productId/low-stock-alert',
      body: {
        'threshold': threshold,
        'enabled': enabled,
      },
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Fetch real stock movement history for a product from the database
  Future<ApiResponse<List<dynamic>>> getStockHistory(String productId) async {
    return _client.get<List<dynamic>>(
      '${ApiConfig.products}/$productId/stock-history',
      fromData: (data) => data as List<dynamic>,
    );
  }
}
