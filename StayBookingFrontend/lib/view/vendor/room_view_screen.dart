import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/service/room/room_service.dart';

class RoomViewScreen extends StatefulWidget {
  const RoomViewScreen({
    required this.room,
    super.key,
  });

  final RoomResponseDto room;

  @override
  State<RoomViewScreen> createState() => _RoomViewScreenState();
}

class _RoomViewScreenState extends State<RoomViewScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  List<String> get _photoUrls => widget.room.photos
      .map(RoomService.roomPhotoUrl)
      .where((url) => url.trim().isNotEmpty)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (_photoUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        final next = (_currentIndex + 1) % _photoUrls.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final hotelName = room.hotelName.trim().isEmpty
        ? 'Hotel #${room.hotelId}'
        : room.hotelName.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(hotelName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imageSlider(),
                  const SizedBox(height: 16),
                  _titleSection(room),
                  const SizedBox(height: 12),
                  _detailCard(
                    children: [
                      _detailRow('Room Type', room.roomType),
                      _detailRow('Hotel', hotelName),
                      _detailRow('Price', 'Rs ${room.price.toStringAsFixed(2)}'),
                      _detailRow('Status', room.available ? 'Available' : 'Unavailable'),
                      _detailRow('Room ID', '${room.id}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailCard(
                    title: 'Description',
                    children: [
                      Text(
                        room.description.trim().isEmpty
                            ? 'No description available.'
                            : room.description,
                        style: const TextStyle(color: Colors.black87, height: 1.4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageSlider() {
    if (_photoUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F2FA),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 36, color: Colors.black54),
            SizedBox(height: 8),
            Text('No room photos available', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photoUrls.length,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  _photoUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => Container(
                    color: const Color(0xFFF4F2FA),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 34),
                  ),
                );
              },
            ),
          ),
        ),
        if (_photoUrls.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: List.generate(
              _photoUrls.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _currentIndex == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? const Color(0xFF6B46E8)
                      : const Color(0xFFD0C8E8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _titleSection(RoomResponseDto room) {
    return Row(
      children: [
        Expanded(
          child: Text(
            room.roomType,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: room.available ? const Color(0xFFDFF6E4) : const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            room.available ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: room.available ? const Color(0xFF1B7D39) : const Color(0xFFC62828),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailCard({String? title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((title ?? '').trim().isNotEmpty) ...[
            Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
