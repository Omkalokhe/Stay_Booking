class RazorpayVerifyResponseDto {
  const RazorpayVerifyResponseDto({
    required this.paymentStatus,
    required this.bookingStatus,
    required this.frontendMessage,
  });

  final String paymentStatus;
  final String bookingStatus;
  final String frontendMessage;

  factory RazorpayVerifyResponseDto.fromJson(Map<String, dynamic> json) {
    return RazorpayVerifyResponseDto(
      paymentStatus:
          (json['paymentStatus'] as String?)?.trim().toUpperCase() ?? '',
      bookingStatus:
          (json['bookingStatus'] as String?)?.trim().toUpperCase() ?? '',
      frontendMessage: (json['frontendMessage'] as String?)?.trim() ?? '',
    );
  }
}
