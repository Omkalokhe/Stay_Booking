import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/constants/hotel_form_constants.dart';
import 'package:stay_booking_frontend/controller/hotel_form_controller.dart';
import 'package:stay_booking_frontend/view/vendor/widgets/hotel_form.dart';

class HotelCreatePage extends GetView<HotelFormController> {
  const HotelCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
    final user = args['user'] is Map ? Map<String, dynamic>.from(args['user'] as Map) : <String, dynamic>{};
    final email = (user['email'] as String?)?.trim() ?? '';
    if (email.isNotEmpty && controller.createdBy.value.trim().isEmpty) {
      controller.createdBy.value = email;
    }

    return Scaffold(
      appBar: AppBar(title: const Text(HotelFormConstants.titleCreateHotel)),
      body: HotelForm(
        controller: controller,
        isEditMode: false,
        onSubmit: () async {
          final success = await controller.submitCreate();
          if (success && context.mounted) {
            Navigator.of(context).pop(true);
          }
        },
      ),
    );
  }
}

