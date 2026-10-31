import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central API configuration with platform-aware base URLs and endpoint routes.
class ApiConfig {
  static const String _prefServerUrlKey = 'krm_custom_server_url';

  /// Default local development base URL depending on operating platform:
  /// - Android Emulator: 10.0.2.2 maps to host machine localhost
  /// - Windows / Web / iOS Simulator: localhost
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost/api/v1';
    }
    if (Platform.isAndroid) {
      // Works directly with: adb reverse tcp:8000 tcp:80
      return 'http://localhost:8000/api/v1';
    }
    return 'http://localhost/api/v1';
  }

  static String _currentBaseUrl = defaultBaseUrl;
  static String get baseUrl => _currentBaseUrl;

  /// Load custom server IP/Domain from persistent storage if configured by user
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefServerUrlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _currentBaseUrl = savedUrl;
      } else {
        _currentBaseUrl = defaultBaseUrl;
      }
    } catch (_) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  /// Update server URL (e.g. for connecting mobile phone to PC on local Wi-Fi: http://192.168.1.XX)
  static Future<void> setCustomBaseUrl(String newUrl) async {
    final cleanUrl = newUrl.endsWith('/') ? newUrl.substring(0, newUrl.length - 1) : newUrl;
    final fullApiUrl = cleanUrl.endsWith('/api/v1') ? cleanUrl : '$cleanUrl/api/v1';
    _currentBaseUrl = fullApiUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefServerUrlKey, fullApiUrl);
  }

  static Future<void> resetToDefault() async {
    _currentBaseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefServerUrlKey);
  }

  // --- Endpoints ---
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authResendOtp = '/auth/resend-otp';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authGoogle = '/auth/google';
  static const String authFirebaseLogin = '/auth/firebase-login';
  static const String authMe = '/auth/me';
  static const String authUpdateProfile = '/auth/profile';
  static const String authLogout = '/auth/logout';
  static const String shopProfile = '/shop/profile';

  static const String dashboardOverview = '/dashboard/overview';
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardRecentTransactions = '/dashboard/recent-transactions';

  static const String products = '/products';
  static const String lowStockInventory = '/inventory/low-stock';
  static const String categories = '/categories';

  static const String sales = '/sales';
  static const String todayBills = '/sales/today';
  static const String transactions = '/transactions';

  static const String customers = '/customers';
  static const String suppliers = '/suppliers';
  static const String purchases = '/purchases';
  static const String expenses = '/expenses';
  static const String notifications = '/notifications';
  static const String mediaUpload = '/media/upload';
}

