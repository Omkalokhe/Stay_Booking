import 'package:stay_booking_frontend/model/room_upload_file.dart';

class UpdateRoomRequestDto {
  UpdateRoomRequestDto({
    required this.hotelId,
    required this.roomType,
    required this.description,
    required this.price,
    required this.available,
    required this.updatedBy,
    required this.photoFiles,
    required this.replacePhotos,
  });

  final int hotelId;
  final String roomType;
  final String description;
  final double price;
  final bool available;
  final String updatedBy;
  final List<RoomUploadFile> photoFiles;
  final bool replacePhotos;
}
