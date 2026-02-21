import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:stay_booking_frontend/model/booking_response_dto.dart';
import 'package:stay_booking_frontend/model/create_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_order_request_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_order_response_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_verify_request_dto.dart';
import 'package:stay_booking_frontend/model/razorpay_verify_response_dto.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_status_request_dto.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:stay_booking_frontend/service/booking/booking_service.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_service.dart';
import 'package:stay_booking_frontend/service/room/room_service.dart';
import 'package:stay_booking_frontend/service/user/user_profile_service.dart';

class BookingController extends GetxController {
  BookingController({
    required this.currentUser,
    BookingService? bookingService,
    HotelService? hotelService,
    RoomService? roomService,
    UserProfileService? userProfileService,
  }) : _bookingService = bookingService ?? BookingService(),
       _hotelService = hotelService ?? HotelService(),
       _roomService = roomService ?? RoomService(),
       _userProfileService = userProfileService ?? UserProfileService();

  final Map<String, dynamic> currentUser;
  final BookingService _bookingService;
  final HotelService _hotelService;
  final RoomService _roomService;
  final UserProfileService _userProfileService;
  final Razorpay _razorpay = Razorpay();
  static const MethodChannel _razorpayChannel = MethodChannel(
    'razorpay_flutter',
  );
  static const String _fallbackRazorpayKeyId = 'rzp_test_SIlc3ejkMvjn2O';

  Completer<RazorpayVerifyResponseDto?>? _paymentCompleter;
  int? _activeRazorpayBookingId;
  String _activeRazorpayOrderId = '';

  final items = <BookingResponseDto>[].obs;
  final hotels = <HotelResponseDto>[].obs;
  final rooms = <RoomResponseDto>[].obs;

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final page = 0.obs;
  final size = 10.obs;
  final totalElements = 0.obs;
  final totalPages = 1.obs;
  final isFirstPage = true.obs;
  final isLastPage = true.obs;

  final sortBy = 'updatedat'.obs;
  final direction = 'desc'.obs;
  final search = ''.obs;
  final selectedHotelId = RxnInt();
  final selectedRoomId = RxnInt();
  final bookingStatusFilter = RxnString();
  final paymentStatusFilter = RxnString();
  final checkInFrom = Rxn<DateTime>();
  final checkOutTo = Rxn<DateTime>();
  DateTime? _lastSuccessfulFetchAt;

  static const bookingStatuses = <String>[
    'PENDING',
    'CONFIRMED',
    'CANCELLED',
    'COMPLETED',
    'NO_SHOW',
  ];

  static const paymentStatuses = <String>[
    'PENDING',
    'SUCCESS',
    'FAILED',
    'REFUNDED',
  ];

  static const sortOptions = <String>[
    'hotelName',
    'roomType',
    'checkInDate',
    'checkOutDate',
    'bookingStatus',
    'paymentStatus',
    'updatedat',
  ];

  int? get currentUserId {
    final idRaw = currentUser['id'];
    if (idRaw is int) return idRaw;
    return int.tryParse(idRaw?.toString() ?? '');
  }

  int? get bookingsQueryUserId {
    if (currentUserRole == 'VENDOR' || currentUserRole == 'ADMIN') {
      return null;
    }
    return currentUserId;
  }

  String get currentUserEmail =>
      (currentUser['email'] as String?)?.trim() ?? 'user@local';

  String get currentUserRole =>
      (currentUser['role'] as String?)?.trim().toUpperCase() ?? 'CUSTOMER';

  bool get canUpdateBookingAndPaymentStatus => currentUserRole == 'VENDOR';

  bool get isEmpty =>
      !isLoading.value && errorMessage.value.isEmpty && items.isEmpty;

