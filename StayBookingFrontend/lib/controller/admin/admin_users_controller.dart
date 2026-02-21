import 'package:get/get.dart';
import 'package:stay_booking_frontend/model/admin/admin_user_dto.dart';
import 'package:stay_booking_frontend/service/admin/admin_management_service.dart';

class AdminUsersController extends GetxController {
  AdminUsersController({
    required this.currentAdminEmail,
    AdminManagementService? service,
  }) : _service = service ?? AdminManagementService();

  final String currentAdminEmail;
  final AdminManagementService _service;

  final items = <AdminUserDto>[].obs;
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
  final roleFilter = RxnString();
  final statusFilter = RxnString();
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

  Future<void> setRoleFilter(String? role) async {
    roleFilter.value = (role ?? '').trim().isEmpty ? null : role;
    await loadFirstPage();
  }

  Future<void> setStatusFilter(String? status) async {
    statusFilter.value = (status ?? '').trim().isEmpty ? null : status;
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

  Future<void> updateAccess({
    required AdminUserDto user,
    String? role,
    String? status,
  }) async {
    final resolvedRole = role?.trim();
    final resolvedStatus = status?.trim();
    if ((resolvedRole ?? '').isEmpty && (resolvedStatus ?? '').isEmpty) {
      Get.snackbar('Validation', 'Select role and/or status to update.');
      return;
    }

    final index = items.indexWhere((e) => e.id == user.id);
    if (index < 0) return;
    final original = items[index];
    final optimistic = original.copyWith(
      role: (resolvedRole ?? original.role).toUpperCase(),
      status: (resolvedStatus ?? original.status).toUpperCase(),
    );
    items[index] = optimistic;

    final result = await _service.updateUserAccess(
      user.id,
      UpdateUserAccessRequest(
        role: resolvedRole,
        status: resolvedStatus,
        updatedBy: currentAdminEmail,
      ),
    );

    if (!result.success) {
      items[index] = original;
    }

    Get.snackbar(result.success ? 'Success' : 'Error', result.message);
  }

  Future<void> deleteUser(AdminUserDto user, {required bool hardDelete}) async {
    final index = items.indexWhere((e) => e.id == user.id);
    if (index < 0) return;

    final snapshot = items[index];
    items.removeAt(index);

    final result = await _service.deleteUser(
      user.id,
      hardDelete: hardDelete,
      deletedBy: currentAdminEmail,
    );

    if (!result.success) {
      items.insert(index, snapshot);
    }

    Get.snackbar(result.success ? 'Success' : 'Error', result.message);
  }

  Future<void> _load({required bool showLoader}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = '';

    final result = await _service.getUsers(
      page: page.value,
      size: size.value,
      sortBy: sortBy.value,
      direction: direction.value,
      role: roleFilter.value,
      status: statusFilter.value,
      search: search.value,
    );

    if (result.success) {
      final visibleItems = result.pageData.content
          .where((user) => user.role.trim().toUpperCase() != 'ADMIN')
          .toList(growable: false);
      items.assignAll(visibleItems);
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
