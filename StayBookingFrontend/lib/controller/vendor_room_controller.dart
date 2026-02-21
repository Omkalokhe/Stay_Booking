import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/model/create_room_request_dto.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/model/room_upload_file.dart';
import 'package:stay_booking_frontend/model/update_room_request_dto.dart';
import 'package:stay_booking_frontend/service/room/room_service.dart';

class VendorRoomController extends GetxController {
  static const int _maxPhotoCount = 6;
  static const int _maxSinglePhotoBytes = 2 * 1024 * 1024;
  static const int _maxTotalPhotoBytes = 8 * 1024 * 1024;

  VendorRoomController({required this.user, RoomService? roomService})
    : _roomService = roomService ?? RoomService();

  final Map<String, dynamic> user;
  final RoomService _roomService;

  final rooms = <RoomResponseDto>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final deletingRoomIds = <int>{}.obs;
  final errorMessage = ''.obs;

  final searchController = TextEditingController();
  final hotelNameFilterController = TextEditingController();

  final page = 0.obs;
  final size = 10.obs;
  final totalPages = 1.obs;
  final totalElements = 0.obs;
  final sortBy = 'updatedat'.obs;
  final direction = 'desc'.obs;
  final availabilityFilter = RxnBool();
  DateTime? _lastSuccessfulFetchAt;

