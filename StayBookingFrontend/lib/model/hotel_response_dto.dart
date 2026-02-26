class HotelResponseDto {
  HotelResponseDto({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.photoUrls = const <String>[],
  });

  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double rating;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;
  final List<String> photoUrls;

  factory HotelResponseDto.fromJson(Map<String, dynamic> json) {
    return HotelResponseDto(
      id: _toInt(json['id']),
      name: (json['name'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      address: (json['address'] as String?)?.trim() ?? '',
      city: (json['city'] as String?)?.trim() ?? '',
      state: (json['state'] as String?)?.trim() ?? '',
      country: (json['country'] as String?)?.trim() ?? '',
      pincode: (json['pincode'] as String?)?.trim() ?? '',
      rating: _toDouble(json['rating']),
      createdAt: (json['createdat'] as String?)?.trim() ?? '',
      updatedAt: (json['updatedat'] as String?)?.trim() ?? '',
      createdBy: (json['createdby'] as String?)?.trim() ?? '',
      updatedBy: (json['updatedby'] as String?)?.trim() ?? '',
      photoUrls: _toStringList(json['photoUrls'] ?? json['photos']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}
