import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';
import 'package:stay_booking_frontend/controller/notification_controller.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/routes/auth_guard.dart';
import 'package:stay_booking_frontend/service/core/http_client.dart';
import 'package:stay_booking_frontend/service/notification/push_notification_service.dart';
import 'package:stay_booking_frontend/view/admin_home_screen.dart';
import 'package:stay_booking_frontend/view/forgot_password_screen.dart';
import 'package:stay_booking_frontend/view/home_screen.dart';
import 'package:stay_booking_frontend/view/login_screen.dart';
import 'package:stay_booking_frontend/view/notification/notification_screen.dart';
import 'package:stay_booking_frontend/view/register_screen.dart';
import 'package:stay_booking_frontend/view/reset_password_screen.dart';
import 'package:stay_booking_frontend/view/splashscreen.dart';
import 'package:stay_booking_frontend/view/vendor/add_room_screen.dart';
import 'package:stay_booking_frontend/view/vendor_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authController = await Get.putAsync<AuthController>(
    () => AuthController().init(),
    permanent: true,
  );
  HttpClient.initialize(authController);
  Get.put(NotificationController(), permanent: true);
  await Get.putAsync<PushNotificationService>(
    () => PushNotificationService().init(),
    permanent: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(
          name: AppRoutes.notifications,
          page: () => const NotificationScreen(),
          middlewares: [AuthGuard()],
        ),
        GetPage(
          name: AppRoutes.adminHome,
          page: () => const AdminHomeScreen(),
          middlewares: [
            AuthGuard(allowedRoles: {'ADMIN'}),
          ],
        ),
        GetPage(
          name: AppRoutes.vendorHome,
          page: () => const VendorHomeScreen(),
          middlewares: [
            AuthGuard(allowedRoles: {'VENDOR', 'ADMIN'}),
          ],
        ),
        GetPage(
          name: AppRoutes.vendorAddRoom,
          page: () {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            final user = args['user'] is Map<String, dynamic>
                ? args['user'] as Map<String, dynamic>
                : <String, dynamic>{};
            final hotelId = args['hotelId'] is int
                ? args['hotelId'] as int
                : int.tryParse(args['hotelId']?.toString() ?? '') ?? 0;
            final hotelName = args['hotelName']?.toString().trim() ?? '';
            return AddRoomScreen(
              user: user,
              hotelId: hotelId,
              hotelName: hotelName,
            );
          },
          middlewares: [
            AuthGuard(allowedRoles: {'VENDOR', 'ADMIN'}),
          ],
        ),
        GetPage(name: AppRoutes.register, page: () => RegisterScreen()),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => ForgotPasswordScreen(),
        ),
        GetPage(
          name: AppRoutes.resetPassword,
          page: () => ResetPasswordScreen(),
        ),

        GetPage(
          name: AppRoutes.forgotPasswordLegacy,
          page: () => ForgotPasswordScreen(),
        ),
      ],
    );
  }
}
