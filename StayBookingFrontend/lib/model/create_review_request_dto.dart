class CreateReviewRequestDto {
  const CreateReviewRequestDto({
    required this.hotelId,
    required this.userId,
    required this.reviewText,
    required this.rating,
  });

  final int hotelId;
  final int userId;
  final String reviewText;
  final int rating;

  Map<String, dynamic> toJson() {
    return {
      'hotelId': hotelId,
      'userId': userId,
      'reviewText': reviewText,
      'rating': rating,
    };
  }
}
