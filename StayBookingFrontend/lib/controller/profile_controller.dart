import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/model/forgot_password_request_dto.dart';
import 'package:stay_booking_frontend/model/update_user_request_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/auth/password_service.dart';
import 'package:stay_booking_frontend/service/user/user_profile_service.dart';

class ProfileController extends GetxController {
  ProfileController({
    required this.initialUser,
    UserProfileService? userProfileService,
    PasswordService? passwordService,
  })  : _userProfileService = userProfileService ?? UserProfileService(),
        _passwordService = passwordService ?? PasswordService();

  final Map<String, dynamic> initialUser;
  final UserProfileService _userProfileService;
  final PasswordService _passwordService;

  final user = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final isUpdating = false.obs;
  final isDeleting = false.obs;
  final isSendingResetOtp = false.obs;
  final isEditing = false.obs;
  final errorMessage = ''.obs;
  final formKey = GlobalKey<FormState>();

  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final pincodeController = TextEditingController();
  final selectedGender = 'Male'.obs;

  static const List<String> genders = ['Male', 'Female', 'Other'];

  @override
  void onInit() {
    super.onInit();
    user.value = initialUser.isEmpty ? null : Map<String, dynamic>.from(initialUser);
    _syncFormFromUser();
    _loadProfile();
  }

  Future<void> refreshProfile() => _loadProfile(force: true);

  @override
  void onClose() {
    fnameController.dispose();
    lnameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  void startEditing() {
    _syncFormFromUser();
    isEditing.value = true;
  }

  void cancelEditing() {
    isEditing.value = false;
    _syncFormFromUser();
  }

  String? requiredField(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(v)) return 'Enter a valid email';
    return null;
  }

  String? validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^\d{10,15}$').hasMatch(v)) return 'Enter valid mobile number';
    return null;
  }

  String? validatePincode(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{4,10}$').hasMatch(v)) return 'Enter valid pincode';
    return null;
  }

  Future<void> submitUpdate() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final currentUser = user.value ?? <String, dynamic>{};
    final dynamic idRaw = currentUser['id'];
    final int? id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      errorMessage.value = 'Unable to update profile: user id missing.';
      return;
    }

    isUpdating.value = true;
    errorMessage.value = '';
    final request = UpdateUserRequestDto(
      fname: fnameController.text.trim(),
      lname: lnameController.text.trim(),
      email: emailController.text.trim(),
      mobileno: mobileController.text.trim(),
      gender: selectedGender.value,
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: countryController.text.trim(),
      pincode: pincodeController.text.trim(),
    );

    try {
      final result = await _userProfileService.updateUser(id, request);
      if (!result.success) {
        errorMessage.value = result.message;
        return;
      }

      final merged = Map<String, dynamic>.from(currentUser);
      merged.addAll(request.toJson());
      if (result.user != null) merged.addAll(result.user!);
      user.value = merged;

      isEditing.value = false;
      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      errorMessage.value = 'Unable to update profile. Please try again.';
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> deleteProfile() async {
    final currentUser = user.value ?? <String, dynamic>{};
    final dynamic idRaw = currentUser['id'];
    final int? id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      errorMessage.value = 'Unable to delete profile: user id missing.';
      return;
    }

    isDeleting.value = true;
    errorMessage.value = '';
    try {
      final result = await _userProfileService.deleteUser(id);
      if (!result.success) {
        errorMessage.value = result.message;
        return;
      }

      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      Get.offAllNamed(AppRoutes.login);
    } catch (_) {
      errorMessage.value = 'Unable to delete profile. Please try again.';
    } finally {
      isDeleting.value = false;
    }
  }

  Future<void> requestPasswordResetOtp() async {
    final currentUser = user.value ?? <String, dynamic>{};
    final email = (currentUser['email'] as String?)?.trim() ?? '';
    if (email.isEmpty) {
      errorMessage.value = 'Email not available for reset password.';
      return;
    }

    isSendingResetOtp.value = true;
    errorMessage.value = '';
    try {
      final result = await _passwordService.forgotPassword(
        ForgotPasswordRequestDto(email: email),
      );
      if (!result.success) {
        errorMessage.value = result.message;
        return;
      }

      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      Get.toNamed(
        AppRoutes.resetPassword,
        arguments: email,
      );
    } catch (_) {
      errorMessage.value = 'Unable to send reset OTP. Please try again.';
    } finally {
      isSendingResetOtp.value = false;
    }
  }

  Future<void> _loadProfile({bool force = false}) async {
    final current = user.value ?? <String, dynamic>{};
    final email = (current['email'] as String?)?.trim() ?? '';
    if (email.isEmpty) {
      errorMessage.value = 'Email not available for profile lookup.';
      return;
    }

    if (!force && isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _userProfileService.getUserByEmail(email);
      if (result.success && result.user != null) {
        user.value = result.user;
        if (!isEditing.value) {
          _syncFormFromUser();
        }
      } else {
        errorMessage.value = result.message;
      }
    } catch (_) {
      errorMessage.value = 'Unable to load profile. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void _syncFormFromUser() {
    final current = user.value ?? <String, dynamic>{};
    fnameController.text = (current['fname'] as String?)?.trim() ?? '';
    lnameController.text = (current['lname'] as String?)?.trim() ?? '';
    emailController.text = (current['email'] as String?)?.trim() ?? '';
    mobileController.text = (current['mobileno'] as String?)?.trim() ?? '';
    addressController.text = (current['address'] as String?)?.trim() ?? '';
    cityController.text = (current['city'] as String?)?.trim() ?? '';
    stateController.text = (current['state'] as String?)?.trim() ?? '';
    countryController.text = (current['country'] as String?)?.trim() ?? '';
    pincodeController.text = (current['pincode'] as String?)?.trim() ?? '';
    final gender = (current['gender'] as String?)?.trim();
    selectedGender.value = genders.contains(gender) ? gender! : genders.first;
  }
}
