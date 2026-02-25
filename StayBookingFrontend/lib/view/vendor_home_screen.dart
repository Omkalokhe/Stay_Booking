import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/booking/booking_controller.dart';
import 'package:stay_booking_frontend/controller/vendor_hotel_controller.dart';
import 'package:stay_booking_frontend/controller/vendor_room_controller.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_booking_tab.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_hotel_tab.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_profile_tab_screen.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_room_tab.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _initializedFromArgs = false;
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
      _refreshCurrentTab(force: true);
    }
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    _refreshCurrentTab(force: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;
    _initializedFromArgs = true;

    final rawArgs = Get.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      final tabRaw = args['initialTab'];
      final parsedTab = tabRaw is int
          ? tabRaw
          : int.tryParse(tabRaw?.toString() ?? '');
      if (parsedTab != null && parsedTab >= 0 && parsedTab <= 3) {
        _selectedIndex = parsedTab;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = Get.arguments;
    final user = _extractUser(rawArgs);

    return Scaffold(
      backgroundColor: Color(0xFF3F1D89),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              VendorHotelTab(user: user),
              VendorRoomTab(user: user),
              VendorBookingTab(user: user),
              VendorProfileTabScreen(user: user),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NavigationBar(
              height: 70,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,

              backgroundColor: Colors.white,
              elevation: 8,

              indicatorColor: const Color(0xFFEDE7FF),

              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.apartment_outlined),
                  selectedIcon: Icon(Icons.apartment_rounded),
                  label: 'Hotel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bedroom_parent_outlined),
                  selectedIcon: Icon(Icons.bedroom_parent_rounded),
                  label: 'Room',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
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
      ),
    );
  }

  Map<String, dynamic> _extractUser(dynamic rawArgs) {
    if (rawArgs is! Map) return <String, dynamic>{};
    final args = Map<String, dynamic>.from(rawArgs);
    final nestedUser = args['user'];
    if (nestedUser is Map) {
      return Map<String, dynamic>.from(nestedUser);
    }
    return args;
  }

  Future<void> _refreshCurrentTabIfStale() async {
    await _refreshCurrentTab(force: false);
  }

  Future<void> _refreshCurrentTab({required bool force}) async {
    if (!mounted) return;
    final user = _extractUser(Get.arguments);
    final email = (user['email'] as String?)?.trim() ?? 'vendor';
    final maxAge = force
        ? const Duration(seconds: 0)
        : const Duration(seconds: 20);

    if (_selectedIndex == 0) {
      final tag = 'vendor-hotel-$email';
      if (Get.isRegistered<VendorHotelController>(tag: tag)) {
        final controller = Get.find<VendorHotelController>(tag: tag);
        await controller.refreshIfStale(maxAge: maxAge);
      }
      return;
    }

    if (_selectedIndex == 1) {
      final tag = 'vendor-room-$email';
      if (Get.isRegistered<VendorRoomController>(tag: tag)) {
        final controller = Get.find<VendorRoomController>(tag: tag);
        await controller.refreshIfStale(maxAge: maxAge);
      }
      return;
    }

    if (_selectedIndex == 2) {
      final tag = 'vendor-booking-$email';
      if (Get.isRegistered<BookingController>(tag: tag)) {
        final controller = Get.find<BookingController>(tag: tag);
        await controller.refreshIfStale(maxAge: maxAge);
      }
    }
  }
}
