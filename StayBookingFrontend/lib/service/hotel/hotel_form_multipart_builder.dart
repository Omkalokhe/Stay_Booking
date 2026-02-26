import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:stay_booking_frontend/constants/hotel_form_constants.dart';
import 'package:stay_booking_frontend/model/hotel_form/create_hotel_request.dart';
import 'package:stay_booking_frontend/model/hotel_form/update_hotel_request.dart';

class MultipartPayload {
  const MultipartPayload({
    required this.fields,
    required this.files,
  });

  final Map<String, String> fields;
  final List<http.MultipartFile> files;
}

Future<MultipartPayload> buildCreateHotelMultipartPayload(
  CreateHotelRequest request,
) async {
  final map = <String, String>{};
  _addString(map, 'name', request.name);
  _addString(map, 'city', request.city);
  _addString(map, 'country', request.country);
  _addString(map, 'description', request.description);
  _addString(map, 'address', request.address);
  _addString(map, 'state', request.state);
  _addString(map, 'pincode', request.pincode);
  _addDouble(map, 'rating', request.rating);
  _addString(map, 'createdby', request.createdBy);

  return _toPayload(map, request.photos);
}

Future<MultipartPayload> buildUpdateHotelMultipartPayload(
  UpdateHotelRequest request,
) async {
  final map = <String, String>{};
  _addString(map, 'name', request.name);
  _addString(map, 'city', request.city);
  _addString(map, 'country', request.country);
  _addString(map, 'description', request.description);
  _addString(map, 'address', request.address);
  _addString(map, 'state', request.state);
  _addString(map, 'pincode', request.pincode);
  _addDouble(map, 'rating', request.rating);
  _addString(map, 'updatedby', request.updatedBy);
  map[HotelFormConstants.fieldReplacePhotos] =
      request.replacePhotos ? 'true' : 'false';

  return _toPayload(map, request.photos);
}

Future<MultipartPayload> _toPayload(
  Map<String, String> fields,
  List<XFile> photos,
) async {
  final files = <http.MultipartFile>[];
  for (final file in photos) {
    files.add(await _toMultipartFile(file));
  }
  return MultipartPayload(fields: fields, files: files);
}

Future<http.MultipartFile> _toMultipartFile(XFile file) async {
  final path = file.path;
  final filename = file.name.trim().isNotEmpty ? file.name.trim() : p.basename(path);
  final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
  final split = mimeType.split('/');
  final mediaType = split.length == 2
      ? MediaType(split.first, split.last)
      : MediaType('application', 'octet-stream');
  final bytes = await file.readAsBytes();

  return http.MultipartFile.fromBytes(
    HotelFormConstants.fieldPhotos,
    bytes,
    filename: filename,
    contentType: mediaType,
  );
}

void _addString(Map<String, String> map, String key, String? value) {
  final v = value?.trim() ?? '';
  if (v.isNotEmpty) {
    map[key] = v;
  }
}

void _addDouble(Map<String, String> map, String key, double? value) {
  if (value != null) {
    map[key] = value.toString();
  }
}

