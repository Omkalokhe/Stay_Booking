import 'package:get/get.dart';
import 'package:stay_booking_frontend/model/booking_response_dto.dart';
import 'package:stay_booking_frontend/model/create_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_status_request_dto.dart';
import 'package:stay_booking_frontend/service/booking/booking_service.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_service.dart';
import 'package:stay_booking_frontend/service/room/room_service.dart';

class BookingController extends GetxController {
  BookingController({
    required this.currentUser,
    BookingService? bookingService,
    HotelService? hotelService,
    RoomService? roomService,
  }) : _bookingService = bookingService ?? BookingService(),
       _hotelService = hotelService ?? HotelService(),
       _roomService = roomService ?? RoomService();

  final Map<String, dynamic> currentUser;
  final BookingService _bookingService;
  final HotelService _hotelService;
  final RoomService _roomService;

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

  bool get isEmpty => !isLoading.value && errorMessage.value.isEmpty && items.isEmpty;

  List<RoomResponseDto> roomsForHotel(int? hotelId) {
    if (hotelId == null) return rooms;
    return rooms.where((r) => r.hotelId == hotelId).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    loadReferenceData();
    loadFirstPage();
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

  Future<BookingResponseDto?> createBooking(CreateBookingRequestDto request) async {
    isSubmitting.value = true;
    try {
      final result = await _bookingService.createBooking(request);
      if (!result.success) {
        Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
        return null;
      }
      await loadFirstPage(showLoader: false);
      Get.snackbar('Success', result.message, snackPosition: SnackPosition.BOTTOM);
      return result.item;
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
        Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
        return null;
      }
      await loadFirstPage(showLoader: false);
      Get.snackbar('Success', result.message, snackPosition: SnackPosition.BOTTOM);
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
        Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
        return null;
      }
      await loadFirstPage(showLoader: false);
      Get.snackbar('Success', result.message, snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.snackbar('Success', result.message, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> deleteBooking(BookingResponseDto booking) async {
    final index = items.indexWhere((e) => e.id == booking.id);
    if (index < 0) return;
    final snapshot = items[index];
    items.removeAt(index);

    final result = await _bookingService.deleteBooking(booking.id);
    if (!result.success) {
      items.insert(index, snapshot);
      Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.snackbar('Success', result.message, snackPosition: SnackPosition.BOTTOM);
    if (items.isEmpty && page.value > 0) {
      page.value -= 1;
    }
    await _load(showLoader: false);
  }

  Future<BookingResponseDto?> getBookingById(int id) async {
    final result = await _bookingService.getBookingById(id);
    if (!result.success) {
      Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
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
}
