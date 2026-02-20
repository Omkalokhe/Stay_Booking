class LoginResponseDto {
  LoginResponseDto({
    required this.message,
    required this.user,
  });

  final String message;
  final Map<String, dynamic>? user;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return LoginResponseDto(
      message: (json['message'] as String?)?.trim() ?? 'Login successful',
      user: rawUser is Map ? Map<String, dynamic>.from(rawUser) : null,
    );
  }
}
