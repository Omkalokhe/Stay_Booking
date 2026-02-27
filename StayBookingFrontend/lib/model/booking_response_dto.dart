class BookingResponseDto {
  const BookingResponseDto({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.hotelId,
    required this.hotelName,
    required this.roomId,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.totalAmount,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final String userEmail;
  final int hotelId;
  final String hotelName;
  final int roomId;
  final String roomType;
  final String checkInDate;
  final String checkOutDate;
  final int numberOfGuests;
  final double totalAmount;
  final String bookingStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String createdAt;
  final String updatedAt;

  BookingResponseDto copyWith({
    int? id,
    int? userId,
    String? userEmail,
    int? hotelId,
    String? hotelName,
    int? roomId,
    String? roomType,
    String? checkInDate,
    String? checkOutDate,
    int? numberOfGuests,
    double? totalAmount,
    String? bookingStatus,
    String? paymentStatus,
    String? paymentMethod,
    String? createdAt,
    String? updatedAt,
  }) {
    return BookingResponseDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      hotelId: hotelId ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      roomId: roomId ?? this.roomId,
      roomType: roomType ?? this.roomType,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      totalAmount: totalAmount ?? this.totalAmount,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BookingResponseDto.fromJson(Map<String, dynamic> json) {
    return BookingResponseDto(
      id: _toInt(json['id']),
      userId: _toInt(json['userId']),
      userEmail: (json['userEmail'] as String?)?.trim() ?? '',
      hotelId: _toInt(json['hotelId']),
      hotelName: (json['hotelName'] as String?)?.trim() ?? '',
      roomId: _toInt(json['roomId']),
      roomType: (json['roomType'] as String?)?.trim() ?? '',
      checkInDate: (json['checkInDate'] as String?)?.trim() ?? '',
      checkOutDate: (json['checkOutDate'] as String?)?.trim() ?? '',
      numberOfGuests: _toInt(json['numberOfGuests']),
      totalAmount: _toDouble(json['totalAmount']),
      bookingStatus: (json['bookingStatus'] as String?)?.trim().toUpperCase() ?? '',
      paymentStatus: (json['paymentStatus'] as String?)?.trim().toUpperCase() ?? '',
      paymentMethod: _normalizePaymentMethod(json['paymentMethod']),
      createdAt: (json['createdAt'] as String?)?.trim() ?? '',
      updatedAt: (json['updatedAt'] as String?)?.trim() ?? '',
    );
  }

  static String _normalizePaymentMethod(dynamic value) {
    final method = (value?.toString() ?? '').trim().toUpperCase();
    return method.isEmpty ? 'RAZORPAY' : method;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
