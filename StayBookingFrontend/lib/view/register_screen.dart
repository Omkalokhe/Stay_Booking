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
      body: Stack(
        children: [
          /// Background image
          Positioned.fill(
            child: Image.asset('assets/images/hotel.png', fit: BoxFit.cover),
          ),

          /// Gradient overlay
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

          /// Content
          SafeArea(
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
                        color: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 12,
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
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Fill details to create your account',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 20),

                                _buildResponsiveFields(contentWidth),

                                const SizedBox(height: 16),

                                /// Role dropdown
                                Obx(() {
                                  return DropdownButtonFormField<AppRole>(
                                    value: _controller.role.value,
                                    dropdownColor: Colors.black87,
                                    // style: TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      'Role',
                                      Icons.badge_outlined,
                                    ),
                                    items:
                                        const [AppRole.customer, AppRole.vendor]
                                            .map(
                                              (appRole) =>
                                                  DropdownMenuItem<AppRole>(
                                                    value: appRole,
                                                    child: Text(
                                                      appRole.label,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _controller.role.value = value;
                                      }
                                    },
                                  );
                                }),

                                const SizedBox(height: 16),

                                /// Gender dropdown
                                Obx(() {
                                  return DropdownButtonFormField<String>(
                                    value: _controller.gender.value,
                                    dropdownColor: Colors.black87,
                                    decoration: _inputDecoration(
                                      'Gender',
                                      Icons.wc_outlined,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Male',
                                        child: Text(
                                          'Male',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Female',
                                        child: Text(
                                          'Female',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Other',
                                        child: Text(
                                          'Other',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        _controller.gender.value = value;
                                      }
                                    },
                                  );
                                }),

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
                                        backgroundColor: const Color(
                                          0xFF5A31D6,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
        ],
      ),
    );
  }

  Widget _buildResponsiveFields(double width) {
    const spacing = 16.0;
    final columns = width >= 900 ? 2 : 1;
    final fieldWidth = columns == 2 ? (width - spacing) / 2 : double.infinity;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.fnameController,
            style: TextStyle(color: Colors.white),
            decoration: _inputDecoration('First Name', Icons.person_outline),
            validator: (value) =>
                _controller.requiredField(value, 'First name'),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.lnameController,
            style: TextStyle(color: Colors.white),
            decoration: _inputDecoration('Last Name', Icons.person_outline),
            validator: (value) => _controller.requiredField(value, 'Last name'),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.emailController,
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email', Icons.mail_outline),
            validator: _controller.validateEmail,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: Obx(
            () => TextFormField(
              controller: _controller.passwordController,
              style: TextStyle(color: Colors.white),
              obscureText: _controller.isPasswordHidden.value,
              decoration: _inputDecoration('Password', Icons.lock_outline)
                  .copyWith(
                    suffixIcon: IconButton(
                      onPressed: _controller.togglePasswordVisibility,
                      icon: Icon(
                        _controller.isPasswordHidden.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
              validator: _controller.validatePassword,
            ),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.mobileController,
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Mobile Number', Icons.phone_outlined),
            validator: _controller.validatePhone,
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.addressController,
            style: TextStyle(color: Colors.white),
            decoration: _inputDecoration('Address', Icons.location_on_outlined),
            validator: (value) => _controller.requiredField(value, 'Address'),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.cityController,
            style: TextStyle(color: Colors.white),
            decoration: _inputDecoration('City', Icons.location_city_outlined),
            validator: (value) => _controller.requiredField(value, 'City'),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.stateController,
            style: TextStyle(color: Colors.white),
            decoration: _inputDecoration('State', Icons.map_outlined),
            validator: (value) => _controller.requiredField(value, 'State'),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.countryController,
            style: TextStyle(color: Colors.white),
            decoration: _inputDecoration('Country', Icons.public_outlined),
            validator: (value) => _controller.requiredField(value, 'Country'),
          ),
        ),
        _fieldBox(
          width: fieldWidth,
          child: TextFormField(
            controller: _controller.pincodeController,
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Pincode', Icons.pin_outlined),
            validator: _controller.validatePincode,
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
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.transparent,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24, width: 2),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.5),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.5),
      ),
    );
  }
}
