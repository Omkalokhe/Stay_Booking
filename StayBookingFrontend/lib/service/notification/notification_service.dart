import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/model/core/paginated_response.dart';
import 'package:stay_booking_frontend/model/notification_response_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';
import 'package:stay_booking_frontend/service/core/service_parser.dart';

class NotificationService {
  NotificationService({http.Client? client})
    : _client = client ?? HttpClient.instance;

  final http.Client _client;
  final ServiceParser _parser = ServiceParser();

  Future<NotificationPageResult> fetchNotifications({
    required int page,
    required int size,
    required bool unreadOnly,
  }) async {
    final response = await _client.get(
      ApiEndpoints.getNotifications(
        page: page,
        size: size,
        unreadOnly: unreadOnly,
      ),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    final pageData = PaginatedResponse.fromDecoded<NotificationResponseDto>(
      decoded,
      NotificationResponseDto.fromJson,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return NotificationPageResult(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Notifications loaded.',
        pageData: pageData,
      );
    }

    return NotificationPageResult(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to load notifications (${response.statusCode})',
      pageData: pageData,
    );
  }

  Future<UnreadCountResult> fetchUnreadCount() async {
    final response = await _client.get(
      ApiEndpoints.getUnreadNotificationCount(),
      headers: const {'Content-Type': 'application/json'},
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return UnreadCountResult(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Unread count loaded.',
        unreadCount: _extractUnreadCount(decoded),
      );
    }

    return UnreadCountResult(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to load unread count (${response.statusCode})',
      unreadCount: 0,
    );
  }

  Future<NotificationActionResult> markAsRead(int id) async {
    final response = await _client.put(
      ApiEndpoints.markNotificationAsRead(id),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{}),
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final item = _extractNotification(decoded);
      return NotificationActionResult(
        success: true,
        message: _parser.extractMessage(decoded) ?? 'Notification marked read.',
        item: item,
      );
    }

    return NotificationActionResult(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to mark notification as read (${response.statusCode})',
      item: null,
    );
  }

  Future<MarkAllAsReadResult> markAllAsRead() async {
    final response = await _client.put(
      ApiEndpoints.markAllNotificationsAsRead(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{}),
    );

    final decoded = _parser.tryParseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return MarkAllAsReadResult(
        success: true,
        message:
            _parser.extractMessage(decoded) ??
            'All notifications marked as read.',
        updatedCount: _extractUpdatedCount(decoded),
      );
    }

    return MarkAllAsReadResult(
      success: false,
      message:
          _parser.extractMessage(decoded) ??
          'Failed to mark all notifications as read (${response.statusCode})',
      updatedCount: 0,
    );
  }

  int _extractUnreadCount(dynamic decoded) {
    if (decoded is Map) {
      final raw = decoded['unreadCount'];
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  int _extractUpdatedCount(dynamic decoded) {
    if (decoded is Map) {
      final raw = decoded['updatedCount'];
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  NotificationResponseDto? _extractNotification(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['id'] != null && decoded['type'] != null) {
        return NotificationResponseDto.fromJson(decoded);
      }
      if (decoded['data'] is Map) {
        return NotificationResponseDto.fromJson(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      }
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map['id'] != null && map['type'] != null) {
        return NotificationResponseDto.fromJson(map);
      }
    }
    return null;
  }
}

class NotificationPageResult {
  const NotificationPageResult({
    required this.success,
    required this.message,
    required this.pageData,
  });

  final bool success;
  final String message;
  final PaginatedResponse<NotificationResponseDto> pageData;
}

class UnreadCountResult {
  const UnreadCountResult({
    required this.success,
    required this.message,
    required this.unreadCount,
  });

  final bool success;
  final String message;
  final int unreadCount;
}

class NotificationActionResult {
  const NotificationActionResult({
    required this.success,
    required this.message,
    required this.item,
  });

  final bool success;
  final String message;
  final NotificationResponseDto? item;
}

class MarkAllAsReadResult {
  const MarkAllAsReadResult({
    required this.success,
    required this.message,
    required this.updatedCount,
  });

  final bool success;
  final String message;
  final int updatedCount;
}
