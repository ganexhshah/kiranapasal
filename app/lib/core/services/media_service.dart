import 'dart:io';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';

class MediaService {
  final ApiClient _client = ApiClient.instance;

  /// Upload product photo or attachment to Cloudflare R2 bucket (protofilo)
  Future<ApiResponse<String>> uploadImage(File imageFile) async {
    final response = await _client.uploadMultipart<Map<String, dynamic>>(
      ApiConfig.mediaUpload,
      file: imageFile,
      fileField: 'image',
      fromData: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final url = response.data!['url'] as String? ?? '';
      return ApiResponse<String>(
        success: true,
        message: response.message,
        data: url,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.failure(
      message: response.message.isNotEmpty ? response.message : 'Image upload failed',
      statusCode: response.statusCode,
      errors: response.errors,
    );
  }
}

