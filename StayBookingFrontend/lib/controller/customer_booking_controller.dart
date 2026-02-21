import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/service/room/room_service.dart';

class CustomerBookingController extends GetxController {
  CustomerBookingController({RoomService? roomService})
    : _roomService = roomService ?? RoomService();

  final RoomService _roomService;

  final rooms = <RoomResponseDto>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final searchController = TextEditingController();
  final hotelNameFilterController = TextEditingController();

  final page = 0.obs;
  final size = 10.obs;
  final totalPages = 1.obs;
  final totalElements = 0.obs;
  final sortBy = 'id'.obs;
  final direction = 'asc'.obs;
  final availabilityFilter = RxnBool();
  DateTime? _lastSuccessfulFetchAt;

  @override
  void onInit() {
    super.onInit();
    fetchRooms(resetPage: true);
  }

  @override
  void onClose() {
    searchController.dispose();
    hotelNameFilterController.dispose();
    super.onClose();
  }

  Future<void> fetchRooms({bool resetPage = false}) async {
    if (isLoading.value) return;
    if (resetPage) page.value = 0;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _roomService.getRooms(
        page: page.value,
        size: size.value,
        sortBy: sortBy.value,
        direction: direction.value,
        hotelName: hotelNameFilterController.text.trim(),
        available: availabilityFilter.value,
        search: searchController.text.trim(),
      );
      if (!result.success) {
        errorMessage.value = result.message;
        return;
      }

      rooms.assignAll(result.items);
      page.value = result.page;
      totalPages.value = result.totalPages <= 0 ? 1 : result.totalPages;
      totalElements.value = result.totalElements;
      _lastSuccessfulFetchAt = DateTime.now();
    } catch (_) {
      errorMessage.value = 'Unable to load rooms. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshIfStale({
    Duration maxAge = const Duration(seconds: 20),
    bool resetPage = false,
  }) async {
    final last = _lastSuccessfulFetchAt;
    if (last == null || DateTime.now().difference(last) >= maxAge) {
      await fetchRooms(resetPage: resetPage);
    }
  }

  Future<void> goToPreviousPage() async {
    if (page.value <= 0) return;
    page.value -= 1;
    await fetchRooms();
  }

  Future<void> goToNextPage() async {
    if (page.value >= totalPages.value - 1) return;
    page.value += 1;
    await fetchRooms();
  }

  void setSortBy(String value) {
    sortBy.value = value;
  }

  void setDirection(String value) {
    direction.value = value;
  }

  void setAvailabilityFilter(bool? value) {
    availabilityFilter.value = value;
  }

  void resetFilters() {
    searchController.clear();
    hotelNameFilterController.clear();
    availabilityFilter.value = null;
    sortBy.value = 'id';
    direction.value = 'asc';
  }

  String roomPhotoUrl(String rawPhoto) => RoomService.roomPhotoUrl(rawPhoto);

  Future<RoomResponseDto> getRoomForView(RoomResponseDto summaryRoom) async {
    try {
      final result = await _roomService.getRoomById(summaryRoom.id);
      if (result.success && result.item != null) {
        return result.item!;
      }
    } catch (_) {
      // Fall back to summary payload.
    }
    return summaryRoom;
  }
}
