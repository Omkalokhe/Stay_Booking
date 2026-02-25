import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';

class AuthGuard extends GetMiddleware {
  AuthGuard({
    this.requireAuth = true,
    this.allowedRoles = const <String>{},
  });

  final bool requireAuth;
  final Set<String> allowedRoles;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    if (requireAuth && !auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (allowedRoles.isNotEmpty) {
      final role = auth.currentRole;
      if (!allowedRoles.contains(role)) {
        auth.handleForbidden();
        final fallback = auth.isAuthenticated
            ? AppRoutes.home
            : AppRoutes.login;
        return RouteSettings(name: fallback);
      }
    }

    return null;
  }
}
