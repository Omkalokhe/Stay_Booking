import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/model/app_role.dart';
import 'package:stay_booking_frontend/model/register_user_request.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/auth/register_service.dart';

class RegisterController extends GetxController {
  RegisterController({RegisterService? registerService})
      : _registerService = registerService ?? RegisterService();

  final RegisterService _registerService;
  final formKey = GlobalKey<FormState>();

  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final pincodeController = TextEditingController();

  final gender = 'Male'.obs;
  final role = AppRole.customer.obs;
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;

  @override
  void onClose() {
    fnameController.dispose();
    lnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mobileController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  String? requiredField(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
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

  String? validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^\d{10,15}$').hasMatch(v)) {
      return 'Enter valid mobile number';
    }
    return null;
  }

  String? validatePincode(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{4,10}$').hasMatch(v)) return 'Enter valid pincode';
    return null;
  }

  Future<void> registerUser() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final payload = RegisterUserRequest(
      fname: fnameController.text.trim(),
      lname: lnameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      role: role.value.apiValue,
      mobileno: mobileController.text.trim(),
      gender: gender.value,
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: countryController.text.trim(),
      pincode: pincodeController.text.trim(),
    );

    try {
      final result = await _registerService.register(payload);
      Get.snackbar(
        result.success ? 'Success' : 'Error',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );

      if (result.success) {
        _clearForm();
        await Future<void>.delayed(const Duration(milliseconds: 700));
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

  void _clearForm() {
    fnameController.clear();
    lnameController.clear();
    emailController.clear();
    passwordController.clear();
    mobileController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    countryController.clear();
    pincodeController.clear();
    gender.value = 'Male';
    role.value = AppRole.customer;
  }
}
