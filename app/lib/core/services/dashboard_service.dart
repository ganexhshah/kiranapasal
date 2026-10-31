import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';

class DashboardService {
  final ApiClient _client = ApiClient.instance;

  /// Fetch today's sales overview with cash/card/udhar breakdown
  Future<ApiResponse<Map<String, dynamic>>> getOverview() async {
    return _client.get<Map<String, dynamic>>(
      ApiConfig.dashboardOverview,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Fetch 2x2 stats grid (Total Products, Customers, Low Stock, Today's Bills)
  Future<ApiResponse<Map<String, dynamic>>> getStats() async {
    return _client.get<Map<String, dynamic>>(
      ApiConfig.dashboardStats,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Fetch recent shop transactions
  Future<ApiResponse<List<dynamic>>> getRecentTransactions() async {
    return _client.get<List<dynamic>>(
      ApiConfig.dashboardRecentTransactions,
      fromData: (data) => data as List<dynamic>,
    );
  }
}

