import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/model/forgot_password_request_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/auth/password_service.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({PasswordService? passwordService})
      : _passwordService = passwordService ?? PasswordService();

  final PasswordService _passwordService;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(v)) return 'Enter a valid email';
    return null;
  }

  Future<void> submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final request = ForgotPasswordRequestDto(
      email: emailController.text.trim(),
    );

    try {
      final result = await _passwordService.forgotPassword(request);
      Get.snackbar(
        result.success ? 'Success' : 'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      if (result.success) {
        final email = emailController.text.trim();
        emailController.clear();
        await Future<void>.delayed(const Duration(milliseconds: 700));
        Get.toNamed(
          AppRoutes.resetPassword,
          arguments: email,
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
