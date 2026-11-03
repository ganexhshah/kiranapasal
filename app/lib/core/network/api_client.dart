import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_response.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _prefTokenKey = 'krm_sanctum_api_token';
  static const String _prefShopIdKey = 'krm_active_shop_id';
  static const String _prefUserNameKey = 'krm_cached_user_name';
  static const String _prefUserAvatarKey = 'krm_cached_user_avatar';
  static const String _prefUserInitialsKey = 'krm_cached_user_initials';
  static const String _prefShopNameKey = 'krm_cached_shop_name';

  String? _authToken;
  String? _activeShopId;
  String? _userName;
  String? _userAvatar;
  String? _userInitials;
  String? _shopName;

  String? get authToken => _authToken;
  String? get activeShopId => _activeShopId;
  String? get userName => _userName;
  String? get userAvatar => _userAvatar;
  String? get userInitials => _userInitials;
  String? get shopName => _shopName;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Initialize stored token, shop ID, and cached profile data
  Future<void> initialize() async {
    await ApiConfig.initialize();
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_prefTokenKey);
      _activeShopId = prefs.getString(_prefShopIdKey);
      _userName = prefs.getString(_prefUserNameKey);
      _userAvatar = prefs.getString(_prefUserAvatarKey);
      _userInitials = prefs.getString(_prefUserInitialsKey);
      _shopName = prefs.getString(_prefShopNameKey);
    } catch (_) {}
  }

  /// Store credentials on successful login
  Future<void> setSession({
    required String token,
    String? shopId,
    String? userName,
    String? userAvatar,
    String? shopName,
  }) async {
    _authToken = token;
    if (shopId != null) {
      _activeShopId = shopId;
    }
    if (userName != null && userName.trim().isNotEmpty) {
      _userName = userName.trim();
    }
    if (userAvatar != null) {
      _userAvatar = userAvatar;
    }
    if (shopName != null && shopName.trim().isNotEmpty) {
      _shopName = shopName.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTokenKey, token);
    if (shopId != null) {
      await prefs.setString(_prefShopIdKey, shopId);
    }
    if (_userName != null) {
      await prefs.setString(_prefUserNameKey, _userName!);
    }
    if (_userAvatar != null) {
      await prefs.setString(_prefUserAvatarKey, _userAvatar!);
    }
    if (_shopName != null) {
      await prefs.setString(_prefShopNameKey, _shopName!);
    }
  }

  /// Persist cached user profile so header loads user data instantly without network lag
  Future<void> setUserProfile({
    String? name,
    String? avatarUrl,
    String? initials,
    String? shopName,
  }) async {
    if (name != null && name.trim().isNotEmpty) _userName = name.trim();
    if (avatarUrl != null) _userAvatar = avatarUrl;
    if (initials != null) _userInitials = initials;
    if (shopName != null && shopName.trim().isNotEmpty) _shopName = shopName.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userName != null) await prefs.setString(_prefUserNameKey, _userName!);
      if (_userAvatar != null) await prefs.setString(_prefUserAvatarKey, _userAvatar!);
      if (_userInitials != null) await prefs.setString(_prefUserInitialsKey, _userInitials!);
      if (_shopName != null) await prefs.setString(_prefShopNameKey, _shopName!);
    } catch (_) {}
  }

  /// Clear session on logout
  Future<void> clearSession() async {
    _authToken = null;
    _activeShopId = null;
    _userName = null;
    _userAvatar = null;
    _userInitials = null;
    _shopName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
    await prefs.remove(_prefShopIdKey);
    await prefs.remove(_prefUserNameKey);
    await prefs.remove(_prefUserAvatarKey);
    await prefs.remove(_prefUserInitialsKey);
    await prefs.remove(_prefShopNameKey);
  }

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (_activeShopId != null && _activeShopId!.isNotEmpty) {
      headers['X-Shop-Id'] = _activeShopId!;
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = ApiConfig.baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';

    if (queryParameters == null || queryParameters.isEmpty) {
      return Uri.parse(fullUrl);
    }

    final stringParams = queryParameters.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return Uri.parse(fullUrl).replace(queryParameters: stringParams);
  }

  /// GET Request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));

      return _handleResponse<T>(response, fromData: fromData);
    } on SocketException {
      return ApiResponse.failure(
        message: 'Cannot reach backend server. Please check your connection or IP.',
        statusCode: 0,
      );
    } on TimeoutException {
      return ApiResponse.failure(
        message: 'Server request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse.failure(message: 'Network error: $e', statusCode: 500);
    }
  }

  /// POST Request
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse<T>(response, fromData: fromData);
    } on SocketException {
      return ApiResponse.failure(
        message: "Can't reach the server. Check your internet connection and try again.",
        statusCode: 0,
      );
    } on TimeoutException {
      return ApiResponse.failure(
        message: 'The server took too long to respond. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      // Log the technical detail; never show it to the shopkeeper.
      debugPrint('Network error: $e');
      return ApiResponse.failure(
        message: 'Something went wrong. Please try again.',
        statusCode: 500,
      );
    }
  }

  /// PUT Request
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse<T>(response, fromData: fromData);
    } catch (e) {
      return ApiResponse.failure(message: 'Network error: $e', statusCode: 500);
    }
  }

  /// DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromData,
  }) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));

      return _handleResponse<T>(response, fromData: fromData);
    } catch (e) {
      return ApiResponse.failure(message: 'Network error: $e', statusCode: 500);
    }
  }

  /// Multipart File Upload (Cloudflare R2 Media Upload)
  Future<ApiResponse<T>> uploadMultipart<T>(
    String path, {
    required File file,
    required String fileField,
    Map<String, String>? fields,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);

      final headers = _buildHeaders();
      headers.remove('Content-Type'); // Allow http package to set multipart boundary
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(
        await http.MultipartFile.fromPath(fileField, file.path),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromData: fromData);
    } catch (e) {
      return ApiResponse.failure(message: 'Upload failed: $e', statusCode: 500);
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response, {
    T Function(dynamic)? fromData,
  }) {
    final status = response.statusCode;

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(decoded, fromData: fromData, statusCode: status);
    } catch (_) {
      if (status >= 200 && status < 300) {
        return ApiResponse<T>(
          success: true,
          message: 'Operation completed successfully',
          statusCode: status,
        );
      }
      return ApiResponse.failure(
        message: 'Server error ($status): ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
        statusCode: status,
      );
    }
  }
}

