import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/constants/hotel_form_constants.dart';
import 'package:stay_booking_frontend/controller/hotel_form_controller.dart';
import 'package:stay_booking_frontend/view/vendor/widgets/hotel_form.dart';

class HotelEditPage extends GetView<HotelFormController> {
  const HotelEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
    final hotelId = args['hotelId'];
    final parsedHotelId = hotelId is int ? hotelId : int.tryParse('$hotelId');
    final user = args['user'] is Map ? Map<String, dynamic>.from(args['user'] as Map) : <String, dynamic>{};
    final email = (user['email'] as String?)?.trim() ?? '';
    if (email.isNotEmpty && controller.updatedBy.value.trim().isEmpty) {
      controller.updatedBy.value = email;
    }

    return Scaffold(
      appBar: AppBar(title: const Text(HotelFormConstants.titleEditHotel)),
      body: parsedHotelId == null
          ? const Center(child: Text(HotelFormConstants.textInvalidHotelId))
          : FutureBuilder<void>(
              future: controller.loadHotel(parsedHotelId),
              builder: (_, snapshot) {
                return HotelForm(
                  controller: controller,
                  isEditMode: true,
                  onSubmit: () async {
                    final success = await controller.submitUpdate(parsedHotelId);
                    if (success && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                );
              },
            ),
    );
  }
}

