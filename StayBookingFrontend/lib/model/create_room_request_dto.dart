import 'package:stay_booking_frontend/model/room_upload_file.dart';

class CreateRoomRequestDto {
  CreateRoomRequestDto({
    required this.hotelId,
    required this.roomType,
    required this.description,
    required this.price,
    required this.available,
    required this.createdBy,
    required this.photoFiles,
  });

  final int hotelId;
  final String roomType;
  final String description;
  final double price;
  final bool available;
  final String createdBy;
  final List<RoomUploadFile> photoFiles;
}
