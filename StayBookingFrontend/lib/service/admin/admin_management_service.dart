import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/model/admin/admin_user_dto.dart';
import 'package:stay_booking_frontend/model/admin/update_room_status_request.dart';
import 'package:stay_booking_frontend/model/core/paginated_response.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';
import 'package:stay_booking_frontend/service/core/service_paged_result.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';

class AdminManagementService {
  AdminManagementService({http.Client? client}) : _client = client ?? HttpClient.instance;

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<ServicePagedResult<AdminUserDto>> getUsers({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? role,
    String? status,
    String? search,
  }) async {
    final response = await _client.get(
      ApiEndpoints.adminUsers(
        page: page,
        size: size,
        sortBy: sortBy,
        direction: direction,
        role: role,
        status: status,
        search: search,
      ),
      headers: const {'Content-Type': 'application/json'},
    );

    return _toPagedResult(
      response,
      fromJson: AdminUserDto.fromJson,
      successMessage: 'Users loaded successfully.',
      fallbackMessage: 'Failed to load users',
    );
  }

  Future<SimpleResult> updateUserAccess(
    int userId,
    UpdateUserAccessRequest request,
  ) async {
    final response = await _client.put(
      ApiEndpoints.adminUpdateUserAccess(userId),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    return _toSimpleResult(
      response,
      successMessage: 'User access updated successfully.',
      fallbackMessage: 'Failed to update user access',
    );
  }

  Future<SimpleResult> deleteUser(
    int userId, {
    required bool hardDelete,
    required String deletedBy,
  }) async {
    final response = await _client.delete(
      ApiEndpoints.adminDeleteUser(
        userId,
        hardDelete: hardDelete,
        deletedBy: deletedBy,
      ),
      headers: const {'Content-Type': 'application/json'},
    );

    return _toSimpleResult(
      response,
      successMessage: hardDelete
          ? 'User permanently deleted.'
          : 'User deleted successfully.',
      fallbackMessage: 'Failed to delete user',
    );
  }

  Future<ServicePagedResult<HotelResponseDto>> getHotels({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? city,
    String? country,
    String? search,
  }) async {
    final response = await _client.get(
      ApiEndpoints.adminHotels(
        page: page,
        size: size,
        sortBy: sortBy,
        direction: direction,
        city: city,
        country: country,
        search: search,
      ),
      headers: const {'Content-Type': 'application/json'},
    );

    return _toPagedResult(
      response,
      fromJson: HotelResponseDto.fromJson,
      successMessage: 'Hotels loaded successfully.',
      fallbackMessage: 'Failed to load hotels',
    );
  }

  Future<SimpleResult> deleteHotel(int hotelId, {required String deletedBy}) async {
    final response = await _client.delete(
      ApiEndpoints.adminDeleteHotel(hotelId, deletedBy: deletedBy),
      headers: const {'Content-Type': 'application/json'},
    );

    return _toSimpleResult(
      response,
      successMessage: 'Hotel deleted successfully.',
      fallbackMessage: 'Failed to delete hotel',
    );
  }

  Future<ServicePagedResult<RoomResponseDto>> getRooms({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? hotelName,
    bool? available,
    String? search,
  }) async {
    final response = await _client.get(
      ApiEndpoints.adminRooms(
        page: page,
        size: size,
        sortBy: sortBy,
        direction: direction,
        hotelName: hotelName,
        available: available,
        search: search,
      ),
      headers: const {'Content-Type': 'application/json'},
    );

    return _toPagedResult(
      response,
      fromJson: RoomResponseDto.fromJson,
      successMessage: 'Rooms loaded successfully.',
      fallbackMessage: 'Failed to load rooms',
    );
  }

  Future<SimpleResult> updateRoomStatus(int roomId, UpdateRoomStatusRequest request) async {
    final response = await _client.put(
      ApiEndpoints.adminUpdateRoomStatus(roomId),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    return _toSimpleResult(
      response,
      successMessage: 'Room status updated successfully.',
      fallbackMessage: 'Failed to update room status',
    );
  }

  Future<SimpleResult> deleteRoom(int roomId) async {
    final response = await _client.delete(
      ApiEndpoints.adminDeleteRoom(roomId),
      headers: const {'Content-Type': 'application/json'},
    );

    return _toSimpleResult(
      response,
      successMessage: 'Room deleted successfully.',
      fallbackMessage: 'Failed to delete room',
    );
  }

  ServicePagedResult<T> _toPagedResult<T>(
    http.Response response, {
    required T Function(Map<String, dynamic> json) fromJson,
    required String successMessage,
    required String fallbackMessage,
  }) {
    final decoded = _parser.tryParseJson(response.body);
    final pageData = PaginatedResponse.fromDecoded<T>(decoded, fromJson);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ServicePagedResult<T>(
        success: true,
        message: _parser.extractMessage(decoded) ?? successMessage,
        pageData: pageData,
      );
    }

    return ServicePagedResult<T>(
      success: false,
      message: _parser.extractMessage(decoded) ?? '$fallbackMessage (${response.statusCode})',
      pageData: pageData,
    );
  }

  SimpleResult _toSimpleResult(
    http.Response response, {
    required String successMessage,
    required String fallbackMessage,
  }) {
    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SimpleResult(
        success: true,
        message: _parser.extractMessage(decoded) ?? successMessage,
      );
    }

    return SimpleResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? '$fallbackMessage (${response.statusCode})',
    );
  }
}
