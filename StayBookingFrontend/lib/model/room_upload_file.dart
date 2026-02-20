import 'package:file_picker/file_picker.dart';

class RoomUploadFile {
  RoomUploadFile({
    required this.fileName,
    this.path,
    this.bytes,
  });

  final String fileName;
  final String? path;
  final List<int>? bytes;

  factory RoomUploadFile.fromPlatformFile(PlatformFile file) {
    return RoomUploadFile(
      fileName: file.name.trim().isEmpty ? 'photo.jpg' : file.name.trim(),
      path: file.path,
      bytes: file.bytes,
    );
  }
}
