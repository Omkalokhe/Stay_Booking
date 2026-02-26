class HotelFormConstants {
  HotelFormConstants._();

  static const String titleCreateHotel = 'Create Hotel';
  static const String titleEditHotel = 'Edit Hotel';
  static const String buttonCreateHotel = 'Create Hotel';
  static const String buttonUpdateHotel = 'Update Hotel';
  static const String buttonPickImages = 'Pick Images';
  static const String labelReplacePhotos = 'Replace existing photos';
  static const String hintName = 'Hotel name';
  static const String hintDescription = 'Description';
  static const String hintAddress = 'Address';
  static const String hintCity = 'City';
  static const String hintState = 'State';
  static const String hintCountry = 'Country';
  static const String hintPincode = 'Pincode';
  static const String hintRating = 'Rating (0.0 - 5.0)';
  static const String hintCreatedBy = 'Created By';
  static const String hintUpdatedBy = 'Updated By';
  static const String textInvalidHotelId = 'Invalid hotel id';
  static const String snackbarSuccessTitle = 'Success';
  static const String snackbarErrorTitle = 'Error';

  static const String fieldPhotos = 'photos';
  static const String fieldReplacePhotos = 'replacePhotos';

  static const int maxFileSizeInBytes = 5 * 1024 * 1024;
  static const Set<String> allowedImageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'svg',
  };

  static const String messageCreateSuccess = 'Hotel created successfully.';
  static const String messageUpdateSuccess = 'Hotel updated successfully.';
  static const String messageLoadFailed = 'Unable to load hotel details.';
  static const String messagePickImagesFailed = 'Unable to pick images.';
  static const String messageUnknownError =
      'Something went wrong. Please try again.';
}

class HotelFormValidationMessages {
  HotelFormValidationMessages._();

  static const String requiredName = 'Name is required.';
  static const String requiredCity = 'City is required.';
  static const String requiredCountry = 'Country is required.';
  static const String invalidRating = 'Rating must be a valid number.';
  static const String invalidRatingRange = 'Rating must be between 0.0 and 5.0.';
  static const String invalidImageType =
      'Only jpg, jpeg, png, gif, webp, or svg files are allowed.';
  static const String invalidImageSize =
      'Each image must be 5 MB or smaller.';
}
