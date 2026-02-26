import 'package:image_picker/image_picker.dart';

class CreateHotelRequest {
  const CreateHotelRequest({
    required this.name,
    required this.city,
    required this.country,
    this.description,
    this.address,
    this.state,
    this.pincode,
    this.rating,
    this.createdBy,
    this.photos = const <XFile>[],
  });

  final String name;
  final String city;
  final String country;
  final String? description;
  final String? address;
  final String? state;
  final String? pincode;
  final double? rating;
  final String? createdBy;
  final List<XFile> photos;
}
