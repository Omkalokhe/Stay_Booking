import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/booking/booking_controller.dart';
import 'package:stay_booking_frontend/controller/customer_booking_controller.dart';

import 'package:stay_booking_frontend/view/home/tabs/booking_tab.dart';
import 'package:stay_booking_frontend/view/home/tabs/home_tab.dart';
import 'package:stay_booking_frontend/view/home/tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  static const _customerBookingTag = 'customer-booking';
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
    if (state == AppLifecycleState.resumed && _selectedIndex == 0) {
      _refreshCustomerRooms(maxAge: const Duration(seconds: 0));
    } else if (state == AppLifecycleState.resumed && _selectedIndex == 1) {
      _refreshCustomerBookings(maxAge: const Duration(seconds: 0));
    }
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _refreshCustomerRooms(maxAge: const Duration(seconds: 0));
    } else if (index == 1) {
      _refreshCustomerBookings(maxAge: const Duration(seconds: 0));
    }
  }

  Future<void> _refreshCurrentTabIfStale() async {
    if (!mounted) return;
    if (_selectedIndex == 0) {
      await _refreshCustomerRooms(maxAge: const Duration(seconds: 20));
    } else if (_selectedIndex == 1) {
      await _refreshCustomerBookings(maxAge: const Duration(seconds: 20));
    }
  }

  Future<void> _refreshCustomerRooms({required Duration maxAge}) async {
    if (!Get.isRegistered<CustomerBookingController>(tag: _customerBookingTag)) {
      return;
    }
    final controller = Get.find<CustomerBookingController>(tag: _customerBookingTag);
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
    return rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final user = _extractUserFromArgs();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F1D89), Color(0xFF24144D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeTab(user: user),
              BookingTab(user: user),
              ProfileTab(user: user),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
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
    );
  }
}
