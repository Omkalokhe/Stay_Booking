class ReviewResponseDto {
  const ReviewResponseDto({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.userName,
    required this.reviewText,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int hotelId;
  final int userId;
  final String? userName;
  final String reviewText;
  final int rating;
  final String createdAt;
  final String updatedAt;

  factory ReviewResponseDto.fromJson(Map<String, dynamic> json) {
    return ReviewResponseDto(
      id: _toInt(json['id']),
      hotelId: _toInt(json['hotelId'] ?? json['hotelid']),
      userId: _toInt(json['userId'] ?? json['userid']),
      userName: (json['userName'] as String?)?.trim(),
      reviewText: (json['reviewText'] as String?)?.trim() ?? '',
      rating: _toInt(json['rating']).clamp(0, 5),
      createdAt:
          (json['createdAt'] as String?)?.trim() ??
          (json['createdat'] as String?)?.trim() ??
          '',
      updatedAt:
          (json['updatedAt'] as String?)?.trim() ??
          (json['updatedat'] as String?)?.trim() ??
          '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
