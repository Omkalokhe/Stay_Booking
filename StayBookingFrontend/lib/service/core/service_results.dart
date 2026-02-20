class SimpleResult {
  const SimpleResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class LoginResult {
  const LoginResult({
    required this.success,
    required this.message,
    this.user,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? user;
}

class RegisterResult {
  const RegisterResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class UserDetailsResult {
  const UserDetailsResult({
    required this.success,
    required this.message,
    required this.user,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? user;
}

class HotelListResult<T> {
  const HotelListResult({
    required this.success,
    required this.message,
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final bool success;
  final String message;
  final List<T> items;
  final int page;
  final int totalPages;
  final int totalElements;
}

class HotelActionResult<T> {
  const HotelActionResult({
    required this.success,
    required this.message,
    required this.item,
  });

  final bool success;
  final String message;
  final T? item;
}
