import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/login_controller.dart';
import 'package:stay_booking_frontend/model/app_role.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginController _controller = Get.put(LoginController());

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  double _cardWidth(double width) {
    if (width >= 1200) return 520;
    if (width >= 900) return 460;
    if (width >= 700) return 420;
    return width;
  }

  double _horizontalPadding(double width) {
    if (width >= 1200) return 48;
    if (width >= 700) return 24;
    return 16;
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    _controller.email.value = _emailController.text.trim();
    _controller.password.value = _passwordController.text;
    await _controller.signIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/hotel.png', fit: BoxFit.cover),
          ),

          /// Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    const Color(0xFF3F1D89).withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = _cardWidth(constraints.maxWidth);
                final horizontalPadding = _horizontalPadding(
                  constraints.maxWidth,
                );

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33110B22),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to continue',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _emailController,
                                style: TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                validator: _controller.validateEmail,
                                decoration: _inputDecoration(
                                  'Email',
                                  Icons.mail_outline,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Obx(
                                () => TextFormField(
                                  controller: _passwordController,
                                  style: TextStyle(color: Colors.white),
                                  obscureText:
                                      _controller.isPasswordHidden.value,
                                  validator: _controller.validatePassword,
                                  decoration:
                                      _inputDecoration(
                                        'Password',
                                        Icons.lock_outline,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          onPressed: _controller
                                              .togglePasswordVisibility,
                                          icon: Icon(
                                            _controller.isPasswordHidden.value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Obx(
                                () => DropdownButtonFormField<AppRole>(
                                  dropdownColor: Colors.black87,
                                  initialValue: _controller.role.value,
                                  decoration: _inputDecoration(
                                    'Role',
                                    Icons.badge_outlined,
                                  ),
                                  items: AppRole.values
                                      .map(
                                        (role) => DropdownMenuItem<AppRole>(
                                          value: role,
                                          child: Text(
                                            role.label,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _controller.role.value = value;
                                    }
                                  },
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.forgotPassword),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: Obx(
                                  () => ElevatedButton(
                                    onPressed: _controller.isLoading.value
                                        ? null
                                        : _onLoginPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5A31D6),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _controller.isLoading.value
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.3,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Align(
                              //   alignment: Alignment.center,
                              //   child: Text(
                              //     'Demo UI with GetX',
                              //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              //       color: const Color(0xFF8A85A0),
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.register),
                                  child: const Text(
                                    'Create new account',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24, width: 2),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.1),
      ),
    );
  }
}
