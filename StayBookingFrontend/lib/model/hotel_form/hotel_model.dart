class HotelModel {
  const HotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.description,
    required this.address,
    required this.state,
    required this.pincode,
    required this.rating,
    required this.createdBy,
    required this.updatedBy,
    required this.photoUrls,
  });

  final int id;
  final String name;
  final String city;
  final String country;
  final String description;
  final String address;
  final String state;
  final String pincode;
  final double? rating;
  final String? createdBy;
  final String? updatedBy;
  final List<String> photoUrls;

  String get fullAddress {
    final parts = <String>[name, address, city, state, pincode]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return parts.join(', ');
  }

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['photoUrls'];
    return HotelModel(
      id: _toInt(json['id']),
      name: (json['name'] as String?)?.trim() ?? '',
      city: (json['city'] as String?)?.trim() ?? '',
      country: (json['country'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      address: (json['address'] as String?)?.trim() ?? '',
      state: (json['state'] as String?)?.trim() ?? '',
      pincode: (json['pincode'] as String?)?.trim() ?? '',
      rating: _toDoubleNullable(json['rating']),
      createdBy: (json['createdby'] as String?)?.trim(),
      updatedBy: (json['updatedby'] as String?)?.trim(),
      photoUrls: rawUrls is List
          ? rawUrls
                .whereType<Object?>()
                .map((e) => e?.toString().trim() ?? '')
                .where((value) => value.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
