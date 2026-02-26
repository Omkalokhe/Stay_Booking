class ApiEndpoints {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://localhost:8080',
    defaultValue: "http://192.168.1.5:8080",
  );

  static Uri login() => Uri.parse('$_baseUrl/api/auth/login');

  static String resolveUrl(String pathOrUrl) {
    final value = pathOrUrl.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final base = Uri.parse(_baseUrl);
    if (value.startsWith('/')) {
      return base.replace(path: value).toString();
    }
    return base.resolve(value).toString();
  }

  static Uri forgotPassword() =>
      Uri.parse('$_baseUrl/api/auth/password/forgot-password');

  static Uri resetPassword() =>
      Uri.parse('$_baseUrl/api/auth/password/reset-password');

  static Uri registerUser() => Uri.parse('$_baseUrl/api/users/register');

  static Uri getUserByEmail(String email) {
    final encoded = Uri.encodeComponent(email.trim());
    return Uri.parse('$_baseUrl/api/users/getByEmail/$encoded');
  }

  static Uri updateUser(int id) => Uri.parse('$_baseUrl/api/users/update/$id');

  static Uri deleteUser(int id) => Uri.parse('$_baseUrl/api/users/delete/$id');

  static Uri createHotel() => Uri.parse('$_baseUrl/api/hotels');

  static Uri getHotelById(int id) => Uri.parse('$_baseUrl/api/hotels/$id');

  static Uri getHotels({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? city,
    String? country,
    String? search,
  }) {
    return Uri.parse('$_baseUrl/api/hotels').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sortBy': sortBy,
        'direction': direction,
        if ((city ?? '').trim().isNotEmpty) 'city': city!.trim(),
        if ((country ?? '').trim().isNotEmpty) 'country': country!.trim(),
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
  }

  static Uri updateHotel(int id) => Uri.parse('$_baseUrl/api/hotels/$id');

  static Uri deleteHotel(int id, {String? deletedBy}) {
    return Uri.parse('$_baseUrl/api/hotels/$id').replace(
      queryParameters: {
        if ((deletedBy ?? '').trim().isNotEmpty) 'deletedBy': deletedBy!.trim(),
      },
    );
  }

  static Uri createRoom() => Uri.parse('$_baseUrl/api/rooms');

  static Uri getRoomById(int id) => Uri.parse('$_baseUrl/api/rooms/$id');

  static Uri getRooms({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? hotelName,
    bool? available,
    String? search,
  }) {
    return Uri.parse('$_baseUrl/api/rooms').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sortBy': sortBy,
        'direction': direction,
        if ((hotelName ?? '').trim().isNotEmpty) 'hotelName': hotelName!.trim(),
        if (available != null) 'available': '$available',
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
  }

  static Uri updateRoom(int id) => Uri.parse('$_baseUrl/api/rooms/$id');

  static Uri deleteRoom(int id) => Uri.parse('$_baseUrl/api/rooms/$id');

  static Uri getRoomPhoto(String filename) {
    final encoded = Uri.encodeComponent(filename.trim());
    return Uri.parse('$_baseUrl/api/rooms/photos/$encoded');
  }

  static Uri adminUsers({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? role,
    String? status,
    String? search,
  }) {
    return Uri.parse('$_baseUrl/api/admin/users').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sortBy': sortBy,
        'direction': direction,
        if ((role ?? '').trim().isNotEmpty) 'role': role!.trim(),
        if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
  }

  static Uri adminUpdateUserAccess(int userId) =>
      Uri.parse('$_baseUrl/api/admin/users/$userId/access');

  static Uri adminDeleteUser(
    int userId, {
    required bool hardDelete,
    required String deletedBy,
  }) {
    return Uri.parse('$_baseUrl/api/admin/users/$userId').replace(
      queryParameters: {
        'hardDelete': '$hardDelete',
        'deletedBy': deletedBy.trim(),
      },
    );
  }

  static Uri adminHotels({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? city,
    String? country,
    String? search,
  }) {
    return Uri.parse('$_baseUrl/api/admin/hotels').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sortBy': sortBy,
        'direction': direction,
        if ((city ?? '').trim().isNotEmpty) 'city': city!.trim(),
        if ((country ?? '').trim().isNotEmpty) 'country': country!.trim(),
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
  }

  static Uri adminDeleteHotel(int hotelId, {required String deletedBy}) {
    return Uri.parse(
      '$_baseUrl/api/admin/hotels/$hotelId',
    ).replace(queryParameters: {'deletedBy': deletedBy.trim()});
  }

  static Uri adminRooms({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    String? hotelName,
    bool? available,
    String? search,
  }) {
    return Uri.parse('$_baseUrl/api/admin/rooms').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sortBy': sortBy,
        'direction': direction,
        if ((hotelName ?? '').trim().isNotEmpty) 'hotelName': hotelName!.trim(),
        if (available != null) 'available': '$available',
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
  }

  static Uri adminUpdateRoomStatus(int roomId) =>
      Uri.parse('$_baseUrl/api/admin/rooms/$roomId/status');

  static Uri adminDeleteRoom(int roomId) =>
      Uri.parse('$_baseUrl/api/admin/rooms/$roomId');

  static Uri createBooking() => Uri.parse('$_baseUrl/api/bookings');

  static Uri getBookingById(int id) => Uri.parse('$_baseUrl/api/bookings/$id');

  static Uri getBookings({
    required int page,
    required int size,
    required String sortBy,
    required String direction,
    int? userId,
    int? hotelId,
    int? roomId,
    String? bookingStatus,
    String? paymentStatus,
    String? checkInFrom,
    String? checkOutTo,
  }) {
    return Uri.parse('$_baseUrl/api/bookings').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sortBy': sortBy,
        'direction': direction,
        if (userId != null) 'userId': '$userId',
        if (hotelId != null) 'hotelId': '$hotelId',
        if (roomId != null) 'roomId': '$roomId',
        if ((bookingStatus ?? '').trim().isNotEmpty)
          'bookingStatus': bookingStatus!.trim().toUpperCase(),
        if ((paymentStatus ?? '').trim().isNotEmpty)
          'paymentStatus': paymentStatus!.trim().toUpperCase(),
        if ((checkInFrom ?? '').trim().isNotEmpty)
          'checkInFrom': checkInFrom!.trim(),
        if ((checkOutTo ?? '').trim().isNotEmpty)
          'checkOutTo': checkOutTo!.trim(),
      },
    );
  }

  static Uri updateBooking(int id) => Uri.parse('$_baseUrl/api/bookings/$id');

  static Uri updateBookingStatus(int id) =>
      Uri.parse('$_baseUrl/api/bookings/$id/status');

  static Uri cancelBooking(int id) =>
      Uri.parse('$_baseUrl/api/bookings/$id/cancel');

  static Uri createRazorpayOrder() =>
      Uri.parse('$_baseUrl/api/payments/razorpay/orders');

  static Uri verifyRazorpayPayment() =>
      Uri.parse('$_baseUrl/api/payments/razorpay/verify');

  static Uri createReview() => Uri.parse('$_baseUrl/api/reviews');

  static Uri getReviewsByHotelId(int hotelId) =>
      Uri.parse('$_baseUrl/api/reviews/hotel/$hotelId');

  /// ================= ADMIN REVIEWS =================

  static Uri getAdminReviews({
    required int page,
    required int size,
    String? sortBy,
    String? direction,
    int? rating,
    String? search,
  }) {
    return Uri.parse('$_baseUrl/api/admin/reviews').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        if ((sortBy ?? '').trim().isNotEmpty) 'sortBy': sortBy!.trim(),
        if ((direction ?? '').trim().isNotEmpty) 'direction': direction!.trim(),
        if (rating != null) 'rating': '$rating',
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
  }

  static Uri deleteReview(int reviewId) =>
      Uri.parse('$_baseUrl/api/reviews/$reviewId');

  static Uri getNotifications({
    required int page,
    required int size,
    required bool unreadOnly,
  }) {
    return Uri.parse('$_baseUrl/api/notifications').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'unreadOnly': '$unreadOnly',
      },
    );
  }

  static Uri getUnreadNotificationCount() =>
      Uri.parse('$_baseUrl/api/notifications/unread-count');

  static Uri markNotificationAsRead(int id) =>
      Uri.parse('$_baseUrl/api/notifications/$id/read');

  static Uri markAllNotificationsAsRead() =>
      Uri.parse('$_baseUrl/api/notifications/read-all');
}
