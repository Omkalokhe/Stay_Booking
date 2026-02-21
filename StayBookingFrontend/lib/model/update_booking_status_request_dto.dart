class UpdateBookingStatusRequestDto {
  const UpdateBookingStatusRequestDto({
    this.bookingStatus,
    this.paymentStatus,
  });

  final String? bookingStatus;
  final String? paymentStatus;

  Map<String, dynamic> toJson() {
    return {
      if ((bookingStatus ?? '').trim().isNotEmpty)
        'bookingStatus': bookingStatus!.trim().toUpperCase(),
      if ((paymentStatus ?? '').trim().isNotEmpty)
        'paymentStatus': paymentStatus!.trim().toUpperCase(),
    };
  }
}
