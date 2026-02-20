class ResetPasswordOtpRequestDto {
  ResetPasswordOtpRequestDto({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
      // Backward compatibility: some backends still expect `token`.
      'token': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}
