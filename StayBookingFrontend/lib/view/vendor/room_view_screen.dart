import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/booking/booking_controller.dart';
import 'package:stay_booking_frontend/model/booking_response_dto.dart';
import 'package:stay_booking_frontend/model/create_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/service/booking/booking_service.dart';
import 'package:stay_booking_frontend/service/room/room_service.dart';
import 'package:stay_booking_frontend/view/review/widgets/hotel_reviews_section.dart';

class RoomViewScreen extends StatefulWidget {
  const RoomViewScreen({required this.room, this.user, super.key});

  final RoomResponseDto room;
  final Map<String, dynamic>? user;

  @override
  State<RoomViewScreen> createState() => _RoomViewScreenState();
}

class _RoomViewScreenState extends State<RoomViewScreen> {
  late final PageController _pageController;
  final BookingService _bookingService = BookingService();
  Timer? _timer;
  int _currentIndex = 0;
  bool _isBookingSubmitting = false;
  bool _isCheckingExistingBooking = false;
  BookingResponseDto? _activeBookingForRoom;

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
    _loadExistingBookingState();
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
      backgroundColor: const Color(0xFF3F1D89),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F1D89),
        foregroundColor: Colors.white,
        title: Text(hotelName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      bottomNavigationBar: _canBook
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _canPerformBookingAction
                      ? _openBookNowSheet
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3F1D89),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isBookingSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_bookingButtonIcon),
                  label: Text(
                    _bookingButtonLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            )
          : null,
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
                      _detailRow(
                        'Price',
                        'Rs ${room.price.toStringAsFixed(2)}',
                      ),
                      _detailRow(
                        'Status',
                        room.available ? 'Available' : 'Unavailable',
                      ),
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
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailCard(
                    title: 'Guest Reviews',
                    children: [
                      HotelReviewsSection(
                        hotelId: room.hotelId,
                        hotelName: hotelName,
                        currentUser: widget.user ?? const <String, dynamic>{},
                        tagPrefix: 'hotel-reviews-room',
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 36,
              color: Colors.black54,
            ),
            SizedBox(height: 8),
            Text(
              'No room photos available',
              style: TextStyle(color: Colors.black54),
            ),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: room.available
                ? const Color(0xFFDFF6E4)
                : const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            room.available ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: room.available
                  ? const Color(0xFF1B7D39)
                  : const Color(0xFFC62828),
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
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  bool get _canBook {
    final user = widget.user;
    if (user == null) return false;
    final role = (user['role'] as String?)?.trim().toUpperCase() ?? '';
    if (role == 'ADMIN' || role == 'VENDOR') return false;
    return _currentUserId != null;
  }

  bool get _canPerformBookingAction {
    return !_isBookingSubmitting &&
        !_isCheckingExistingBooking &&
        _activeBookingForRoom == null &&
        widget.room.available;
  }

  IconData get _bookingButtonIcon {
    if (_isCheckingExistingBooking) return Icons.hourglass_top_rounded;
    if (_activeBookingForRoom != null) {
      return Icons.check_circle_outline_rounded;
    }
    if (!widget.room.available) return Icons.block_outlined;
    return Icons.calendar_month_outlined;
  }

  String get _bookingButtonLabel {
    if (_isCheckingExistingBooking) return 'Checking booking status...';
    if (_activeBookingForRoom != null) {
      return 'Booking ${_activeBookingForRoom!.bookingStatus}';
    }
    if (!widget.room.available) return 'Room Unavailable';
    return 'Book Now';
  }

  int? get _currentUserId {
    final raw = widget.user?['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<void> _loadExistingBookingState() async {
    if (!_canBook) return;
    final userId = _currentUserId;
    if (userId == null) return;

    setState(() {
      _isCheckingExistingBooking = true;
    });

    final result = await _bookingService.getBookings(
      page: 0,
      size: 100,
      sortBy: 'updatedat',
      direction: 'desc',
      userId: userId,
      roomId: widget.room.id,
    );

    BookingResponseDto? activeBooking;
    if (result.success) {
      for (final booking in result.pageData.content) {
        if (_isActiveBooking(booking)) {
          activeBooking = booking;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _activeBookingForRoom = activeBooking;
      _isCheckingExistingBooking = false;
    });
  }

  bool _isActiveBooking(BookingResponseDto booking) {
    final status = booking.bookingStatus.trim().toUpperCase();
    if (status != 'PENDING' && status != 'CONFIRMED') {
      return false;
    }

    final checkout = DateTime.tryParse(booking.checkOutDate);
    if (checkout == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkoutDateOnly = DateTime(
      checkout.year,
      checkout.month,
      checkout.day,
    );
    return !checkoutDateOnly.isBefore(today);
  }

  Future<void> _openBookNowSheet() async {
    DateTime? checkInDate = DateTime.now();
    DateTime? checkOutDate = DateTime.now().add(const Duration(days: 1));
    String guestsText = '1';
    bool isSheetSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book ${widget.room.roomType}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selected = await _pickDate(checkInDate);
                              if (selected == null) return;
                              setModalState(() {
                                checkInDate = selected;
                                if (checkOutDate != null &&
                                    !checkOutDate!.isAfter(checkInDate!)) {
                                  checkOutDate = checkInDate!.add(
                                    const Duration(days: 1),
                                  );
                                }
                              });
                            },
                            icon: const Icon(Icons.event_available_outlined),
                            label: Text(_dateOnly(checkInDate!)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selected = await _pickDate(
                                checkOutDate,
                                minDate: checkInDate?.add(
                                  const Duration(days: 1),
                                ),
                              );
                              if (selected == null) return;
                              setModalState(() => checkOutDate = selected);
                            },
                            icon: const Icon(Icons.event_busy_outlined),
                            label: Text(_dateOnly(checkOutDate!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      enabled: !isSheetSubmitting,
                      initialValue: guestsText,
                      onChanged: (value) => guestsText = value,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of Guests',
                        prefixIcon: Icon(Icons.group_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_isBookingSubmitting || isSheetSubmitting)
                            ? null
                            : () async {
                                final userId = _currentUserId;
                                if (userId == null) {
                                  Get.snackbar(
                                    'Error',
                                    'Unable to identify current user.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                final guests = int.tryParse(guestsText.trim());
                                if (guests == null || guests <= 0) {
                                  Get.snackbar(
                                    'Validation',
                                    'Guests must be greater than 0.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                if (checkInDate == null ||
                                    checkOutDate == null) {
                                  Get.snackbar(
                                    'Validation',
                                    'Check-in and check-out dates are required.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                if (!checkOutDate!.isAfter(checkInDate!)) {
                                  Get.snackbar(
                                    'Validation',
                                    'Check-out must be after check-in date.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }

                                setModalState(() => isSheetSubmitting = true);
                                setState(() => _isBookingSubmitting = true);
                                final controller = _resolveBookingController();
                                final result = await controller.createBooking(
                                  CreateBookingRequestDto(
                                    userId: userId,
                                    hotelId: widget.room.hotelId,
                                    roomId: widget.room.id,
                                    checkInDate: _dateOnly(checkInDate!),
                                    checkOutDate: _dateOnly(checkOutDate!),
                                    numberOfGuests: guests,
                                  ),
                                );
                                if (!mounted) return;
                                setState(() => _isBookingSubmitting = false);
                                if (context.mounted) {
                                  setModalState(
                                    () => isSheetSubmitting = false,
                                  );
                                }

                                if (result != null && context.mounted) {
                                  setState(() {
                                    _activeBookingForRoom = result;
                                  });
                                  Navigator.of(context).pop();
                                }
                              },
                        child: const Text('Confirm Booking'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  BookingController _resolveBookingController() {
    final user = widget.user ?? <String, dynamic>{};
    final email = (user['email'] as String?)?.trim() ?? 'user';
    final tag = 'booking-$email';
    if (Get.isRegistered<BookingController>(tag: tag)) {
      return Get.find<BookingController>(tag: tag);
    }
    return Get.put(BookingController(currentUser: user), tag: tag);
  }

  Future<DateTime?> _pickDate(DateTime? initial, {DateTime? minDate}) {
    final now = DateTime.now();
    final safeMin = DateTime(now.year, now.month, now.day);
    final firstDate = minDate ?? safeMin;
    final initialDate = initial != null && !initial.isBefore(firstDate)
        ? initial
        : firstDate;

    return showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      initialDate: initialDate,
    );
  }

  String _dateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
