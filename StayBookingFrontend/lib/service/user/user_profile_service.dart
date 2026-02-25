import 'dart:convert';

import 'package:stay_booking_frontend/model/update_user_request_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';
import 'package:http/http.dart' as http;

class UserProfileService {
  UserProfileService({http.Client? client}) : _client = client ?? HttpClient.instance;

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<UserDetailsResult> getUserByEmail(String email) async {
    final response = await _client.get(
      ApiEndpoints.getUserByEmail(email),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = _parser.extractUserMap(decoded);
      if (user != null) {
        return UserDetailsResult(
          success: true,
          message: _parser.extractMessage(decoded) ?? 'Profile loaded successfully.',
          user: user,
        );
      }
      return const UserDetailsResult(
        success: false,
        message: 'Profile data was empty.',
        user: null,
      );
    }

    return UserDetailsResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to load profile (${response.statusCode})',
      user: null,
    );
  }

  Future<UserDetailsResult> updateUser(
    int id,
    UpdateUserRequestDto request,
  ) async {
    final response = await _client.put(
      ApiEndpoints.updateUser(id),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return UserDetailsResult(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Profile updated successfully.',
        user: _parser.extractUserMap(decoded),
      );
    }

    return UserDetailsResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Profile update failed (${response.statusCode})',
      user: _parser.extractUserMap(decoded),
    );
  }

  Future<SimpleResult> deleteUser(int id) async {
    final response = await _client.delete(
      ApiEndpoints.deleteUser(id),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SimpleResult(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Profile deleted successfully.',
      );
    }

    return SimpleResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to delete profile (${response.statusCode})',
    );
  }
}
