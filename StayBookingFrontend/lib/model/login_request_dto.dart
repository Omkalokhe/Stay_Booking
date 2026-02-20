import 'package:stay_booking_frontend/model/app_role.dart';

class LoginRequestDto {
  LoginRequestDto({
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final AppRole role;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role.apiValue,
    };
  }
}
