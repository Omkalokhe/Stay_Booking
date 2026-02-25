import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/notification_controller.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';

const AndroidNotificationChannel _highImportanceChannel =
    AndroidNotificationChannel(
      'staybooking_notifications',
      'StayBooking Notifications',
      description: 'Notifications for booking and payment updates.',
      importance: Importance.high,
    );

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _ensureLocalNotificationSetup();
  await _showLocalNotification(message);
}

class PushNotificationService extends GetxService {
  Future<PushNotificationService> init() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _ensureLocalNotificationSetup();
    await _requestPermissions();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    return this;
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);

    final title = _resolveTitle(message);
    final body = _resolveBody(message);
    if (title.isNotEmpty || body.isNotEmpty) {
      Get.snackbar(
        title.isEmpty ? 'New Notification' : title,
        body.isEmpty ? 'You have a new update.' : body,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    }

    if (Get.isRegistered<NotificationController>()) {
      final controller = Get.find<NotificationController>();
      await controller.onRealtimeEventReceived();
    }
  }

  Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    if (Get.isRegistered<NotificationController>()) {
      final controller = Get.find<NotificationController>();
      await controller.onRealtimeEventReceived();
    }
    _handleNotificationTap(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = Get.currentRoute;
    if (route != AppRoutes.notifications) {
      Get.toNamed(AppRoutes.notifications);
    }
  }
}

Future<void> _ensureLocalNotificationSetup() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);

  await _localNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if ((payload ?? '').isNotEmpty) {
        try {
          final decoded = jsonDecode(payload!);
          if (decoded is Map && Get.currentRoute != AppRoutes.notifications) {
            Get.toNamed(AppRoutes.notifications);
          }
        } catch (_) {
          // ignore invalid payload
        }
      }
    },
  );

  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_highImportanceChannel);
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final title = _resolveTitle(message);
  final body = _resolveBody(message);

  if (title.isEmpty && body.isEmpty) return;

  final androidDetails = AndroidNotificationDetails(
    _highImportanceChannel.id,
    _highImportanceChannel.name,
    channelDescription: _highImportanceChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@mipmap/ic_launcher',
  );

  await _localNotificationsPlugin.show(
    message.hashCode,
    title.isEmpty ? 'StayBooking' : title,
    body.isEmpty ? 'You have a new notification.' : body,
    NotificationDetails(android: androidDetails),
    payload: jsonEncode(message.data),
  );
}

String _resolveTitle(RemoteMessage message) {
  final notificationTitle = message.notification?.title?.trim() ?? '';
  if (notificationTitle.isNotEmpty) return notificationTitle;
  return (message.data['title']?.toString().trim() ?? '');
}

String _resolveBody(RemoteMessage message) {
  final notificationBody = message.notification?.body?.trim() ?? '';
  if (notificationBody.isNotEmpty) return notificationBody;
  return (message.data['message']?.toString().trim() ?? '');
}
