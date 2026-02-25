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
  late final AnimationController _controller;
  late final Animation<double> _zoomAnimation;
  late final Animation<double> _iconScale;

  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    /// Background zoom
    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    /// Icon pulse
    _iconScale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _timer = Timer(const Duration(seconds: 5), _navigate);
  }

  void _navigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Get.offNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _floatingIcon(IconData icon, Alignment alignment, double delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: (2000 + delay * 500).toInt()),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Align(
          alignment: alignment,
          child: Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, -20 * value),
              child: Icon(icon, color: Colors.white70, size: 32),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background image with zoom animation
          AnimatedBuilder(
            animation: _zoomAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _zoomAnimation.value,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/hotel.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Color(0xAA3F1D89)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          _floatingIcon(Icons.hotel, Alignment.topLeft, 0),
          _floatingIcon(Icons.flight_takeoff, Alignment.topRight, 1),
          _floatingIcon(Icons.location_on, Alignment.bottomLeft, 2),
          _floatingIcon(Icons.luggage, Alignment.bottomRight, 3),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _iconScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _iconScale.value,
                      child: const Icon(
                        Icons.hotel_class,
                        color: Colors.white,
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  "StayBook",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Find your perfect stay",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
