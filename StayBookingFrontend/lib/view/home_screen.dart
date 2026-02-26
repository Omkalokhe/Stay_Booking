import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';
import 'package:stay_booking_frontend/controller/booking/booking_controller.dart';
import 'package:stay_booking_frontend/controller/customer_hotel_controller.dart';
import 'package:stay_booking_frontend/controller/notification_controller.dart';
import 'package:stay_booking_frontend/view/home/tabs/booking_tab.dart';
import 'package:stay_booking_frontend/view/home/tabs/home_tab.dart';
import 'package:stay_booking_frontend/view/home/tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthController _authController = Get.find<AuthController>();
  final NotificationController _notificationController =
      Get.find<NotificationController>();
  int _selectedIndex = 0;
  bool _initializedFromArgs = false;
  static const _customerHotelsTag = 'customer-hotels';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshCurrentTabIfStale();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationController.refreshOnAppResume();
      if (_selectedIndex == 0) {
        _refreshCustomerHotels(maxAge: const Duration(seconds: 0));
      } else if (_selectedIndex == 1) {
        _refreshCustomerBookings(maxAge: const Duration(seconds: 0));
      }
    }
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _refreshCustomerHotels(maxAge: const Duration(seconds: 0));
    } else if (index == 1) {
      _refreshCustomerBookings(maxAge: const Duration(seconds: 0));
    }
  }

  Future<void> _refreshCurrentTabIfStale() async {
    if (!mounted) return;
    if (_selectedIndex == 0) {
      await _refreshCustomerHotels(maxAge: const Duration(seconds: 20));
    } else if (_selectedIndex == 1) {
      await _refreshCustomerBookings(maxAge: const Duration(seconds: 20));
    }
  }

  Future<void> _refreshCustomerHotels({required Duration maxAge}) async {
    if (!Get.isRegistered<CustomerHotelController>(
      tag: _customerHotelsTag,
    )) {
      return;
    }
    final controller = Get.find<CustomerHotelController>(
      tag: _customerHotelsTag,
    );
    await controller.refreshIfStale(maxAge: maxAge);
  }

  Future<void> _refreshCustomerBookings({required Duration maxAge}) async {
    final user = _extractUserFromArgs();
    final email = (user['email'] as String?)?.trim() ?? 'user';
    final tag = 'booking-$email';
    if (!Get.isRegistered<BookingController>(tag: tag)) {
      return;
    }
    final controller = Get.find<BookingController>(tag: tag);
    await controller.refreshIfStale(maxAge: maxAge);
  }

  Map<String, dynamic> _extractUserFromArgs() {
    final rawArgs = Get.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      final nestedUser = args['user'];
      if (nestedUser is Map) {
        return Map<String, dynamic>.from(nestedUser);
      }
      return args;
    }
    if (_authController.isAuthenticated) {
      return Map<String, dynamic>.from(_authController.currentUser);
    }
    return <String, dynamic>{};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;
    _initializedFromArgs = true;

    final rawArgs = Get.arguments;
    if (rawArgs is! Map) return;
    final args = Map<String, dynamic>.from(rawArgs);
    final tabRaw = args['initialTab'];
    final parsedTab = tabRaw is int
        ? tabRaw
        : int.tryParse(tabRaw?.toString() ?? '');
    if (parsedTab != null && parsedTab >= 0 && parsedTab <= 2) {
      _selectedIndex = parsedTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authController.isAuthenticated;
    final user = _extractUserFromArgs();
    final tabCount = isAuthenticated ? 3 : 1;
    if (_selectedIndex >= tabCount) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: Color(0xFF3F1D89),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(),
        child: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeTab(user: user),
                if (isAuthenticated) BookingTab(user: user),
                if (isAuthenticated) ProfileTab(user: user),
              ],
            ),
          ),
      ),
      bottomNavigationBar: isAuthenticated
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: NavigationBar(
                    height: 70,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onDestinationSelected,
                    backgroundColor: const Color(0xFFFAF9FF),
                    elevation: 8,
                    indicatorColor: const Color(0xFFD9CCFF),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        selectedIcon: Icon(Icons.calendar_month_rounded),
                        label: 'Booking',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline_rounded),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
