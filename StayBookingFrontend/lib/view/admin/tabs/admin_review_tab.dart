import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/review/review_controller.dart';
import 'package:stay_booking_frontend/model/review_response_dto.dart';

class AdminReviewTab extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminReviewTab({super.key, required this.user});

  @override
  State<AdminReviewTab> createState() => _AdminReviewTabState();
}

class _AdminReviewTabState extends State<AdminReviewTab> {
  late final ReviewController controller;

  final ScrollController scrollController = ScrollController();
  final searchController = TextEditingController();

  int selectedRating = 0;

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      ReviewController(hotelId: 0, currentUser: widget.user, adminMode: true),
      tag: 'admin-reviews-controller',
    );

    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.loadNextPage();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    controller.applyFilters(
      search: searchController.text.trim(),
      rating: selectedRating == 0 ? null : selectedRating,
    );
  }

  void _onRatingChanged(int rating) {
    setState(() => selectedRating = rating);

    controller.applyFilters(
      search: searchController.text.trim(),
      rating: rating == 0 ? null : rating,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Reviews')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search reviews...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: List.generate(6, (index) {
                final rating = index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(rating == 0 ? 'All' : '$rating ⭐'),
                    selected: selectedRating == rating,
                    onSelected: (selected) => _onRatingChanged(rating),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.reviews.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.reviews.isEmpty) {
                return const Center(child: Text('No reviews found'));
              }

              return RefreshIndicator(
                onRefresh: controller.refreshAdminReviews,
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.reviews.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.reviews.length) {
                      return controller.isLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox();
                    }

                    final review = controller.reviews[index];
                    return _reviewCard(review);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(ReviewResponseDto review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(review.userName ?? 'Unknown user'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(review.reviewText),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(review),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ReviewResponseDto review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      controller.deleteReview(review);
    }
  }
}
