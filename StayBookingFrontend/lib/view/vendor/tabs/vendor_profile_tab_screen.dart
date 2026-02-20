import 'package:flutter/material.dart';

import 'package:stay_booking_frontend/view/home/tabs/profile_tab.dart';

class VendorProfileTabScreen extends StatelessWidget {
  const VendorProfileTabScreen({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return ProfileTab(user: user);
  }
}
