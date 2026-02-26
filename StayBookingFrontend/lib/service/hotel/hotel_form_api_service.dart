import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/model/core/api_error.dart';
import 'package:stay_booking_frontend/model/core/result.dart';
import 'package:stay_booking_frontend/model/hotel_form/create_hotel_request.dart';
import 'package:stay_booking_frontend/model/hotel_form/hotel_model.dart';
import 'package:stay_booking_frontend/model/hotel_form/update_hotel_request.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_form_multipart_builder.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';

abstract class IHotelApiService {
  Future<Result<HotelModel>> createHotel(CreateHotelRequest req);
  Future<Result<HotelModel>> updateHotel(int id, UpdateHotelRequest req);
  Future<Result<HotelModel>> getHotelById(int id);
}

class HotelApiService implements IHotelApiService {
  HotelApiService({http.Client? client}) : _client = client ?? HttpClient.instance;

  final http.Client _client;

  @override
  Future<Result<HotelModel>> createHotel(CreateHotelRequest req) async {
    try {
      final payload = await buildCreateHotelMultipartPayload(req);
      final request = http.MultipartRequest('POST', ApiEndpoints.createHotel())
        ..fields.addAll(payload.fields)
        ..files.addAll(payload.files);
      final response = await _client.send(request);
      final parsed = await _parseJsonFromStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Result.failure(_errorFromPayload(parsed, response.statusCode));
      }
      final hotel = _parseHotelPayload(parsed);
      if (hotel == null) {
        return Result.failure(
          const ApiError(message: 'Hotel created but response was invalid.'),
        );
      }
      return Result.success(hotel);
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Unable to create hotel.'),
      );
    }
  }

  @override
  Future<Result<HotelModel>> updateHotel(int id, UpdateHotelRequest req) async {
    try {
      final payload = await buildUpdateHotelMultipartPayload(req);
      final request = http.MultipartRequest('PUT', ApiEndpoints.updateHotel(id))
        ..fields.addAll(payload.fields)
        ..files.addAll(payload.files);
      final response = await _client.send(request);
      final parsed = await _parseJsonFromStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Result.failure(_errorFromPayload(parsed, response.statusCode));
      }
      final hotel = _parseHotelPayload(parsed);
      if (hotel == null) {
        return Result.failure(
          const ApiError(message: 'Hotel updated but response was invalid.'),
        );
      }
      return Result.success(hotel);
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Unable to update hotel.'),
      );
    }
  }

  @override
  Future<Result<HotelModel>> getHotelById(int id) async {
    try {
      final response = await _client.get(
        ApiEndpoints.getHotelById(id),
        headers: const {'Content-Type': 'application/json'},
      );
      final parsed = _tryParseJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Result.failure(_errorFromPayload(parsed, response.statusCode));
      }
      final hotel = _parseHotelPayload(parsed);
      if (hotel == null) {
        return Result.failure(
          const ApiError(message: 'Hotel data not found in response.'),
        );
      }
      return Result.success(hotel);
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Unable to load hotel details.'),
      );
    }
  }

  HotelModel? _parseHotelPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['hotel'] is Map) {
        return HotelModel.fromJson(Map<String, dynamic>.from(data['hotel'] as Map));
      }
      if (data['data'] is Map) {
        return HotelModel.fromJson(Map<String, dynamic>.from(data['data'] as Map));
      }
      if (data['id'] != null) {
        return HotelModel.fromJson(data);
      }
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['id'] != null) {
        return HotelModel.fromJson(map);
      }
    }
    return null;
  }

  Future<dynamic> _parseJsonFromStream(http.StreamedResponse response) async {
    final raw = await response.stream.bytesToString();
    return _tryParseJson(raw);
  }

  dynamic _tryParseJson(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  ApiError _errorFromPayload(dynamic payload, int statusCode) {
    if (payload is Map) {
      final message = (payload['message'] as String?)?.trim();
      if (message != null && message.isNotEmpty) {
        return ApiError(message: message, statusCode: statusCode);
      }
    }
    return ApiError(
      message: 'Request failed ($statusCode).',
      statusCode: statusCode,
    );
  }
}

