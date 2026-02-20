import 'dart:convert';

import 'package:stay_booking_frontend/model/create_hotel_request_dto.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/model/update_hotel_request_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';
import 'package:http/http.dart' as http;

class HotelService {
  HotelService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<HotelListResult<HotelResponseDto>> getHotels({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? city,
    String? country,
    String? search,
  }) async {
    final response = await _client.get(
      ApiEndpoints.getHotels(
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

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractListPayload(decoded);
      return HotelListResult<HotelResponseDto>(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Hotels loaded successfully.',
        items: _parseHotels(data.itemsRaw),
        page: data.page,
        totalPages: data.totalPages,
        totalElements: data.totalElements,
      );
    }

    return HotelListResult<HotelResponseDto>(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to load hotels (${response.statusCode})',
      items: const [],
      page: page,
      totalPages: 1,
      totalElements: 0,
    );
  }

  Future<HotelActionResult<HotelResponseDto>> createHotel(
    CreateHotelRequestDto request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.createHotel(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    final hotel = _extractHotel(decoded);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<HotelResponseDto>(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Hotel created successfully.',
        item: hotel,
      );
    }

    return HotelActionResult<HotelResponseDto>(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to create hotel (${response.statusCode})',
      item: hotel,
    );
  }

  Future<HotelActionResult<HotelResponseDto>> getHotelById(int id) async {
    final response = await _client.get(
      ApiEndpoints.getHotelById(id),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    final hotel = _extractHotel(decoded);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<HotelResponseDto>(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Hotel loaded successfully.',
        item: hotel,
      );
    }

    return HotelActionResult<HotelResponseDto>(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to load hotel (${response.statusCode})',
      item: hotel,
    );
  }

  Future<HotelActionResult<HotelResponseDto>> updateHotel(
    int id,
    UpdateHotelRequestDto request,
  ) async {
    final response = await _client.put(
      ApiEndpoints.updateHotel(id),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final decoded = _parser.tryParseJson(response.body);
    final hotel = _extractHotel(decoded);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<HotelResponseDto>(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Hotel updated successfully.',
        item: hotel,
      );
    }

    return HotelActionResult<HotelResponseDto>(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to update hotel (${response.statusCode})',
      item: hotel,
    );
  }

  Future<SimpleResult> deleteHotel(int id, {String? deletedBy}) async {
    final response = await _client.delete(
      ApiEndpoints.deleteHotel(id, deletedBy: deletedBy),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SimpleResult(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Hotel deleted successfully.',
      );
    }

    return SimpleResult(
      success: false,
      message: _parser.extractMessage(decoded) ?? 'Failed to delete hotel (${response.statusCode})',
    );
  }

  List<HotelResponseDto> _parseHotels(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => HotelResponseDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }
    return const [];
  }

  HotelResponseDto? _extractHotel(dynamic decoded) {
    if (decoded is Map) {
      if (decoded['hotel'] is Map) {
        return HotelResponseDto.fromJson(
          Map<String, dynamic>.from(decoded['hotel'] as Map),
        );
      }
      if (decoded['data'] is Map) {
        return HotelResponseDto.fromJson(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      }
      if (decoded['id'] != null && decoded['name'] != null) {
        return HotelResponseDto.fromJson(Map<String, dynamic>.from(decoded));
      }
    }
    return null;
  }

  _ListPayload _extractListPayload(dynamic decoded) {
    if (decoded is List) {
      return _ListPayload(
        itemsRaw: decoded,
        page: 0,
        totalPages: 1,
        totalElements: decoded.length,
      );
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map['content'] is List) {
        return _ListPayload(
          itemsRaw: map['content'],
          page: _toInt(map['number']),
          totalPages: _toInt(map['totalPages'], defaultValue: 1),
          totalElements: _toInt(map['totalElements']),
        );
      }
      if (map['data'] is Map) {
        final dataMap = Map<String, dynamic>.from(map['data'] as Map);
        if (dataMap['content'] is List) {
          return _ListPayload(
            itemsRaw: dataMap['content'],
            page: _toInt(dataMap['number']),
            totalPages: _toInt(dataMap['totalPages'], defaultValue: 1),
            totalElements: _toInt(dataMap['totalElements']),
          );
        }
      }
      if (map['data'] is List) {
        final list = map['data'] as List;
        return _ListPayload(
          itemsRaw: list,
          page: 0,
          totalPages: 1,
          totalElements: list.length,
        );
      }
    }

    return const _ListPayload(
      itemsRaw: [],
      page: 0,
      totalPages: 1,
      totalElements: 0,
    );
  }

  int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }
}

class _ListPayload {
  const _ListPayload({
    required this.itemsRaw,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final dynamic itemsRaw;
  final int page;
  final int totalPages;
  final int totalElements;
}
