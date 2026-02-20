import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stay_booking_frontend/controller/register_controller.dart';
import 'package:stay_booking_frontend/model/app_role.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final RegisterController _controller = Get.put(RegisterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
              final contentWidth = constraints.maxWidth >= 1100
                  ? 1000.0
                  : constraints.maxWidth >= 800
                      ? 760.0
                      : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _controller.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Register',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fill details to create your account',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.black54,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              _buildResponsiveFields(contentWidth),
                              const SizedBox(height: 16),
                              Obx(
                                () => DropdownButtonFormField<AppRole>(
                                  initialValue: _controller.role.value,
                                  decoration: _inputDecoration(
                                    'Role',
                                    Icons.badge_outlined,
                                  ),
                                  items: AppRole.values
                                      .map(
                                        (appRole) => DropdownMenuItem<AppRole>(
                                          value: appRole,
                                          child: Text(appRole.label),
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
                              const SizedBox(height: 16),
                              Obx(
                                () => DropdownButtonFormField<String>(
                                  initialValue: _controller.gender.value,
                                  decoration: _inputDecoration('Gender', Icons.wc_outlined),
                                  items: const [
                                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _controller.gender.value = value;
                                    }
                                  },
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
                                        : _controller.registerUser,
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
                                            'Submit',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
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

  Widget _buildResponsiveFields(double width) {
    const spacing = 16.0;
    final columns = width >= 900 ? 2 : 1;
    final fieldWidth = columns == 2
        ? (width - spacing) / 2
        : double.infinity;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.fnameController,
            decoration: _inputDecoration('First Name', Icons.person_outline),
            validator: (value) => _controller.requiredField(value, 'First name'),
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.lnameController,
            decoration: _inputDecoration('Last Name', Icons.person_outline),
            validator: (value) => _controller.requiredField(value, 'Last name'),
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email', Icons.mail_outline),
            validator: _controller.validateEmail,
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: Obx(
            () => TextFormField(
              controller: _controller.passwordController,
              obscureText: _controller.isPasswordHidden.value,
              decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  onPressed: _controller.togglePasswordVisibility,
                  icon: Icon(
                    _controller.isPasswordHidden.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: _controller.validatePassword,
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.mobileController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Mobile Number', Icons.phone_outlined),
            validator: _controller.validatePhone,
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.addressController,
            decoration: _inputDecoration('Address', Icons.location_on_outlined),
            validator: (value) => _controller.requiredField(value, 'Address'),
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.cityController,
            decoration: _inputDecoration('City', Icons.location_city_outlined),
            validator: (value) => _controller.requiredField(value, 'City'),
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.stateController,
            decoration: _inputDecoration('State', Icons.map_outlined),
            validator: (value) => _controller.requiredField(value, 'State'),
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.countryController,
            decoration: _inputDecoration('Country', Icons.public_outlined),
            validator: (value) => _controller.requiredField(value, 'Country'),
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.pincodeController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Pincode', Icons.pin_outlined),
            validator: _controller.validatePincode,
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }

  Widget _fieldBox({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
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
