import 'package:google_sign_in/google_sign_in.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';
import 'printing_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _client = ApiClient.instance;

  bool get isAuthenticated => _client.isAuthenticated;
  String? get activeShopId => _client.activeShopId;

  /// Login with email or phone number and password
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConfig.authLogin,
      body: {
        'identifier': identifier.trim(),
        'password': password,
      },
      fromData: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final token = response.data!['token'] as String?;
      final shop = response.data!['shop'] as Map<String, dynamic>?;
      final shopId = shop?['id'] as String?;

      if (token != null) {
        await _client.setSession(token: token, shopId: shopId);
      }
      if (shop != null) {
        await PrintingService.instance.syncFromShop(shop);
      }
    }

    return response;
  }

  /// Register new user and store, triggers 6-digit OTP email via Resend
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? shopName,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    };
    if (phone != null && phone.trim().isNotEmpty) {
      body['phone'] = phone.trim();
    }
    if (shopName != null && shopName.trim().isNotEmpty) {
      body['shop_name'] = shopName.trim();
    }

    final response = await _client.post<Map<String, dynamic>>(
      ApiConfig.authRegister,
      body: body,
      fromData: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final token = response.data!['token'] as String?;
      final shop = response.data!['shop'] as Map<String, dynamic>?;
      final shopId = shop?['id'] as String?;

      if (token != null) {
        await _client.setSession(token: token, shopId: shopId);
      }
      if (shop != null) {
        await PrintingService.instance.syncFromShop(shop);
      }
    }

    return response;
  }

  /// Verify 6-digit OTP sent via Resend email
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return _client.post<Map<String, dynamic>>(
      ApiConfig.authVerifyOtp,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Resend 6-digit OTP code to email via Resend
  Future<ApiResponse<Map<String, dynamic>>> resendOtp({
    required String email,
  }) async {
    return _client.post<Map<String, dynamic>>(
      ApiConfig.authResendOtp,
      body: {
        'email': email.trim(),
      },
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Request password reset instructions & OTP sent via Resend
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    return _client.post<Map<String, dynamic>>(
      ApiConfig.authForgotPassword,
      body: {
        'email': email.trim(),
      },
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Reset account password with 6-digit OTP received from email
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConfig.authResetPassword,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
        'password': password,
      },
      fromData: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final token = response.data!['token'] as String?;
      final shop = response.data!['shop'] as Map<String, dynamic>?;
      final shopId = shop?['id'] as String?;

      if (token != null) {
        await _client.setSession(token: token, shopId: shopId);
      }
    }

    return response;
  }

  bool _googleInitialized = false;

  /// Authenticate with Google account and synchronize with backend
  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await googleSignIn.initialize(
          serverClientId: '405002567086-ashuuk4rlju57vj2unelfk7r9gr69hqd.apps.googleusercontent.com',
        );
        _googleInitialized = true;
      }

      final account = await googleSignIn.authenticate();

      final body = <String, dynamic>{
        'email': account.email,
        'name': account.displayName ?? 'Google User',
        'google_id': account.id,
      };
      if (account.photoUrl != null) {
        body['avatar_url'] = account.photoUrl;
      }
      final idToken = account.authentication.idToken;
      if (idToken != null && idToken.isNotEmpty) {
        body['id_token'] = idToken;
      }

      final response = await _client.post<Map<String, dynamic>>(
        ApiConfig.authGoogle,
        body: body,
        fromData: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final token = response.data!['token'] as String?;
        final shop = response.data!['shop'] as Map<String, dynamic>?;
        final shopId = shop?['id'] as String?;

        if (token != null) {
          await _client.setSession(token: token, shopId: shopId);
        }
        if (shop != null) {
          await PrintingService.instance.syncFromShop(shop);
        }
      }

      return response;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Google sign-in was cancelled.',
          statusCode: 400,
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.description?.isNotEmpty == true
            ? e.description!
            : 'Unable to sign in with Google. Please try again.',
        statusCode: 400,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      String friendlyMessage;
      if (errStr.contains('cancel')) {
        friendlyMessage = 'Google sign-in was cancelled.';
      } else if (errStr.contains('network') ||
          errStr.contains('socket') ||
          errStr.contains('connection') ||
          errStr.contains('timeout')) {
        friendlyMessage =
            'Network error: unable to connect to Google. Please check your internet connection.';
      } else if (errStr.contains('api: 10') || errStr.contains('developer_error')) {
        friendlyMessage =
            'Google Sign-In configuration error. Please log in using your email/phone and password.';
      } else {
        friendlyMessage =
            'Unable to complete Google sign-in. Please try again or use your password.';
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: friendlyMessage,
        statusCode: 500,
      );
    }
  }

  /// Authenticate with backend using Firebase ID token
  Future<ApiResponse<Map<String, dynamic>>> loginWithFirebaseToken({
    required String firebaseToken,
    String? phone,
    String? shopName,
    String? ownerName,
  }) async {
    final body = <String, dynamic>{
      'firebase_token': firebaseToken,
    };
    if (phone != null) body['phone'] = phone;
    if (shopName != null) body['shop_name'] = shopName;
    if (ownerName != null) body['owner_name'] = ownerName;

    final response = await _client.post<Map<String, dynamic>>(
      ApiConfig.authFirebaseLogin,
      body: body,
      fromData: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final token = response.data!['token'] as String?;
      final shop = response.data!['shop'] as Map<String, dynamic>?;
      final shopId = shop?['id'] as String?;

      if (token != null) {
        await _client.setSession(token: token, shopId: shopId);
      }
      if (shop != null) {
        await PrintingService.instance.syncFromShop(shop);
      }
    }

    return response;
  }

  /// Get current user profile and active shop context
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    return _client.get<Map<String, dynamic>>(
      ApiConfig.authMe,
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update authenticated user profile (name, phone, avatar)
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    return _client.put<Map<String, dynamic>>(
      ApiConfig.authUpdateProfile,
      body: {
        'name': name.trim(),
        'phone': ?phone?.trim(),
        'avatar_url': ?avatarUrl,
      },
      fromData: (data) => data as Map<String, dynamic>,
    );
  }

  /// Logout and revoke Sanctum token
  Future<void> logout() async {
    try {
      await _client.post(ApiConfig.authLogout);
    } catch (_) {}
    await _client.clearSession();
  }
}
