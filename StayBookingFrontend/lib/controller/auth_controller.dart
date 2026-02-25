import 'dart:async';

import 'package:get/get.dart';
import 'package:stay_booking_frontend/model/auth_session.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/auth/auth_storage_service.dart';

class AuthController extends GetxService {
  AuthController({AuthStorageService? storageService})
    : _storageService = storageService ?? AuthStorageService();

  final AuthStorageService _storageService;
  final Rxn<AuthSession> session = Rxn<AuthSession>();

  Timer? _expiryTimer;
  bool _isHandlingUnauthorized = false;
  bool _forbiddenToastVisible = false;

  bool get isAuthenticated =>
      session.value != null && !(session.value?.isExpired ?? true);

  Map<String, dynamic> get currentUser =>
      session.value?.user ?? <String, dynamic>{};

  String get currentRole => session.value?.role ?? '';

  Future<AuthController> init() async {
    await restoreSession();
    return this;
  }

  Future<void> restoreSession() async {
    final restored = await _storageService.read();
    if (restored == null || restored.accessToken.trim().isEmpty) {
      await clearSession();
      return;
    }
    if (restored.isExpired) {
      await logout(
        redirectToLogin: false,
        showMessage: false,
      );
      return;
    }

    session.value = restored;
    _scheduleExpiry(restored.expiresAt);
  }

  Future<void> startSession({
    required String tokenType,
    required String accessToken,
    required int expiresInMinutes,
    required Map<String, dynamic> user,
  }) async {
    final safeMinutes = expiresInMinutes <= 0 ? 1 : expiresInMinutes;
    final authSession = AuthSession(
      tokenType: tokenType.trim().isEmpty ? 'Bearer' : tokenType.trim(),
      accessToken: accessToken.trim(),
      expiresInMinutes: safeMinutes,
      expiresAt: DateTime.now().add(Duration(minutes: safeMinutes)),
      user: Map<String, dynamic>.from(user),
    );

    session.value = authSession;
    await _storageService.write(authSession);
    _scheduleExpiry(authSession.expiresAt);
  }

  Future<void> logout({
    bool redirectToLogin = true,
    bool showMessage = false,
    String message = 'Session expired. Please sign in again.',
  }) async {
    await clearSession();
    if (showMessage) {
      Get.snackbar(
        'Session Expired',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    if (redirectToLogin) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> clearSession() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    session.value = null;
    await _storageService.clear();
  }

  Future<void> handleUnauthorized() async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;
    try {
      await logout(showMessage: true, redirectToLogin: true);
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  void handleForbidden() {
    if (_forbiddenToastVisible) return;
    _forbiddenToastVisible = true;
    Get.snackbar(
      'Not Authorized',
      'You are not authorized to perform this action.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    Future<void>.delayed(const Duration(seconds: 3), () {
      _forbiddenToastVisible = false;
    });
  }

  void _scheduleExpiry(DateTime expiresAt) {
    _expiryTimer?.cancel();
    final delay = expiresAt.difference(DateTime.now());
    if (delay <= Duration.zero) {
      unawaited(logout(showMessage: true));
      return;
    }
    _expiryTimer = Timer(delay, () {
      unawaited(logout(showMessage: true));
    });
  }
}
