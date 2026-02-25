class LoginResponseDto {
  LoginResponseDto({
    required this.message,
    required this.user,
    required this.tokenType,
    required this.accessToken,
    required this.expiresInMinutes,
  });

  final String message;
  final Map<String, dynamic>? user;
  final String tokenType;
  final String accessToken;
  final int expiresInMinutes;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return LoginResponseDto(
      message: (json['message'] as String?)?.trim() ?? 'Login successful',
      user: rawUser is Map ? Map<String, dynamic>.from(rawUser) : null,
      tokenType: (json['tokenType'] as String?)?.trim().isNotEmpty == true
          ? (json['tokenType'] as String).trim()
          : 'Bearer',
      accessToken: (json['accessToken'] as String?)?.trim() ?? '',
      expiresInMinutes: _toInt(json['expiresInMinutes'], fallback: 0),
    );
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
