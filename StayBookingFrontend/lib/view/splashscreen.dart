import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _title = 'Splash Screen';
  late final AnimationController _controller;
  late final List<String> _chars;
  late final List<Interval> _charIntervals;
  Timer? _fallbackTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _navigateToLogin();
        }
      })
      ..forward();

    // Fallback so splash cannot get stuck if animation callbacks are skipped.
    _fallbackTimer = Timer(const Duration(seconds: 6), _navigateToLogin);

    _chars = _title.split('');

    final step = 0.8 / _chars.length;
    _charIntervals = List<Interval>.generate(_chars.length, (index) {
      final start = step * index;
      final end = (start + 0.25).clamp(0.0, 1.0);
      return Interval(start, end, curve: Curves.easeOutCubic);
    });
  }

  Widget _buildAnimatedChar(String char, Interval interval, double fontSize) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: interval,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.2),
          end: Offset.zero,
        ).animate(curved),
        child: Text(
          char,
          style: _textStyle(fontSize),
        ),
      ),
    );
  }

  TextStyle _textStyle(double fontSize) {
    return TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(
          color: Colors.white54,
          blurRadius: 8,
        ),
        Shadow(
          color: Colors.white30,
          blurRadius: 14,
        ),
      ],
    );
  }

  double _responsiveFontSize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide < 360) return 32;
    if (shortestSide < 600) return 40;
    return 52;
  }

  void _navigateToLogin() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Get.offNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = _responsiveFontSize(context);

    return Scaffold(
      body: Container(
        color: Colors.deepPurple,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(
                _chars.length,
                (index) => _buildAnimatedChar(
                  _chars[index],
                  _charIntervals[index],
                  fontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