  List<RoomResponseDto> roomsForHotel(int? hotelId) {
    if (hotelId == null) return rooms;
    return rooms.where((r) => r.hotelId == hotelId).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    loadReferenceData();
    loadFirstPage();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  Future<void> loadReferenceData() async {
    final hotelsResult = await _hotelService.getHotels(
      page: 0,
      size: 100,
      sortBy: 'updatedat',
      direction: 'desc',
    );
    if (hotelsResult.success) {
      hotels.assignAll(hotelsResult.items);
    }

    final roomsResult = await _roomService.getRooms(
      page: 0,
      size: 100,
      sortBy: 'updatedat',
      direction: 'desc',
    );
    if (roomsResult.success) {
      rooms.assignAll(roomsResult.items);
    }
  }

  Future<void> loadFirstPage({bool showLoader = true}) async {
    page.value = 0;
    await _load(showLoader: showLoader);
  }

  Future<void> refreshList() async {
    isRefreshing.value = true;
    await _load(showLoader: false);
    isRefreshing.value = false;
  }

  Future<void> refreshIfStale({
    Duration maxAge = const Duration(seconds: 20),
    bool resetPage = false,
  }) async {
    final last = _lastSuccessfulFetchAt;
    if (last == null || DateTime.now().difference(last) >= maxAge) {
      if (resetPage) {
        await loadFirstPage(showLoader: false);
      } else {
        await _load(showLoader: false);
      }
    }
  }

  Future<void> goToNextPage() async {
    if (isLastPage.value) return;
    page.value += 1;
    await _load(showLoader: true);
  }

  Future<void> goToPreviousPage() async {
    if (isFirstPage.value) return;
    page.value -= 1;
    await _load(showLoader: true);
  }

  Future<void> applySearch(String value) async {
    search.value = value.trim();
    await loadFirstPage();
  }

  Future<void> setSort(String value) async {
    sortBy.value = value;
    await loadFirstPage();
  }

  Future<void> setDirection(String value) async {
    direction.value = value;
    await loadFirstPage();
  }

  Future<void> setHotelFilter(int? value) async {
    selectedHotelId.value = value;
    if (selectedRoomId.value != null &&
        roomsForHotel(value).every((room) => room.id != selectedRoomId.value)) {
      selectedRoomId.value = null;
    }
    await loadFirstPage();
  }

  Future<void> setRoomFilter(int? value) async {
    selectedRoomId.value = value;
    await loadFirstPage();
  }

  Future<void> setBookingStatusFilter(String? value) async {
    bookingStatusFilter.value = (value ?? '').trim().isEmpty ? null : value;
    await loadFirstPage();
  }

  Future<void> setPaymentStatusFilter(String? value) async {
    paymentStatusFilter.value = (value ?? '').trim().isEmpty ? null : value;
    await loadFirstPage();
  }

  Future<void> setCheckInFrom(DateTime? value) async {
    checkInFrom.value = value;
    await loadFirstPage();
  }

  Future<void> setCheckOutTo(DateTime? value) async {
    checkOutTo.value = value;
    await loadFirstPage();
  }

  Future<void> resetFilters() async {
    selectedHotelId.value = null;
    selectedRoomId.value = null;
    bookingStatusFilter.value = null;
    paymentStatusFilter.value = null;
    checkInFrom.value = null;
    checkOutTo.value = null;
    sortBy.value = 'updatedat';
    direction.value = 'desc';
    await applySearch('');
  }

  Future<BookingResponseDto?> createBooking(
    CreateBookingRequestDto request,
  ) async {
    isSubmitting.value = true;
    try {
      final result = await _bookingService.createBooking(request);
      if (!result.success) {
        Get.snackbar(
          'Error',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      await loadFirstPage(showLoader: false);
      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return result.item;
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to create booking right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<BookingResponseDto?> updateBooking(
    int id,
    UpdateBookingRequestDto request,
  ) async {
    isSubmitting.value = true;
    try {
      final result = await _bookingService.updateBooking(id, request);
      if (!result.success) {
        Get.snackbar(
          'Error',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      await loadFirstPage(showLoader: false);
      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return result.item;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<BookingResponseDto?> updateStatus(
    int id,
    UpdateBookingStatusRequestDto request,
  ) async {
    if (!canUpdateBookingAndPaymentStatus) {
      Get.snackbar(
        'Forbidden',
        'Only vendors can update booking or payment status.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    if ((request.bookingStatus ?? '').trim().isEmpty &&
        (request.paymentStatus ?? '').trim().isEmpty) {
      Get.snackbar(
        'Validation',
        'At least one status field is required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    isSubmitting.value = true;
    try {
      final result = await _bookingService.updateBookingStatus(id, request);
      if (!result.success) {
        Get.snackbar(
          'Error',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      await loadFirstPage(showLoader: false);
      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return result.item;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> cancelBooking(BookingResponseDto booking) async {
    final index = items.indexWhere((e) => e.id == booking.id);
    if (index < 0) return;
    final snapshot = items[index];
    items[index] = booking.copyWith(bookingStatus: 'CANCELLED');

    final result = await _bookingService.cancelBooking(booking.id);
    if (!result.success) {
      items[index] = snapshot;
      Get.snackbar(
        'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.snackbar(
      'Success',
      result.message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<bool> payBookingWithRazorpay(BookingResponseDto booking) async {
    if (!_isRazorpaySupportedPlatform) {
      Get.snackbar(
        'Unavailable',
        'Razorpay checkout is supported on Android and iOS only.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (!await _isRazorpayPluginAvailable()) {
      Get.snackbar(
        'Payment Setup Error',
        'Razorpay plugin not loaded. Run a full app restart and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (isSubmitting.value) return false;

    isSubmitting.value = true;
    try {
      final orderResult = await _bookingService.createRazorpayOrder(
        RazorpayOrderRequestDto(bookingId: booking.id),
      );
      if (!orderResult.success || orderResult.item == null) {
        Get.snackbar(
          'Payment Failed',
          orderResult.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final order = orderResult.item!;
      final paymentUser = await _resolvePaymentUser();
      _activeRazorpayBookingId = booking.id;
      _activeRazorpayOrderId = order.orderId.trim();
      _paymentCompleter = Completer<RazorpayVerifyResponseDto?>();

      _openRazorpayCheckout(order: order, booking: booking, user: paymentUser);
      final verified = await _paymentCompleter!.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => null,
      );
      _clearActivePaymentContext();
      if (verified == null) return false;

      await loadFirstPage(showLoader: false);
      Get.snackbar(
        'Payment Update',
        verified.frontendMessage.trim().isEmpty
            ? 'Payment processed successfully.'
            : verified.frontendMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on MissingPluginException {
      _clearActivePaymentContext();
      Get.snackbar(
        'Payment Setup Error',
        'Razorpay plugin is not initialized. Please rebuild the app and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (_) {
      _clearActivePaymentContext();
      Get.snackbar(
        'Payment Failed',
        'Unable to start Razorpay checkout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<BookingResponseDto?> getBookingById(int id) async {
    final result = await _bookingService.getBookingById(id);
    if (!result.success) {
      Get.snackbar(
        'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
    return result.item;
  }

  Future<void> _load({required bool showLoader}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = '';

    final result = await _bookingService.getBookings(
      page: page.value,
      size: size.value,
      sortBy: sortBy.value,
      direction: direction.value,
      userId: bookingsQueryUserId,
      hotelId: selectedHotelId.value,
      roomId: selectedRoomId.value,
      bookingStatus: bookingStatusFilter.value,
      paymentStatus: paymentStatusFilter.value,
      checkInFrom: _formatDateOnly(checkInFrom.value),
      checkOutTo: _formatDateOnly(checkOutTo.value),
    );

    if (result.success) {
      items.assignAll(result.pageData.content);
      page.value = result.pageData.page;
      totalPages.value = result.pageData.totalPages;
      totalElements.value = result.pageData.totalElements;
      isFirstPage.value = result.pageData.first;
      isLastPage.value = result.pageData.last;
      _lastSuccessfulFetchAt = DateTime.now();
    } else {
      errorMessage.value = result.message;
    }

    isLoading.value = false;
  }

  String _formatDateOnly(DateTime? value) {
    if (value == null) return '';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool get _isRazorpaySupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _openRazorpayCheckout({
    required RazorpayOrderResponseDto order,
    required BookingResponseDto booking,
    required Map<String, dynamic> user,
  }) {
    final keyId = order.keyId.trim().isNotEmpty
        ? order.keyId.trim()
        : _fallbackRazorpayKeyId;
    final contact = _resolveUserContact(user);
    final prefill = <String, dynamic>{
      'email': (user['email'] as String?)?.trim().isNotEmpty == true
          ? (user['email'] as String).trim()
          : currentUserEmail,
    };
    if (contact != null) {
      prefill['contact'] = contact;
    }
    final options = <String, dynamic>{
      'key': keyId,
      'amount': order.amountInPaise,
      'currency': order.currency.trim().isEmpty ? 'INR' : order.currency,
      'name': 'Stay Booking',
      'description': 'Room booking payment',
      'order_id': order.orderId,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'theme': {'color': '#3E1E86'},
      'prefill': prefill,
      'notes': {
        'bookingId': '${booking.id}',
        'hotelName': booking.hotelName,
        'roomType': booking.roomType,
      },
    };
    _razorpay.open(options);
  }

  Future<bool> _isRazorpayPluginAvailable() async {
    try {
      await _razorpayChannel.invokeMethod('resync');
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return true;
    }
  }

  String? _normalizedPhone(dynamic raw) {
    final digits = (raw?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) return null;
    return digits;
  }

  String? _resolveUserContact(Map<String, dynamic> user) {
    final raw =
        user['mobileno'] ??
        user['mobileNo'] ??
        user['mobile'] ??
        user['phoneNumber'] ??
        user['phone'];
    return _normalizedPhone(raw);
  }

  Future<Map<String, dynamic>> _resolvePaymentUser() async {
    final email = currentUserEmail.trim();
    if (email.isEmpty) return currentUser;

    try {
      final profile = await _userProfileService.getUserByEmail(email);
      if (profile.success && profile.user != null) {
        return profile.user!;
      }
    } catch (_) {
      // Fall back to the in-memory user if profile lookup fails.
    }
    return currentUser;
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final bookingId = _activeRazorpayBookingId;
    if (bookingId == null) {
      _paymentCompleter?.complete(null);
      return;
    }

    final verifyResult = await _bookingService.verifyRazorpayPayment(
      RazorpayVerifyRequestDto(
        bookingId: bookingId,
        razorpayOrderId: (response.orderId ?? '').trim().isEmpty
            ? _activeRazorpayOrderId
            : response.orderId!,
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      ),
    );

    if (!verifyResult.success || verifyResult.item == null) {
      Get.snackbar(
        'Payment Failed',
        verifyResult.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      _paymentCompleter?.complete(null);
      return;
    }

    _paymentCompleter?.complete(verifyResult.item);
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    final reason = (response.message ?? 'Payment was not completed.').trim();
    Get.snackbar('Payment Failed', reason, snackPosition: SnackPosition.BOTTOM);
    _paymentCompleter?.complete(null);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final wallet = (response.walletName ?? '').trim();
    Get.snackbar(
      'External Wallet',
      wallet.isEmpty
          ? 'External wallet selected.'
          : 'External wallet selected: $wallet',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _clearActivePaymentContext() {
    _activeRazorpayBookingId = null;
    _activeRazorpayOrderId = '';
    _paymentCompleter = null;
  }
}
