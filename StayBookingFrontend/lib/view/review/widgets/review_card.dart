import 'package:flutter/material.dart';
import 'package:stay_booking_frontend/model/review_response_dto.dart';
import 'package:stay_booking_frontend/view/review/widgets/rating_stars.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.review,
    required this.canDelete,
    this.isDeleting = false,
    this.onDelete,
    super.key,
  });

  final ReviewResponseDto review;
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFF9F8FD),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(review.userName),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingStars(rating: review.rating, size: 18),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    onPressed: isDeleting ? null : onDelete,
                    tooltip: 'Delete review',
                    icon: isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review.reviewText.trim().isEmpty
                  ? 'No review text provided.'
                  : review.reviewText.trim(),
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(review.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(String? userName) {
    final value = (userName ?? '').trim();
    if (value.isNotEmpty) return value;
    return 'Anonymous User';
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    final month = monthNames[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$month $day, $year';
  }
}
