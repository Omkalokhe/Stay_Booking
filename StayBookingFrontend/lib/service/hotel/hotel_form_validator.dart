import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:stay_booking_frontend/constants/hotel_form_constants.dart';

class HotelFormValidator {
  const HotelFormValidator._();

  static String? validateCreateRequired({
    required String name,
    required String city,
    required String country,
  }) {
    if (name.trim().isEmpty) return HotelFormValidationMessages.requiredName;
    if (city.trim().isEmpty) return HotelFormValidationMessages.requiredCity;
    if (country.trim().isEmpty) return HotelFormValidationMessages.requiredCountry;
    return null;
  }

  static String? validateRating(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final rating = double.tryParse(trimmed);
    if (rating == null) return HotelFormValidationMessages.invalidRating;
    if (rating < 0.0 || rating > 5.0) {
      return HotelFormValidationMessages.invalidRatingRange;
    }
    return null;
  }

  static Future<String?> validateImageFile(XFile file) async {
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    if (!HotelFormConstants.allowedImageExtensions.contains(ext)) {
      return HotelFormValidationMessages.invalidImageType;
    }

    final size = await file.length();
    if (size > HotelFormConstants.maxFileSizeInBytes) {
      return HotelFormValidationMessages.invalidImageSize;
    }
    return null;
  }
}

