import 'package:get/get.dart';
import 'package:stay_booking_frontend/routes/hotel_form_binding.dart';
import 'package:stay_booking_frontend/view/vendor/hotel_create_page.dart';
import 'package:stay_booking_frontend/view/vendor/hotel_edit_page.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';

class HotelFormRoutes {
  HotelFormRoutes._();

  static List<GetPage<dynamic>> pages() {
    return <GetPage<dynamic>>[
      GetPage(
        name: AppRoutes.vendorCreateHotel,
        page: () => const HotelCreatePage(),
        binding: HotelFormBinding(),
      ),
      GetPage(
        name: AppRoutes.vendorEditHotel,
        page: () => const HotelEditPage(),
        binding: HotelFormBinding(),
      ),
    ];
  }
}

