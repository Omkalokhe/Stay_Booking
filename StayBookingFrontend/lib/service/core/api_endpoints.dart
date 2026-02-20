class ApiEndpoints {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
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

  static Uri forgotPassword() => Uri.parse('$_baseUrl/api/auth/password/forgot-password');

  static Uri resetPassword() => Uri.parse('$_baseUrl/api/auth/password/reset-password');

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
}
