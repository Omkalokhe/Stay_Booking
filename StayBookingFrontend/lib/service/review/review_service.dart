import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/model/core/paginated_response.dart';
import 'package:stay_booking_frontend/model/create_review_request_dto.dart';
import 'package:stay_booking_frontend/model/review_response_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';

class ReviewService {
  ReviewService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  /// ================= CUSTOMER =================

  Future<ReviewListResult> getReviewsByHotelId(int hotelId) async {
    final response = await _client.get(
      ApiEndpoints.getReviewsByHotelId(hotelId),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ReviewListResult(
        success: true,
        message: 'Reviews loaded',
        statusCode: response.statusCode,
        items: _extractReviews(decoded),
      );
    }

    return ReviewListResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to load reviews',
      statusCode: response.statusCode,
      items: const [],
    );
  }

  /// ================= ADMIN PAGINATION =================

  Future<AdminReviewPageResult> getAdminReviews({
    required int page,
    required int size,
    int? rating,
    String? search,
    String sortBy = 'createdAt',
    String direction = 'desc',
  }) async {
    final uri = ApiEndpoints.getAdminReviews(
      page: page,
      size: size,
      rating: rating,
      search: search,
      sortBy: sortBy,
      direction: direction,
    );

    final response = await _client.get(
      uri,
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final pageData = PaginatedResponse.fromDecoded<ReviewResponseDto>(
        decoded,
        (json) => ReviewResponseDto.fromJson(json),
      );

      return AdminReviewPageResult(
        success: true,
        message: 'Reviews loaded',
        statusCode: response.statusCode,
        page: pageData,
      );
    }

    return AdminReviewPageResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to load reviews',
      statusCode: response.statusCode,
      page: const PaginatedResponse(
        content: [],
        page: 0,
        size: 0,
        totalElements: 0,
        totalPages: 1,
        first: true,
        last: true,
      ),
    );
  }

  /// ================= CREATE =================

  Future<ReviewActionResult> createReview(
    CreateReviewRequestDto request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.createReview(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ReviewActionResult(
        success: true,
        message: 'Review submitted',
        statusCode: response.statusCode,
        item: _extractReview(decoded),
        fieldErrors: const {},
      );
    }

    return ReviewActionResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Unable to submit review',
      statusCode: response.statusCode,
      item: null,
      fieldErrors: const {},
    );
  }

  /// ================= DELETE =================

  Future<ReviewDeleteResult> deleteReview(int reviewId) async {
    final response = await _client.delete(
      ApiEndpoints.deleteReview(reviewId),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ReviewDeleteResult(
        success: true,
        message: 'Review deleted',
        statusCode: response.statusCode,
      );
    }

    return ReviewDeleteResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Delete failed',
      statusCode: response.statusCode,
    );
  }

  /// ================= PARSERS =================

  List<ReviewResponseDto> _extractReviews(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => ReviewResponseDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (decoded is Map && decoded['content'] is List) {
      return (decoded['content'] as List)
          .whereType<Map>()
          .map((e) => ReviewResponseDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return [];
  }

  ReviewResponseDto? _extractReview(dynamic decoded) {
    if (decoded is Map) {
      return ReviewResponseDto.fromJson(Map<String, dynamic>.from(decoded));
    }
    return null;
  }
}

/// ================= RESULTS =================

class ReviewListResult {
  const ReviewListResult({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.items,
  });

  final bool success;
  final String message;
  final int statusCode;
  final List<ReviewResponseDto> items;
}

class AdminReviewPageResult {
  const AdminReviewPageResult({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.page,
  });

  final bool success;
  final String message;
  final int statusCode;
  final PaginatedResponse<ReviewResponseDto> page;
}

class ReviewActionResult {
  const ReviewActionResult({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.item,
    required this.fieldErrors,
  });

  final bool success;
  final String message;
  final int statusCode;
  final ReviewResponseDto? item;
  final Map<String, String> fieldErrors;
}

class ReviewDeleteResult {
  const ReviewDeleteResult({
    required this.success,
    required this.message,
    required this.statusCode,
  });

  final bool success;
  final String message;
  final int statusCode;
}
