class RazorpayOrderRequestDto {
  const RazorpayOrderRequestDto({required this.bookingId});

  final int bookingId;

  Map<String, dynamic> toJson() {
    return {'bookingId': bookingId};
  }
}
