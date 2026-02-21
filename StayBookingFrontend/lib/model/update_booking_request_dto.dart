class UpdateBookingRequestDto {
  const UpdateBookingRequestDto({
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
  });

  final String checkInDate;
  final String checkOutDate;
  final int numberOfGuests;

  Map<String, dynamic> toJson() {
    return {
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'numberOfGuests': numberOfGuests,
    };
  }
}
