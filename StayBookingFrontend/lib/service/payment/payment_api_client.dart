import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/model/payment_models.dart';

typedef AccessTokenProvider = Future<String?> Function();

class PaymentApiClient {
  PaymentApiClient({
    required String baseUrl,
    required AccessTokenProvider accessTokenProvider,
    http.Client? client,
    Duration timeout = const Duration(seconds: 20),
  }) : _baseUrl = baseUrl.trim().replaceAll(RegExp(r'/$'), ''),
       _accessTokenProvider = accessTokenProvider,
       _client = client ?? http.Client(),
       _timeout = timeout;

  final String _baseUrl;
  final AccessTokenProvider _accessTokenProvider;
  final http.Client _client;
  final Duration _timeout;

  Future<RazorpayOrderResponse> createOrder({
    required CreateRazorpayOrderRequest request,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/payments/razorpay/orders');
    _log('create_order_request', {'bookingId': request.bookingId});
    final response = await _send(
      method: 'POST',
      uri: uri,
      body: request.toJson(),
    );

    final payload = _decodeBody(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return RazorpayOrderResponse.fromJson(_asJsonMap(payload));
    }

    throw _errorFromResponse(response, payload);
  }

  Future<VerifyRazorpayPaymentResponse> verifyPayment({
    required VerifyRazorpayPaymentRequest request,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/payments/razorpay/verify');
    _log('verify_request', {'bookingId': request.bookingId});
    final response = await _send(
      method: 'POST',
      uri: uri,
      body: request.toJson(),
    );

    final payload = _decodeBody(response.body);
    if (response.statusCode == 200) {
      return VerifyRazorpayPaymentResponse.fromJson(_asJsonMap(payload));
    }

    throw _errorFromResponse(response, payload);
  }

  Future<RazorpayPaymentStatusResponse> getPaymentStatus({
    required int bookingId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/payments/razorpay/status').replace(
      queryParameters: {'bookingId': '$bookingId'},
    );
    _log('status_request', {'bookingId': bookingId});
    final response = await _send(method: 'GET', uri: uri);

    final payload = _decodeBody(response.body);
    if (response.statusCode == 200) {
      return RazorpayPaymentStatusResponse.fromJson(_asJsonMap(payload));
    }

    throw _errorFromResponse(response, payload);
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _headers();
      late final Future<http.Response> task;

      switch (method) {
        case 'POST':
          task = _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        case 'GET':
          task = _client.get(uri, headers: headers);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
      return await task.timeout(_timeout);
    } on TimeoutException {
      throw const PaymentApiException(
        message: 'Network timeout while calling payment API.',
        isTransient: true,
      );
    } on PaymentApiException {
      rethrow;
    } catch (e) {
      throw PaymentApiException(
        message: 'Network error while calling payment API: $e',
        isTransient: true,
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = (await _accessTokenProvider())?.trim() ?? '';
    return <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  PaymentApiException _errorFromResponse(http.Response response, dynamic payload) {
    final message = extractBackendMessage(
      payload,
      fallback: 'Payment API failed (${response.statusCode}).',
    );
    final statusCode = response.statusCode;
    final transient =
        statusCode >= 500 || statusCode == 408 || statusCode == 429;
    _log('api_error', {
      'statusCode': statusCode,
      'transient': transient,
      'message': message,
    });
    return PaymentApiException(
      message: message,
      statusCode: statusCode,
      isTransient: transient,
    );
  }

  dynamic _decodeBody(String body) {
    final raw = body.trim();
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic payload) {
    if (payload is Map) return Map<String, dynamic>.from(payload);
    throw PaymentApiException(
      message: extractBackendMessage(
        payload,
        fallback: 'Invalid response format from payment server.',
      ),
      isTransient: false,
    );
  }

  void _log(String event, Map<String, Object?> data) {
    if (!kDebugMode) return;
    final details = data.entries
        .map((e) => '${e.key}=${e.value ?? 'null'}')
        .join(', ');
    debugPrint('[PaymentApi] $event${details.isEmpty ? '' : ' | $details'}');
  }
}
