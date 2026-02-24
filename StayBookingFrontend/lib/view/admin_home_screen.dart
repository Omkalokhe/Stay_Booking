import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/admin/admin_hotels_controller.dart';
import 'package:stay_booking_frontend/controller/admin/admin_rooms_controller.dart';
import 'package:stay_booking_frontend/controller/admin/admin_users_controller.dart';
import 'package:stay_booking_frontend/controller/review/review_controller.dart';
import 'package:stay_booking_frontend/view/admin/tabs/admin_hotels_tab.dart';
import 'package:stay_booking_frontend/view/admin/tabs/admin_profile_tab.dart';
import 'package:stay_booking_frontend/view/admin/tabs/admin_review_tab.dart';
import 'package:stay_booking_frontend/view/admin/tabs/admin_rooms_tab.dart';
import 'package:stay_booking_frontend/view/admin/tabs/admin_users_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
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
  Widget build(BuildContext context) {
    final rawArgs = Get.arguments;
    final user = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                AdminUsersTab(user: user),
                AdminHotelsTab(user: user),
                AdminRoomsTab(user: user),
                AdminReviewTab(user: user),
                AdminProfileTab(user: user),
              ],
            ),
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'User',
              ),
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment),
                label: 'Hotel',
              ),
              NavigationDestination(
                icon: Icon(Icons.bed_outlined),
                selectedIcon: Icon(Icons.bed),
                label: 'Room',
              ),
              NavigationDestination(
                icon: Icon(Icons.rate_review_outlined),
                selectedIcon: Icon(Icons.rate_review),
                label: 'Review',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCurrentTabIfStale() async {
    await _refreshCurrentTab(force: false);
  }

  Future<void> _refreshCurrentTab({required bool force}) async {
    if (!mounted) return;
    final maxAge = force
        ? const Duration(seconds: 0)
        : const Duration(seconds: 20);

    if (_selectedIndex == 0) {
      const tag = 'admin-users-controller';
      if (Get.isRegistered<AdminUsersController>(tag: tag)) {
        final controller = Get.find<AdminUsersController>(tag: tag);
        await controller.refreshIfStale(maxAge: maxAge);
      }
      return;
    }

    if (_selectedIndex == 1) {
      const tag = 'admin-hotels-controller';
      if (Get.isRegistered<AdminHotelsController>(tag: tag)) {
        final controller = Get.find<AdminHotelsController>(tag: tag);
        await controller.refreshIfStale(maxAge: maxAge);
      }
      return;
    }

    if (_selectedIndex == 2) {
      const tag = 'admin-rooms-controller';
      if (Get.isRegistered<AdminRoomsController>(tag: tag)) {
        final controller = Get.find<AdminRoomsController>(tag: tag);
        await controller.refreshIfStale(maxAge: maxAge);
      }
    }
    if (_selectedIndex == 3) {
      const tag = 'admin-reviews-controller';
      if (Get.isRegistered<ReviewController>(tag: tag)) {
        final controller = Get.find<ReviewController>(tag: tag);
        await controller.refreshAdminReviews();
      }
    }
  }
}
