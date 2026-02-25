import 'package:flutter_test/flutter_test.dart';
import 'package:stay_booking_frontend/model/notification_response_dto.dart';

void main() {
  group('NotificationResponseDto', () {
    test('parses known enum fields and timestamps', () {
      final dto = NotificationResponseDto.fromJson({
        'id': 42,
        'type': 'PAYMENT_SUCCESS',
        'channel': 'IN_APP',
        'deliveryStatus': 'SENT',
        'title': 'Payment received',
        'message': 'Your booking payment was successful.',
        'referenceType': 'BOOKING',
        'referenceId': 12,
        'isRead': false,
        'createdAt': '2026-02-25T10:30:00Z',
        'readAt': null,
      });

      expect(dto.id, 42);
      expect(dto.type, NotificationType.paymentSuccess);
      expect(dto.channel, NotificationChannel.inApp);
      expect(dto.deliveryStatus, NotificationDeliveryStatus.sent);
      expect(dto.referenceId, 12);
      expect(dto.isRead, isFalse);
      expect(dto.createdAt.isAfter(DateTime(2026, 2, 25)), isTrue);
      expect(dto.readAt, isNull);
    });

    test('falls back to unknown enum values safely', () {
      final dto = NotificationResponseDto.fromJson({
        'id': '7',
        'type': 'SOMETHING_NEW',
        'channel': 'PUSH',
        'deliveryStatus': 'QUEUED',
        'title': 'x',
        'message': 'y',
        'referenceType': 'BOOKING',
        'isRead': 'true',
        'createdAt': 'invalid-date',
      });

      expect(dto.id, 7);
      expect(dto.type, NotificationType.unknown);
      expect(dto.channel, NotificationChannel.unknown);
      expect(dto.deliveryStatus, NotificationDeliveryStatus.unknown);
      expect(dto.isRead, isTrue);
    });
  });
}
