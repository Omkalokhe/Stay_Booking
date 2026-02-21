class CreateBookingRequestDto {
  const CreateBookingRequestDto({
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
  });

  final int userId;
  final int hotelId;
  final int roomId;
  final String checkInDate;
  final String checkOutDate;
  final int numberOfGuests;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'hotelId': hotelId,
      'roomId': roomId,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'numberOfGuests': numberOfGuests,
    };
  }
}
