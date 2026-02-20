import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/model/reset_password_otp_request_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/auth/password_service.dart';

class ResetPasswordController extends GetxController {
  ResetPasswordController({
    required this.email,
    PasswordService? passwordService,
  }) : _passwordService = passwordService ?? PasswordService();

  final String email;
  final PasswordService _passwordService;
  final formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isNewPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;
  final isLoading = false.obs;

  @override
  void onClose() {
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordHidden.value = !isNewPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  String? validateOtp(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{4}$').hasMatch(v)) return 'Enter valid 4-digit OTP';
    return null;
  }

  String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'New password is required';
    if (v.length < 8) return 'Minimum 8 characters required';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Confirm password is required';
    if (v != newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final request = ResetPasswordOtpRequestDto(
      email: email,
      otp: otpController.text.trim(),
      newPassword: newPasswordController.text,
      confirmPassword: confirmPasswordController.text,
    );

    try {
      final result = await _passwordService.resetPasswordWithOtp(request);
      Get.snackbar(
        result.success ? 'Success' : 'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );

      if (result.success) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        Get.offAllNamed(AppRoutes.login);
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
