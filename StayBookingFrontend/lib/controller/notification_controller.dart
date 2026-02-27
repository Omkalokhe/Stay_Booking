import 'dart:async';

import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';
import 'package:stay_booking_frontend/model/auth_session.dart';
import 'package:stay_booking_frontend/model/core/paginated_response.dart';
import 'package:stay_booking_frontend/model/notification_response_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/booking/booking_service.dart';
import 'package:stay_booking_frontend/service/notification/notification_service.dart';

class NotificationController extends GetxController {
  NotificationController({
    NotificationService? notificationService,
    AuthController? authController,
    BookingService? bookingService,
  }) : _notificationService = notificationService ?? NotificationService(),
       _authController = authController ?? Get.find<AuthController>(),
       _bookingService = bookingService ?? BookingService();

  final NotificationService _notificationService;
  final AuthController _authController;
  final BookingService _bookingService;

  final notifications = <NotificationResponseDto>[].obs;
  final unreadCount = 0.obs;
  final unreadOnly = true.obs;
  final bookingContextByReferenceId = <int, BookingNotificationContext>{}.obs;

  final page = 0.obs;
  final size = 20.obs;
  final totalPages = 1.obs;
  final totalElements = 0.obs;
  final isFirstPage = true.obs;
  final isLastPage = true.obs;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isRefreshing = false.obs;
  final isMarkingAll = false.obs;
  final errorMessage = ''.obs;
  final _loadingContextByReferenceId = <int>{};
  bool _isFetchingUnreadCount = false;
  static const Duration _pollInterval = Duration(seconds: 5);
  Timer? _pollingTimer;
  Worker? _sessionWorker;

  bool get isEmpty =>
      !isLoading.value && errorMessage.value.isEmpty && notifications.isEmpty;

  @override
  void onInit() {
    super.onInit();
    if (_authController.isAuthenticated) {
      fetchUnreadCount();
      _startPolling();
    }
    _sessionWorker = ever<AuthSession?>(_authController.session, (session) {
      if (session == null) {
        _stopPolling();
        clearState();
      } else {
        fetchUnreadCount();
        _startPolling();
      }
    });
  }

  @override
  void onClose() {
    _stopPolling();
    _sessionWorker?.dispose();
    super.onClose();
  }

  Future<void> loadFirstPage({bool showLoader = true}) async {
    if (!_authController.isAuthenticated) return;

    if (showLoader) {
      isLoading.value = true;
    }
    errorMessage.value = '';
    page.value = 0;

    final result = await _notificationService.fetchNotifications(
      page: page.value,
      size: size.value,
      unreadOnly: unreadOnly.value,
    );

    if (result.success) {
      final content = unreadOnly.value
          ? result.pageData.content
                .where((e) => !e.isReadEffective)
                .toList(growable: false)
          : result.pageData.content;
      notifications.assignAll(content);
      _syncPageMeta(result.pageData);
      _hydrateBookingContexts(content);
    } else {
      errorMessage.value = result.message;
    }

    isLoading.value = false;
  }

  Future<void> refreshList() async {
    if (!_authController.isAuthenticated) return;

    isRefreshing.value = true;
    await loadFirstPage(showLoader: false);
    await fetchUnreadCount();
    isRefreshing.value = false;
  }

