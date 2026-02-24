import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/model/create_review_request_dto.dart';
import 'package:stay_booking_frontend/model/review_response_dto.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_service.dart';
import 'package:stay_booking_frontend/service/review/review_service.dart';

class ReviewController extends GetxController {
  ReviewController({
    required this.hotelId,
    required this.currentUser,
    this.hotelName = '',
    this.adminMode = false,
    ReviewService? reviewService,
    HotelService? hotelService,
  }) : _reviewService = reviewService ?? ReviewService(),
       _hotelService = hotelService ?? HotelService();

  final int hotelId;
  final String hotelName;
  final bool adminMode;
  final Map<String, dynamic> currentUser;

  final ReviewService _reviewService;
  final HotelService _hotelService;

  /// ================= STATE =================

  final reviews = <ReviewResponseDto>[].obs;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isSubmitting = false.obs;

  final deletingReviewId = RxnInt();
  final errorMessage = ''.obs;

  final selectedRating = 0.obs;
  final averageRating = RxnDouble(); // fallback only
  final fieldErrors = <String, String>{}.obs;

  final reviewTextController = TextEditingController();

  /// ================= PAGINATION =================

  final currentPage = 0.obs;
  final totalPages = 1.obs;
  final pageSize = 10;

  bool get hasNextPage => currentPage.value < totalPages.value - 1;

  /// Filters (Admin)
  String? searchQuery;
  int? ratingFilter;

  /// ================= USER =================

  int? get currentUserId {
    final raw = currentUser['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  String get currentUserRole =>
      (currentUser['role'] as String?)?.trim().toUpperCase() ?? '';

  bool get isAdmin => currentUserRole == 'ADMIN';

  bool get canWriteReview =>
      currentUserId != null && currentUserRole == 'CUSTOMER';

  /// ================= LIVE RATING =================

  double get computedAverageRating {
    if (reviews.isEmpty) return 0;

    final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / reviews.length;
  }

  /// ================= LIFECYCLE =================

  @override
  void onInit() {
    super.onInit();

    if (adminMode) {
      loadFirstPage();
    } else {
      loadAll();
    }
  }

  @override
  void onClose() {
    reviewTextController.dispose();
    super.onClose();
  }

  /// ================= CUSTOMER FLOW =================

  Future<void> loadAll() async {
    isLoading.value = true;

    await Future.wait([_loadHotelRating(), refreshReviews()]);

    isLoading.value = false;
  }

  Future<void> refreshReviews() async {
    final result = await _reviewService.getReviewsByHotelId(hotelId);

    if (result.success) {
      reviews.assignAll(result.items);
    } else {
      errorMessage.value = result.message;
    }
  }

  /// ================= ADMIN PAGINATION =================

  Future<void> loadFirstPage() async {
    isLoading.value = true;
    errorMessage.value = '';

    currentPage.value = 0;
    reviews.clear();

    final result = await _reviewService.getAdminReviews(
      page: currentPage.value,
      size: pageSize,
      search: searchQuery,
      rating: ratingFilter,
    );

    if (result.success) {
      reviews.assignAll(result.page.content);
      totalPages.value = result.page.totalPages;
    } else {
      errorMessage.value = result.message;
    }

    isLoading.value = false;
  }

  Future<void> loadNextPage() async {
    if (!hasNextPage || isLoadingMore.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    final result = await _reviewService.getAdminReviews(
      page: currentPage.value,
      size: pageSize,
      search: searchQuery,
      rating: ratingFilter,
    );

    if (result.success) {
      reviews.addAll(result.page.content);
      totalPages.value = result.page.totalPages;
    }

    isLoadingMore.value = false;
  }

  Future<void> refreshAdminReviews() async {
    await loadFirstPage();
  }

  void applyFilters({String? search, int? rating}) {
    searchQuery = search;
    ratingFilter = rating;
    loadFirstPage();
  }

  /// ================= CREATE REVIEW =================

  Future<bool> submitReview() async {
    if (isSubmitting.value) return false;

    final userId = currentUserId;
    final reviewText = reviewTextController.text.trim();
    final rating = selectedRating.value;

    if (userId == null || reviewText.isEmpty) {
      Get.snackbar('Validation', 'Review required');
      return false;
    }

    isSubmitting.value = true;

    try {
      final result = await _reviewService.createReview(
        CreateReviewRequestDto(
          hotelId: hotelId,
          userId: userId,
          reviewText: reviewText,
          rating: rating,
        ),
      );

      if (!result.success) {
        Get.snackbar('Error', result.message);
        return false;
      }

      reviewTextController.clear();
      selectedRating.value = 0;

      await refreshReviews();

      Get.snackbar('Success', 'Review submitted');
      return true;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// ================= DELETE =================

  Future<void> deleteReview(ReviewResponseDto review) async {
    if (deletingReviewId.value != null) return;

    if (!isAdmin && !isOwnedByCurrentUser(review)) return;

    deletingReviewId.value = review.id;

    final snapshot = List<ReviewResponseDto>.from(reviews);
    reviews.removeWhere((r) => r.id == review.id);

    final result = await _reviewService.deleteReview(review.id);
    deletingReviewId.value = null;

    if (!result.success) {
      reviews.assignAll(snapshot);
      Get.snackbar('Error', result.message);
      return;
    }

    Get.snackbar('Success', 'Review deleted');
  }

  bool isOwnedByCurrentUser(ReviewResponseDto review) =>
      currentUserId == review.userId;

  /// ================= HOTEL RATING =================

  Future<void> _loadHotelRating() async {
    final result = await _hotelService.getHotelById(hotelId);

    if (result.success && result.item != null) {
      averageRating.value = result.item!.rating;
    }
  }
}
