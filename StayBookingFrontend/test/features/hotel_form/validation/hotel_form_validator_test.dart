import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stay_booking_frontend/constants/hotel_form_constants.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_form_validator.dart';

void main() {
  group('HotelFormValidator', () {
    test('validateCreateRequired returns errors for missing required fields', () {
      final error = HotelFormValidator.validateCreateRequired(
        name: '',
        city: 'Pune',
        country: 'India',
      );
      expect(error, HotelFormValidationMessages.requiredName);
    });

    test('validateRating validates range', () {
      expect(
        HotelFormValidator.validateRating('5.5'),
        HotelFormValidationMessages.invalidRatingRange,
      );
      expect(HotelFormValidator.validateRating('4.5'), isNull);
    });

    test('validateImageFile validates extension and size', () async {
      final tmpDir = await Directory.systemTemp.createTemp('hotel_form_validator');
      final file = File('${tmpDir.path}/ok.jpg');
      await file.writeAsBytes(List<int>.filled(1024, 1));

      final xFile = XFile(file.path);
      final error = await HotelFormValidator.validateImageFile(xFile);
      expect(error, isNull);

      final badFile = File('${tmpDir.path}/bad.txt');
      await badFile.writeAsBytes(List<int>.filled(1024, 1));
      final badError = await HotelFormValidator.validateImageFile(XFile(badFile.path));
      expect(badError, HotelFormValidationMessages.invalidImageType);
    });
  });
}

