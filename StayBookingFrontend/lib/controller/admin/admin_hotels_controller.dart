import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/admin/admin_refresh_bus.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/service/admin/admin_management_service.dart';

class AdminHotelsController extends GetxController {
  AdminHotelsController({
    required this.currentAdminEmail,
    AdminManagementService? service,
  }) : _service = service ?? AdminManagementService();

  final String currentAdminEmail;
  final AdminManagementService _service;
  final AdminRefreshBus _refreshBus = Get.isRegistered<AdminRefreshBus>()
      ? Get.find<AdminRefreshBus>()
      : Get.put(AdminRefreshBus(), permanent: true);

  final items = <HotelResponseDto>[].obs;
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
  final cityFilter = ''.obs;
  final countryFilter = ''.obs;
  DateTime? _lastSuccessfulFetchAt;

  bool get isEmpty => !isLoading.value && errorMessage.value.isEmpty && items.isEmpty;

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

  Future<void> applyCity(String value) async {
    cityFilter.value = value.trim();
    await loadFirstPage();
  }

  Future<void> applyCountry(String value) async {
    countryFilter.value = value.trim();
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

  Future<void> deleteHotel(HotelResponseDto hotel) async {
    final index = items.indexWhere((e) => e.id == hotel.id);
    if (index < 0) return;

    final snapshot = items[index];
    items.removeAt(index);

    final result = await _service.deleteHotel(
      hotel.id,
      deletedBy: currentAdminEmail,
    );

    if (!result.success) {
      items.insert(index, snapshot);
    } else {
      if (items.isEmpty && page.value > 0) {
        page.value -= 1;
      }
      await _load(showLoader: false);
      _refreshBus.notifyHotelsChanged();
    }

    Get.snackbar(result.success ? 'Success' : 'Error', result.message);
  }

  Future<void> _load({required bool showLoader}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = '';

    final result = await _service.getHotels(
      page: page.value,
      size: size.value,
      sortBy: sortBy.value,
      direction: direction.value,
      city: cityFilter.value,
      country: countryFilter.value,
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
