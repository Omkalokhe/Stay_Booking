import 'package:http/http.dart' as http;

class HttpClient {
  static final http.Client _instance = http.Client();

  static http.Client get instance => _instance;
}
