class RoomResponseDto {
  RoomResponseDto({
    required this.id,
    required this.hotelId,
    required this.hotelName,
    required this.roomType,
    required this.description,
    required this.price,
    required this.available,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  final int id;
  final int hotelId;
  final String hotelName;
  final String roomType;
  final String description;
  final double price;
  final bool available;
  final List<String> photos;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;

  RoomResponseDto copyWith({
    int? id,
    int? hotelId,
    String? hotelName,
    String? roomType,
    String? description,
    double? price,
    bool? available,
    List<String>? photos,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return RoomResponseDto(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      roomType: roomType ?? this.roomType,
      description: description ?? this.description,
      price: price ?? this.price,
      available: available ?? this.available,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  factory RoomResponseDto.fromJson(Map<String, dynamic> json) {
    return RoomResponseDto(
      id: _toInt(json['id']),
      hotelId: _toInt(_extractHotelId(json)),
      hotelName: _extractHotelName(json),
      roomType: (json['roomType'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      price: _toDouble(json['price']),
      available: _toBool(json['available']),
      photos: _extractPhotos(json),
      createdAt: (json['createdat'] as String?)?.trim() ?? '',
      updatedAt: (json['updatedat'] as String?)?.trim() ?? '',
      createdBy: (json['createdby'] as String?)?.trim() ?? '',
      updatedBy: (json['updatedby'] as String?)?.trim() ?? '',
    );
  }

  static dynamic _extractHotelId(Map<String, dynamic> json) {
    final hotel = json['hotel'];
    if (hotel is Map) {
      return hotel['id'];
    }
    return json['hotelId'] ?? json['hotelid'];
  }

  static String _extractHotelName(Map<String, dynamic> json) {
    final hotel = json['hotel'];
    if (hotel is Map) {
      final name = (hotel['name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    final fromTopLevel =
        (json['hotelName'] as String?)?.trim() ??
        (json['hotelname'] as String?)?.trim() ??
        '';
    return fromTopLevel;
  }

  static List<String> _extractPhotos(Map<String, dynamic> json) {
    final raw =
        json['photos'] ??
        json['roomPhotos'] ??
        json['photoUrls'] ??
        json['photourls'] ??
        json['images'] ??
        json['imageUrls'] ??
        json['imageurls'] ??
        json['photo'] ??
        json['image'];
    if (raw is List) {
      return raw
          .map((item) {
            if (item is String) return item.trim();
            if (item is Map) {
              final fileName =
                  item['filename'] ??
                  item['fileName'] ??
                  item['name'] ??
                  item['photo'] ??
                  item['photoUrl'] ??
                  item['photoURL'] ??
                  item['image'] ??
                  item['imageUrl'] ??
                  item['imageURL'] ??
                  item['url'] ??
                  item['path'] ??
                  item['filePath'] ??
                  item['filepath'];
              return (fileName as String?)?.trim() ?? '';
            }
            return '';
          })
          .where((element) => element.isNotEmpty)
          .toList(growable: false);
    }

    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }

    return const [];
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final raw = value?.toString().toLowerCase().trim() ?? '';
    return raw == 'true' || raw == '1' || raw == 'yes';
  }
}
