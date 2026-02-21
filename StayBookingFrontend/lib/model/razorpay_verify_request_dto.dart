class RazorpayVerifyRequestDto {
  const RazorpayVerifyRequestDto({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final int bookingId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'razorpayOrderId': razorpayOrderId.trim(),
      'razorpayPaymentId': razorpayPaymentId.trim(),
      'razorpaySignature': razorpaySignature.trim(),
    };
  }
}
