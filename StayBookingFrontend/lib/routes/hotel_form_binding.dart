import 'package:get/get.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_form_api_service.dart';
import 'package:stay_booking_frontend/controller/hotel_form_controller.dart';

class HotelFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IHotelApiService>(
      () => HotelApiService(),
    );
    Get.lazyPut<HotelFormController>(
      () => HotelFormController(
        hotelApiService: Get.find<IHotelApiService>(),
      ),
    );
  }
}

