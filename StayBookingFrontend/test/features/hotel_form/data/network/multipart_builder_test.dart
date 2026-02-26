import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stay_booking_frontend/model/hotel_form/create_hotel_request.dart';
import 'package:stay_booking_frontend/model/hotel_form/update_hotel_request.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_form_multipart_builder.dart';

void main() {
  group('multipart builder', () {
    test('buildCreateHotelMultipartPayload includes only non-empty fields and photos', () async {
      final tmpDir = await Directory.systemTemp.createTemp('hotel_form_create');
      final photo = File('${tmpDir.path}/one.jpg');
      await photo.writeAsBytes(List<int>.filled(1024, 1));

      final req = CreateHotelRequest(
        name: 'Hotel A',
        city: 'Pune',
        country: 'India',
        description: '',
        photos: <XFile>[XFile(photo.path)],
      );

      final payload = await buildCreateHotelMultipartPayload(req);
      final map = payload.fields;

      expect(map['name'], 'Hotel A');
      expect(map['city'], 'Pune');
      expect(map['country'], 'India');
      expect(map.containsKey('description'), isFalse);
      expect(payload.files.length, 1);
      expect(payload.files.first.field, 'photos');
    });

    test('buildUpdateHotelMultipartPayload appends replacePhotos true/false', () async {
      final req = UpdateHotelRequest(
        name: 'Hotel B',
        replacePhotos: true,
      );

      final payload = await buildUpdateHotelMultipartPayload(req);
      final map = payload.fields;

      expect(map['name'], 'Hotel B');
      expect(map['replacePhotos'], 'true');
    });
  });
}

