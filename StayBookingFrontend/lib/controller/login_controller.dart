import 'package:get/get.dart';
import 'package:stay_booking_frontend/model/app_role.dart';
import 'package:stay_booking_frontend/model/login_request_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/auth/login_service.dart';

class LoginController extends GetxController {
  LoginController({LoginService? loginService})
      : _loginService = loginService ?? LoginService();

  final LoginService _loginService;
  final email = ''.obs;
  final password = ''.obs;
  final role = AppRole.customer.obs;
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(v)) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters required';
    return null;
  }

  Future<void> signIn() async {
    isLoading.value = true;
    final request = LoginRequestDto(
      email: email.value,
      password: password.value,
      role: role.value,
    );

    try {
      final result = await _loginService.login(request);
      Get.snackbar(
        result.success ? 'Success' : 'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      if (result.success) {
        final roleValue =
            (result.user?['role'] as String?)?.trim().toUpperCase() ?? '';
        final targetRoute = switch (roleValue) {
          'ADMIN' => AppRoutes.adminHome,
          'VENDOR' => AppRoutes.vendorHome,
          _ => AppRoutes.home,
        };

        await Future<void>.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(
          targetRoute,
          arguments: result.user ?? <String, dynamic>{},
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to connect to server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}