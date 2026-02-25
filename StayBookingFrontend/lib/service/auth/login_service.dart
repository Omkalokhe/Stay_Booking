import 'dart:convert';

import 'package:stay_booking_frontend/model/login_request_dto.dart';
import 'package:stay_booking_frontend/model/login_response_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';
import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/service/core/http_client.dart';

class LoginService {
  LoginService() : _client = HttpClient.instance;

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<LoginResult> login(LoginRequestDto request) async {
    final response = await _client.post(
      ApiEndpoints.login(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final loginResponse = decoded is Map<String, dynamic>
          ? LoginResponseDto.fromJson(decoded)
          : LoginResponseDto(
              message: 'Login successful',
              user: null,
              tokenType: 'Bearer',
              accessToken: '',
              expiresInMinutes: 0,
            );

      return LoginResult(
        success: true,
        message: loginResponse.message,
        user: loginResponse.user,
        tokenType: loginResponse.tokenType,
        accessToken: loginResponse.accessToken,
        expiresInMinutes: loginResponse.expiresInMinutes,
      );
    }

    return LoginResult(
      success: false,
      message: _parser.extractMessage(decoded) ??
          'Login failed (${response.statusCode})${response.body.trim().isNotEmpty ? ': ${response.body}' : ''}',
      user: null,
      tokenType: '',
      accessToken: '',
      expiresInMinutes: 0,
    );
  }
}
