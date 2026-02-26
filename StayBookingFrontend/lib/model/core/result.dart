import 'package:stay_booking_frontend/model/core/api_error.dart';

class Result<T> {
  const Result._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  final bool isSuccess;
  final T? data;
  final ApiError? error;

  factory Result.success(T data) {
    return Result<T>._(isSuccess: true, data: data);
  }

  factory Result.failure(ApiError error) {
    return Result<T>._(isSuccess: false, error: error);
  }
}

