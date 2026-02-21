import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/admin/admin_refresh_bus.dart';
import 'package:stay_booking_frontend/model/admin/update_room_status_request.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/service/admin/admin_management_service.dart';

class AdminRoomsController extends GetxController {
  AdminRoomsController({
    required this.currentAdminEmail,
    AdminManagementService? service,
  }) : _service = service ?? AdminManagementService();

  final String currentAdminEmail;
  final AdminManagementService _service;
  final AdminRefreshBus _refreshBus = Get.isRegistered<AdminRefreshBus>()
      ? Get.find<AdminRefreshBus>()
      : Get.put(AdminRefreshBus(), permanent: true);
  Worker? _hotelsMutationWorker;

  final items = <RoomResponseDto>[].obs;
  final isLoading = false.obs;
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
  final hotelNameFilter = ''.obs;
  final availableFilter = RxnBool();
  DateTime? _lastSuccessfulFetchAt;

  bool get isEmpty => !isLoading.value && errorMessage.value.isEmpty && items.isEmpty;

  @override
  void onInit() {
    super.onInit();
    _hotelsMutationWorker = ever<int>(
      _refreshBus.hotelsMutationVersion,
      (_) async {
        if (isClosed) return;
        await refreshList();
      },
    );
  }

  @override
  void onClose() {
    _hotelsMutationWorker?.dispose();
    super.onClose();
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

  Future<void> applyHotelName(String value) async {
    hotelNameFilter.value = value.trim();
    await loadFirstPage();
  }

  Future<void> applyAvailable(bool? value) async {
    availableFilter.value = value;
    await loadFirstPage();
  }

  Future<void> setSort(String value) async {
    sortBy.value = value;
    await loadFirstPage();
  }

  Future<void> toggleDirection() async {
    direction.value = direction.value == 'asc' ? 'desc' : 'asc';
    await loadFirstPage();
  }

  Future<void> toggleAvailability(RoomResponseDto room, bool nextValue) async {
    final index = items.indexWhere((e) => e.id == room.id);
    if (index < 0) return;

    final original = items[index];
    items[index] = original.copyWith(available: nextValue);

    final result = await _service.updateRoomStatus(
      room.id,
      UpdateRoomStatusRequest(
        available: nextValue,
        updatedBy: currentAdminEmail,
      ),
    );

    if (!result.success) {
      items[index] = original;
    }

    Get.snackbar(result.success ? 'Success' : 'Error', result.message);
  }

  Future<void> deleteRoom(RoomResponseDto room) async {
    final index = items.indexWhere((e) => e.id == room.id);
    if (index < 0) return;

    final snapshot = items[index];
    items.removeAt(index);

    final result = await _service.deleteRoom(room.id);
    if (!result.success) {
      items.insert(index, snapshot);
    }

    Get.snackbar(result.success ? 'Success' : 'Error', result.message);
  }

  Future<void> _load({required bool showLoader}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = '';

    final result = await _service.getRooms(
      page: page.value,
      size: size.value,
      sortBy: sortBy.value,
      direction: direction.value,
      hotelName: hotelNameFilter.value,
      available: availableFilter.value,
      search: search.value,
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
      if (items.isEmpty) {
        totalPages.value = 1;
        totalElements.value = 0;
        isFirstPage.value = true;
        isLastPage.value = true;
      }
    }

    isLoading.value = false;
  }
}
