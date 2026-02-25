import 'dart:convert';

import 'package:stay_booking_frontend/model/forgot_password_request_dto.dart';
import 'package:stay_booking_frontend/model/reset_password_otp_request_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';
import 'package:http/http.dart' as http;

class PasswordService {
  PasswordService({http.Client? client}) : _client = client ?? HttpClient.instance;

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<SimpleResult> forgotPassword(ForgotPasswordRequestDto request) async {
    final response = await _client.post(
      ApiEndpoints.forgotPassword(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    final message = _parser.extractMessage(decoded);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SimpleResult(
        success: true,
        message: message ?? 'OTP sent successfully if the email is registered.',
      );
    }

    return SimpleResult(
      success: false,
      message: message ?? 'Request failed (${response.statusCode})',
    );
  }

  Future<SimpleResult> resetPasswordWithOtp(
    ResetPasswordOtpRequestDto request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.resetPassword(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    final message = _parser.extractMessage(decoded);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SimpleResult(
        success: true,
        message: message ?? 'Password reset successful.',
      );
    }

    return SimpleResult(
      success: false,
      message: message ?? 'Reset password failed (${response.statusCode})',
    );
  }
}
