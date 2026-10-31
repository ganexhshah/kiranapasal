/// Standardized envelope model matching backend JSON response structure.
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;
  final Map<String, dynamic>? meta;
  final int statusCode;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    this.statusCode = 200,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic dataJson)? fromData,
    int statusCode = 200,
  }) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? (statusCode >= 200 && statusCode < 300),
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'] as T?,
      errors: json['errors'],
      meta: json['meta'] as Map<String, dynamic>?,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure({
    required String message,
    int statusCode = 400,
    dynamic errors,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

