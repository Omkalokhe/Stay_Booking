class CreateHotelRequestDto {
  CreateHotelRequestDto({
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.rating,
    required this.createdBy,
  });

  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double rating;
  final String createdBy;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'rating': rating,
      'createdby': createdBy,
    };
  }
}
