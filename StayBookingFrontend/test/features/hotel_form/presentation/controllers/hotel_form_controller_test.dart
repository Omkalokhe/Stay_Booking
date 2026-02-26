import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stay_booking_frontend/model/core/api_error.dart';
import 'package:stay_booking_frontend/model/core/result.dart';
import 'package:stay_booking_frontend/model/hotel_form/create_hotel_request.dart';
import 'package:stay_booking_frontend/model/hotel_form/hotel_model.dart';
import 'package:stay_booking_frontend/model/hotel_form/update_hotel_request.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_form_api_service.dart';
import 'package:stay_booking_frontend/controller/hotel_form_controller.dart';

class _MockHotelApiService extends Mock implements IHotelApiService {}

class _FakeCreateHotelRequest extends Fake implements CreateHotelRequest {}

class _FakeUpdateHotelRequest extends Fake implements UpdateHotelRequest {}

void main() {
  late _MockHotelApiService service;
  late HotelFormController controller;

  setUpAll(() {
    registerFallbackValue(_FakeCreateHotelRequest());
    registerFallbackValue(_FakeUpdateHotelRequest());
  });

  setUp(() {
    Get.testMode = true;
    service = _MockHotelApiService();
    controller = HotelFormController(
      hotelApiService: service,
      onMessage: (_, __) {},
    );
  });

  test('submitCreate success flow', () async {
    controller.name.value = 'Hotel One';
    controller.city.value = 'Pune';
    controller.country.value = 'India';

    when(() => service.createHotel(any())).thenAnswer(
      (_) async => Result.success(_hotel(id: 1, name: 'Hotel One')),
    );

    final success = await controller.submitCreate();
    expect(success, isTrue);
    expect(controller.errorMessage.value, isNull);
    expect(controller.lastLoadedHotel?.id, 1);
    verify(() => service.createHotel(any())).called(1);
  });

  test('submitUpdate failure flow', () async {
    controller.name.value = 'Hotel Two';
    controller.rating.value = '4.2';

    when(() => service.updateHotel(any(), any())).thenAnswer(
      (_) async => Result.failure(
        const ApiError(message: 'Update failed'),
      ),
    );

    final success = await controller.submitUpdate(10);
    expect(success, isFalse);
    expect(controller.errorMessage.value, 'Update failed');
    verify(() => service.updateHotel(10, any())).called(1);
  });
}

HotelModel _hotel({required int id, required String name}) {
  return HotelModel(
    id: id,
    name: name,
    city: 'Pune',
    country: 'India',
    description: '',
    address: '',
    state: '',
    pincode: '',
    rating: 4.5,
    createdBy: null,
    updatedBy: null,
    photoUrls: const <String>[],
  );
}

