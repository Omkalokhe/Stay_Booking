import 'package:flutter/material.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_booking_tab.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_hotel_tab.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_profile_tab_screen.dart';
import 'package:stay_booking_frontend/view/vendor/tabs/vendor_room_tab.dart';
import 'package:get/get.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _selectedIndex = 0;
  bool _initializedFromArgs = false;

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F1D89), Color.fromARGB(255, 37, 21, 76)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
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
}
