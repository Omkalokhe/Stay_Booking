import 'dart:convert';

class ServiceParser {
  dynamic tryParseJson(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? extractMessage(dynamic decoded) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final dynamic message =
          map['message'] ?? map['error'] ?? map['detail'] ?? map['details'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final dynamic errors = map['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is String && first.trim().isNotEmpty) return first;
        if (first is Map) {
          final errorMap = Map<String, dynamic>.from(first);
          final dynamic errorMsg =
              errorMap['defaultMessage'] ?? errorMap['message'] ?? errorMap['error'];
          if (errorMsg is String && errorMsg.trim().isNotEmpty) return errorMsg;
        }
      }
      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        if (firstValue is String && firstValue.trim().isNotEmpty) {
          return firstValue;
        }
        if (firstValue is List && firstValue.isNotEmpty) {
          final first = firstValue.first;
          if (first is String && first.trim().isNotEmpty) return first;
        }
      }
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded;
    }
    return null;
  }

  Map<String, dynamic>? extractUserMap(dynamic decoded) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final user = decoded['user'];
      if (user is Map) return Map<String, dynamic>.from(user);

      final data = decoded['data'];
      if (data is Map) return Map<String, dynamic>.from(data);

      return map;
    }
    return null;
  }
}
