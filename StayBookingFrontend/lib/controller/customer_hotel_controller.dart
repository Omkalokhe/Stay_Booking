import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_service.dart';

class CustomerHotelController extends GetxController {
  CustomerHotelController({HotelService? hotelService})
    : _hotelService = hotelService ?? HotelService();

  final HotelService _hotelService;

  final hotels = <HotelResponseDto>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final searchController = TextEditingController();
  final cityFilterController = TextEditingController();
  final countryFilterController = TextEditingController();

  final page = 0.obs;
  final size = 10.obs;
  final totalPages = 1.obs;
  final totalElements = 0.obs;
  final sortBy = 'updatedat'.obs;
  final direction = 'desc'.obs;
  DateTime? _lastSuccessfulFetchAt;

  @override
  void onInit() {
    super.onInit();
    fetchHotels(resetPage: true);
  }

  @override
  void onClose() {
    searchController.dispose();
    cityFilterController.dispose();
    countryFilterController.dispose();
    super.onClose();
  }

  Future<void> fetchHotels({bool resetPage = false}) async {
    if (isLoading.value) return;
    if (resetPage) page.value = 0;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _hotelService.getHotels(
        page: page.value,
        size: size.value,
        sortBy: sortBy.value,
        direction: direction.value,
        city: cityFilterController.text.trim(),
        country: countryFilterController.text.trim(),
        search: searchController.text.trim(),
      );
      if (!result.success) {
        errorMessage.value = result.message;
        return;
      }

      hotels.assignAll(result.items);
      page.value = result.page;
      totalPages.value = result.totalPages <= 0 ? 1 : result.totalPages;
      totalElements.value = result.totalElements;
      _lastSuccessfulFetchAt = DateTime.now();
    } catch (_) {
      errorMessage.value = 'Unable to load hotels. Please try again.';
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
      await fetchHotels(resetPage: resetPage);
    }
  }

  Future<void> goToPreviousPage() async {
    if (page.value <= 0) return;
    page.value -= 1;
    await fetchHotels();
  }

  Future<void> goToNextPage() async {
    if (page.value >= totalPages.value - 1) return;
    page.value += 1;
    await fetchHotels();
  }

  void setSortBy(String value) {
    sortBy.value = value;
  }

  void setDirection(String value) {
    direction.value = value;
  }

  void resetFilters() {
    searchController.clear();
    cityFilterController.clear();
    countryFilterController.clear();
    sortBy.value = 'updatedat';
    direction.value = 'desc';
  }
}
