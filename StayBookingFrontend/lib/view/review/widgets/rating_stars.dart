import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.size = 22,
    this.onRatingChanged,
    this.activeColor = const Color(0xFFF4B400),
    this.inactiveColor = const Color(0xFFD0D0D0),
    super.key,
  });

  final int rating;
  final double size;
  final ValueChanged<int>? onRatingChanged;
  final Color activeColor;
  final Color inactiveColor;

  bool get _isInteractive => onRatingChanged != null;

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final icon = Icon(
          starIndex <= clamped ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: starIndex <= clamped ? activeColor : inactiveColor,
        );
        if (!_isInteractive) {
          return icon;
        }
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onRatingChanged!(starIndex),
          child: Padding(padding: const EdgeInsets.all(2), child: icon),
        );
      }),
    );
  }
}
