import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/service/hotel/hotel_service.dart';
import 'package:stay_booking_frontend/service/room/room_service.dart';
import 'package:stay_booking_frontend/view/vendor/room_view_screen.dart';

class HotelDetailsScreen extends StatefulWidget {
  const HotelDetailsScreen({
    required this.hotel,
    this.user,
    super.key,
  });

  final HotelResponseDto hotel;
  final Map<String, dynamic>? user;

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  final HotelService _hotelService = HotelService();
  final RoomService _roomService = RoomService();

  bool _isLoading = true;
  String _errorMessage = '';
  late HotelResponseDto _hotel;
  final List<RoomResponseDto> _rooms = <RoomResponseDto>[];

  @override
  void initState() {
    super.initState();
    _hotel = widget.hotel;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final hotelResult = await _hotelService.getHotelById(widget.hotel.id);
      if (hotelResult.success && hotelResult.item != null) {
        _hotel = hotelResult.item!;
      }

      final rooms = await _loadRoomsForHotel(_hotel);
      _rooms
        ..clear()
        ..addAll(rooms);
    } catch (_) {
      _errorMessage = 'Unable to load hotel details. Please try again.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<RoomResponseDto>> _loadRoomsForHotel(HotelResponseDto hotel) async {
    final collected = <RoomResponseDto>[];
    var currentPage = 0;
    var totalPages = 1;

    while (currentPage < totalPages && currentPage < 20) {
      final result = await _roomService.getRooms(
        page: currentPage,
        size: 50,
        sortBy: 'updatedat',
        direction: 'desc',
        hotelName: hotel.name,
      );
      if (!result.success) break;

      final matched = result.items.where((room) {
        if (room.hotelId > 0) return room.hotelId == hotel.id;
        return room.hotelName.trim().toLowerCase() ==
            hotel.name.trim().toLowerCase();
      });
      collected.addAll(matched);

      totalPages = result.totalPages <= 0 ? 1 : result.totalPages;
      currentPage += 1;
    }
    return collected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage.isNotEmpty) ...[
                    _errorBanner(_errorMessage),
                    const SizedBox(height: 12),
                  ],
                  _hotelHeader(_hotel),
                  const SizedBox(height: 16),
                  _detailCard(_hotel),
                  const SizedBox(height: 16),
                  Text(
                    'Rooms (${_rooms.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (_rooms.isEmpty)
                    _emptyRooms()
                  else
                    ..._rooms.map(_roomCard),
                ],
              ),
            ),
    );
  }

  Widget _hotelHeader(HotelResponseDto hotel) {
    if (hotel.photoUrls.isEmpty) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDFF),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.hotel_rounded, size: 60, color: Color(0xFF5A31D6)),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hotel.photoUrls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final url = ApiEndpoints.resolveUrl(hotel.photoUrls[index]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF2EDFF),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailCard(HotelResponseDto hotel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hotel.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('${hotel.city}, ${hotel.state}, ${hotel.country}'),
          const SizedBox(height: 6),
          if (hotel.address.isNotEmpty) Text('Address: ${hotel.address}'),
          if (hotel.pincode.isNotEmpty) Text('Pincode: ${hotel.pincode}'),
          const SizedBox(height: 6),
          Text('Rating: ${hotel.rating.toStringAsFixed(1)}'),
          const SizedBox(height: 8),
          Text(
            hotel.description.isEmpty ? 'No description available.' : hotel.description,
          ),
        ],
      ),
    );
  }

  Widget _roomCard(RoomResponseDto room) {
    final photo = room.photos.isNotEmpty ? RoomService.roomPhotoUrl(room.photos.first) : '';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final detailedRoom = await _getRoomForView(room);
        if (!mounted) return;
        Get.to(() => RoomViewScreen(room: detailedRoom, user: widget.user));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 8,
                    child: Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF1EEFA),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              if (photo.isNotEmpty) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.roomType,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _statusChip(room.available),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                room.description.isEmpty ? 'No description added.' : room.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text('Price: Rs ${room.price.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }

  Future<RoomResponseDto> _getRoomForView(RoomResponseDto summaryRoom) async {
    try {
      final result = await _roomService.getRoomById(summaryRoom.id);
      if (result.success && result.item != null) {
        return result.item!;
      }
    } catch (_) {
      // Fall back to summary payload.
    }
    return summaryRoom;
  }

  Widget _statusChip(bool available) {
    final color = available ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Available' : 'Unavailable',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _emptyRooms() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('No rooms found for this hotel.'),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }
}
