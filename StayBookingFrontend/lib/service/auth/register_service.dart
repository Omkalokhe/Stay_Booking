import 'dart:convert';

import 'package:stay_booking_frontend/model/register_user_request.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';
import 'package:http/http.dart' as http;

class RegisterService {
  RegisterService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<RegisterResult> register(RegisterUserRequest request) async {
    final response = await _client.post(
      ApiEndpoints.registerUser(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return const RegisterResult(success: true, message: 'Registration successful');
    }

    final decoded = _parser.tryParseJson(response.body);
    return RegisterResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Registration failed (${response.statusCode})',
    );
  }
}
