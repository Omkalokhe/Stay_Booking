import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/controller/reset_password_controller.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';

class ResetPasswordScreen extends StatelessWidget {
  ResetPasswordScreen({super.key});

  final ResetPasswordController _controller = Get.put(
    ResetPasswordController(
      email: (Get.arguments is String) ? Get.arguments as String : '',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final email = _controller.email;

    if (email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.forgotPassword);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F1D89), Color(0xFF24144D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 1200
                  ? 48.0
                  : constraints.maxWidth >= 700
                      ? 24.0
                      : 16.0;
              final contentWidth = constraints.maxWidth >= 900 ? 560.0 : 460.0;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _controller.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter OTP and New Password',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                email.isEmpty
                                    ? 'Enter details to reset your password.'
                                    : 'OTP has been sent to $email',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.black54,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _controller.otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: _controller.validateOtp,
                                decoration: _inputDecoration('4-digit OTP', Icons.pin_outlined),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => TextFormField(
                                  controller: _controller.newPasswordController,
                                  obscureText: _controller.isNewPasswordHidden.value,
                                  validator: _controller.validatePassword,
                                  decoration: _inputDecoration(
                                    'New Password',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: _controller.toggleNewPasswordVisibility,
                                      icon: Icon(
                                        _controller.isNewPasswordHidden.value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Obx(
                                () => TextFormField(
                                  controller: _controller.confirmPasswordController,
                                  obscureText: _controller.isConfirmPasswordHidden.value,
                                  validator: _controller.validateConfirmPassword,
                                  decoration: _inputDecoration(
                                    'Confirm Password',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: _controller.toggleConfirmPasswordVisibility,
                                      icon: Icon(
                                        _controller.isConfirmPasswordHidden.value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: Obx(
                                  () => ElevatedButton(
                                    onPressed: _controller.isLoading.value
                                        ? null
                                        : _controller.submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5A31D6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _controller.isLoading.value
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Reset Password',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () => Get.offAllNamed(AppRoutes.login),
                                  child: const Text('Back to Sign In'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      counterText: '',
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F2FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B46E8), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.1),
      ),
    );
  }
}
