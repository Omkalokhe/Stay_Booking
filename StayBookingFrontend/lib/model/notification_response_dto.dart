enum NotificationType {
  bookingCreated,
  bookingUpdated,
  bookingCancelled,
  bookingStatusChanged,
  paymentSuccess,
  paymentFailed,
  unknown,
}

enum NotificationChannel { inApp, email, unknown }

enum NotificationDeliveryStatus { sent, failed, unknown }

class NotificationResponseDto {
  const NotificationResponseDto({
    required this.id,
    required this.type,
    required this.channel,
    required this.deliveryStatus,
    required this.title,
    required this.message,
    required this.referenceType,
    required this.referenceId,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
  });

  final int id;
  final NotificationType type;
  final NotificationChannel channel;
  final NotificationDeliveryStatus deliveryStatus;
  final String title;
  final String message;
  final String referenceType;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isReadEffective => isRead || readAt != null;

  NotificationResponseDto copyWith({
    int? id,
    NotificationType? type,
    NotificationChannel? channel,
    NotificationDeliveryStatus? deliveryStatus,
    String? title,
    String? message,
    String? referenceType,
    int? referenceId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationResponseDto(
      id: id ?? this.id,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      title: title ?? this.title,
      message: message ?? this.message,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory NotificationResponseDto.fromJson(Map<String, dynamic> json) {
    return NotificationResponseDto(
      id: _toInt(json['id']),
      type: _typeFromRaw(json['type']),
      channel: _channelFromRaw(json['channel']),
      deliveryStatus: _deliveryStatusFromRaw(json['deliveryStatus']),
      title: (json['title'] as String?)?.trim() ?? '',
      message: (json['message'] as String?)?.trim() ?? '',
      referenceType: (json['referenceType'] as String?)?.trim() ?? '',
      referenceId: _toNullableInt(json['referenceId']),
      isRead: _toBool(json['isRead']),
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      readAt: _toDateTime(json['readAt']),
    );
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static bool _toBool(dynamic raw) {
    if (raw is bool) return raw;
    final value = raw?.toString().toLowerCase().trim() ?? '';
    return value == 'true' || value == '1' || value == 'yes';
  }

  static DateTime? _toDateTime(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static NotificationType _typeFromRaw(dynamic raw) {
    final value = raw?.toString().toUpperCase().trim() ?? '';
    return switch (value) {
      'BOOKING_CREATED' => NotificationType.bookingCreated,
      'BOOKING_UPDATED' => NotificationType.bookingUpdated,
      'BOOKING_CANCELLED' => NotificationType.bookingCancelled,
      'BOOKING_STATUS_CHANGED' => NotificationType.bookingStatusChanged,
      'PAYMENT_SUCCESS' => NotificationType.paymentSuccess,
      'PAYMENT_FAILED' => NotificationType.paymentFailed,
      _ => NotificationType.unknown,
    };
  }

  static NotificationChannel _channelFromRaw(dynamic raw) {
    final value = raw?.toString().toUpperCase().trim() ?? '';
    return switch (value) {
      'IN_APP' => NotificationChannel.inApp,
      'EMAIL' => NotificationChannel.email,
      _ => NotificationChannel.unknown,
    };
  }

  static NotificationDeliveryStatus _deliveryStatusFromRaw(dynamic raw) {
    final value = raw?.toString().toUpperCase().trim() ?? '';
    return switch (value) {
      'SENT' => NotificationDeliveryStatus.sent,
      'FAILED' => NotificationDeliveryStatus.failed,
      _ => NotificationDeliveryStatus.unknown,
    };
  }
}
