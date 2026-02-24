import 'package:flutter/material.dart';
import 'package:stay_booking_frontend/view/review/widgets/hotel_reviews_section.dart';

class HotelReviewScreen extends StatelessWidget {
  const HotelReviewScreen({
    required this.hotelId,
    required this.currentUser,
    this.hotelName = '',
    super.key,
  });

  final int hotelId;
  final Map<String, dynamic> currentUser;
  final String hotelName;

  @override
  Widget build(BuildContext context) {
    final title = hotelName.trim().isEmpty
        ? 'Hotel #$hotelId Reviews'
        : hotelName;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F1D89),
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HotelReviewsSection(
              hotelId: hotelId,
              hotelName: hotelName,
              currentUser: currentUser,
              tagPrefix: 'hotel-reviews-screen',
            ),
          ],
        ),
      ),
    );
  }
}
