import 'package:flutter/material.dart';
import 'package:stay_booking_frontend/controller/profile_controller.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:get/get.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final emailKey = (user['email'] as String?)?.trim() ?? 'guest';
    final profileTag = 'profile-$emailKey';
    final profileController =
        Get.isRegistered<ProfileController>(tag: profileTag)
        ? Get.find<ProfileController>(tag: profileTag)
        : Get.put(ProfileController(initialUser: user), tag: profileTag);

    return Obx(() {
      final currentUser = profileController.user.value ?? <String, dynamic>{};
      final email = (currentUser['email'] as String?)?.trim() ?? '-';
      final role = (currentUser['role'] as String?)?.trim() ?? '-';
      final phone = (currentUser['mobileno'] as String?)?.trim() ?? '-';
      final firstName = (currentUser['fname'] as String?)?.trim() ?? '';
      final lastName = (currentUser['lname'] as String?)?.trim() ?? '';
      final fullName = '$firstName $lastName'.trim();
      final gender = (currentUser['gender'] as String?)?.trim() ?? '-';
      final address = (currentUser['address'] as String?)?.trim() ?? '-';
      final city = (currentUser['city'] as String?)?.trim() ?? '-';
      final state = (currentUser['state'] as String?)?.trim() ?? '-';
      final country = (currentUser['country'] as String?)?.trim() ?? '-';
      final pincode = (currentUser['pincode'] as String?)?.trim() ?? '-';
      final status = (currentUser['status'] as String?)?.trim() ?? '-';

      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
          titleSpacing: 12,
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF5A31D6),
                child: Text(
                  _initialsFromName(fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$role | $status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                ),
                onPressed: () => Get.offAllNamed(AppRoutes.login),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 1000
                  ? 24.0
                  : 16.0;
              final contentWidth = constraints.maxWidth >= 1000 ? 900.0 : 620.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Form(
                      key: profileController.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          if (profileController.isLoading.value)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: LinearProgressIndicator(),
                            ),
                          if (profileController.errorMessage.value.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDECEC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFC62828),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      profileController.errorMessage.value,
                                      style: const TextStyle(
                                        color: Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (profileController.isEditing.value)
                            _buildEditForm(profileController)
                          else
                            _buildReadOnlyDetails(
                              email: email,
                              phone: phone,
                              gender: gender,
                              role: role,
                              status: status,
                              address: address,
                              city: city,
                              state: state,
                              country: country,
                              pincode: pincode,
                            ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: profileController.isEditing.value
                                    ? OutlinedButton.icon(
                                        onPressed:
                                            profileController.isUpdating.value
                                            ? null
                                            : profileController.cancelEditing,
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('Cancel'),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed:
                                            profileController.startEditing,
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Update Profile'),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: profileController.isEditing.value
                                    ? ElevatedButton.icon(
                                        onPressed:
                                            profileController.isUpdating.value
                                            ? null
                                            : profileController.submitUpdate,
                                        icon: profileController.isUpdating.value
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.check_rounded),
                                        label: Text(
                                          profileController.isUpdating.value
                                              ? 'Saving...'
                                              : 'Save',
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFC62828,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed:
                                            profileController.isDeleting.value
                                            ? null
                                            : () => _showDeleteConfirmation(
                                                context,
                                                profileController,
                                              ),
                                        icon: profileController.isDeleting.value
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.delete_outline_rounded,
                                              ),
                                        label: Text(
                                          profileController.isDeleting.value
                                              ? 'Deleting...'
                                              : 'Delete Profile',
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!profileController.isEditing.value)
                                TextButton.icon(
                                  onPressed:
                                      profileController.isSendingResetOtp.value
                                      ? null
                                      : profileController
                                            .requestPasswordResetOtp,
                                  icon:
                                      profileController.isSendingResetOtp.value
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.lock_reset_rounded),
                                  label: Text(
                                    profileController.isSendingResetOtp.value
                                        ? 'Sending...'
                                        : 'Reset Password',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildReadOnlyDetails({
    required String email,
    required String phone,
    required String gender,
    required String role,
    required String status,
    required String address,
    required String city,
    required String state,
    required String country,
    required String pincode,
  }) {
    return Column(
      children: [
        _infoTile('Email', email),
        const SizedBox(height: 10),
        _infoTile('Mobile', phone),
        const SizedBox(height: 10),
        _infoTile('Gender', gender),
        const SizedBox(height: 10),
        _infoTile('Role', role),
        const SizedBox(height: 10),
        _infoTile('Status', status),
        const SizedBox(height: 10),
        _infoTile('Address', address),
        const SizedBox(height: 10),
        _infoTile('City', city),
        const SizedBox(height: 10),
        _infoTile('State', state),
        const SizedBox(height: 10),
        _infoTile('Country', country),
        const SizedBox(height: 10),
        _infoTile('Pincode', pincode),
      ],
    );
  }

  Widget _buildEditForm(ProfileController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final fieldWidth = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.fnameController,
                validator: (v) => controller.requiredField(v, 'First name'),
                decoration: _inputDecoration(
                  'First Name',
                  Icons.person_outline,
                ),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.lnameController,
                validator: (v) => controller.requiredField(v, 'Last name'),
                decoration: _inputDecoration('Last Name', Icons.person_outline),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.emailController,
                validator: controller.validateEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email', Icons.mail_outline),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.mobileController,
                validator: controller.validatePhone,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Mobile', Icons.phone_outlined),
              ),
            ),
            _field(
              width: fieldWidth,
              child: Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedGender.value,
                  items: ProfileController.genders
                      .map(
                        (g) =>
                            DropdownMenuItem<String>(value: g, child: Text(g)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) controller.selectedGender.value = value;
                  },
                  decoration: _inputDecoration('Gender', Icons.wc_outlined),
                ),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.addressController,
                validator: (v) => controller.requiredField(v, 'Address'),
                decoration: _inputDecoration('Address', Icons.home_outlined),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.cityController,
                validator: (v) => controller.requiredField(v, 'City'),
                decoration: _inputDecoration(
                  'City',
                  Icons.location_city_outlined,
                ),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.stateController,
                validator: (v) => controller.requiredField(v, 'State'),
                decoration: _inputDecoration('State', Icons.map_outlined),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.countryController,
                validator: (v) => controller.requiredField(v, 'Country'),
                decoration: _inputDecoration('Country', Icons.public_outlined),
              ),
            ),
            _field(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.pincodeController,
                validator: controller.validatePincode,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Pincode', Icons.pin_outlined),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _field({required double width, required Widget child}) {
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

  String _initialsFromName(String fullName) {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF292536), fontSize: 15),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ProfileController controller,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Profile'),
          content: const Text(
            'This action is permanent and cannot be undone. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete ?? false) {
      await controller.deleteProfile();
    }
  }
}