  Future<void> loadNextPage() async {
    if (!_authController.isAuthenticated) return;
    if (isLastPage.value || isLoadingMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    final nextPage = page.value + 1;
    final result = await _notificationService.fetchNotifications(
      page: nextPage,
      size: size.value,
      unreadOnly: unreadOnly.value,
    );

    if (result.success) {
      final content = unreadOnly.value
          ? result.pageData.content
                .where((e) => !e.isReadEffective)
                .toList(growable: false)
          : result.pageData.content;
      notifications.addAll(content);
      _syncPageMeta(result.pageData);
      _hydrateBookingContexts(content);
    } else {
      errorMessage.value = result.message;
    }
    isLoadingMore.value = false;
  }

  Future<void> setUnreadOnly(bool value) async {
    if (unreadOnly.value == value) return;
    unreadOnly.value = value;
    await loadFirstPage();
  }

  Future<void> fetchUnreadCount() async {
    if (_isFetchingUnreadCount) return;
    if (!_authController.isAuthenticated) {
      unreadCount.value = 0;
      return;
    }
    _isFetchingUnreadCount = true;
    try {
      final result = await _notificationService.fetchUnreadCount();
      if (result.success) {
        unreadCount.value = result.unreadCount < 0 ? 0 : result.unreadCount;
      }
    } catch (_) {
      // Keep silent to avoid interrupting UI; next poll/push will retry.
    } finally {
      _isFetchingUnreadCount = false;
    }
  }

  Future<void> markAsRead(NotificationResponseDto item) async {
    if (!_authController.isAuthenticated || item.isReadEffective) return;
    final index = notifications.indexWhere((e) => e.id == item.id);
    if (index < 0) return;

    final before = notifications[index];
    notifications[index] = before.copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
    if (unreadCount.value > 0) unreadCount.value -= 1;

    final result = await _notificationService.markAsRead(item.id);
    if (!result.success) {
      notifications[index] = before;
      unreadCount.value += 1;
      Get.snackbar(
        'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (result.item != null) {
      notifications[index] = result.item!.copyWith(
        isRead: true,
        readAt: result.item!.readAt ?? DateTime.now(),
      );
    }
    if (unreadOnly.value) {
      notifications.removeWhere((e) => e.id == item.id);
    }
  }

  Future<void> markAllAsRead() async {
    if (!_authController.isAuthenticated || isMarkingAll.value) return;
    if (notifications.isEmpty) return;

    isMarkingAll.value = true;
    final snapshot = List<NotificationResponseDto>.from(notifications);
    final now = DateTime.now();
    if (unreadOnly.value) {
      notifications.clear();
    } else {
      notifications.assignAll(
        notifications.map((e) => e.copyWith(isRead: true, readAt: now)),
      );
    }
    unreadCount.value = 0;

    final result = await _notificationService.markAllAsRead();
    isMarkingAll.value = false;

    if (!result.success) {
      notifications.assignAll(snapshot);
      await fetchUnreadCount();
      Get.snackbar(
        'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await loadFirstPage(showLoader: false);
    await fetchUnreadCount();
    Get.snackbar(
      'Success',
      result.updatedCount > 0
          ? '${result.updatedCount} notifications marked as read.'
          : result.message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> refreshOnAppResume() async {
    if (!_authController.isAuthenticated) return;
    await onRealtimeEventReceived();
  }

  Future<void> onRealtimeEventReceived() async {
    if (!_authController.isAuthenticated) return;
    await fetchUnreadCount();
    if (Get.currentRoute == AppRoutes.notifications) {
      await loadFirstPage(showLoader: false);
    }
  }

  String bookingContextText(NotificationResponseDto item) {
    final refId = item.referenceId;
    if (refId == null) return '';
    final context = bookingContextByReferenceId[refId];
    if (context == null) return '';
    final room = context.roomType.trim();
    final hotel = context.hotelName.trim();
    if (room.isEmpty && hotel.isEmpty) return '';
    if (room.isEmpty) return hotel;
    if (hotel.isEmpty) return room;
    return '$room • $hotel';
  }

  void clearState() {
    notifications.clear();
    unreadCount.value = 0;
    bookingContextByReferenceId.clear();
    _loadingContextByReferenceId.clear();
    unreadOnly.value = true;
    page.value = 0;
    totalPages.value = 1;
    totalElements.value = 0;
    isFirstPage.value = true;
    isLastPage.value = true;
    errorMessage.value = '';
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      fetchUnreadCount();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _hydrateBookingContexts(
    List<NotificationResponseDto> items,
  ) async {
    final bookingReferenceIds = items
        .where(
          (e) => _isBookingReference(e.referenceType) && e.referenceId != null,
        )
        .map((e) => e.referenceId!)
        .toSet();

    for (final refId in bookingReferenceIds) {
      if (bookingContextByReferenceId.containsKey(refId)) continue;
      if (_loadingContextByReferenceId.contains(refId)) continue;
      _loadingContextByReferenceId.add(refId);
      try {
        final result = await _bookingService.getBookingById(refId);
        if (result.success && result.item != null) {
          final booking = result.item!;
          bookingContextByReferenceId[refId] = BookingNotificationContext(
            hotelName: booking.hotelName,
            roomType: booking.roomType,
          );
          bookingContextByReferenceId.refresh();
        }
      } catch (_) {
        // Ignore individual reference lookup failures.
      } finally {
        _loadingContextByReferenceId.remove(refId);
      }
    }
  }

  bool _isBookingReference(String rawReferenceType) {
    return rawReferenceType.trim().toUpperCase().contains('BOOKING');
  }

  void _syncPageMeta(PaginatedResponse<NotificationResponseDto> pageData) {
    page.value = pageData.page;
    totalPages.value = pageData.totalPages <= 0 ? 1 : pageData.totalPages;
    totalElements.value = pageData.totalElements;
    isFirstPage.value = pageData.first;
    isLastPage.value = pageData.last;
  }
}

class BookingNotificationContext {
  const BookingNotificationContext({
    required this.hotelName,
    required this.roomType,
  });

  final String hotelName;
  final String roomType;
}
