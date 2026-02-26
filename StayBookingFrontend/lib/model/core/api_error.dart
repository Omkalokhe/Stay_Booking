class ApiError {
  const ApiError({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;
}

class ApiException implements Exception {
  const ApiException(this.error);

  final ApiError error;
}
