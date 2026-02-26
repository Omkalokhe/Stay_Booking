import 'package:image_picker/image_picker.dart';

class UpdateHotelRequest {
  const UpdateHotelRequest({
    this.name,
    this.city,
    this.country,
    this.description,
    this.address,
    this.state,
    this.pincode,
    this.rating,
    this.updatedBy,
    this.photos = const <XFile>[],
    this.replacePhotos = false,
  });

  final String? name;
  final String? city;
  final String? country;
  final String? description;
  final String? address;
  final String? state;
  final String? pincode;
  final double? rating;
  final String? updatedBy;
  final List<XFile> photos;
  final bool replacePhotos;
}
