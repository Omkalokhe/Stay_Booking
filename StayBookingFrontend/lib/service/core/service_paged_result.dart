import 'package:stay_booking_frontend/model/core/paginated_response.dart';

class ServicePagedResult<T> {
  const ServicePagedResult({
    required this.success,
    required this.message,
    required this.pageData,
  });

  final bool success;
  final String message;
  final PaginatedResponse<T> pageData;
}