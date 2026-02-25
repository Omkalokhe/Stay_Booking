import 'package:http/http.dart' as http;
import 'package:stay_booking_frontend/controller/auth_controller.dart';

class AuthHttpClient extends http.BaseClient {
  AuthHttpClient({
    required http.Client inner,
    required AuthController authController,
  }) : _inner = inner,
       _authController = authController;

  final http.Client _inner;
  final AuthController _authController;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isPublicRequest = !_shouldAttachToken(request);
    if (!isPublicRequest) {
      final token = _authController.session.value?.accessToken.trim() ?? '';
      final tokenType = _authController.session.value?.tokenType.trim();
      if (token.isNotEmpty) {
        request.headers['Authorization'] =
            '${(tokenType?.isNotEmpty ?? false) ? tokenType : 'Bearer'} $token';
      }
    }

    final response = await _inner.send(request);
    if (!isPublicRequest && response.statusCode == 401) {
      await _authController.handleUnauthorized();
    } else if (!isPublicRequest && response.statusCode == 403) {
      _authController.handleForbidden();
    }
    return response;
  }

  bool _shouldAttachToken(http.BaseRequest request) {
    final method = request.method.toUpperCase();
    final path = request.url.path.toLowerCase();

    if (path == '/api/auth/login') return false;
    if (path.startsWith('/api/auth/password/')) return false;
    if (path == '/api/users/register') return false;
    if (method == 'GET' && (path == '/api/hotels' || path.startsWith('/api/hotels/'))) {
      return false;
    }
    if (method == 'GET' && (path == '/api/rooms' || path.startsWith('/api/rooms/'))) {
      return false;
    }
    if (method == 'GET' && path.startsWith('/api/reviews/hotel/')) return false;
    return true;
  }
}

class HttpClient {
  static http.Client? _instance;

  static void initialize(AuthController authController) {
    _instance = AuthHttpClient(
      inner: http.Client(),
      authController: authController,
    );
  }

  static http.Client get instance {
    final current = _instance;
    if (current != null) return current;
    throw StateError('HttpClient not initialized. Call HttpClient.initialize first.');
  }
}
