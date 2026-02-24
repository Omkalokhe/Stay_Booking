import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/review/review_controller.dart';
import 'package:stay_booking_frontend/model/review_response_dto.dart';
import 'package:stay_booking_frontend/view/review/widgets/rating_stars.dart';
import 'package:stay_booking_frontend/view/review/widgets/review_card.dart';

class HotelReviewsSection extends StatefulWidget {
  const HotelReviewsSection({
    required this.hotelId,
    required this.currentUser,
    this.hotelName = '',
    this.tagPrefix = 'hotel-reviews',
    super.key,
  });

  final int hotelId;
  final Map<String, dynamic> currentUser;
  final String hotelName;
  final String tagPrefix;

  @override
  State<HotelReviewsSection> createState() => _HotelReviewsSectionState();
}

class _HotelReviewsSectionState extends State<HotelReviewsSection> {
  late final String _tag;
  late final ReviewController _controller;

  @override
  void initState() {
    super.initState();
    final userPart = (widget.currentUser['id'] ?? 'guest').toString().trim();
    _tag = '${widget.tagPrefix}-${widget.hotelId}-$userPart';
    _controller = Get.isRegistered<ReviewController>(tag: _tag)
        ? Get.find<ReviewController>(tag: _tag)
        : Get.put(
            ReviewController(
              hotelId: widget.hotelId,
              hotelName: widget.hotelName,
              currentUser: widget.currentUser,
            ),
            tag: _tag,
          );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ReviewController>(tag: _tag)) {
      Get.delete<ReviewController>(tag: _tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final average = _controller.computedAverageRating;
      final reviewCount = _controller.reviews.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryCard(average, reviewCount),
          const SizedBox(height: 12),
          if (_controller.canWriteReview) _writeReviewCard(),
          if (_controller.canWriteReview) const SizedBox(height: 12),
          if (_controller.isLoading.value && _controller.reviews.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (_controller.errorMessage.value.isNotEmpty &&
              _controller.reviews.isEmpty)
            _errorState(_controller.errorMessage.value)
          else if (_controller.reviews.isEmpty)
            _emptyState()
          else
            ..._controller.reviews.map(_buildReviewCard),
        ],
      );
    });
  }

  Widget _summaryCard(double average, int reviewCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            average == 0 ? 'N/A' : average.toStringAsFixed(1),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingStars(rating: average.round()),
              const SizedBox(height: 4),
              Text(
                '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _controller.refreshReviews,
            tooltip: 'Refresh reviews',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _writeReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a review',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RatingStars(
                rating: _controller.selectedRating.value,
                onRatingChanged: (value) {
                  _controller.selectedRating.value = value;
                  _controller.fieldErrors.remove('rating');
                },
              ),
              const SizedBox(width: 8),
              Text(
                _controller.selectedRating.value == 0
                    ? 'Select rating'
                    : '${_controller.selectedRating.value}/5',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          if (_controller.fieldErrors['rating'] != null) ...[
            const SizedBox(height: 4),
            Text(
              _controller.fieldErrors['rating']!,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _controller.reviewTextController,
            minLines: 4,
            maxLines: 6,
            maxLength: 2000,
            onChanged: (_) => _controller.fieldErrors.remove('reviewText'),
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              errorText: _controller.fieldErrors['reviewText'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_controller.reviewTextController.text.length}/2000',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _controller.isSubmitting.value
                  ? null
                  : _controller.submitReview,
              icon: _controller.isSubmitting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: Text(
                _controller.isSubmitting.value
                    ? 'Submitting...'
                    : 'Submit Review',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewResponseDto review) {
    return ReviewCard(
      review: review,
      canDelete: _controller.isOwnedByCurrentUser(review),
      isDeleting: _controller.deletingReviewId.value == review.id,
      onDelete: () => _controller.deleteReview(review),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'No reviews yet. Be the first to write one.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _errorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }
}
