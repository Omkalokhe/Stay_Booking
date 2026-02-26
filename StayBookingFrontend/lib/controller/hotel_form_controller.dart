import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stay_booking_frontend/constants/hotel_form_constants.dart';
import 'package:stay_booking_frontend/model/hotel_form/create_hotel_request.dart';
import 'package:stay_booking_frontend/model/hotel_form/hotel_model.dart';
import 'package:stay_booking_frontend/model/hotel_form/update_hotel_request.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_form_api_service.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_form_validator.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';

class HotelFormController extends GetxController {
  HotelFormController({
    required IHotelApiService hotelApiService,
    ImagePicker? imagePicker,
    void Function(String title, String message)? onMessage,
  }) : _hotelApiService = hotelApiService,
       _imagePicker = imagePicker ?? ImagePicker(),
       _onMessage = onMessage;

  final IHotelApiService _hotelApiService;
  final ImagePicker _imagePicker;
  final void Function(String title, String message)? _onMessage;

  final RxString name = ''.obs;
  final RxString city = ''.obs;
  final RxString country = ''.obs;
  final RxString description = ''.obs;
  final RxString address = ''.obs;
  final RxString state = ''.obs;
  final RxString pincode = ''.obs;
  final RxString rating = ''.obs;
  final RxString createdBy = ''.obs;
  final RxString updatedBy = ''.obs;

  final RxList<XFile> selectedImages = <XFile>[].obs;
  final RxList<String> existingPhotoUrls = <String>[].obs;
  final RxBool replacePhotos = false.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  HotelModel? lastLoadedHotel;

  Future<void> pickImages() async {
    try {
      final picked = await _imagePicker.pickMultiImage();
      if (picked.isEmpty) return;

      final accepted = <XFile>[];
      for (final file in picked) {
        final imageError = await HotelFormValidator.validateImageFile(file);
        if (imageError != null) {
          _showError(imageError);
          continue;
        }
        accepted.add(file);
      }
      selectedImages.addAll(accepted);
    } catch (_) {
      _showError(HotelFormConstants.messagePickImagesFailed);
    }
  }

  void removeSelectedImageAt(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    selectedImages.removeAt(index);
  }

  void removeExistingPhotoAt(int index) {
    if (index < 0 || index >= existingPhotoUrls.length) return;
    existingPhotoUrls.removeAt(index);
  }

  Future<bool> submitCreate() async {
    errorMessage.value = null;
    final requiredError = HotelFormValidator.validateCreateRequired(
      name: name.value,
      city: city.value,
      country: country.value,
    );
    if (requiredError != null) {
      _showError(requiredError);
      return false;
    }
    isLoading.value = true;
    try {
      final request = CreateHotelRequest(
        name: name.value.trim(),
        city: city.value.trim(),
        country: country.value.trim(),
        description: _asNullable(description.value),
        address: _asNullable(address.value),
        state: _asNullable(state.value),
        pincode: _asNullable(pincode.value),
        rating: 0.0,
        createdBy: _asNullable(createdBy.value),
        photos: List<XFile>.from(selectedImages),
      );
      final result = await _hotelApiService.createHotel(request);
      if (!result.isSuccess || result.data == null) {
        _showError(
          result.error?.message ?? HotelFormConstants.messageUnknownError,
        );
        return false;
      }
      _showMessage(
        HotelFormConstants.snackbarSuccessTitle,
        HotelFormConstants.messageCreateSuccess,
      );
      _setHotel(result.data!);
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitUpdate(int hotelId) async {
    errorMessage.value = null;

    isLoading.value = true;
    try {
      final request = UpdateHotelRequest(
        name: _asNullable(name.value),
        city: _asNullable(city.value),
        country: _asNullable(country.value),
        description: _asNullable(description.value),
        address: _asNullable(address.value),
        state: _asNullable(state.value),
        pincode: _asNullable(pincode.value),
        rating: null,
        updatedBy: _asNullable(updatedBy.value),
        photos: List<XFile>.from(selectedImages),
        replacePhotos: replacePhotos.value,
      );
      final result = await _hotelApiService.updateHotel(hotelId, request);
      if (!result.isSuccess || result.data == null) {
        _showError(
          result.error?.message ?? HotelFormConstants.messageUnknownError,
        );
        return false;
      }
      _showMessage(
        HotelFormConstants.snackbarSuccessTitle,
        HotelFormConstants.messageUpdateSuccess,
      );
      _setHotel(result.data!);
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHotel(int hotelId) async {
    errorMessage.value = null;
    isLoading.value = true;
    try {
      final result = await _hotelApiService.getHotelById(hotelId);
      if (!result.isSuccess || result.data == null) {
        _showError(result.error?.message ?? HotelFormConstants.messageLoadFailed);
        return;
      }
      _setHotel(result.data!);
    } finally {
      isLoading.value = false;
    }
  }

  String resolvePhotoUrl(String pathOrUrl) => ApiEndpoints.resolveUrl(pathOrUrl);

  File fileFromXFile(XFile file) => File(file.path);

  void _setHotel(HotelModel hotel) {
    lastLoadedHotel = hotel;
    name.value = hotel.name;
    city.value = hotel.city;
    country.value = hotel.country;
    description.value = hotel.description;
    address.value = hotel.address;
    state.value = hotel.state;
    pincode.value = hotel.pincode;
    existingPhotoUrls.assignAll(hotel.photoUrls);
    selectedImages.clear();
  }

  void _showError(String message) {
    errorMessage.value = message;
    _showMessage(HotelFormConstants.snackbarErrorTitle, message);
  }

  void _showMessage(String title, String message) {
    if (_onMessage != null) {
      _onMessage(title, message);
      return;
    }
    Get.snackbar(title, message);
  }

  static String? _asNullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

}

