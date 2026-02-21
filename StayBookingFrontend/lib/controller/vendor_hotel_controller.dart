import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/model/create_hotel_request_dto.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/model/update_hotel_request_dto.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_service.dart';

class VendorHotelController extends GetxController {
  VendorHotelController({
    required this.user,
    HotelService? hotelService,
  }) : _hotelService = hotelService ?? HotelService();

  final Map<String, dynamic> user;
  final HotelService _hotelService;

  final hotels = <HotelResponseDto>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final deletingHotelIds = <int>{}.obs;
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

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final pincodeController = TextEditingController();
  final ratingController = TextEditingController(text: '0');
  final editingHotelId = RxnInt();

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
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    ratingController.dispose();
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

  Future<void> goToPreviousPage() async {
    if (page.value <= 0) return;
    page.value -= 1;
    await fetchHotels();
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

  void startCreate() {
    editingHotelId.value = null;
    _clearForm();
  }

  void startEdit(HotelResponseDto hotel) {
    editingHotelId.value = hotel.id;
    nameController.text = hotel.name;
    descriptionController.text = hotel.description;
    addressController.text = hotel.address;
    cityController.text = hotel.city;
    stateController.text = hotel.state;
    countryController.text = hotel.country;
    pincodeController.text = hotel.pincode;
    ratingController.text = hotel.rating.toStringAsFixed(1);
  }

  Future<bool> submitForm() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isSubmitting.value = true;
    try {
      final id = editingHotelId.value;
      final success = id == null ? await _createHotel() : await _updateHotel(id);
      if (success) {
        _clearForm();
        editingHotelId.value = null;
      }
      return success;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> _createHotel() async {
    final request = CreateHotelRequestDto(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: countryController.text.trim(),
      pincode: pincodeController.text.trim(),
      rating: _parseRating(ratingController.text),
      createdBy: _currentUserEmail(),
    );
    final result = await _hotelService.createHotel(request);
    if (!result.success) {
      Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    Get.snackbar('Success', result.message, snackPosition: SnackPosition.BOTTOM);
    await fetchHotels();
    return true;
  }

  Future<bool> _updateHotel(int id) async {
    final request = UpdateHotelRequestDto(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: countryController.text.trim(),
      pincode: pincodeController.text.trim(),
      rating: _parseRating(ratingController.text),
      updatedBy: _currentUserEmail(),
    );
    final result = await _hotelService.updateHotel(id, request);
    if (!result.success) {
      Get.snackbar('Error', result.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    Get.snackbar('Success', result.message, snackPosition: SnackPosition.BOTTOM);
    await fetchHotels();
    return true;
  }

  Future<void> deleteHotel(HotelResponseDto hotel) async {
    deletingHotelIds.add(hotel.id);
    try {
      final result = await _hotelService.deleteHotel(
        hotel.id,
        deletedBy: _currentUserEmail(),
      );
      Get.snackbar(
        result.success ? 'Success' : 'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      if (result.success) {
        await fetchHotels();
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to delete hotel. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      deletingHotelIds.remove(hotel.id);
    }
  }

  String? requiredField(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? validateRating(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Rating is required';
    final rating = double.tryParse(v);
    if (rating == null) return 'Enter valid rating';
    if (rating < 0 || rating > 5) return 'Rating must be between 0 and 5';
    return null;
  }

  double _parseRating(String value) => double.tryParse(value.trim()) ?? 0;

  void _clearForm() {
    nameController.clear();
    descriptionController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    countryController.clear();
    pincodeController.clear();
    ratingController.text = '0';
  }

  String _currentUserEmail() {
    return (user['email'] as String?)?.trim() ?? '';
  }
}
