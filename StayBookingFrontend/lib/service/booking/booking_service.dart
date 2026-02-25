import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/model/booking_response_dto.dart';
import 'package:stay_booking_frontend/model/core/paginated_response.dart';
import 'package:stay_booking_frontend/model/create_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_order_request_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_order_response_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_verify_request_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_verify_response_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_status_request_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';
import 'package:stay_booking_frontend/service/core/service_paged_result.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';

class BookingService {
  BookingService({http.Client? client}) : _client = client ?? HttpClient.instance;

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<ServicePagedResult<BookingResponseDto>> getBookings({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    int? userId,
    int? hotelId,
    int? roomId,
    String? bookingStatus,
    String? paymentStatus,
    String? checkInFrom,
    String? checkOutTo,
  }) async {
    final response = await _client.get(
      ApiEndpoints.getBookings(
        page: page,
        size: size,
        sortBy: sortBy,
        direction: direction,
        userId: userId,
        hotelId: hotelId,
        roomId: roomId,
        bookingStatus: bookingStatus,
        paymentStatus: paymentStatus,
        checkInFrom: checkInFrom,
        checkOutTo: checkOutTo,
      ),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    final pageData = PaginatedResponse.fromDecoded<BookingResponseDto>(
      decoded,
      BookingResponseDto.fromJson,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ServicePagedResult<BookingResponseDto>(
        success: true,
        message:
            _parser.extractMessage(decoded) ?? 'Bookings loaded successfully.',
        pageData: pageData,
      );
    }

    return ServicePagedResult<BookingResponseDto>(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to load bookings (${response.statusCode})',
      pageData: pageData,
    );
  }

  Future<HotelActionResult<BookingResponseDto>> createBooking(
    CreateBookingRequestDto request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.createBooking(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    return _toActionResult(
      response,
      successMessage: 'Booking created successfully.',
      conflictMessage: 'Room already booked for selected dates.',
    );
  }

  Future<HotelActionResult<BookingResponseDto>> getBookingById(int id) async {
    final response = await _client.get(
      ApiEndpoints.getBookingById(id),
      headers: const {'Content-Type': 'application/json'},
    );
    return _toActionResult(
      response,
      successMessage: 'Booking loaded successfully.',
      conflictMessage: 'Unable to load booking.',
    );
  }

  Future<HotelActionResult<BookingResponseDto>> updateBooking(
    int id,
    UpdateBookingRequestDto request,
  ) async {
    final response = await _client.put(
      ApiEndpoints.updateBooking(id),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    return _toActionResult(
      response,
      successMessage: 'Booking updated successfully.',
      conflictMessage: 'Unable to update booking for selected dates.',
    );
  }

  Future<HotelActionResult<BookingResponseDto>> updateBookingStatus(
    int id,
    UpdateBookingStatusRequestDto request,
  ) async {
    final response = await _client.put(
      ApiEndpoints.updateBookingStatus(id),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    return _toActionResult(
      response,
      successMessage: 'Booking status updated successfully.',
      conflictMessage: 'Unable to update booking status.',
    );
  }

  Future<HotelActionResult<BookingResponseDto>> cancelBooking(int id) async {
    final response = await _client.put(
      ApiEndpoints.cancelBooking(id),
      headers: const {'Content-Type': 'application/json'},
    );
    return _toActionResult(
      response,
      successMessage: 'Booking cancelled successfully.',
      conflictMessage: 'Unable to cancel booking.',
    );
  }

  Future<HotelActionResult<RazorpayOrderResponseDto>> createRazorpayOrder(
    RazorpayOrderRequestDto request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.createRazorpayOrder(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    final order = _extractRazorpayOrder(decoded);
    final message = order?.frontendMessage.trim().isNotEmpty == true
        ? order!.frontendMessage
        : _parser.extractMessage(decoded);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<RazorpayOrderResponseDto>(
        success: true,
        message: message ?? 'Payment order created successfully.',
        item: order,
      );
    }

    if (response.statusCode == 409) {
      return HotelActionResult<RazorpayOrderResponseDto>(
        success: false,
        message: message ?? 'Unable to create payment order for this booking.',
        item: order,
      );
    }

    return HotelActionResult<RazorpayOrderResponseDto>(
      success: false,
      message:
          message ?? 'Payment order request failed (${response.statusCode})',
      item: order,
    );
  }

  Future<HotelActionResult<RazorpayVerifyResponseDto>> verifyRazorpayPayment(
    RazorpayVerifyRequestDto request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.verifyRazorpayPayment(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    final verification = _extractRazorpayVerification(decoded);
    final message = verification?.frontendMessage.trim().isNotEmpty == true
        ? verification!.frontendMessage
        : _parser.extractMessage(decoded);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<RazorpayVerifyResponseDto>(
        success: true,
        message: message ?? 'Payment verified successfully.',
        item: verification,
      );
    }

    if (response.statusCode == 409) {
      return HotelActionResult<RazorpayVerifyResponseDto>(
        success: false,
        message: message ?? 'Payment verification failed.',
        item: verification,
      );
    }

    return HotelActionResult<RazorpayVerifyResponseDto>(
      success: false,
      message:
          message ??
          'Payment verification request failed (${response.statusCode})',
      item: verification,
    );
  }

  HotelActionResult<BookingResponseDto> _toActionResult(
    http.Response response, {
    required String successMessage,
    required String conflictMessage,
  }) {
    final decoded = _parser.tryParseJson(response.body);
    final item = _extractBooking(decoded);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<BookingResponseDto>(
        success: true,
        message: _parser.extractMessage(decoded) ?? successMessage,
        item: item,
      );
    }

    if (response.statusCode == 409) {
      return HotelActionResult<BookingResponseDto>(
        success: false,
        message: _parser.extractMessage(decoded) ?? conflictMessage,
        item: item,
      );
    }

    return HotelActionResult<BookingResponseDto>(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Request failed (${response.statusCode})',
      item: item,
    );
  }

  BookingResponseDto? _extractBooking(dynamic decoded) {
    if (decoded is Map) {
      if (decoded['data'] is Map) {
        return BookingResponseDto.fromJson(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      }
      if (decoded['booking'] is Map) {
        return BookingResponseDto.fromJson(
          Map<String, dynamic>.from(decoded['booking'] as Map),
        );
      }
      if (decoded['id'] != null && decoded['roomId'] != null) {
        return BookingResponseDto.fromJson(Map<String, dynamic>.from(decoded));
      }
    }
    return null;
  }

  RazorpayOrderResponseDto? _extractRazorpayOrder(dynamic decoded) {
    if (decoded is! Map) return null;

    final root = Map<String, dynamic>.from(decoded);
    final candidates = <Map<String, dynamic>>[];

    if (root['data'] is Map) {
      candidates.add(Map<String, dynamic>.from(root['data'] as Map));
    }
    if (root['payment'] is Map) {
      candidates.add(Map<String, dynamic>.from(root['payment'] as Map));
    }
    if (root['result'] is Map) {
      candidates.add(Map<String, dynamic>.from(root['result'] as Map));
    }
    candidates.add(root);

    for (final candidate in candidates) {
      if (candidate['orderId'] != null || candidate['amountInPaise'] != null) {
        return RazorpayOrderResponseDto.fromJson(candidate);
      }
    }
    return null;
  }

  RazorpayVerifyResponseDto? _extractRazorpayVerification(dynamic decoded) {
    if (decoded is! Map) return null;

    final root = Map<String, dynamic>.from(decoded);
    final candidates = <Map<String, dynamic>>[];

    if (root['data'] is Map) {
      candidates.add(Map<String, dynamic>.from(root['data'] as Map));
    }
    if (root['payment'] is Map) {
      candidates.add(Map<String, dynamic>.from(root['payment'] as Map));
    }
    if (root['result'] is Map) {
      candidates.add(Map<String, dynamic>.from(root['result'] as Map));
    }
    candidates.add(root);

    for (final candidate in candidates) {
      if (candidate['paymentStatus'] != null ||
          candidate['bookingStatus'] != null) {
        return RazorpayVerifyResponseDto.fromJson(candidate);
      }
    }
    return null;
  }
}
