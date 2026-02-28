import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/booking/booking_controller.dart';
import 'package:stay_booking_frontend/controller/payment/payment_flow_controller.dart';
import 'package:stay_booking_frontend/model/booking_response_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_status_request_dto.dart';
import 'package:stay_booking_frontend/view/review/hotel_review_screen.dart';
import 'package:stay_booking_frontend/view/widgets/notification_bell_action.dart';

class BookingTab extends StatefulWidget {
  const BookingTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  late final BookingController _controller;
  late final PaymentFlowController _paymentController;
  final _searchController = TextEditingController();

  bool get _canUpdateStatus => _controller.canUpdateBookingAndPaymentStatus;

  @override
  void initState() {
    super.initState();
    final tag =
        'booking-${(widget.user['email'] as String?)?.trim() ?? 'user'}';
    _controller = Get.isRegistered<BookingController>(tag: tag)
        ? Get.find<BookingController>(tag: tag)
        : Get.put(BookingController(currentUser: widget.user), tag: tag);
    final paymentTag = 'payment-$tag';
    _paymentController =
        Get.isRegistered<PaymentFlowController>(tag: paymentTag)
        ? Get.find<PaymentFlowController>(tag: paymentTag)
        : Get.put(PaymentFlowController(), tag: paymentTag, permanent: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E1E86),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E1E86),
        foregroundColor: Colors.white,
        titleSpacing: 15,
        title: _buildSearchBar(),
        actions: [
          const NotificationBellAction(),
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filters',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _controller.refreshList,
        child: Obx(() {
          if (_controller.isLoading.value && _controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.errorMessage.value.isNotEmpty &&
              _controller.items.isEmpty) {
            return _ErrorState(
              message: _controller.errorMessage.value,
              onRetry: _controller.loadFirstPage,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              return ListView(
                padding: _contentPadding(constraints.maxWidth),
                children: [
                  if (_controller.isEmpty)
                    const _EmptyState(
                      message: 'No bookings found for selected filters.',
                    )
                  else if (isWide)
                    _BookingsTable(
                      items: _controller.items,
                      onView: _openBookingDetails,
                      onEdit: _openUpdateBookingSheet,
                      onStatus: _canUpdateStatus
                          ? _openStatusUpdateSheet
                          : null,
                      onPayNow: _openPayNowSheet,
                      onReview: _openHotelReviewScreen,
                      onCancel: _cancelBookingAndRefresh,
                    )
                  else
                    ..._controller.items.map(_buildBookingCard),
                  const SizedBox(height: 12),
                  _PaginationBar(controller: _controller),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _controller.applySearch,
        decoration: InputDecoration(
          hintText: 'Search bookings',
          filled: true,
          fillColor: const Color(0xFFE7E5EC),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF595761)),
          suffixIcon: IconButton(
            onPressed: () => _controller.applySearch(_searchController.text),
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF595761)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    int? hotelId = _controller.selectedHotelId.value;
    int? roomId = _controller.selectedRoomId.value;
    String? bookingStatus = _controller.bookingStatusFilter.value;
    String? paymentStatus = _controller.paymentStatusFilter.value;
    DateTime? checkInFrom = _controller.checkInFrom.value;
    DateTime? checkOutTo = _controller.checkOutTo.value;
    String sortBy = _controller.sortBy.value;
    String direction = _controller.direction.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final rooms = _controller.roomsForHotel(hotelId);
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
                  children: [
                    DropdownButtonFormField<int?>(
                      initialValue: hotelId,
                      decoration: const InputDecoration(labelText: 'Hotel'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Hotels'),
                        ),
                        ..._controller.hotels.map(
                          (h) => DropdownMenuItem<int?>(
                            value: h.id,
                            child: Text(h.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => hotelId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: roomId,
                      decoration: const InputDecoration(labelText: 'Room'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Rooms'),
                        ),
                        ...rooms.map(
                          (r) => DropdownMenuItem<int?>(
                            value: r.id,
                            child: Text('${r.roomType} (${r.hotelName})'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setModalState(() => roomId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: bookingStatus,
                      decoration: const InputDecoration(
                        labelText: 'Booking Status',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Booking Status'),
                        ),
                        ...BookingController.bookingStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => bookingStatus = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: paymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Payment Status'),
                        ),
                        ...BookingController.paymentStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => paymentStatus = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDate(checkInFrom);
                              if (picked == null) return;
                              setModalState(() => checkInFrom = picked);
                            },
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              checkInFrom == null
                                  ? 'CheckIn From'
                                  : _dateOnly(checkInFrom!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDate(checkOutTo);
                              if (picked == null) return;
                              setModalState(() => checkOutTo = picked);
                            },
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              checkOutTo == null
                                  ? 'CheckOut To'
                                  : _dateOnly(checkOutTo!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sortBy,
                      decoration: const InputDecoration(labelText: 'Sort By'),
                      items: BookingController.sortOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(growable: false),
                      onChanged: (v) =>
                          setModalState(() => sortBy = v ?? 'updatedat'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: direction,
                      decoration: const InputDecoration(labelText: 'Direction'),
                      items: const [
                        DropdownMenuItem(
                          value: 'asc',
                          child: Text('Ascending'),
                        ),
                        DropdownMenuItem(
                          value: 'desc',
                          child: Text('Descending'),
                        ),
                      ],
                      onChanged: (v) =>
                          setModalState(() => direction = v ?? 'desc'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              _searchController.clear();
                              await _controller.resetFilters();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _controller.setHotelFilter(hotelId);
                              await _controller.setRoomFilter(roomId);
                              await _controller.setBookingStatusFilter(
                                bookingStatus,
                              );
                              await _controller.setPaymentStatusFilter(
                                paymentStatus,
                              );
                              await _controller.setCheckInFrom(checkInFrom);
                              await _controller.setCheckOutTo(checkOutTo);
                              await _controller.setSort(sortBy);
                              await _controller.setDirection(direction);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

  Future<void> _openUpdateBookingSheet(BookingResponseDto booking) async {
    DateTime? checkInDate = _parseDate(booking.checkInDate);
    DateTime? checkOutDate = _parseDate(booking.checkOutDate);
    final guestsController = TextEditingController(
      text: '${booking.numberOfGuests}',
    );

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
                  children: [
                    Text(
                      'Update Booking #${booking.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await _pickDate(checkInDate);
                              if (picked == null) return;
                              setModalState(() => checkInDate = picked);
                            },
                            child: Text(
                              checkInDate == null
                                  ? 'Check-In Date'
                                  : _dateOnly(checkInDate!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await _pickDate(checkOutDate);
                              if (picked == null) return;
                              setModalState(() => checkOutDate = picked);
                            },
                            child: Text(
                              checkOutDate == null
                                  ? 'Check-Out Date'
                                  : _dateOnly(checkOutDate!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: guestsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of Guests',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => FilledButton(
                          onPressed: _controller.isSubmitting.value
                              ? null
                              : () async {
                                  if (checkInDate == null ||
                                      checkOutDate == null) {
                                    Get.snackbar(
                                      'Validation',
                                      'Please select check-in and check-out dates.',
                                    );
                                    return;
                                  }
                                  final guests =
                                      int.tryParse(
                                        guestsController.text.trim(),
                                      ) ??
                                      0;
                                  if (guests <= 0) {
                                    Get.snackbar(
                                      'Validation',
                                      'Guests must be greater than 0.',
                                    );
                                    return;
                                  }
                                  final result = await _controller
                                      .updateBooking(
                                        booking.id,
                                        UpdateBookingRequestDto(
                                          checkInDate: _dateOnly(checkInDate!),
                                          checkOutDate: _dateOnly(
                                            checkOutDate!,
                                          ),
                                          numberOfGuests: guests,
                                        ),
                                      );
                                  if (result != null && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: _controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update Booking'),
                        ),
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
    guestsController.dispose();
  }

  Future<void> _openStatusUpdateSheet(BookingResponseDto booking) async {
    if (!_canUpdateStatus) {
      Get.snackbar(
        'Forbidden',
        'Only vendors can update booking or payment status.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    String? bookingStatus = booking.bookingStatus;
    String? paymentStatus = booking.paymentStatus;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: bookingStatus,
                      decoration: const InputDecoration(
                        labelText: 'Booking Status',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Change'),
                        ),
                        ...BookingController.bookingStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => bookingStatus = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: paymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Change'),
                        ),
                        ...BookingController.paymentStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => paymentStatus = v),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => FilledButton(
                          onPressed: _controller.isSubmitting.value
                              ? null
                              : () async {
                                  final result = await _controller.updateStatus(
                                    booking.id,
                                    UpdateBookingStatusRequestDto(
                                      bookingStatus: bookingStatus,
                                      paymentStatus: paymentStatus,
                                    ),
                                  );
                                  if (result != null && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: _controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update Status'),
                        ),
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

  Future<void> _openBookingDetails(BookingResponseDto booking) async {
    final latest = await _controller.getBookingById(booking.id);
    final data = latest ?? booking;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _kv('User', data.userEmail),
                  _kv('Hotel', data.hotelName),
                  _kv('Room', data.roomType),
                  _kv('Check-In', data.checkInDate),
                  _kv('Check-Out', data.checkOutDate),
                  _kv('Guests', '${data.numberOfGuests}'),
                  _kv(
                    'Total Amount',
                    'Rs ${data.totalAmount.toStringAsFixed(2)}',
                  ),
                  _kv('Booking Status', data.bookingStatus),
                  _kv('Payment Status', data.paymentStatus),
                  _kv('Created', data.createdAt),
                  _kv('Updated', data.updatedAt),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canPayNow(BookingResponseDto booking) {
    final paymentStatus = booking.paymentStatus.trim().toUpperCase();
    final bookingStatus = booking.bookingStatus.trim().toUpperCase();
    const blockedBookingStatuses = {'CANCELLED', 'COMPLETED', 'NO_SHOW'};
    return paymentStatus == 'PENDING' &&
        !blockedBookingStatuses.contains(bookingStatus);
  }

  bool _canReview(BookingResponseDto booking) {
    final paymentStatus = booking.paymentStatus.trim().toUpperCase();
    final bookingStatus = booking.bookingStatus.trim().toUpperCase();
    return paymentStatus == 'SUCCESS' ||
        (paymentStatus == 'REFUNDED' && bookingStatus == 'CANCELLED');
  }

  Future<void> _startPaymentForBooking(BookingResponseDto booking) async {
    if (!_canPayNow(booking)) return;
    await _paymentController.startPayment(bookingId: booking.id);
    if (!mounted) return;

    final state = _paymentController.uiState.value;
    final msg = _paymentController.message.value.trim();
    if (state == PaymentUiState.success) {
      _controller.markBookingPaidLocally(booking.id);
      if (mounted) {
        setState(() {});
      }
      await _controller.loadFirstPage(showLoader: false);
      if (mounted) {
        setState(() {});
      }
      unawaited(
        _controller.syncBookingAfterPayment(
          booking.id,
          maxAttempts: 12,
          interval: const Duration(seconds: 3),
        ),
      );
    }
    if (msg.isNotEmpty) {
      Get.snackbar(
        state == PaymentUiState.success ? 'Payment Success' : 'Payment Update',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openPayNowSheet(BookingResponseDto booking) async {
    if (!_canPayNow(booking)) return;
    _paymentController.resetState();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F2FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.hotelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.roomType} | ${booking.checkInDate} to ${booking.checkOutDate}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Amount',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              'Rs ${booking.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_paymentController.message.value.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _paymentController.message.value,
                      style: TextStyle(
                        color:
                            _paymentController.uiState.value ==
                                PaymentUiState.success
                            ? const Color(0xFF1B7D39)
                            : const Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _paymentController.isLoading.value
                          ? null
                          : () async {
                              await _startPaymentForBooking(booking);
                              if (!mounted) return;
                              if (_paymentController.uiState.value ==
                                  PaymentUiState.success) {
                                Navigator.of(this.context).pop();
                              }
                            },
                      icon: _paymentController.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.payments_outlined),
                      label: Text(
                        _paymentController.isLoading.value
                            ? 'Processing...'
                            : 'Pay Now',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openHotelReviewScreen(BookingResponseDto booking) async {
    await Get.to(
      () => HotelReviewScreen(
        hotelId: booking.hotelId,
        hotelName: booking.hotelName,
        currentUser: widget.user,
      ),
    );
  }

  Future<void> _cancelBookingAndRefresh(BookingResponseDto booking) async {
    await _controller.cancelBooking(booking);
    if (!mounted) return;
    setState(() {});
    await _controller.loadFirstPage(showLoader: false);
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBookingCard(BookingResponseDto booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.hotelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.roomType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                _bookingActionButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  onTap: () => _openBookingDetails(booking),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${booking.checkInDate} to ${booking.checkOutDate}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Guests: ${booking.numberOfGuests}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                Text(
                  'Rs ${booking.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  label: 'Booking: ${booking.bookingStatus}',
                  isPositive:
                      booking.bookingStatus.trim().toUpperCase() == 'CONFIRMED',
                ),
                _statusChip(
                  label: 'Payment: ${booking.paymentStatus}',
                  isPositive:
                      booking.paymentStatus.trim().toUpperCase() == 'SUCCESS',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _bookingActionButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onTap: () => _openUpdateBookingSheet(booking),
                    expand: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _bookingActionButton(
                    label: _canUpdateStatus
                        ? 'Status'
                        : _canPayNow(booking)
                        ? 'Pay Now'
                        : _canReview(booking)
                        ? 'Review'
                        : 'View',
                    icon: _canUpdateStatus
                        ? Icons.swap_horiz_outlined
                        : _canPayNow(booking)
                        ? Icons.payments_outlined
                        : _canReview(booking)
                        ? Icons.rate_review_outlined
                        : Icons.visibility_outlined,
                    onTap: _canUpdateStatus
                        ? () => _openStatusUpdateSheet(booking)
                        : _canPayNow(booking)
                        ? () => _openPayNowSheet(booking)
                        : _canReview(booking)
                        ? () => _openHotelReviewScreen(booking)
                        : () => _openBookingDetails(booking),
                    expand: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _bookingActionButton(
                    label: 'Cancel',
                    icon: Icons.cancel_outlined,
                    onTap: () => _cancelBookingAndRefresh(booking),
                    isDestructive: true,
                    expand: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingActionButton({
    required String label,
    required IconData icon,
    required Future<void> Function() onTap,
    bool isDestructive = false,
    bool expand = false,
  }) {
    final fg = isDestructive
        ? const Color(0xFFC62828)
        : const Color(0xFF4A4458);
    final bg = isDestructive
        ? const Color(0xFFFDECEC)
        : const Color(0xFFF4F2FA);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: bg == const Color(0xFFF4F2FA)
                ? const Color(0xFFE1DDEE)
                : const Color(0xFFF6D3D3),
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: expand
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip({required String label, required bool isPositive}) {
    final bg = isPositive ? const Color(0xFFDFF6E4) : const Color(0xFFF4F2FA);
    final fg = isPositive ? const Color(0xFF1B7D39) : const Color(0xFF4A4458);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$key:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDate: initial ?? now,
    );
  }

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _dateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  EdgeInsets _contentPadding(double width) {
    final horizontal = width >= 1200
        ? 32.0
        : width >= 900
        ? 24.0
        : 16.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24);
  }
}

class _BookingsTable extends StatelessWidget {
  const _BookingsTable({
    required this.items,
    required this.onView,
    required this.onEdit,
    required this.onStatus,
    required this.onPayNow,
    required this.onReview,
    required this.onCancel,
  });

  final List<BookingResponseDto> items;
  final ValueChanged<BookingResponseDto> onView;
  final ValueChanged<BookingResponseDto> onEdit;
  final ValueChanged<BookingResponseDto>? onStatus;
  final ValueChanged<BookingResponseDto> onPayNow;
  final ValueChanged<BookingResponseDto> onReview;
  final ValueChanged<BookingResponseDto> onCancel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Hotel')),
          DataColumn(label: Text('Room')),
          DataColumn(label: Text('Check-In')),
          DataColumn(label: Text('Check-Out')),
          DataColumn(label: Text('Guests')),
          DataColumn(label: Text('Booking')),
          DataColumn(label: Text('Payment')),
          DataColumn(label: Text('Actions')),
        ],
        rows: items
            .map(
              (b) => DataRow(
                cells: [
                  DataCell(Text('${b.id}')),
                  DataCell(Text(b.hotelName)),
                  DataCell(Text(b.roomType)),
                  DataCell(Text(b.checkInDate)),
                  DataCell(Text(b.checkOutDate)),
                  DataCell(Text('${b.numberOfGuests}')),
                  DataCell(Text(b.bookingStatus)),
                  DataCell(Text(b.paymentStatus)),
                  DataCell(
                    Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () => onView(b),
                          tooltip: 'View',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(b),
                          tooltip: 'Edit',
                        ),
                        if (onStatus != null)
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_outlined),
                            onPressed: () => onStatus!(b),
                            tooltip: 'Status',
                          ),
                        if (onStatus == null && _canPayNowRow(b))
                          IconButton(
                            icon: const Icon(Icons.payments_outlined),
                            onPressed: () => onPayNow(b),
                            tooltip: 'Pay Now',
                          ),
                        if (onStatus == null && _canReviewRow(b))
                          IconButton(
                            icon: const Icon(Icons.rate_review_outlined),
                            onPressed: () => onReview(b),
                            tooltip: 'Review',
                          ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          onPressed: () => onCancel(b),
                          tooltip: 'Cancel',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  bool _canPayNowRow(BookingResponseDto booking) {
    final paymentStatus = booking.paymentStatus.trim().toUpperCase();
    final bookingStatus = booking.bookingStatus.trim().toUpperCase();
    const blockedBookingStatuses = {'CANCELLED', 'COMPLETED', 'NO_SHOW'};
    return paymentStatus == 'PENDING' &&
        !blockedBookingStatuses.contains(bookingStatus);
  }

  bool _canReviewRow(BookingResponseDto booking) {
    final paymentStatus = booking.paymentStatus.trim().toUpperCase();
    final bookingStatus = booking.bookingStatus.trim().toUpperCase();
    return paymentStatus == 'SUCCESS' ||
        (paymentStatus == 'REFUNDED' && bookingStatus == 'CANCELLED');
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.controller});

  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Total: ${controller.totalElements.value} | Page ${controller.page.value + 1}/${controller.totalPages.value}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: controller.isFirstPage.value
              ? null
              : controller.goToPreviousPage,
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        IconButton(
          onPressed: controller.isLastPage.value
              ? null
              : controller.goToNextPage,
          icon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool showLoader}) onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => onRetry(showLoader: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
