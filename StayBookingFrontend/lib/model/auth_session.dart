class AuthSession {
  const AuthSession({
    required this.tokenType,
    required this.accessToken,
    required this.expiresInMinutes,
    required this.expiresAt,
    required this.user,
  });

  final String tokenType;
  final String accessToken;
  final int expiresInMinutes;
  final DateTime expiresAt;
  final Map<String, dynamic> user;

  String get role => (user['role'] as String?)?.trim().toUpperCase() ?? '';

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tokenType': tokenType,
      'accessToken': accessToken,
      'expiresInMinutes': expiresInMinutes,
      'expiresAt': expiresAt.toIso8601String(),
      'user': user,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final expiresAtRaw = (json['expiresAt'] as String?)?.trim() ?? '';
    final expiresAt =
        DateTime.tryParse(expiresAtRaw)?.toUtc().toLocal() ?? DateTime.now();

    return AuthSession(
      tokenType: (json['tokenType'] as String?)?.trim().isNotEmpty == true
          ? (json['tokenType'] as String).trim()
          : 'Bearer',
      accessToken: (json['accessToken'] as String?)?.trim() ?? '',
      expiresInMinutes: _toInt(json['expiresInMinutes'], fallback: 0),
      expiresAt: expiresAt,
      user: rawUser is Map<String, dynamic>
          ? rawUser
          : rawUser is Map
          ? Map<String, dynamic>.from(rawUser)
          : <String, dynamic>{},
    );
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