  final formKey = GlobalKey<FormState>();
  final hotelIdController = TextEditingController();
  final roomTypeController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final available = true.obs;
  final isHotelIdReadOnly = false.obs;
  final selectedPhotos = <PlatformFile>[].obs;
  final existingPhotos = <String>[].obs;
  final replacePhotos = false.obs;
  final editingRoomId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    fetchRooms(resetPage: true);
  }

  @override
  void onClose() {
    searchController.dispose();
    hotelNameFilterController.dispose();
    hotelIdController.dispose();
    roomTypeController.dispose();
    descriptionController.dispose();
    priceController.dispose();
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

  Future<void> goToPreviousPage() async {
    if (page.value <= 0) return;
    page.value -= 1;
    await fetchRooms();
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

  void startCreate({int? presetHotelId, bool lockHotelId = false}) {
    editingRoomId.value = null;
    replacePhotos.value = false;
    existingPhotos.clear();
    _clearForm();
    if (presetHotelId != null && presetHotelId > 0) {
      hotelIdController.text = '$presetHotelId';
    }
    isHotelIdReadOnly.value = lockHotelId;
  }

  void startEdit(RoomResponseDto room) {
    editingRoomId.value = room.id;
    hotelIdController.text = '${room.hotelId}';
    roomTypeController.text = room.roomType;
    descriptionController.text = room.description;
    priceController.text = room.price.toStringAsFixed(2);
    available.value = room.available;
    selectedPhotos.clear();
    existingPhotos.assignAll(room.photos);
    replacePhotos.value = false;
    isHotelIdReadOnly.value = false;
  }

  Future<void> pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files
        .where(
          (file) =>
              (file.path ?? '').trim().isNotEmpty ||
              ((file.bytes?.isNotEmpty ?? false) &&
                  file.name.trim().isNotEmpty),
        )
        .toList(growable: false);
    if (picked.isEmpty) return;

    // Append new picks and skip duplicates so users can select in batches.
    final existingKeys = selectedPhotos.map(_photoKey).toSet();
    final toAdd = picked.where(
      (file) => !existingKeys.contains(_photoKey(file)),
    );
    final accepted = <PlatformFile>[];
    var totalBytes = _selectedPhotosTotalBytes();
    var count = selectedPhotos.length;

    var rejectedByCount = 0;
    var rejectedBySingleSize = 0;
    var rejectedByTotalSize = 0;

    for (final file in toAdd) {
      final size = file.size;
      if (count >= _maxPhotoCount) {
        rejectedByCount += 1;
        continue;
      }
      if (size <= 0) {
        rejectedBySingleSize += 1;
        continue;
      }
      if (size > _maxSinglePhotoBytes) {
        rejectedBySingleSize += 1;
        continue;
      }
      if (totalBytes + size > _maxTotalPhotoBytes) {
        rejectedByTotalSize += 1;
        continue;
      }
      accepted.add(file);
      count += 1;
      totalBytes += size;
    }

    if (accepted.isNotEmpty) {
      selectedPhotos.addAll(accepted);
    }

    if (rejectedByCount > 0 ||
        rejectedBySingleSize > 0 ||
        rejectedByTotalSize > 0) {
      final notes = <String>[
        if (rejectedByCount > 0)
          '$rejectedByCount skipped (max $_maxPhotoCount photos).',
        if (rejectedBySingleSize > 0)
          '$rejectedBySingleSize skipped (each must be <= ${_mb(_maxSinglePhotoBytes)} MB).',
        if (rejectedByTotalSize > 0)
          '$rejectedByTotalSize skipped (total must be <= ${_mb(_maxTotalPhotoBytes)} MB).',
      ];
      Get.snackbar(
        'Some photos were skipped',
        notes.join(' '),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void removePickedPhoto(PlatformFile file) {
    selectedPhotos.remove(file);
  }

  Future<bool> submitForm() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isSubmitting.value = true;
    try {
      final id = editingRoomId.value;
      final success = id == null ? await _createRoom() : await _updateRoom(id);
      if (success) {
        _clearForm();
        editingRoomId.value = null;
        existingPhotos.clear();
        replacePhotos.value = false;
        isHotelIdReadOnly.value = false;
      }
      return success;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> _createRoom() async {
    final hotelId = _parseHotelId(hotelIdController.text);
    if (hotelId == null) {
      Get.snackbar(
        'Error',
        'Invalid hotel selection. Please open Add Room from a hotel card.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!_validatePhotoPayload()) return false;

    final request = CreateRoomRequestDto(
      hotelId: hotelId,
      roomType: roomTypeController.text.trim(),
      description: descriptionController.text.trim(),
      price: _parsePrice(priceController.text),
      available: available.value,
      createdBy: _currentUserEmail(),
      photoFiles: selectedPhotos
          .map(RoomUploadFile.fromPlatformFile)
          .toList(growable: false),
    );

    final result = await _roomService.createRoom(request);
    if (!result.success) {
      Get.snackbar(
        'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    Get.snackbar(
      'Success',
      result.message,
      snackPosition: SnackPosition.BOTTOM,
    );
    await fetchRooms();
    return true;
  }

  Future<bool> _updateRoom(int id) async {
    final hotelId = _parseHotelId(hotelIdController.text);
    if (hotelId == null) {
      Get.snackbar(
        'Error',
        'Invalid hotel ID.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!_validatePhotoPayload()) return false;

    final request = UpdateRoomRequestDto(
      hotelId: hotelId,
      roomType: roomTypeController.text.trim(),
      description: descriptionController.text.trim(),
      price: _parsePrice(priceController.text),
      available: available.value,
      updatedBy: _currentUserEmail(),
      photoFiles: selectedPhotos
          .map(RoomUploadFile.fromPlatformFile)
          .toList(growable: false),
      replacePhotos: replacePhotos.value,
    );

    final result = await _roomService.updateRoom(id, request);
    if (!result.success) {
      Get.snackbar(
        'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    Get.snackbar(
      'Success',
      result.message,
      snackPosition: SnackPosition.BOTTOM,
    );
    await fetchRooms();
    return true;
  }

  Future<void> deleteRoom(RoomResponseDto room) async {
    deletingRoomIds.add(room.id);
    try {
      final result = await _roomService.deleteRoom(room.id);
      Get.snackbar(
        result.success ? 'Success' : 'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      if (result.success) {
        await fetchRooms();
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to delete room. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      deletingRoomIds.remove(room.id);
    }
  }

  Future<RoomResponseDto> getRoomForView(RoomResponseDto summaryRoom) async {
    try {
      final result = await _roomService.getRoomById(summaryRoom.id);
      if (result.success && result.item != null) {
        return result.item!;
      }
    } catch (_) {
      // Fall back to list payload if details call fails.
    }
    return summaryRoom;
  }

  String roomPhotoUrl(String rawPhoto) {
    return RoomService.roomPhotoUrl(rawPhoto);
  }

  void resetFilters() {
    searchController.clear();
    hotelNameFilterController.clear();
    sortBy.value = 'updatedat';
    direction.value = 'desc';
    availabilityFilter.value = null;
  }

  String? requiredField(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? validateHotelId(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Hotel ID is required';
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return 'Enter valid Hotel ID';
    return null;
  }

  String? validatePrice(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Price is required';
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return 'Enter valid price';
    return null;
  }

  int? _parseHotelId(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  double _parsePrice(String value) => double.tryParse(value.trim()) ?? 0;

  void _clearForm() {
    hotelIdController.clear();
    roomTypeController.clear();
    descriptionController.clear();
    priceController.clear();
    available.value = true;
    selectedPhotos.clear();
    isHotelIdReadOnly.value = false;
  }

  String _photoKey(PlatformFile file) {
    final path = (file.path ?? '').trim();
    if (path.isNotEmpty) return 'path:$path';
    return 'mem:${file.name.trim()}-${file.size}';
  }

  String _currentUserEmail() {
    final email = (user['email'] as String?)?.trim() ?? '';
    return email.isEmpty ? 'vendor@local' : email;
  }

  int _selectedPhotosTotalBytes() {
    return selectedPhotos.fold<int>(0, (sum, file) => sum + file.size);
  }

  bool _validatePhotoPayload() {
    if (selectedPhotos.length > _maxPhotoCount) {
      Get.snackbar(
        'Validation',
        'Max $_maxPhotoCount photos allowed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final tooLargeCount = selectedPhotos
        .where((file) => file.size > _maxSinglePhotoBytes)
        .length;
    if (tooLargeCount > 0) {
      Get.snackbar(
        'Validation',
        '$tooLargeCount photo(s) exceed ${_mb(_maxSinglePhotoBytes)} MB limit.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final totalBytes = _selectedPhotosTotalBytes();
    if (totalBytes > _maxTotalPhotoBytes) {
      Get.snackbar(
        'Validation',
        'Total photo size exceeds ${_mb(_maxTotalPhotoBytes)} MB.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  String _mb(int bytes) {
    final value = bytes / (1024 * 1024);
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}
