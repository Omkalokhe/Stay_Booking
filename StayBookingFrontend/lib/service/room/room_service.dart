import 'package:stay_booking_frontend/model/create_room_request_dto.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/model/update_room_request_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';
import 'package:stay_booking_frontend/service/core/service_results.dart';
import 'package:http/http.dart' as http;

class RoomService {
  RoomService({http.Client? client}) : _client = client ?? HttpClient.instance;

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<HotelListResult<RoomResponseDto>> getRooms({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? hotelName,
    bool? available,
    String? search,
  }) async {
    final response = await _client.get(
      ApiEndpoints.getRooms(
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

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractListPayload(decoded);
      return HotelListResult<RoomResponseDto>(
        success: true,
        message:
            _parser.extractMessage(decoded) ?? 'Rooms loaded successfully.',
        items: _parseRooms(data.itemsRaw),
        page: data.page,
        totalPages: data.totalPages,
        totalElements: data.totalElements,
      );
    }

    return HotelListResult<RoomResponseDto>(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to load rooms (${response.statusCode})',
      items: const [],
      page: page,
      totalPages: 1,
      totalElements: 0,
    );
  }

  Future<HotelActionResult<RoomResponseDto>> getRoomById(int id) async {
    final response = await _client.get(
      ApiEndpoints.getRoomById(id),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    final room = _extractRoom(decoded);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<RoomResponseDto>(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Room loaded successfully.',
        item: room,
      );
    }

    return HotelActionResult<RoomResponseDto>(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to load room (${response.statusCode})',
      item: room,
    );
  }

  Future<HotelActionResult<RoomResponseDto>> createRoom(
    CreateRoomRequestDto request,
  ) async {
    final multipartRequest =
        http.MultipartRequest('POST', ApiEndpoints.createRoom())
          ..fields['hotelId'] = '${request.hotelId}'
          ..fields['hotelid'] = '${request.hotelId}'
          ..fields['roomType'] = request.roomType
          ..fields['description'] = request.description
          ..fields['price'] = '${request.price}'
          ..fields['available'] = '${request.available}'
          ..fields['createdby'] = request.createdBy
          ..fields['createdBy'] = request.createdBy;

    for (final file in request.photoFiles) {
      final multipart = await _toMultipartFile(
        fileName: file.fileName,
        path: file.path,
        bytes: file.bytes,
      );
      if (multipart != null) {
        multipartRequest.files.add(multipart);
      }
    }

    return _sendMultipart(
      multipartRequest,
      successMessage: 'Room created successfully.',
    );
  }

  Future<HotelActionResult<RoomResponseDto>> updateRoom(
    int id,
    UpdateRoomRequestDto request,
  ) async {
    final multipartRequest =
        http.MultipartRequest('PUT', ApiEndpoints.updateRoom(id))
          ..fields['hotelId'] = '${request.hotelId}'
          ..fields['hotelid'] = '${request.hotelId}'
          ..fields['roomType'] = request.roomType
          ..fields['description'] = request.description
          ..fields['price'] = '${request.price}'
          ..fields['available'] = '${request.available}'
          ..fields['updatedby'] = request.updatedBy
          ..fields['updatedBy'] = request.updatedBy
          ..fields['replacePhotos'] = '${request.replacePhotos}';

    for (final file in request.photoFiles) {
      final multipart = await _toMultipartFile(
        fileName: file.fileName,
        path: file.path,
        bytes: file.bytes,
      );
      if (multipart != null) {
        multipartRequest.files.add(multipart);
      }
    }

    return _sendMultipart(
      multipartRequest,
      successMessage: 'Room updated successfully.',
    );
  }

  Future<SimpleResult> deleteRoom(int id) async {
    final response = await _client.delete(
      ApiEndpoints.deleteRoom(id),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SimpleResult(
        success: true,
        message:
            _parser.extractMessage(decoded) ?? 'Room deleted successfully.',
      );
    }

    return SimpleResult(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to delete room (${response.statusCode})',
    );
  }

  Future<HotelActionResult<RoomResponseDto>> _sendMultipart(
    http.MultipartRequest request, {
    required String successMessage,
  }) async {
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = _parser.tryParseJson(response.body);
    final room = _extractRoom(decoded);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return HotelActionResult<RoomResponseDto>(
        success: true,
        message: _parser.extractMessage(decoded) ?? successMessage,
        item: room,
      );
    }

    if (response.statusCode == 413) {
      return HotelActionResult<RoomResponseDto>(
        success: false,
        message:
            'Upload is too large. Please use fewer/smaller photos (<= 2 MB each, <= 8 MB total).',
        item: room,
      );
    }

    return HotelActionResult<RoomResponseDto>(
      success: false,
      message: _parser.extractMessage(decoded) ?? _extractRawMessage(response),
      item: room,
    );
  }

  List<RoomResponseDto> _parseRooms(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => RoomResponseDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }
    return const [];
  }

  RoomResponseDto? _extractRoom(dynamic decoded) {
    if (decoded is Map) {
      if (decoded['room'] is Map) {
        return RoomResponseDto.fromJson(
          Map<String, dynamic>.from(decoded['room'] as Map),
        );
      }
      if (decoded['data'] is Map) {
        return RoomResponseDto.fromJson(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      }
      if (decoded['id'] != null && decoded['roomType'] != null) {
        return RoomResponseDto.fromJson(Map<String, dynamic>.from(decoded));
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

  String _extractRawMessage(http.Response response) {
    final raw = response.body.trim();
    if (raw.isEmpty) return 'Request failed (${response.statusCode})';
    final compact = raw.replaceAll(RegExp(r'\s+'), ' ');
    final maxLen = 180;
    final clipped = compact.length > maxLen
        ? '${compact.substring(0, maxLen)}...'
        : compact;
    return 'Request failed (${response.statusCode}): $clipped';
  }

  Future<http.MultipartFile?> _toMultipartFile({
    required String fileName,
    String? path,
    List<int>? bytes,
  }) async {
    if (bytes != null && bytes.isNotEmpty) {
      return http.MultipartFile.fromBytes('photos', bytes, filename: fileName);
    }

    final safePath = (path ?? '').trim();
    if (safePath.isEmpty) return null;
    return http.MultipartFile.fromPath('photos', safePath);
  }

  static String roomPhotoUrl(String rawPhoto) {
    final photo = rawPhoto.trim();
    if (photo.isEmpty) return '';

    if (photo.startsWith('/api/rooms/photos/') ||
        photo.startsWith('api/rooms/photos/') ||
        photo.startsWith('/api/') ||
        photo.startsWith('api/')) {
      return ApiEndpoints.resolveUrl(photo);
    }

    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }
    return ApiEndpoints.getRoomPhoto(photo).toString();
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
